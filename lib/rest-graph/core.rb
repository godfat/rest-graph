
require 'rest-graph/rest-core/rest-core.rb'

# the data structure used in RestGraph

class RestGraph < RestCore.struct('RestGraph',
                                  :app_id, :secret,
                                  :old_server, :graph_server)
  include RestCore

  def graph_server
    puts "[DEPRECATED] please use `server' instead of `graph_server'"
    super
  end

  def graph_server= new_server
    puts "[DEPRECATED] please use `server=' instead of `graph_server='"
    super
  end

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

  # setup defaults
  module DefaultAttributes
    extend self
    def default_server      ; 'https://graph.facebook.com/'; end
    def default_old_server  ; 'https://api.facebook.com/'  ; end
    def default_app_id      ; nil                          ; end
    def default_secret      ; nil                          ; end
    def default_error_handler
      lambda{ |error, url| raise ::RestGraph::Error.parse(error, url) }
    end
    def default_graph_server
      puts "[DEPRECATED] please use `default_server' instead of " \
           "`default_graph_server'"
      default_server
    end
  end
  extend DefaultAttributes

  # common methods

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

  def next_page hash, opts={}, &cb
    if hash['paging'].kind_of?(Hash) && hash['paging']['next']
      request(opts, [:get, URI.encode(hash['paging']['next'])], &cb)
    else
      yield(nil) if block_given?
    end
  end

  def prev_page hash, opts={}, &cb
    if hash['paging'].kind_of?(Hash) && hash['paging']['previous']
      request(opts, [:get, URI.encode(hash['paging']['previous'])], &cb)
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
    "#{server}oauth/authorize#{build_query_string(query)}"
  end

  def authorize! opts={}
    query = {:client_id => app_id, :client_secret => secret}.merge(opts)
    self.data = Rack::Utils.parse_query(
                  request({:auto_decode => false}.merge(opts),
                          [:get, url('oauth/access_token', query)]))
  end





  # old rest facebook api, i will definitely love to remove them someday

  def old_rest path, query={}, opts={}, &cb
    uri = url("method/#{path}", {:format => 'json'}.merge(query),
              old_server, opts)
    if opts[:post]
      request(
        opts.merge(:uri => uri),
        [:post,
         url("method/#{path}", {:format => 'json'}, old_server, opts),
         query],
        &cb)
    else
      request(opts, [:get, uri], &cb)
    end
  end

  def secret_old_rest path, query={}, opts={}, &cb
    old_rest(path, query, {:secret => true}.merge(opts), &cb)
  end

  def fql code, query={}, opts={}, &cb
    old_rest('fql.query', {:query => code}.merge(query), opts, &cb)
  end

  def fql_multi codes, query={}, opts={}, &cb
    old_rest('fql.multiquery',
      {:queries => self.class.json_encode(codes)}.merge(query), opts, &cb)
  end

  def exchange_sessions query={}, opts={}, &cb
    q = {:client_id => app_id, :client_secret => secret,
         :type => 'client_cred'}.merge(query)
    request(opts, [:post, url('oauth/exchange_sessions', q)], &cb)
  end

  def check_sig_and_return_data cookies
    cookies if secret && if block_given?
                           yield
                         else
                           calculate_sig(cookies)
                         end == cookies['sig']
  end

  def check_error opts, uri, hash
    if error_handler && hash.kind_of?(Hash) &&
       (hash['error'] ||    # from graph api
        hash['error_code']) # from fql
      cache_assign(opts, uri, nil)
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

  def merge_data lhs, rhs
    [lhs, rhs].each{ |hash|
      return rhs.reject{ |k, v| k == 'paging' } if
        !hash.kind_of?(Hash) || !hash['data'].kind_of?(Array)
    }
    lhs['data'].unshift(*rhs['data'])
    lhs
  end
end
