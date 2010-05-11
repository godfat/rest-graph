
require 'rest_client'

require 'cgi'

# the data structure used in RestGraph
RestGraphStruct = Struct.new(:data, :auto_decode,
                             :graph_server, :fql_server,
                             :accept, :lang,
                             :app_id, :secret)

class RestGraph < RestGraphStruct
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
  end
  extend DefaultAttributes

  def initialize o = {}
    (Attributes + [:access_token]).each{ |name|
      send("#{name}=", o[name]) if o.key?(name)
    }
    check_arguments!
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

  def get    path, opts = {}
    request(graph_server, path, opts, :get)
  end

  def delete path, opts = {}
    request(graph_server, path, opts, :delete)
  end

  def post   path, payload, opts = {}
    request(graph_server, path, opts, :post, payload)
  end

  def put    path, payload, opts = {}
    request(graph_server, path, opts, :put,  payload)
  end

  def fql query, opts = {}
    request(fql_server, 'method/fql.query',
      {:query  => query, :format => 'json'}.merge(opts), :get)
  end

  # cookies, app_id, secrect related below

  def parse_rack_env! env
    self.data = env['HTTP_COOKIE'] =~ /fbs_#{app_id}="(.+?)"/ &&
      check_sig_and_return_data(Rack::Utils.parse_query($1))
  end

  def parse_cookies! cookies
    self.data = parse_fbs!(cookies["fbs_#{app_id}"])
  end

  def parse_fbs! fbs
    self.data = fbs &&
      check_sig_and_return_data(Rack::Utils.parse_query(fbs[1..-2]))
  end

  # multi-request by eventmachine (em-http)
  def multi requests
    m = EM::MultiRequest.new
    requests.each{ |(method, path, opts)|
      m.add(EM::HttpRequest.new(graph_server + path).
      send(method, :query => opts))
    }
    m.callback{
      yield(m.responses[:succeeded].map(&:response).
            map(&method(:post_request)))
    }
  end

  private
  def check_arguments!
    if auto_decode
      begin
        require 'json'
      rescue LoadError
        require 'json_pure'
      end
    end

    if app_id && secret # want to parse access_token in cookies
      require 'digest/md5'
      require 'rack'
    elsif app_id || secret
      raise ArgumentError.new("You may want to pass both"      \
                              " app_id(#{app_id.inspect}) and" \
                              " secret(#{secret.inspect})")
    end
  end

  def request server, path, opts, method, payload = nil
    post_request(
      RestClient::Resource.new(server)[path + build_query_string(opts)].
      send(method, *[payload, build_headers].compact))
  rescue RestClient::InternalServerError => e
    post_request(e.http_body)
  end

  def build_query_string q = {}
    query = q.merge(access_token ? {:access_token => access_token} : {})
    return '' if query.empty?
    return '?' + query.map{ |(k, v)| "#{k}=#{CGI.escape(v.to_s)}" }.join('&')
  end

  def build_headers
    headers = {}
    headers['Accept']          = accept if accept
    headers['Accept-Language'] = lang   if lang
    headers
  end

  def post_request result
    auto_decode ? JSON.parse(result) : result
  end

  def check_sig_and_return_data cookies
    cookies if calculate_sig(cookies) == cookies['sig']
  end

  def calculate_sig cookies
    args = cookies.reject{ |(k, v)| k == 'sig' }.sort.
      map{ |a| a.join('=') }.join

    Digest::MD5.hexdigest(args + secret)
  end
end
