# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  include RestGraph::RailsUtil

  # ---

  before_filter :rest_graph_setup, :only => [:index]

  def index
    render :text => rest_graph.get('me').to_json
  end

  # ---

  before_filter lambda{ |controller|
    controller.rest_graph_setup(:iframe => true,
                                :scope  => 'publish_stream')

  }, :only => [:iframe]

  alias_method :iframe, :index

  # ---

  before_filter lambda{ |controller|
    controller.rest_graph_setup(:auto_redirect => false)
  }, :only => [:no_redirect]

  def no_redirect
    rest_graph.get('me')
  rescue RestGraph::Error
    render :text => 'XD'
  end
end
