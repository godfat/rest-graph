
require 'rest-graph'

module RestGraph::RailsController
  module_function
  # filters for you
  def setup_iframe
    @fb_sig_in_iframe = true
  end

  def setup_rest_graph
    rest_graph_create

    # exchange the code with access_token
    if params[:code]
      @rg.authorize!(:code => params[:code],
                     :redirect_uri => normalized_request_uri)
      logger.debug(
        "DEBUG: RestGraph: detected code with #{normalized_request_uri}, " \
        "parsed: #{@rg.data.inspect}")
    end

    # if the code is bad or not existed,
    # check if there's one in session,
    # meanwhile, there the sig and access_token is correct,
    # that means we're in the context of iframe
    if !@rg.authorized? && params[:session]
      @rg.parse_json!(params[:session])
      logger.debug(
        "DEBUG: RestGraph: detected session, parsed: #{@rg.data.inspect}")

      if @rg.authorized?
        @fb_sig_in_iframe = true
      else
        logger.warn("WARN: RestGraph: bad session: #{params[:session]}")
      end
    end

    # if we're not in iframe nor code passed,
    # we could check out cookies as well.
    if !@rg.authorized?
      @rg.parse_cookies!(cookies)
      logger.debug(
        "DEBUG: RestGraph: detected cookies, parsed: #{@rg.data.inspect}")
    end

    # there are above 3 ways to check the user identity!
    # if nor of them passed, then we can suppose the user
    # didn't authorize for us
  end

  # override this if you need different app_id and secret
  def rest_graph_create
    @rg ||= RestGraph.new(:error_handler => method(:rest_graph_authorize),
                            :log_handler => method(:rest_graph_log))
  end

  def rest_graph_authorize error=nil
    logger.warn("WARN: RestGraph: #{error.inspect}") if error

    @authorize_url = @rg.authorize_url(
      {:redirect_uri => normalized_request_uri,
       :scope        => rest_graph_authorize_scope}.
      merge(rest_graph_authorize_options))

    logger.debug("DEBUG: RestGraph: redirect to #{@authorize_url}")

    rest_graph_authorize_redirect
    return false
  end

  # override this if you need different access scope
  def rest_graph_authorize_scope
    @rest_graph_authorize_scope ||=
      'offline_access,publish_stream,read_friendlists'
  end

  # override this if you want the simple redirect_to
  def rest_graph_authorize_redirect
    render :template => 'rest-graph/authorization'
  end

  def rest_graph_authorize_options
    @rest_graph_authorize_options ||= {}
  end

  def rest_graph_log duration, url
    logger.debug("DEBUG: RestGraph: spent #{duration} requesting #{url}")
  end

  def normalized_request_uri
    if @fb_sig_in_iframe
      "http://apps.facebook.com/" \
      "#{RestGraph.default_canvas}#{request.request_uri}"
    else
      request.url
    end.sub(/[\&\?]session=[^\&]+/, '').
        sub(/[\&\?]code=[^\&]+/, '')
  end
end
