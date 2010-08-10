
require 'rest-graph'

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
    def []  key       ;  read(key)       ; end
    def []= key, value; write(key, value); end
  end
end

::ActiveSupport::Cache::Store.send(:include, ::RestGraph::RailsCache)

module RestGraph::RailsUtil
  module Helper
    def rest_graph
      controller.rest_graph
    end
  end

  def self.included controller
    controller.rescue_from(::RestGraph::Error){ |exception|
      logger.debug("DEBUG: RestGraph: action halt")
    }
    controller.helper(::RestGraph::RailsUtil::Helper)
  end

  def rest_graph_setup options={}
    rest_graph_options_ctl.merge!(rest_graph_extract_options(options, :reject))
    rest_graph_options_new.merge!(rest_graph_extract_options(options, :select))

    rest_graph_check_cookie                # for javascript sdk (canvas or not)
    rest_graph_check_params_signed_request # canvas
    rest_graph_check_params_session        # i think it would be deprecated
    rest_graph_check_code                  # oauth api

    # there are above 4 ways to check the user identity!
    # if nor of them passed, then we can suppose the user
    # didn't authorize for us, but we can check if user has authorized
    # before, in that case, the fbs would be inside session,
    # as we just saved it there

    rest_graph_check_rg_fbs # check rest-graph storage

    if rest_graph_oget(:ensure_authorized) && !rest_graph.authorized?
      rest_graph_authorize('ensure authorized', true)
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

  def rest_graph_authorize error=nil, redirect=false
    logger.warn("WARN: RestGraph: #{error.inspect}")

    if redirect || rest_graph_auto_authorize?
      @rest_graph_authorize_url = rest_graph.authorize_url(
        {:redirect_uri => rest_graph_normalized_request_uri,
         :scope        => rest_graph_oget(:auto_authorize_scope)}.
        merge(rest_graph_oget(:auto_authorize_options)))

      logger.debug("DEBUG: RestGraph: redirect to #{@rest_graph_authorize_url}")

      rest_graph_authorize_redirect
    end

    raise ::RestGraph::Error.new(error)
  end

  # override this if you want the simple redirect_to
  def rest_graph_authorize_redirect
    if !rest_graph_oget(:iframe)
      redirect_to @rest_graph_authorize_url
    else
      # for rails 3
      @rest_graph_safe_url = if ''.respond_to?(:html_safe)
                               @rest_graph_authorize_url.html_safe
                             else
                               @rest_graph_authorize_url
                             end

      render :inline => <<-HTML
      <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
      "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
      <html>
        <head>
        <script type="text/javascript">
          window.top.location.href = '<%= @rest_graph_safe_url %>'
        </script>
        <noscript>
          <meta http-equiv="refresh" content="0;url=<%= h @rest_graph_authorize_url %>" />
          <meta http-equiv="window-target" content="_top" />
        </noscript>
        </head>
        <body>
          <div>Please <a href="<%= h @rest_graph_authorize_url %>" target="_top">authorize</a> if this page is not automatically redirected.</div>
        </body>
      </html>
      HTML
    end
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
    @rest_graph_options_new ||=
      {:error_handler => method(:rest_graph_authorize),
         :log_handler => method(:rest_graph_log)}
  end
  # ==================== end options utility =======================



  # ==================== begin facebook check ======================
  # if we're not in canvas nor code passed,
  # we could check out cookies as well.
  def rest_graph_check_cookie
    return if rest_graph.authorized? ||
              !cookies["fbs_#{rest_graph.app_id}"]

    rest_graph.parse_cookies!(cookies)
    logger.debug("DEBUG: RestGraph: detected cookies, parsed:" \
                 " #{rest_graph.data.inspect}")
  end

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
    return if rest_graph.authorized? ||
              !(fbs = session[rest_graph_storage_key])
    rest_graph.parse_fbs!(fbs)
    logger.debug("DEBUG: RestGraph: detected rest-graph session, parsed:" \
                 " #{rest_graph.data.inspect}")
  end

  def rest_graph_check_rg_cookies
    return if rest_graph.authorized? ||
              !(fbs = cookies[rest_graph_storage_key])
    rest_graph.parse_fbs!(fbs)
    logger.debug("DEBUG: RestGraph: detected rest-graph cookies, parsed:" \
                 " #{rest_graph.data.inspect}")
  end
  # ====================   end check ================================
  # ==================== begin write ================================
  def rest_graph_write_rg_fbs
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
  def rest_graph_log event
    message = "DEBUG: RestGraph: spent #{sprintf('%f', event.duration)} "
    case event
      when RestGraph::Event::Requested
        logger.debug(message + "requesting #{event.url}")

      when RestGraph::Event::CacheHit
        logger.debug(message + "cache hit' #{event.url}")
    end
  end

  def rest_graph_normalized_request_uri
    URI.parse(if rest_graph_in_canvas?
                # rails 3 uses newer rack which has fullpath
                "http://apps.facebook.com/#{rest_graph_oget(:canvas)}" +
                (request.respond_to?(:fullpath) ?
                  request.fullpath : request.request_uri)
              else
                request.url
              end).
      tap{ |uri|
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
    result = options.send(method){ |(k, v)| RestGraph::Attributes.member?(k) }
    return result if result.kind_of?(Hash) # RUBY_VERSION >= 1.9.1
    result.inject({}){ |r, (k, v)| r[k] = v; r }
  end
  # ==================== end misc ================================
end
