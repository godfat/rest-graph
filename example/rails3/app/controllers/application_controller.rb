
class ApplicationController < ActionController::Base
  protect_from_forgery

  include RestGraph::RailsUtil

  before_filter :filter_common       , :only => [:index]
  before_filter :filter_canvas       , :only => [:canvas]
  before_filter :filter_options      , :only => [:options]
  before_filter :filter_no_auto      , :only => [:no_auto]
  before_filter :filter_diff_app_id  , :only => [:diff_app_id]
  before_filter :filter_diff_canvas  , :only => [:diff_canvas]
  before_filter :filter_iframe_canvas, :only => [:iframe_canvas]
  before_filter :filter_cache        , :only => [:cache]
  before_filter :filter_hanlder      , :only => [:handler_]
  before_filter :filter_session      , :only => [:session_]
  before_filter :filter_cookies      , :only => [:cookies_]

  def index
    render :text => rest_graph.get('me').to_json
  end
  alias_method :canvas       , :index
  alias_method :options      , :index
  alias_method :diff_canvas  , :index
  alias_method :iframe_canvas, :index
  alias_method :handler_     , :index
  alias_method :session_     , :index
  alias_method :cookies_     , :index

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

  def error
    raise RestGraph::Error.new("don't rescue me")
  end

  def reinitialize
    cache_nil = rest_graph.cache
    rest_graph_setup(:cache => {'a' => 'b'})
    cache     = rest_graph.cache
    render :text => YAML.dump([cache_nil, cache])
  end

  def helper; end

  private
  def filter_common
    rest_graph_setup(:auto_authorize => true, :canvas => '')
  end

  def filter_canvas
    rest_graph_setup(:canvas               => RestGraph.default_canvas,
                     :auto_authorize_scope => 'publish_stream')
  end

  def filter_diff_canvas
    rest_graph_setup(:canvas               => 'ToT',
                     :auto_authorize_scope => 'email')
  end

  def filter_iframe_canvas
    rest_graph_setup(:canvas               => 'zzz',
                     :auto_authorize       => true)
  end

  def filter_no_auto
    rest_graph_setup(:auto_authorize => false)
  end

  def filter_diff_app_id
    rest_graph_setup(:app_id => 'zzz',
                     :auto_authorize => true)
  end

  def filter_options
    rest_graph_setup(:auto_authorize_options => {:scope => 'bogus'},
                     :canvas => nil)
  end

  def filter_cache
    rest_graph_setup(:cache => Rails.cache)
  end

  def filter_hanlder
    rest_graph_setup(:write_handler => method(:write_handler),
                     :check_handler => method(:check_handler))
  end

  def write_handler fbs
    Rails.cache[:fbs] = fbs
  end

  def check_handler
    Rails.cache[:fbs]
  end

  def filter_session
    rest_graph_setup(:write_session => true)
  end

  def filter_cookies
    rest_graph_setup(:write_cookies => true)
  end
end
