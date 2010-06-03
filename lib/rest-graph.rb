
# gem
require 'rest_client'

# stdlib
require 'digest/md5'
require 'cgi'

# optional gem
begin
  require 'rack'
rescue LoadError; end

begin
  require 'json'
rescue LoadError
  begin
    require 'json_pure'
  rescue LoadError; end
end

# the data structure used in RestGraph
RestGraphStruct = Struct.new(:data, :auto_decode,
                             :graph_server, :fql_server,
                             :accept, :lang,
                             :app_id, :secret,
                             :error_handler,
                             :log_handler) unless defined?(RestGraphStruct)

class RestGraph < RestGraphStruct
  class Error < RuntimeError; end

  Attributes = RestGraphStruct.members.map(&:to_sym)

  # honor default attributes
  Attributes.each{ |name|
    module_eval <<-RUBY
      def #{name}
        (r = super).nil? ? (self.#{name} = self.class.default_#{name}) : r
      end
    RUBY
  }

  # setup defaults
  module DefaultAttributes
    extend self
    def default_data        ; {}                           ; end
    def default_auto_decode ; true                         ; end
    def default_graph_server; 'https://graph.facebook.com/'; end
    def default_fql_server  ; 'https://api.facebook.com/'  ; end
    def default_accept      ; 'text/javascript'            ; end
    def default_lang        ; 'en-us'                      ; end
    def default_app_id      ; nil                          ; end
    def default_secret      ; nil                          ; end
    def default_error_handler
      lambda{ |error| raise ::RestGraph::Error.new(error) }
    end
    def default_log_handler
      lambda{ |duration, url| }
    end
  end
  extend DefaultAttributes

  def initialize o={}
    (Attributes + [:access_token]).each{ |name|
      send("#{name}=", o[name]) if o.key?(name)
    }
  end

  def access_token
    data['access_token']
  end

  def access_token= token
    data['access_token'] = token
  end

  def authorized?
    !!access_token
  end

  def get    path, query={}, opts={}
    request(graph_server, path, query, :get,    nil,   opts[:suppress_decode])
  end

  def delete path, query={}, opts={}
    request(graph_server, path, query, :delete, nil,   opts[:suppress_decode])
  end

  def post   path, payload, query={}, opts={}
    request(graph_server, path, query, :post, payload, opts[:suppress_decode])
  end

  def put    path, payload, query={}, opts={}
    request(graph_server, path, query, :put,  payload, opts[:suppress_decode])
  end

  # cookies, app_id, secrect related below

  if RUBY_VERSION >= '1.9.1'
    def parse_rack_env! env
      self.data = env['HTTP_COOKIE'] =~ /fbs_#{app_id}=([^\;]+)/ &&
        check_sig_and_return_data(Rack::Utils.parse_query($1))
    end
  else
    def parse_rack_env! env
      self.data = (env['HTTP_COOKIE'] || '') =~ /fbs_#{app_id}=([^\;]+)/ &&
        check_sig_and_return_data(Rack::Utils.parse_query($1))
    end
  end

  def parse_cookies! cookies
    self.data = parse_fbs!(cookies["fbs_#{app_id}"])
  end

  def parse_fbs! fbs
    self.data = fbs &&
      check_sig_and_return_data(Rack::Utils.parse_query(fbs))
  end

  def parse_json! json
    self.data = json &&
      check_sig_and_return_data(JSON.load(json))
  rescue JSON::ParserError
  end

  # oauth related

  def authorize_url opts={}
    query = {:client_id => app_id, :access_token => nil}.merge(opts)
    "#{graph_server}oauth/authorize#{build_query_string(query)}"
  end

  def authorize! opts={}
    query = {:client_id => app_id, :client_secret => secret}.merge(opts)
    self.data = Rack::Utils.parse_query(
      request(graph_server, 'oauth/access_token', query, :get, nil, true))
  end

  # old rest facebook api, i will definitely love to remove them someday

  def fql code, query={}, opts={}
    request(fql_server, 'method/fql.query',
      {:query => code, :format => 'json'}.merge(query),
      :get, opts[:suppress_decode])
  end

  def fql_multi codes, query={}, opts={}
    c = if codes.respond_to?(:to_json)
           codes.to_json
        else
          middle = codes.inject([]){ |r, (k, v)|
                     r << "\"#{k}\":\"#{v.gsub('"','\\"')}\""
                   }.join(',')
          "{#{middle}}"
        end
    request(fql_server, 'method/fql.multiquery',
      {:queries => c, :format => 'json'}.merge(query),
      :get, opts[:suppress_decode])
  end

  private
  def request server, path, opts, method, payload=nil, suppress_decode=nil
    start_time = Time.now
    res = RestClient::Resource.new(server)[path + build_query_string(opts)]
    post_request(
      res.send(method, *[payload, build_headers].compact), suppress_decode)
  rescue RestClient::InternalServerError => e
    post_request(e.http_body, suppress_decode)
  ensure
    log_handler.call(Time.now - start_time, res.url)
  end

  def build_query_string query={}
    qq = access_token ? {:access_token => access_token}.merge(query) : query
    q  = qq.select{ |k, v| v }
    return '' if q.empty?
    return '?' + q.map{ |(k, v)| "#{k}=#{CGI.escape(v.to_s)}" }.join('&')
  end

  def build_headers
    headers = {}
    headers['Accept']          = accept if accept
    headers['Accept-Language'] = lang   if lang
    headers
  end

  def post_request result, suppress_decode=nil
    if auto_decode && !suppress_decode
      check_error(JSON.parse(result))
    else
      result
    end
  end

  def check_sig_and_return_data cookies
    cookies if secret && calculate_sig(cookies) == cookies['sig']
  end

  def check_error hash
    if error_handler && hash.kind_of?(Hash) && hash['error']
      error_handler.call(hash)
    else
      hash
    end
  end

  def calculate_sig cookies
    args = cookies.reject{ |(k, v)| k == 'sig' }.sort.
      map{ |a| a.join('=') }.join

    Digest::MD5.hexdigest(args + secret)
  end
end
