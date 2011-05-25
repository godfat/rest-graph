
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

module RestCore
  # ------------------------ event ------------------------
  EventStruct = Struct.new(:duration, :url) unless
    RestCore.const_defined?(:EventStruct)

  class Event < EventStruct
    # self.class.name[/(?<=::)\w+$/] if RUBY_VERSION >= '1.9.2'
    def name; self.class.name[/::\w+$/].tr(':', ''); end
    def to_s; "RestCore: spent #{sprintf('%f', duration)} #{name} #{url}";end
  end
  class Event::MultiDone    < Event; end
  class Event::Requested    < Event; end
  class Event::CacheHit     < Event; end
  class Event::CacheCleared < Event; end
  class Event::Failed       < Event; end
  # ------------------------ event ------------------------
end

module RestCore::Middleware
  def self.included mod
    mod.send(:include, RestCore)
    mod.send(:attr_reader, :app)
    return unless mod.respond_to?(:members)
    accessors = mod.members.map{ |member| <<-RUBY }.join("\n")
      def #{member} env
        if env.key?('#{member}')
          env['#{member}']
        else
          @#{member}
        end
      end
    RUBY
    args      = [:app] + mod.members
    args_list = args.join(', ')
    ivar_list = args.map{ |a| "@#{a}" }.join(', ')
    initialize = <<-RUBY
      def initialize #{args_list}
        #{ivar_list} = #{args_list}
      end
    RUBY
    mod.module_eval("#{accessors}\n#{initialize}")
  end
  def call env; app.call(env)                          ; end
  def fail env; app.fail(env) if app.respond_to?(:fail); end
  def log  env; app. log(env) if app.respond_to?(:log ); end
end

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
    middles.reverse.inject(app.new){ |app, (middle, args, block)|
      begin
        middle.new(app, *partial_deep_copy(args), &block)
      rescue ArgumentError => e
        raise ArgumentError.new("#{middle}: #{e}")
      end
    }
  end

  def partial_deep_copy obj
    case obj
      when Array; obj.map{ |o| partial_deep_copy(o) }
      when Hash ; obj.inject({}){ |r, (k, v)| r[k] = partial_deep_copy(v); r }
      when Numeric, Symbol, TrueClass, FalseClass, NilClass; obj
      else begin obj.dup; rescue TypeError; obj; end
    end
  end

  def to_client prefix, *attrs
    # struct = Struct.new(*members, *attrs) if RUBY_VERSION >= 1.9.2
    struct = Struct.new(*(members + attrs))
    client = Class.new(struct)
    client.send(:include, Client)
    Object.const_set( prefix , client)
    client.const_set('Struct', struct)
    class << client; attr_reader :builder; end
    client.instance_variable_set(:@builder, self)
    client
  end
end

