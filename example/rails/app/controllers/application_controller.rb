# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  include RestGraph::RailsUtil

  before_filter :filter_common,      :only => [:index]
  before_filter :filter_canvas,      :only => [:canvas]
  before_filter :filter_options,     :only => [:options]
  before_filter :filter_no_auto,     :only => [:no_auto]
  before_filter :filter_diff_app_id, :only => [:app_id]

  def index
    render :text => rest_graph.get('me').to_json
  end
  alias_method :canvas,  :index
  alias_method :options, :index

  def no_auto
    rest_graph.get('me')
  rescue RestGraph::Error
    render :text => 'XD'
  end

  def app_id
    render :text => rest_graph.app_id
  end

  private
  def filter_common
    rest_graph_setup(:auto_authorize => true)
  end

  def filter_canvas
    rest_graph_setup(:canvas => true,
                     :auto_authorize => true,
                     :auto_authorize_scope => 'publish_stream')
  end

  def filter_no_auto
    rest_graph_setup(:auto_authorize => false)
  end

  def filter_diff_app_id
    rest_graph_setup(:app_id => 'zzz',
                     :auto_authorize => true)
  end

  def filter_options
    rest_graph_setup(:auto_authorize_options => {:scope => 'bogus'})
  end
end
