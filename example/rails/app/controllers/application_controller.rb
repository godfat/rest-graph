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
  before_filter :filter_diff_app_id, :only => [:diff_app_id]
  before_filter :filter_diff_canvas, :only => [:diff_canvas]
  before_filter :filter_cache,       :only => [:cache]

  def index
    render :text => rest_graph.get('me').to_json
  end
  alias_method :canvas     , :index
  alias_method :options    , :index
  alias_method :diff_canvas, :index

  def no_auto
    rest_graph.get('me')
  rescue RestGraph::Error
    render :text => 'XD'
  end

  def diff_app_id
    render :text => rest_graph.app_id
  end

  def cache
    url = rest_graph.url('cache')
    rest_graph.get('cache')
    rest_graph.get('cache')
    render :text => Rails.cache.read(Digest::MD5.hexdigest(url))
  end

  private
  def filter_common
    rest_graph_setup(:auto_authorize => true)
  end

  def filter_canvas
    rest_graph_setup(:canvas               => RestGraph.default_canvas,
                     :auto_authorize_scope => 'publish_stream')
  end

  def filter_diff_canvas
    rest_graph_setup(:canvas               => 'ToT',
                     :auto_authorize_scope => 'email')
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

  def filter_cache
    rest_graph_setup(:cache => Rails.cache)
  end
end
