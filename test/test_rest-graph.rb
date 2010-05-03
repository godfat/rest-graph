
require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'rack'     if RUBY_VERSION < '1.9.0' # autoload broken in 1.8?
require 'rest-graph'

require 'rr'
require 'webmock'
require 'bacon'

include RR::Adapters::RRMethods
include WebMock
WebMock.disable_net_connect!
Bacon.summary_on_exit

describe RestGraph do
  before do
    reset_webmock
  end

  def normalize_query query
    '?' + query[1..-1].split('&').sort.join('&')
  end

  it 'would build correct headers' do
    rg = RestGraph.new(:accept => 'text/html',
                       :lang   => 'zh-tw')
    rg.send(:build_headers).should == {'Accept'          => 'text/html',
                                       'Accept-Language' => 'zh-tw'}
  end

  it 'would build empty query string' do
    RestGraph.new.send(:build_query_string).should == ''
  end

  it 'would create access_token in query string' do
    RestGraph.new(:access_token => 'token').send(:build_query_string).
      should == '?access_token=token'
  end

  it 'would build correct query string' do
    normalize_query(
    RestGraph.new(:access_token => 'token').send(:build_query_string,
                                                 :message => 'hi!!')).
      should == '?access_token=token&message=hi%21%21'

    normalize_query(
    RestGraph.new.send(:build_query_string, :message => 'hi!!',
                                            :subject => '(&oh&)')).
      should == '?message=hi%21%21&subject=%28%26oh%26%29'
  end

  it 'would request to correct server' do
    stub_request(:get, 'http://nothing.godfat.org/me').with(
      :headers => {'Accept'          => 'text/plain',
                   'Accept-Language' => 'zh-tw',
                   'Accept-Encoding' => 'gzip, deflate', # this is by ruby
                  }.merge(RUBY_VERSION <= '1.9.0' ?
                  {} :
                  {'User-Agent'      => 'Ruby'})).       # this is by ruby
      to_return(:body => '{"data": []}')

    RestGraph.new(:graph_server => 'http://nothing.godfat.org/',
                  :lang   => 'zh-tw',
                  :accept => 'text/plain').get('me').should == {'data' => []}
  end

  it 'would post right' do
    stub_request(:post, 'https://graph.facebook.com/feed/me').
      with(:body => 'message=hi%20there').to_return(:body => 'ok')

    RestGraph.new(:auto_decode => false).
      post('feed/me', :message => 'hi there').should == 'ok'
  end

  it 'would auto decode json' do
    RestGraph.new(:auto_decode => true).send(:post_request, '[]').
      should == []
  end

  it 'would not auto decode json' do
    RestGraph.new(:auto_decode => false).send(:post_request, '[]').
      should == '[]'
  end

  it 'would call post_request after request' do
    stub_request(:put, 'https://graph.facebook.com/feed/me').
      with(:body => 'message=hi%20there').to_return(:body => '[]')

    begin
      RestGraph.send(:public, :post_request) # TODO: rr, why??

      mock.proxy(rg = RestGraph.new).post_request('[]')
      rg.put('feed/me', :message => 'hi there').
        should == []
    ensure
      RestGraph.send(:private, :post_request) # TODO: rr, why??
    end
  end

  it 'would not raise exception when encountering 500' do
    stub_request(:delete, 'https://graph.facebook.com/123').to_return(
      :body => '[]', :status => 500)

    RestGraph.new.delete('123').should == []
  end

  it 'would extract correct access_token' do
    access_token = '1|2-5|f.'
    app_id       = '1829'
    secret       = app_id.reverse
    sig          = '398262caea8442bd8801e8fba7c55c8a'
    fbs          = "\"access_token=#{CGI.escape(access_token)}&expires=0&" \
                   "secret=abc&session_key=def-456&sig=#{sig}&uid=3\""
    http_cookie  =
      "__utma=123; __utmz=456.utmcsr=(d)|utmccn=(d)|utmcmd=(n); " \
      "fbs_#{app_id}=#{fbs}"

    rg  = RestGraph.new(:app_id => app_id, :secret => secret)
    rg.parse_token_in_rack_env!('HTTP_COOKIE' => http_cookie).
                    should == access_token
    rg.access_token.should == access_token

    rg.parse_token_in_cookies!({"fbs_#{app_id}" => fbs}).
                    should == access_token
    rg.access_token.should == access_token

    rg.parse_token_in_fbs!(fbs).
                    should == access_token
    rg.access_token.should == access_token
  end

  it 'would do fql query with/without access_token' do
    fql = 'SELECT name FROM likes where id="123"'
    query = "query=#{fql}&format=json"
    stub_request(:get, "https://api.facebook.com/method/fql.query?#{query}").
      to_return(:body => '[]')

    RestGraph.new.fql(fql).should == []

    token = 'token'.reverse
    stub_request(:get, "https://api.facebook.com/method/fql.query?#{query}" \
      "&access_token=#{token}").
      to_return(:body => '[]')

    RestGraph.new(:access_token => token).fql(fql).should == []
  end
end
