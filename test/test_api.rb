
if respond_to?(:require_relative, true)
  require_relative 'common'
else
  require File.dirname(__FILE__) + '/common'
end

describe RestGraph do
  after do
    reset_webmock
    RR.verify
  end

  should 'generate correct url' do
    TestHelper.normalize_url(
    RestGraph.new(:access_token => 'awesome').url('path', :query => 'str')).
      should ==
        'https://graph.facebook.com/path?access_token=awesome&query=str'
  end

  should 'request to correct server' do
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

  should 'post right' do
    stub_request(:post, 'https://graph.facebook.com/feed/me').
      with(:body => 'message=hi%20there').to_return(:body => 'ok')

    RestGraph.new(:auto_decode => false).
      post('feed/me', :message => 'hi there').should == 'ok'
  end

  should 'suppress auto-decode in an api call' do
    stub_request(:get, 'https://graph.facebook.com/woot').
      to_return(:body => 'bad json')

    rg = RestGraph.new(:auto_decode => true)
    rg.get('woot', {}, :suppress_decode => true).should == 'bad json'
    rg.auto_decode.should == true
  end

  should 'call post_request after request' do
    stub_request(:put, 'https://graph.facebook.com/feed/me').
      with(:body => 'message=hi%20there').to_return(:body => '[]')

    mock.proxy(rg = RestGraph.new).post_request('[]', {})
    rg.put('feed/me', :message => 'hi there').
      should == []
  end

  should 'not raise exception when encountering error' do
    [500, 401, 402, 403].each{ |status|
      stub_request(:delete, 'https://graph.facebook.com/123').to_return(
        :body => '[]', :status => status)

      RestGraph.new.delete('123').should == []
    }
  end

  should 'convert query to string' do
    mock(o = Object.new).to_s{ 'i am mock' }
    stub_request(:get, "https://graph.facebook.com/search?q=i%20am%20mock").
      to_return(:body => 'ok')
    RestGraph.new(:auto_decode => false).get('search', :q => o).should == 'ok'
  end
end
