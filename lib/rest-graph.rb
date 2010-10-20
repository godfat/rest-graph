
# optional http client
begin; require 'restclient'     ; rescue LoadError; end
begin; require 'em-http-request'; rescue LoadError; end

# optional gem
begin; require 'rack'           ; rescue LoadError; end

# stdlib
require 'digest/md5'
require 'openssl'

require 'cgi'

# the data structure used in RestGraph
RestGraphStruct = Struct.new(:auto_decode, :strict,
                             :graph_server, :old_server,
                             :accept, :lang,
                             :app_id, :secret,
                             :data, :cache,
                             :log_method,
                             :log_handler,
                             :error_handler) unless defined?(RestGraphStruct)

class RestGraph < RestGraphStruct
  EventStruct = Struct.new(:duration, :url)           unless
    defined?(::RestGraph::EventStruct)

  Attributes  = RestGraphStruct.members.map(&:to_sym) unless
    defined?(::RestGraph::Attributes)

  class Event < EventStruct; end
  class Event::Requested < Event; end
  class Event::CacheHit  < Event; end

  class Error < RuntimeError
    class AccessToken < Error; end
    class InvalidAccessToken < AccessToken; end
    class MissingAccessToken < AccessToken; end

    attr_reader :error
    def initialize error
      @error = error
      super(error.inspect)
    end

    module Util
      extend self
      def parse error
        return Error.new(error) unless error.kind_of?(Hash)
        if    invalid_token?(error)
          InvalidAccessToken.new(error)
        elsif missing_token?(error)
          MissingAccessToken.new(error)
        else
          Error.new(error)
        end
      end

      def invalid_token? error
        (%w[OAuthInvalidTokenException
            OAuthException].include?((error['error'] || {})['type'])) ||
        (error['error_code'] == 190) # Invalid OAuth 2.0 Access Token
      end

      def missing_token? error
        (error['error'] || {})['message'] =~ /^An active access token/ ||
        (error['error_code'] == 104) # Requires valid signature
      end
    end
    extend Util
  end

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
    def default_auto_decode ; true                         ; end
    def default_strict      ; false                        ; end
    def default_graph_server; 'https://graph.facebook.com/'; end
    def default_old_server  ; 'https://api.facebook.com/'  ; end
    def default_accept      ; 'text/javascript'            ; end
    def default_lang        ; 'en-us'                      ; end
    def default_app_id      ; nil                          ; end
    def default_secret      ; nil                          ; end
    def default_data        ; {}                           ; end
    def default_cache       ; nil                          ; end
    def default_log_method  ; nil                          ; end
    def default_log_handler ; nil                          ; end
    def default_error_handler
      lambda{ |error| raise ::RestGraph::Error.parse(error) }
    end
  end
  extend DefaultAttributes

  # Fallback to ruby-hmac gem in case system openssl
  # lib doesn't support SHA256 (OSX 10.5)
  def self.hmac_sha256 key, data
    # for ruby version >= 1.8.7, we can simply pass sha256,
    # instead of OpenSSL::Digest::Digest.new('sha256')
    # i'll go back to original implementation once all old systems died
    OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha256'), key, data)
  rescue RuntimeError
    require 'hmac-sha2'
    HMAC::SHA256.digest(key, data)
  end

  # begin json backend adapter
  module YajlRuby
    def self.extended mod
      mod.const_set(:ParseError, Yajl::ParseError)
    end
    def json_encode hash
      Yajl::Encoder.encode(hash)
    end
    def json_decode json
      Yajl::Parser.parse(json)
    end
  end

  module Json
    def self.extended mod
      mod.const_set(:ParseError, JSON::ParserError)
    end
    def json_encode hash
      JSON.dump(hash)
    end
    def json_decode json
      JSON.parse(json)
    end
  end

  module Gsub
    class ParseError < RuntimeError; end
    def self.extended mod
      mod.const_set(:ParseError, Gsub::ParseError)
    end
    # only works for flat hash
    def json_encode hash
      middle = hash.inject([]){ |r, (k, v)|
                 r << "\"#{k}\":\"#{v.gsub('"','\\"')}\""
               }.join(',')
      "{#{middle}}"
    end
    def json_decode json
      raise NotImplementedError.new(
        'You need to install either yajl-ruby, json, or json_pure gem')
    end
  end

  def self.select_json! picked=false
    if    defined?(::Yajl)
      extend YajlRuby
    elsif defined?(::JSON)
      extend Json
    elsif picked
      extend Gsub
    else
      # pick a json gem if available
      %w[yajl json].each{ |json|
        begin
          require json
          break
        rescue LoadError
        end
      }
      select_json!(true)
    end
  end
  select_json! unless respond_to?(:json_decode)
  #   end json backend adapter





  # common methods

  def initialize o={}
    (Attributes + [:access_token]).each{ |name|
      send("#{name}=", o[name]) if o.key?(name)
    }
  end

  def access_token
    data['access_token'] || data['oauth_token']
  end

  def access_token= token
    data['access_token'] = token
  end

  def authorized?
    !!access_token
  end

  def secret_access_token
    "#{app_id}|#{secret}"
  end

  def lighten!
    [:cache, :log_method, :log_handler, :error_handler].each{ |obj|
      send("#{obj}=", nil) }
    self
  end

  def lighten
    dup.lighten!
  end

  def inspect
    super.gsub(/(\w+)=([^,>]+)/){ |match|
      value = $2 == 'nil' ? self.class.send("default_#{$1}").inspect : $2
      "#{$1}=#{value}"
    }
  end





  # graph api related methods

  def url path, query={}, server=graph_server
    "#{server}#{path}#{build_query_string(query)}"
  end

  def get    path, query={}, opts={}, &cb
    request(opts, [:get   , url(path, query, graph_server)], &cb)
  end

  def delete path, query={}, opts={}, &cb
    request(opts, [:delete, url(path, query, graph_server)], &cb)
  end

  def post   path, payload={}, query={}, opts={}, &cb
    request(opts, [:post  , url(path, query, graph_server), payload], &cb)
  end

  def put    path, payload={}, query={}, opts={}, &cb
    request(opts, [:put   , url(path, query, graph_server), payload], &cb)
  end

  # request by eventmachine (em-http)

  def aget    path, query={}, opts={}, &cb
    get(path, query, {:async => true}.merge(opts), &cb)
  end

  def adelete path, query={}, opts={}, &cb
    delete(path, query, {:async => true}.merge(opts), &cb)
  end

  def apost   path, payload={}, query={}, opts={}, &cb
    post(path, payload, query, {:async => true}.merge(opts), &cb)
  end

  def aput    path, payload={}, query={}, opts={}, &cb
    put(path, payload, query, {:async => true}.merge(opts), &cb)
  end

  def multi reqs, opts={}, &cb
    request({:async => true}.merge(opts),
      *reqs.map{ |(meth, path, query, payload)|
        [meth, url(path, query || {}, graph_server), payload]
      }, &cb)
  end





  def next_page hash, opts={}, &cb
    return unless hash['paging'].kind_of?(Hash) && hash['paging']['next']
    request(opts, [:get, hash['paging']['next']], &cb)
  end

  def prev_page hash, opts={}, &cb
    return unless hash['paging'].kind_of?(Hash) && hash['paging']['previous']
    request(opts, [:get, hash['paging']['previous']], &cb)
  end
  alias_method :previous_page, :prev_page

  def for_pages hash, pages=1, kind=:next_page, opts={}, &cb
    return hash if pages <= 1
    send(kind, hash, opts){ |result|
      for_pages(merge_data(result, hash), pages - 1, kind, opts, &cb)
    } || hash
  end





  # cookies, app_id, secrect related below

  def parse_rack_env! env
    env['HTTP_COOKIE'].to_s =~ /fbs_#{app_id}=([^\;]+)/
    self.data = parse_fbs!($1)
  end

  def parse_cookies! cookies
    self.data = parse_fbs!(cookies["fbs_#{app_id}"])
  end

  def parse_fbs! fbs
    self.data = check_sig_and_return_data(
      # take out facebook sometimes there but sometimes not quotes in cookies
      Rack::Utils.parse_query(fbs.to_s.gsub('"', '')))
  end

  def parse_json! json
    self.data = json &&
      check_sig_and_return_data(self.class.json_decode(json))
  rescue ParseError
  end

  def fbs
    "#{fbs_without_sig(data).join('&')}&sig=#{calculate_sig(data)}"
  end

  # facebook's new signed_request...

  def parse_signed_request! request
    sig_encoded, json_encoded = request.split('.')
    sig,  json = [sig_encoded, json_encoded].map{ |str|
      "#{str.tr('-_', '+/')}==".unpack('m').first
    }
    self.data = self.class.json_decode(json) if
      secret && self.class.hmac_sha256(secret, json_encoded) == sig
  rescue ParseError
  end





  # oauth related

  def authorize_url opts={}
    query = {:client_id => app_id, :access_token => nil}.merge(opts)
    "#{graph_server}oauth/authorize#{build_query_string(query)}"
  end

  def authorize! opts={}
    query = {:client_id => app_id, :client_secret => secret}.merge(opts)
    self.data = Rack::Utils.parse_query(
                  request({:suppress_decode => true}.merge(opts),
                          [:get, url('oauth/access_token', query)]))
  end





  # old rest facebook api, i will definitely love to remove them someday

  def old_rest path, query={}, opts={}, &cb
    request(
      opts,
      [:get,
      url("method/#{path}", {:format => 'json'}.merge(query), old_server)],
      &cb)
  end

  def secret_old_rest path, query={}, opts={}, &cb
    old_rest(path, {:access_token => secret_access_token}.merge(query), opts,
      &cb)
  end
  alias_method :broken_old_rest, :secret_old_rest

  def exchange_sessions query={}, opts={}, &cb
    q = {:client_id => app_id, :client_secret => secret,
         :type => 'client_cred'}.merge(query)
    request(opts, [:post, url('oauth/exchange_sessions', q)], &cb)
  end

  def fql code, query={}, opts={}, &cb
    old_rest('fql.query', {:query => code}.merge(query), opts, &cb)
  end

  def fql_multi codes, query={}, opts={}, &cb
    old_rest('fql.multiquery',
      {:queries => self.class.json_encode(codes)}.merge(query), opts, &cb)
  end





  private
  def request opts, *reqs, &cb
    if opts[:async]
      request_em(opts, reqs, &cb)
    else
      request_rc(opts, *reqs.first, &cb)
    end
  end

  def request_em opts, reqs
    start_time = Time.now
    rs = reqs.map{ |(meth, uri, payload)|
      r = EM::HttpRequest.new(uri).send(meth, :body => payload){ |c|
        c.callback{ log(Event::Requested.new(Time.now - start_time, uri)) }
      }
      if cached = cache_get(uri)
        r.instance_variable_set('@response', cached)
        r.succeed
        EM.next_tick{ r.succeed }
      end
      r
    }
    EM::MultiRequest.new(rs){ |m|
      log(Event::Requested.new(Time.now - start_time,
        m.responses.values.flatten.map(&:uri).join(', ')))

      results = m.responses.values.flatten.map(&:response).
                  map(&method(:post_request))
      yield(results.size == 1 ? results.first : results)
    }
    []
  end

  def request_rc opts, meth, uri, payload=nil, &cb
    start_time = Time.now
    post_request(cache_get(uri) || fetch(meth, uri, payload), opts, &cb)
  rescue RestClient::Exception => e
    post_request(e.http_body, opts, &cb)
  ensure
    log(Event::Requested.new(Time.now - start_time, uri))
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

  def post_request result, opts={}, &cb
    if auto_decode && !opts[:suppress_decode]
      decoded = self.class.json_decode("[#{result}]").first
      check_error(if strict || !decoded.kind_of?(String)
                    decoded
                  else
                    self.class.json_decode(decoded)
                  end, &cb)
    else
      block_given? ? yield(result) : result
    end
  end

  def check_sig_and_return_data cookies
    cookies if secret && calculate_sig(cookies) == cookies['sig']
  end

  def check_error hash
    if error_handler && hash.kind_of?(Hash) &&
       (hash['error'] ||    # from graph api
        hash['error_code']) # from fql
      error_handler.call(hash)
    else
      block_given? ? yield(hash) : hash
    end
  end

  def calculate_sig cookies
    Digest::MD5.hexdigest(fbs_without_sig(cookies).join + secret)
  end

  def fbs_without_sig cookies
    cookies.reject{ |(k, v)| k == 'sig' }.sort.map{ |a| a.join('=') }
  end

  def cache_key uri
    Digest::MD5.hexdigest(uri)
  end

  def cache_get uri
    return unless cache
    start_time = Time.now
    cache[cache_key(uri)].tap{ |result|
      log(Event::CacheHit.new(Time.now - start_time, uri)) if result
    }
  end

  def fetch meth, uri, payload
    RestClient::Request.execute(:method => meth, :url => uri,
                                :headers => build_headers,
                                :payload => payload).body.
      tap{ |result|
        cache[cache_key(uri)] = result if cache && meth == :get
      }
  end

  def merge_data lhs, rhs
    [lhs, rhs].each{ |hash|
      return rhs.reject{ |k, v| k == 'paging' } if
        !hash.kind_of?(Hash) || !hash['data'].kind_of?(Array)
    }
    lhs['data'].unshift(*rhs['data'])
    lhs
  end

  def log event
    if log_handler
      log_handler.call(event)
    elsif log_method
      message = "DEBUG: RestGraph: spent #{sprintf('%f', event.duration)} "
      case event
        when RestGraph::Event::Requested
          log_method.call(message + "requesting #{event.url}")

        when RestGraph::Event::CacheHit
          log_method.call(message + "cache hit' #{event.url}")
      end
    end
  end
end
