
require 'rest-graph'

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

  def rest_graph_options
    @rest_graph_options ||=
      {:canvas                 => false,
       :auto_authorize         => false,
       :auto_authorize_options => {},
       :auto_authorize_scope   => ''}
  end

  def rest_graph_options_new
    @rest_graph_options_new ||=
      {:error_handler => method(:rest_graph_authorize),
         :log_handler => method(:rest_graph_log)}
  end

  def rest_graph_setup options={}
    rest_graph_options    .merge!(rest_graph_extract_options(options, :reject))
    rest_graph_options_new.merge!(rest_graph_extract_options(options, :select))

    rest_graph_check_code           if !rest_graph.authorized? &&
                                        params[:code]

    rest_graph_check_params_session if !rest_graph.authorized? &&
                                        params[:session]

    rest_graph_check_cookie         if !rest_graph.authorized? &&
                                        cookies["fbs_#{rest_graph.app_id}"]

    # there are above 3 ways to check the user identity!
    # if nor of them passed, then we can suppose the user
    # didn't authorize for us, but we can check if user has authorized
    # before, in that case, the fbs would be inside session,
    # as we just saved it there

    rest_graph_check_session        if !rest_graph.authorized? &&
                                        session['fbs']
  end

  # override this if you need different app_id and secret
  def rest_graph
    @rest_graph ||= RestGraph.new(rest_graph_options_new)
  end

  def rest_graph_authorize error
    logger.warn("WARN: RestGraph: #{error.inspect}")

    if rest_graph_auto_authorize?
      @rest_graph_authorize_url = rest_graph.authorize_url(
        {:redirect_uri => rest_graph_normalized_request_uri,
         :scope        => rest_graph_options[:auto_authorize_scope]}.
        merge(            rest_graph_options[:auto_authorize_options]))

      logger.debug("DEBUG: RestGraph: redirect to #{@rest_graph_authorize_url}")

      rest_graph_authorize_redirect
    end

    raise ::RestGraph::Error.new(error)
  end

  # override this if you want the simple redirect_to
  def rest_graph_authorize_redirect
    if !rest_graph_in_canvas?
      redirect_to @rest_graph_authorize_url

    else
      render :inline => <<-HTML
      <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
      "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
      <html>
        <head>
        <script type="text/javascript">
          window.top.location.href = '<%= @rest_graph_authorize_url %>'
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

  private
  # exchange the code with access_token
  def rest_graph_check_code
    rest_graph.authorize!(:code => params[:code],
                          :redirect_uri => rest_graph_normalized_request_uri)
    logger.debug(
      "DEBUG: RestGraph: detected code with "  \
      "#{rest_graph_normalized_request_uri}, " \
      "parsed: #{rest_graph.data.inspect}")

    rest_graph_write_session
  end

  # if the code is bad or not existed,
  # check if there's one in session,
  # meanwhile, there the sig and access_token is correct,
  # that means we're in the context of canvas
  def rest_graph_check_params_session
    rest_graph.parse_json!(params[:session])
    logger.debug("DEBUG: RestGraph: detected session, parsed:" \
                 " #{rest_graph.data.inspect}")

    if rest_graph.authorized?
      @fb_sig_in_canvas = true
    else
      logger.warn("WARN: RestGraph: bad session: #{params[:session]}")
    end

    rest_graph_write_session
  end

  # if we're not in canvas nor code passed,
  # we could check out cookies as well.
  def rest_graph_check_cookie
    rest_graph.parse_cookies!(cookies)
    logger.debug("DEBUG: RestGraph: detected cookies, parsed:" \
                 " #{rest_graph.data.inspect}")
  end

  def rest_graph_check_session
    rest_graph.parse_fbs!(session['fbs'])
    logger.debug("DEBUG: RestGraph: detected session, parsed:" \
                 " #{rest_graph.data.inspect}")
  end

  def rest_graph_write_session
    fbs = rest_graph.data.to_a.map{ |k_v| k_v.join('=') }.join('&')
    session['fbs'] = fbs
    logger.debug("DEBUG: RestGraph: wrote session: fbs => #{fbs}")
  end

  def rest_graph_log duration, url
    logger.debug("DEBUG: RestGraph: spent #{duration} requesting #{url}")
  end

  def rest_graph_normalized_request_uri
    if rest_graph_in_canvas?
      "http://apps.facebook.com/" \
      "#{RestGraph.default_canvas}#{request.request_uri}"
    else
      request.url
    end.sub(/[\&\?]session=[^\&]+/, '').
        sub(/[\&\?]code=[^\&]+/, '')
  end

  def rest_graph_in_canvas?
    rest_graph_options[:canvas] || @fb_sig_in_canvas
  end

  def rest_graph_auto_authorize?
    !rest_graph_options[:auto_authorize_scope  ].empty? ||
    !rest_graph_options[:auto_authorize_options].empty? ||
     rest_graph_options[:auto_authorize]
  end

  def rest_graph_extract_options options, method
    result = options.send(method){ |(k, v)| RestGraph::Attributes.member?(k) }
    return result if result.kind_of?(Hash) # RUBY_VERSION >= 1.9.1
    result.inject({}){ |r, (k, v)| r[k] = v; r }
  end
end
