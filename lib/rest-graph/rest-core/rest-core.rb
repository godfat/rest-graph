
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
  class Event::MultiDone < Event; end
  class Event::Requested < Event; end
  class Event::CacheHit  < Event; end
  class Event::Failed    < Event; end
  # ------------------------ event ------------------------



  # ------------------------ json  ------------------------
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
  # ------------------------ json  ------------------------



  def self.members_core
    [:auto_decode, :timeout, :cache, :accept, :lang,
     :log_method, :log_handler, :error_handler]
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

  def self.included mod
    return if mod < Hmac
    mod.send(:extend, Hmac)
    setup_accessor(mod)
    select_json!(mod)
  end

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




  def initialize o={}
    (members + [:access_token]).each{ |name|
      send("#{name}=", o[name]) if o.key?(name)
    }
  end

  def lighten! o={}
    attributes.each{ |k, v| case v; when Proc, IO; send("#{k}=", false); end}
    send(:initialize, o)
    self
  end

  def lighten o={}
    dup.lighten!(o)
  end

  def inspect
    "#<struct #{self.class.name} #{attributes.map{ |k, v|
      "#{k}=#{v.inspect}" }.join(', ')}>"
  end

  def attributes
    Hash[each_pair.map{ |k, v| [k, send(k)] }]
  end


  def request opts, *reqs, &cb
    Timeout.timeout(opts[:timeout] || timeout){
      reqs.each{ |(meth, uri, payload)|
        next if meth != :get     # only get result would get cached
        cache_assign(opts, uri, nil)
      } if opts[:cache] == false # remove cache if we don't want it

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

  def request_rc opts, meth, uri, payload=nil, &cb
    start_time = Time.now
    post_request(opts, uri,
                 cache_get(opts, uri) || fetch(opts, uri, meth, payload),
                 &cb)
  rescue RestClient::Exception => e
    post_request(opts, uri, e.http_body, &cb)
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

  def post_request opts, uri, result, &cb
    if decode?(opts)
                                  # [this].first is not needed for yajl-ruby
      decoded = self.class.json_decode("[#{result}]").first
      check_error(opts, uri, decoded, &cb)
    else
      block_given? ? yield(result) : result
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


  def cache_key opts, uri
    Digest::MD5.hexdigest(opts[:uri] || uri)
  end

  def cache_assign opts, uri, value
    return unless cache
    cache[cache_key(opts, uri)] = value
  end

  def cache_get opts, uri
    return unless cache
    start_time = Time.now
    cache[cache_key(opts, uri)].tap{ |result|
      log(Event::CacheHit.new(Time.now - start_time, uri)) if result
    }
  end

  def cache_for opts, uri, meth, value
    return unless cache
    # fake post (opts[:post] => true) is considered get and need cache
    return if meth != :get unless opts[:post]

    if opts[:expires_in].kind_of?(Fixnum) && cache.method(:store).arity == -3
      cache.store(cache_key(opts, uri), value,
                  :expires_in => opts[:expires_in])
    else
      cache_assign(opts, uri, value)
    end
  end

  def fetch opts, uri, meth, payload
    RestClient::Request.execute(:method => meth, :url => uri,
                                :headers => build_headers(opts),
                                :payload => payload).body.
      tap{ |result| cache_for(opts, uri, meth, result) }
  end

  def log event
    log_handler.call(event)             if log_handler
    log_method .call("DEBUG: #{event}") if log_method
  end
end
