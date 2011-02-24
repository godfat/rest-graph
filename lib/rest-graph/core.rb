
# optional http client
begin; require 'restclient'     ; rescue LoadError; end
begin; require 'em-http-request'; rescue LoadError; end

# optional gem
begin; require 'rack'           ; rescue LoadError; end

# stdlib
require 'digest/md5'
require 'openssl'

require 'cgi'
require 'timeout'

# the data structure used in RestGraph
RestGraphStruct = Struct.new(:auto_decode, :strict, :timeout,
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

  class Event < EventStruct
    # self.class.name[/(?<=::)\w+$/] if RUBY_VERSION >= '1.9.2'
    def name; self.class.name[/::\w+$/].tr(':', ''); end
    def to_s; "RestGraph: spent #{sprintf('%f', duration)} #{name} #{url}";end
  end
  class Event::MultiDone < Event; end
  class Event::Requested < Event; end
  class Event::CacheHit  < Event; end
  class Event::Failed    < Event; end

  class Error < RuntimeError
    class AccessToken < Error; end
    class InvalidAccessToken < AccessToken; end
    class MissingAccessToken < AccessToken; end

    attr_reader :error, :url
    def initialize error, url=''
      @error, @url = error, url
      super("#{error.inspect} from #{url}")
    end

    module Util
      extend self
      def parse error, url=''
        return Error.new(error, url) unless error.kind_of?(Hash)
        if    invalid_token?(error)
          InvalidAccessToken.new(error, url)
        elsif missing_token?(error)
          MissingAccessToken.new(error, url)
        else
          Error.new(error, url)
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
    def default_timeout     ; 10                           ; end
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
      lambda{ |error, url| raise ::RestGraph::Error.parse(error, url) }
    end
  end
  extend DefaultAttributes

  # Fallback to ruby-hmac gem in case system openssl
  # lib doesn't support SHA256 (OSX 10.5)
  def self.hmac_sha256 key, data
    OpenSSL::HMAC.digest('sha256', key, data)
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

  def url path, query={}, server=graph_server, opts={}
    "#{server}#{path}#{build_query_string(query, opts)}"
  end

  # extra options:
  #   auto_decode: Bool # decode with json or not in this method call
  #                     # default: auto_decode in rest-graph instance
  #        secret: Bool # use secret_acccess_token or not
  #                     # default: false
  #         cache: Bool # use cache or not; if it's false, update cache, too
  #                     # default: true
  #    expires_in: Int  # control when would the cache be expired
  #                     # default: nothing
  #         async: Bool # use eventmachine for http client or not
  #                     # default: false, but true in aget family
  #       headers: Hash # additional hash you want to pass
  def get    path, query={}, opts={}, &cb
    request(opts, [:get   , url(path, query, graph_server, opts)], &cb)
  end

  def delete path, query={}, opts={}, &cb
    request(opts, [:delete, url(path, query, graph_server, opts)], &cb)
  end

  def post   path, payload={}, query={}, opts={}, &cb
    request(opts, [:post  , url(path, query, graph_server, opts), payload],
            &cb)
  end

  def put    path, payload={}, query={}, opts={}, &cb
    request(opts, [:put   , url(path, query, graph_server, opts), payload],
            &cb)
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
        [meth, url(path, query || {}, graph_server, opts), payload]
      }, &cb)
  end





  def next_page hash, opts={}, &cb
    if hash['paging'].kind_of?(Hash) && hash['paging']['next']
      request(opts, [:get, hash['paging']['next']], &cb)
    else
      yield(nil) if block_given?
    end
  end

  def prev_page hash, opts={}, &cb
    if hash['paging'].kind_of?(Hash) && hash['paging']['previous']
      request(opts, [:get, hash['paging']['previous']], &cb)
    else
      yield(nil) if block_given?
    end
  end
  alias_method :previous_page, :prev_page

  def for_pages hash, pages=1, opts={}, kind=:next_page, &cb
    if pages > 1
      merge_data(send(kind, hash, opts){ |result|
        yield(result.freeze) if block_given?
        for_pages(result, pages - 1, opts, kind, &cb) if result
      }, hash)
    else
      yield(nil) if block_given?
      hash
    end
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
    self.data = nil
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
    self.data = check_sig_and_return_data(
                  self.class.json_decode(json).merge('sig' => sig)){
                    self.class.hmac_sha256(secret, json_encoded)
                  }
  rescue ParseError
    self.data = nil
  end





  # oauth related

  def authorize_url opts={}
    query = {:client_id => app_id, :access_token => nil}.merge(opts)
    "#{graph_server}oauth/authorize#{build_query_string(query)}"
  end

  def authorize! opts={}
    query = {:client_id => app_id, :client_secret => secret}.merge(opts)
    self.data = Rack::Utils.parse_query(
                  request({:auto_decode => false}.merge(opts),
                          [:get, url('oauth/access_token', query)]))
  end





  # old rest facebook api, i will definitely love to remove them someday

  def old_rest path, query={}, opts={}, &cb
    request(
      opts,
      [:get,
       url("method/#{path}", {:format => 'json'}.merge(query),
           old_server, opts)],
      &cb)
  end

  def secret_old_rest path, query={}, opts={}, &cb
    old_rest(path, query, {:secret => true}.merge(opts), &cb)
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





  def request opts, *reqs, &cb
    Timeout.timeout(timeout){
      reqs.each{ |(meth, uri, payload)|
        next if meth != :get
        cache_assign(uri, nil)
      } if opts[:cache] == false

      if opts[:async]
        request_em(opts, reqs, &cb)
      else
        request_rc(opts, *reqs.first, &cb)
      end
    }
  end

  protected
  def request_em opts, reqs
    start_time = Time.now
    rs = reqs.map{ |(meth, uri, payload)|
      r = EM::HttpRequest.new(uri).send(meth, :body => payload)
      if cached = cache_get(uri)
        # TODO: this is hack!!
        r.instance_variable_set('@response', cached)
        r.instance_variable_set('@state'   , :finish)
        r.on_request_complete
        r.succeed(r)
      else
        r.callback{
          cache_for(uri, r.response, meth, opts)
          log(Event::Requested.new(Time.now - start_time, uri))
        }
        r.error{
          log(Event::Failed.new(Time.now - start_time, uri))
        }
      end
      r
    }
    EM::MultiRequest.new(rs){ |m|
      # TODO: how to deal with the failed?
      clients = m.responses[:succeeded]
      results = clients.map{ |client|
        post_request(client.response, client.uri, opts)
      }

      if reqs.size == 1
        yield(results.first)
      else
        log(Event::MultiDone.new(Time.now - start_time,
          clients.map(&:uri).join(', ')))
        yield(results)
      end
    }
  end

  def request_rc opts, meth, uri, payload=nil, &cb
    start_time = Time.now
    post_request(cache_get(uri) || fetch(meth, uri, payload, opts),
                 uri, opts, &cb)
  rescue RestClient::Exception => e
    post_request(e.http_body, uri, opts, &cb)
  ensure
    log(Event::Requested.new(Time.now - start_time, uri))
  end

  def build_query_string query={}, opts={}
    token = opts[:secret] ? secret_access_token : access_token
    qq = token ? {:access_token => token}.merge(query) : query
    q  = qq.select{ |k, v| v } # compacting the hash
    return '' if q.empty?
    return '?' + q.map{ |(k, v)| "#{k}=#{CGI.escape(v.to_s)}" }.join('&')
  end

  def build_headers opts={}
    headers = {}
    headers['Accept']          = accept if accept
    headers['Accept-Language'] = lang   if lang
    headers.merge(opts[:headers] || {})
  end

  def post_request result, uri, opts, &cb
    if decode?(opts)
                                  # [this].first is not needed for yajl-ruby
      decoded = self.class.json_decode("[#{result}]").first
      check_error(decoded, uri, &cb)
    else
      block_given? ? yield(result) : result
    end
  rescue ParseError => error
    error_handler.call(error, uri) if error_handler
  end

  def decode? opts
    if opts.has_key?(:auto_decode)
      opts[:auto_decode]
    elsif opts.has_key?(:suppress_decode)
      !opts[:suppress_decode]
    else
      auto_decode
    end
  end

  def check_sig_and_return_data cookies
    cookies if secret && if block_given?
                           yield
                         else
                           calculate_sig(cookies)
                         end == cookies['sig']
  end

  def check_error hash, uri
    if error_handler && hash.kind_of?(Hash) &&
       (hash['error'] ||    # from graph api
        hash['error_code']) # from fql
      cache_assign(uri, nil)
      error_handler.call(hash, uri)
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

  def cache_assign uri, value
    return unless cache
    cache[cache_key(uri)] = value
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

  def cache_for uri, result, meth, opts
    return if !cache || meth != :get

    if opts[:expires_in].kind_of?(Fixnum) && cache.method(:store).arity == -3
      cache.store(cache_key(uri), result, :expires_in => opts[:expires_in])
    else
      cache_assign(uri, result)
    end
  end

  def fetch meth, uri, payload, opts
    RestClient::Request.execute(:method => meth, :url => uri,
                                :headers => build_headers(opts),
                                :payload => payload).body.
      tap{ |result| cache_for(uri, result, meth, opts) }
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
    log_handler.call(event)             if log_handler
    log_method .call("DEBUG: #{event}") if log_method
  end
end