module RestCore::Client
  def self.included mod
    # honor default attributes
    src = mod.members.map{ |name|
      <<-RUBY
        def #{name}
          if (r = super).nil? && self.class.respond_to?(:default_#{name})
            self.class.default_#{name}
          else
            r
          end
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
    mod.const_set('Accessor', accessor)
    mod.send(:include, accessor)
  end

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
      req = reqs.first
      app.call(build_env.merge('REQUEST_METHOD'  => req[0],
                               'REQUEST_URI'     => req[1],
                               'REQUEST_HEADERS' => opts[:headers],
                               'REQUEST_PAYLOAD' => req[2]))
    end
  end
  # ------------------------ instance ---------------------



  protected
  def build_env
    attributes.inject({}){ |r, (k,v)|
      r[k.to_s] = v unless v.nil?
      r
    }
  end

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
          log(env.merge('event' =>
            Event::Requested.new(Time.now - start_time, uri)))
        }
        r.error{
          log(env.merge('event' =>
            Event::Failed.new(Time.now - start_time, uri)))
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
        log(env.merge('event' => Event::MultiDone.new(Time.now - start_time,
          clients.map(&:uri).join(', '))))
        yield(results)
      end
    }
  end

  def build_query_string query={}, opts={}
    q = query.select{ |k, v| v } # compacting the hash
    return '' if q.empty?
    return '?' + q.map{ |(k, v)| "#{k}=#{CGI.escape(v.to_s)}" }.join('&')
  end
end

class RestCore::CommonLogger
  def self.members; [:log_method]; end
  include RestCore::Middleware

  def call env
    start_time = Time.now
    result = app.call(env)
    log(env.merge('event' =>
      Event::Requested.new(Time.now - start_time, env['REQUEST_URI'])))
    result
  end

  def log env
    log_method(env).call("DEBUG: #{env['event']}") if log_method(env)
    app.log(env)
  end
end

class RestCore::Cache
  def self.members; [:cache]; end
  include RestCore::Middleware

  def call env
    cache_get(env) || cache_for(env, app.call(env))
  end

  def fail env
    cache_assign(env, nil)
    app.fail(env)
  end

  protected
  def cache_key env
    Digest::MD5.hexdigest(env['cache.key'] || env['REQUEST_URI'])
  end

  def cache_get env
    return unless cache(env)
    start_time = Time.now
    cache(env)[cache_key(env)].tap{ |result|
      if result
        log(env.merge('event' =>
          Event::CacheHit.new(Time.now - start_time, env['REQUEST_URI'])))
      end
    }
  end

  def cache_for env, value
    return value unless cache(env)
    # fake post (opts[:post] => true) is considered get and need cache
    return value if env['REQUEST_METHOD'] != :get unless env['cache.post']

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

    start_time = Time.now
    log(env.merge('event' =>
      Event::CacheCleared.new(Time.now - start_time, env['REQUEST_URI']))) if
        value.nil?

    cache(env)[cache_key(env)] = value
  end
end

class RestCore::ErrorDetector
  def self.members; [:error_detector]; end
  include RestCore::Middleware

  def call env
    response = app.call(env)
    if response.kind_of?(Hash) &&
       error_detector(env).call(env.merge('RESPONSE' => response))

      app.fail(env.merge('RESPONSE' => response))
    end
    response
  end
end

class RestCore::ErrorHandler
  def self.members; [:error_handler]; end
  include RestCore::Middleware

  def fail env
    app.fail(env)
    error_handler(env).call(env) if error_handler(env)
  end
end

class RestCore::AutoJsonDecode
  def self.members; [:auto_decode]; end
  include RestCore::Middleware

  def call env
    if auto_decode(env)
                                  # [this].first is not needed for yajl-ruby
      self.class.json_decode("[#{app.call(env)}]").first
    else
      app.call(env)
    end
  rescue self.class.const_get(:ParseError) => error
    app.fail(env.merge('exception' => error))
  end

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
  select_json!(self)
  # ------------------------ json -------------------------
end

class RestCore::Timeout
  def self.members; [:timeout]; end
  include RestCore::Middleware

  def call env
    ::Timeout.timeout(timeout(env)){ app.call(env) }
  end
end

class RestCore::DefaultSite
  def self.members; [:site]; end
  include RestCore::Middleware

  def call env
    if env['REQUEST_URI'].start_with?('http')
      app.call(env)
    else
      app.call(env.merge('REQUEST_URI' =>
        "#{site(env)}#{env['REQUEST_URI']}"))
    end
  end
end

class RestCore::DefaultHeaders
  def self.members; [:headers]; end
  include RestCore::Middleware
  def call env
    app.call(env.merge('REQUEST_HEADERS' =>
      @headers.merge(headers(env)).merge(env['REQUEST_HEADERS'] || {})))
  end
end

class RestCore::RestClient
  include RestCore::Middleware
  def initialize; require 'restclient'; end
  def call env
    ::RestClient::Request.execute(:method  => env['REQUEST_METHOD' ],
                                  :url     => env['REQUEST_URI'    ],
                                  :headers => env['REQUEST_HEADERS'],
                                  :payload => env['REQUEST_PAYLOAD']).body
  rescue ::RestClient::Exception => e
    e.http_body
  end
end

RestCore::Builder.client('RestGraph',
                         :app_id, :secret,
                         :old_site,
                         :old_server, :graph_server) do

  use DefaultSite   ,  'https://graph.facebook.com/'
  use ErrorDetector , lambda{ |env| env['RESPONSE']['error'] ||
                                    env['RESPONSE']['error_code'] }
  use AutoJsonDecode, true

  use Cache         , {}
  use Timeout       ,  10
  use DefaultHeaders, {'Accept'          => 'application/json',
                       'Accept-Language' => 'en-us'}

  use ErrorHandler  , lambda{ |env| p "error: #{env.inspect}" }
  use CommonLogger  , method(:puts)

  run RestClient
end


#   # ------------------------ hmac -------------------------
#   module Hmac
#     # Fallback to ruby-hmac gem in case system openssl
#     # lib doesn't support SHA256 (OSX 10.5)
#     def hmac_sha256 key, data
#       OpenSSL::HMAC.digest('sha256', key, data)
#     rescue RuntimeError
#       require 'hmac-sha2'
#       HMAC::SHA256.digest(key, data)
#     end
#   end
#   # ------------------------ hmac -------------------------
#
#
#
#   # ------------------------ instance ---------------------
# end
