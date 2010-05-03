
require 'rest_client'

require 'cgi'

class RestGraph
  attr_accessor :access_token, :server, :accept, :lang, :auto_decode
  def initialize o = {}
    self.access_token = o[:access_token]
    self.server       = o[:server] || 'https://graph.facebook.com/'
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

  def client
    @client ||= RestClient::Resource.new(server)
  end

  def get    path, query = {}
    request(path, query, :get)
  end

  def delete path, query = {}
    request(path, query, :delete)
  end

  def post   path, payload, query = {}
    request(path, query, :post, payload)
  end

  def put    path, payload, query = {}
    request(path, query, :put,  payload)
  end

  private
  def request path, query, method, payload = nil
    post_request(
      client[path + build_query_string(query)].
        send(method, *[payload, build_headers].compact))
  rescue RestClient::InternalServerError => e
    post_request(e.http_body)
  end

  def build_query_string q = {}
    query = q.merge(access_token ? {:access_token => access_token} : {})
    return '' if query.empty?
    return '?' + query.sort.map{ |(k, v)| "#{k}=#{CGI.escape(v)}" }.join('&')
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
