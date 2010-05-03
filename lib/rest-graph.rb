
require 'rest_client'

require 'cgi'

class RestGraph
  autoload :Rack, 'rack'
  def self.parse_token_in_rack_env env, app_id = '\d+'
    env['HTTP_COOKIE'] =~ /fbs_#{app_id}="(.+?)"/ &&
      Rack::Utils.parse_query($1)['access_token']
  end

  def self.parse_token_in_cookies cookies, app_id
    parse_token_in_fb_cookie(cookies["fbs_#{app_id}"])
  end

  def self.parse_token_in_fb_cookie fb_cookie
    fb_cookie && Rack::Utils.parse_query(fb_cookie[1..-2])['access_token']
  end

  attr_accessor :access_token, :graph_server, :fql_server,
                :accept, :lang, :auto_decode
  def initialize o = {}
    self.access_token = o[:access_token]
    self.graph_server = o[:graph_server] || 'https://graph.facebook.com/'
    self.fql_server   = o[:fql_server]   || 'https://api.facebook.com/'
    self.accept       = o[:accept] || 'text/javascript'
    self.lang         = o[:lang]   || 'en-us'
    self.auto_decode  = o.key?(:auto_decode) ? o[:auto_decode] : true

    if auto_decode
      begin
        require 'json'
      rescue LoadError
        require 'json_pure'
      end
    end
  end

  def get    path, query = {}
    request(graph_server, path, query, :get)
  end

  def delete path, query = {}
    request(graph_server, path, query, :delete)
  end

  def post   path, payload, query = {}
    request(graph_server, path, query, :post, payload)
  end

  def put    path, payload, query = {}
    request(graph_server, path, query, :put,  payload)
  end

  def fql query
    request(fql_server, 'method/fql.query', :get, :query => query)
  end

  private
  def request server, path, query, method, payload = nil
    post_request(
      RestClient::Resource.new(server)[path + build_query_string(query)].
      send(method, *[payload, build_headers].compact))
  rescue RestClient::InternalServerError => e
    post_request(e.http_body)
  end

  def build_query_string q = {}
    query = q.merge(access_token ? {:access_token => access_token} : {})
    return '' if query.empty?
    return '?' + query.map{ |(k, v)| "#{k}=#{CGI.escape(v)}" }.join('&')
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
end
