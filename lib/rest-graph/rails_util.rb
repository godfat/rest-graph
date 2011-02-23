
require 'cgi'
require 'uri'

require 'rest-graph/core'

if Rails::VERSION::MAJOR >= 3
  class RestGraph
    class Railtie < Rails::Railtie
      initializer 'rest-graph' do |app|
        RestGraph::RailsUtil.init(app)
      end
    end
  end
end

# this cannot be put here because of load order,
# so put in the bottom of this file to load up for rails2.
# if Rails::VERSION::MAJOR == 2
#   ::RestGraph::RailsUtil.init(Rails)
# end

class RestGraph
  module DefaultAttributes
    def default_canvas                ; ''   ; end
    def default_iframe                ; false; end
    def default_auto_authorize        ; false; end
    def default_auto_authorize_options; {}   ; end
    def default_auto_authorize_scope  ; ''   ; end
    def default_ensure_authorized     ; false; end
    def default_write_session         ; false; end
    def default_write_cookies         ; false; end
    def default_write_handler         ;   nil; end
    def default_check_handler         ;   nil; end
  end

  module RailsCache
    def []    key       ;  read(key)                ; end
    def []=   key, value; write(key, value)         ; end
    def store key, value,
              options={}; write(key, value, options); end
  end
end

module RestGraph::RailsUtil
  def self.init app=Rails
    ActiveSupport::Cache::Store.send(:include, RestGraph::RailsCache)
    RestGraph::ConfigUtil.load_config_for_rails(app)
  end

  module Helper
    def rest_graph
      controller.send(:rest_graph)
    end
  end

  def self.included controller
    # skip if included already, any better way to detect this?
    return if controller.respond_to?(:rest_graph, true)

    controller.rescue_from(RestGraph::Error::AccessToken,
                           :with => :rest_graph_on_error)
    controller.helper(RestGraph::RailsUtil::Helper)
    controller.instance_methods.select{ |method|
      method.to_s =~ /^rest_graph/
    }.each{ |method| controller.send(:protected, method) }
  end

  def rest_graph_setup options={}
    rest_graph_options_ctl.merge!(rest_graph_extract_options(options, :reject))
    rest_graph_options_new.merge!(rest_graph_extract_options(options, :select))

    # we'll need to reinitialize rest_graph with the new options,
    # otherwise if you're calling rest_graph before rest_graph_setup,
    # you'll end up with default options without the ones you've passed
    # into rest_graph_setup.
    rest_graph.send(:initialize, rest_graph_options_new)

    rest_graph_check_params_signed_request # canvas
    rest_graph_check_params_session        # i think it would be deprecated
    rest_graph_check_cookie                # for js sdk (canvas or not)
    rest_graph_check_code                  # oauth api

    # there are above 4 ways to check the user identity!
    # if nor of them passed, then we can suppose the user
    # didn't authorize for us, but we can check if user has authorized
    # before, in that case, the fbs would be inside session,
    # as we just saved it there

    rest_graph_check_rg_fbs # check rest-graph storage

    if rest_graph_oget(:ensure_authorized) && !rest_graph.authorized?
      rest_graph_authorize('ensure authorized')
      false # action halt, redirect to do authorize,
            # eagerly, as opposed to auto_authorize
    else
      true  # keep going
    end
  end

  # override this if you need different app_id and secret
  def rest_graph
    @rest_graph ||= RestGraph.new(rest_graph_options_new)
  end

  def rest_graph_on_error error=nil
    rest_graph_authorize(error, false)
  end

  def rest_graph_authorize error=nil, force_redirect=true
    logger.warn("WARN: RestGraph: #{error.inspect}")

    if force_redirect || rest_graph_auto_authorize?
      @rest_graph_authorize_url = rest_graph.authorize_url(
        {:redirect_uri => rest_graph_normalized_request_uri,
         :scope        => rest_graph_oget(:auto_authorize_scope)}.
        merge(rest_graph_oget(:auto_authorize_options)))

      logger.debug("DEBUG: RestGraph: redirect to #{@rest_graph_authorize_url}")

      cookies.delete("fbs_#{rest_graph.app_id}")
      rest_graph_authorize_redirect
    end
  end

  # override this if you want the simple redirect_to
  def rest_graph_authorize_redirect
    unless rest_graph_in_canvas?
      redirect_to @rest_graph_authorize_url
    else
      rest_graph_js_redirect(@rest_graph_authorize_url,
                              rest_graph_authorize_body)
    end
  end

  def rest_graph_js_redirect redirect_url, body=''
    render :inline => <<-HTML
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    <html>
      <head>
      <script type="text/javascript">
        window.top.location.href = '#{redirect_url}'
      </script>
      <noscript>
        <meta http-equiv="refresh" content="0;url=#{
          CGI.escapeHTML(redirect_url)}"/>
        <meta http-equiv="window-target" content="_top"/>
      </noscript>
      </head>
      <body>
        #{body}
      </bodt>
    </html>
    HTML
  end

  def rest_graph_authorize_body redirect_url=@rest_graph_authorize_url
    <<-HTML
    <div>
      Please
      <a href="#{CGI.escapeHTML(redirect_url)}" target="_top">authorize</a>
      if this page is not automatically redirected.
    </div>
    HTML
  end

  module_function

  # ==================== begin options utility =======================
  def rest_graph_oget key
    if rest_graph_options_ctl.has_key?(key)
      rest_graph_options_ctl[key]
    else
      RestGraph.send("default_#{key}")
    end
  end

  def rest_graph_options_ctl
    @rest_graph_options_ctl ||= {}
  end

  def rest_graph_options_new
    @rest_graph_options_new ||= {:log_method => logger.method(:debug)}
  end
  # ==================== end options utility =======================



  # ==================== begin facebook check ======================
  def rest_graph_check_params_signed_request
    return if rest_graph.authorized? || !params[:signed_request]

    rest_graph.parse_signed_request!(params[:signed_request])
    logger.debug("DEBUG: RestGraph: detected signed_request, parsed:" \
                 " #{rest_graph.data.inspect}")

    if rest_graph.authorized?
      rest_graph_write_rg_fbs
    else
      logger.warn(
        "WARN: RestGraph: bad signed_request: #{params[:signed_request]}")
    end
  end

  # if the code is bad or not existed,
  # check if there's one in session,
  # meanwhile, there the sig and access_token is correct,
  # that means we're in the context of canvas
  def rest_graph_check_params_session
    return if rest_graph.authorized? || !params[:session]

    rest_graph.parse_json!(params[:session])
    logger.debug("DEBUG: RestGraph: detected session, parsed:" \
                 " #{rest_graph.data.inspect}")

    if rest_graph.authorized?
      rest_graph_write_rg_fbs
    else
      logger.warn("WARN: RestGraph: bad session: #{params[:session]}")
    end
  end

  # if we're not in canvas nor code passed,
  # we could check out cookies as well.
  def rest_graph_check_cookie
    return if rest_graph.authorized? ||
              !cookies["fbs_#{rest_graph.app_id}"]

    rest_graph.parse_cookies!(cookies)
    logger.debug("DEBUG: RestGraph: detected cookies, parsed:" \
                 " #{rest_graph.data.inspect}")
  end

  # exchange the code with access_token
  def rest_graph_check_code
    return if rest_graph.authorized? || !params[:code]

    rest_graph.authorize!(:code => params[:code],
                          :redirect_uri => rest_graph_normalized_request_uri)
    logger.debug(
      "DEBUG: RestGraph: detected code with "  \
      "#{rest_graph_normalized_request_uri}, " \
      "parsed: #{rest_graph.data.inspect}")

    rest_graph_write_rg_fbs if rest_graph.authorized?
  end
  # ==================== end facebook check ======================



  # ==================== begin check ================================
  def rest_graph_storage_key
    "rest_graph_fbs_#{rest_graph_oget(:app_id)}"
  end

  def rest_graph_check_rg_fbs
    rest_graph_check_rg_handler # custom method to store fbs
    rest_graph_check_rg_session # prefered way to store fbs
    rest_graph_check_rg_cookies # in canvas, session might not work..
  end

  def rest_graph_check_rg_handler handler=rest_graph_oget(:check_handler)
    return if rest_graph.authorized? || !handler
    rest_graph.parse_fbs!(handler.call)
    logger.debug("DEBUG: RestGraph: called check_handler, parsed:" \
                 " #{rest_graph.data.inspect}")
  end

  def rest_graph_check_rg_session
    return if rest_graph.authorized? || !rest_graph_oget(:write_session) ||
              !(fbs = session[rest_graph_storage_key])
    rest_graph.parse_fbs!(fbs)
    logger.debug("DEBUG: RestGraph: detected rest-graph session, parsed:" \
                 " #{rest_graph.data.inspect}")
  end

  def rest_graph_check_rg_cookies
    return if rest_graph.authorized? || !rest_graph_oget(:write_cookies) ||
              !(fbs = cookies[rest_graph_storage_key])
    rest_graph.parse_fbs!(fbs)
    logger.debug("DEBUG: RestGraph: detected rest-graph cookies, parsed:" \
                 " #{rest_graph.data.inspect}")
  end
  # ====================   end check ================================
  # ==================== begin write ================================
  def rest_graph_write_rg_fbs
    cookies.delete("fbs_#{rest_graph.app_id}")
    rest_graph_write_rg_handler
    rest_graph_write_rg_session
    rest_graph_write_rg_cookies
  end

  def rest_graph_write_rg_handler handler=rest_graph_oget(:write_handler)
    return if !handler
    handler.call(fbs = rest_graph.fbs)
    logger.debug("DEBUG: RestGraph: called write_handler: fbs => #{fbs}")
  end

  def rest_graph_write_rg_session
    return if !rest_graph_oget(:write_session)
    session[rest_graph_storage_key] = fbs = rest_graph.fbs
    logger.debug("DEBUG: RestGraph: wrote session: fbs => #{fbs}")
  end

  def rest_graph_write_rg_cookies
    return if !rest_graph_oget(:write_cookies)
    cookies[rest_graph_storage_key] = fbs = rest_graph.fbs
    logger.debug("DEBUG: RestGraph: wrote cookies: fbs => #{fbs}")
  end
  # ==================== end write ================================



  # ==================== begin misc ================================
  def rest_graph_normalized_request_uri
    uri = if rest_graph_in_canvas?
            # rails 3 uses newer rack which has fullpath
            "http://apps.facebook.com/#{rest_graph_oget(:canvas)}" +
            (request.respond_to?(:fullpath) ?
              request.fullpath : request.request_uri)
          else
            request.url
          end

    rest_graph_filter_uri(uri)
  end

  def rest_graph_filter_uri uri
    URI.parse(URI.encode(uri)).tap{ |uri|
      uri.query = uri.query.split('&').reject{ |q|
                    q =~ /^(code|session|signed_request)\=/
                  }.join('&') if uri.query
      uri.query = nil if uri.query.blank?
    }.to_s
  end

  def rest_graph_in_canvas?
    !rest_graph_oget(:canvas).blank?
  end

  def rest_graph_auto_authorize?
    !rest_graph_oget(:auto_authorize_scope)  .blank? ||
    !rest_graph_oget(:auto_authorize_options).blank? ||
     rest_graph_oget(:auto_authorize)
  end

  def rest_graph_extract_options options, method
    # Hash[] is for ruby 1.8.7
    Hash[options.send(method){ |(k, v)| RestGraph::Attributes.member?(k) }]
  end
  # ==================== end misc ================================
end

if Rails::VERSION::MAJOR == 2
  RestGraph::RailsUtil.init(Rails)
end
