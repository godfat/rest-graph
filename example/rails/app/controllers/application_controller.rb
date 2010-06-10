# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  include RestGraph::RailsUtil

  before_filter :rest_graph_setup,       :only => [:index, :url_for_standalone]
  before_filter :filter_for_iframe,      :only => [:iframe, :url_for_canvas]
  before_filter :filter_for_no_redirect, :only => [:no_redirect]
  before_filter :filter_for_diff_app_id, :only => [:app_id]

  def index
    render :text => rest_graph.get('me').to_json
  end

  alias_method :iframe, :index

  def no_redirect
    rest_graph.get('me')
  rescue RestGraph::Error
    render :text => 'XD'
  end

  def app_id
    render :text => rest_graph.app_id
  end

  def url_for_canvas
    render :text => url_for(:action => 'index')
  end

  alias_method :url_for_standalone, :url_for_canvas

  private
  def filter_for_iframe
    rest_graph_setup(:iframe => true,
                     :scope  => 'publish_stream')
  end

  def filter_for_no_redirect
    rest_graph_setup(:auto_redirect => false)
  end

  def filter_for_diff_app_id
    rest_graph_setup(:app_id => 'zzz')
  end
end
