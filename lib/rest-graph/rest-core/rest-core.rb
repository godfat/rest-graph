
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


module RestCore; end

class RestCore::Builder
  include RestCore

  def self.client prefix, *attrs, &block
    new(&block).to_client(prefix, *attrs)
  end

  attr_reader :app, :middles
  def initialize &block
    @middles = []
    instance_eval(&block) if block_given?
  end

  def use middle, *args, &block
    middles << [middle, args, block]
  end

  def run app
    @app = app
  end

  def members
    middles.map{ |(middle, args, block)| middle.members }.flatten
  end

  def to_app
    # === foldr m.new app middles
    middles.reverse.inject(app){ |app, (middle, args, block)|
      middle.new(app, *args, &block)
    }
  end

  def to_client prefix, *attrs
    name = "#{prefix}Struct"
    struct = if RestCore.const_defined?(name)
               RestCore.const_get(name)
             else
               # if RUBY_VERSION >= 1.9.2
               # RestCore.const_set(name, Struct.new(*members, *attrs))
               RestCore.const_set(name, Struct.new(*(members + attrs)))
             end

    client = Class.new(struct)
    client.send(:include, Client)
    class << client; attr_reader :builder; end
    client.instance_variable_set(:@builder, self)
    client
  end
end

module RestCore::Client
  attr_reader :app
  def initialize o={}
    (members + [:access_token]).each{ |name|
      send("#{name}=", o[name]) if o.key?(name)
    }
    @app = self.class.builder.to_app
  end

  def attributes
    Hash[each_pair.map{ |k, v| [k, send(k)] }]
  end

  def inspect
    "#<struct #{self.class.name} #{attributes.map{ |k, v|
      "#{k}=#{v.inspect}" }.join(', ')}>"
  end

  def lighten! o={}
    attributes.each{ |k, v| case v; when Proc, IO; send("#{k}=", false); end}
    send(:initialize, o)
    self
  end

  def lighten o={}
    dup.lighten!(o)
  end

  def url path, query={}, prefix=site, opts={}
    "#{prefix}#{path}#{build_query_string(query, opts)}"
  end

  # extra options:
  #   auto_decode: Bool # decode with json or not in this API request
  #                     # default: auto_decode in rest-graph instance
  #       timeout: Int  # the timeout for this API request
  #                     # default: timeout in rest-graph instance
  #        secret: Bool # use secret_acccess_token or not
  #                     # default: false
  #         cache: Bool # use cache or not; if it's false, update cache, too
  #                     # default: true
  #    expires_in: Int  # control when would the cache be expired
  #                     # default: nil
  #         async: Bool # use eventmachine for http client or not
  #                     # default: false, but true in aget family
  #       headers: Hash # additional hash you want to pass
  #                     # default: {}
  def get    path, query={}, opts={}, &cb
    request(opts, [:get   , url(path, query, site, opts)], &cb)
  end

  def delete path, query={}, opts={}, &cb
    request(opts, [:delete, url(path, query, site, opts)], &cb)
  end

  def post   path, payload={}, query={}, opts={}, &cb
    request(opts, [:post  , url(path, query, site, opts), payload],
            &cb)
  end

  def put    path, payload={}, query={}, opts={}, &cb
    request(opts, [:put   , url(path, query, site, opts), payload],
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
        [meth, url(path, query || {}, site, opts), payload]
      }, &cb)
  end

  def request opts, *reqs, &cb
    reqs.each{ |(meth, uri, payload)|
      next if meth != :get     # only get result would get cached
      cache_assign(opts, uri, nil)
    } if opts[:cache] == false # remove cache if we don't want it

    if opts[:async]
      request_em(opts, reqs, &cb)
    else
      request_rc(opts, *reqs.first, &cb)
    end
  end
  # ------------------------ instance ---------------------



  protected
  # those are for user to override
  def prepare_query_string opts={};    {}; end
  def prepare_headers      opts={};    {}; end
  def error?               decoded; false; end

  private
  def request_em opts, reqs
    start_time = Time.now
    rs = reqs.map{ |(meth, uri, payload)|
      r = EM::HttpRequest.new(uri).send(meth, :body => payload,
                                              :head => build_headers(opts))
      if cached = cache_get(opts, uri)
        # TODO: this is hack!!
        r.instance_variable_set('@response', cached)
        r.instance_variable_set('@state'   , :finish)
        r.on_request_complete
        r.succeed(r)
      else
        r.callback{
          cache_for(opts, uri, meth, r.response)
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
        post_request(opts, client.uri, client.response)
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

  def build_query_string query={}, opts={}
                                              # compacting the hash
    q = prepare_query_string(opts).merge(query).select{ |k, v| v }
    return '' if q.empty?
    return '?' + q.map{ |(k, v)| "#{k}=#{CGI.escape(v.to_s)}" }.join('&')
  end

  def build_headers opts={}
    headers = {}
    headers['Accept']          = accept if accept
    headers['Accept-Language'] = lang   if lang
    headers.merge(prepare_headers(opts).merge(opts[:headers] || {}))
  end

  def post_request opts, uri, result
    if decode?(opts)
                                  # [this].first is not needed for yajl-ruby
      decoded = self.class.json_decode("[#{result}]").first
      if error?(decoded)
        cache_assign(opts, uri, nil)
        error_handler.call(decoded, uri) if error_handler
      end
      block_given? ? yield(decoded) : decoded
    else
      block_given? ? yield(result ) : result
    end
  rescue self.class.const_get(:ParseError) => error
    error_handler.call(error, uri) if error_handler
  end

  def decode? opts
    if opts.has_key?(:auto_decode)
      opts[:auto_decode]
    else
      auto_decode
    end
  end

  def log event
    log_handler.call(event)             if log_handler
    log_method .call("DEBUG: #{event}") if log_method
  end
end

class RestCore::Cache
  def self.members; [:cache]; end
  def cache env; env['cache'] || @cache; end

  attr_reader :app
  def initialize app, cache
    @app, @cache = app, cache
  end

  def call env
    cache_get(env) || cache_for(env, app.call(env))
  end

  protected
  def cache_key env
    Digest::MD5.hexdigest(env['cache.key'] || env['rest-core.uri'])
  end

  def cache_get env
    return unless cache(env)
    start_time = Time.now
    cache(env)[cache_key(env)].tap{ |result|
      if result
        log(Event::CacheHit.new(Time.now - start_time, env['rest-core.uri']))
      end
    }
  end

  def cache_for env, value
    return value unless cache(env)
    # fake post (opts[:post] => true) is considered get and need cache
    return if env['REQUEST_METHOD'] != :get unless env['cache.post']

    if env['cache.expires_in'].kind_of?(Fixnum) &&
       cache(env).method(:store).arity == -3
      cache(env).store(cache_key(env), value,
                  :expires_in => env['cache.expires_in'])
    else
      cache_assign(env, value)
    end
  end

  def cache_assign env, value
    return value unless cache(env)
    cache(env)[cache_key(env)] = value
  end
end

class RestCore::Timeout
  def self.members; [:timeout]; end
  def timeout env; env['timeout'] || @timeout; end

  attr_reader :app
  def initialize app, timeout=10
    @app, @timeout = app, timeout
  end

  def call env
    Timeout.timeout(timeout(env)){ app.call(env) }
  end
end

class RestCore::RestClient
  def self.members; []; end

  def call env
    RestClient::Request.execute(:method  => env['REQUEST_METHOD'   ],
                                :url     => env['rest-core.uri'    ],
                                :headers => env['rest-core.headers'],
                                :payload => env['rest-core.payload']).body
  rescue RestClient::Exception => e
    e.http_body
  end
end

RestGraph = RestCore::Builder.client('RestGraph',
                                     :app_id, :secret,
                                     :old_site,
                                     :old_server, :graph_server) do
  use Cache, {}
  use Timeout, 10
  run RestClient.new
end

module RestCore
  # ------------------------ class ------------------------
  def self.included mod
    return if   mod < DefaultAttributes
    mod.send(:extend, DefaultAttributes)
    mod.send(:extend, Hmac)
    setup_accessor(mod)
    select_json!(mod)
  end

  def self.members_core
    [:site, :accept, :lang, :auto_decode, :timeout,
     :data, :cache, :log_method, :log_handler, :error_handler]
  end

  def self.struct prefix, *members
    name = "#{prefix}Struct"
    if const_defined?(name)
      const_get(name)
    else
      # Struct.new(*members_core, *members) if RUBY_VERSION >= '1.9.2'
      const_set(name, Struct.new(*(members_core + members)))
    end
  end

  def self.setup_accessor mod
    # honor default attributes
    src = mod.members.map{ |name|
      <<-RUBY
        def #{name}
          if (r = super).nil? then self.#{name} = self.class.default_#{name}
                              else r end
        end
        self
      RUBY
    }
    # if RUBY_VERSION < '1.9.2'
    src << <<-RUBY if mod.members.first.kind_of?(String)
      def members
        super.map(&:to_sym)
      end
      self
    RUBY
    # end
    accessor = Module.new.module_eval(src.join("\n"))
    const_set("#{mod.name}Accessor", accessor)
    mod.send(:include, accessor)
  end
  # ------------------------ class ------------------------



  # ------------------------ default ----------------------
  module DefaultAttributes
    extend self
    def default_site         ; 'http://localhost/'; end
    def default_accept       ; 'text/javascript'  ; end
    def default_lang         ; 'en-us'            ; end
    def default_auto_decode  ; true               ; end
    def default_timeout      ; 10                 ; end
    def default_data         ; {}                 ; end
    def default_cache        ; nil                ; end
    def default_log_method   ; nil                ; end
    def default_log_handler  ; nil                ; end
    def default_error_handler; nil                ; end
  end
  extend DefaultAttributes
  # ------------------------ default ----------------------

  # ------------------------ event ------------------------
  EventStruct = Struct.new(:duration, :url) unless
    RestCore.const_defined?(:EventStruct)

  class Event < EventStruct
    # self.class.name[/(?<=::)\w+$/] if RUBY_VERSION >= '1.9.2'
    def name; self.class.name[/::\w+$/].tr(':', ''); end
    def to_s; "RestCore: spent #{sprintf('%f', duration)} #{name} #{url}";end
  end
  class Event::MultiDone < Event; end
  class Event::Requested < Event; end
  class Event::CacheHit  < Event; end
  class Event::Failed    < Event; end
  # ------------------------ event ------------------------



  # ------------------------ json -------------------------
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

  def self.select_json! mod, picked=false
    if    Object.const_defined?(:Yajl)
      mod.send(:extend, YajlRuby)
    elsif Object.const_defined?(:JSON)
      mod.send(:extend, Json)
    elsif picked
      mod.send(:extend, Gsub)
    else
      # pick a json gem if available
      %w[yajl json].each{ |json|
        begin
          require json
          break
        rescue LoadError
        end
      }
      select_json!(mod, true)
    end
  end
  # ------------------------ json -------------------------


  # ------------------------ hmac -------------------------
  module Hmac
    # Fallback to ruby-hmac gem in case system openssl
    # lib doesn't support SHA256 (OSX 10.5)
    def hmac_sha256 key, data
      OpenSSL::HMAC.digest('sha256', key, data)
    rescue RuntimeError
      require 'hmac-sha2'
      HMAC::SHA256.digest(key, data)
    end
  end
  # ------------------------ hmac -------------------------



  # ------------------------ instance ---------------------
end
