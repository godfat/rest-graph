
if respond_to?(:require_relative, true)
  require_relative 'common'
else
  require File.dirname(__FILE__) + '/common'
end

describe RestGraph do
  before do
    reset_webmock
  end

  after do
    RR.verify
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
    TestHelper.normalize_query(
    RestGraph.new(:access_token => 'token').send(:build_query_string,
                                                 :message => 'hi!!')).
      should == '?access_token=token&message=hi%21%21'

    TestHelper.normalize_query(
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

  it 'could suppress auto-decode in an api call' do
    stub_request(:get, 'https://graph.facebook.com/woot').
      to_return(:body => 'bad json')

    rg = RestGraph.new(:auto_decode => true)
    rg.get('woot', {}, :suppress_decode => true).should == 'bad json'
    rg.auto_decode.should == true
  end

  it 'would call post_request after request' do
    stub_request(:put, 'https://graph.facebook.com/feed/me').
      with(:body => 'message=hi%20there').to_return(:body => '[]')

    mock.proxy(rg = RestGraph.new).post_request('[]', nil)
    rg.put('feed/me', :message => 'hi there').
      should == []
  end

  it 'would not raise exception when encountering 500' do
    stub_request(:delete, 'https://graph.facebook.com/123').to_return(
      :body => '[]', :status => 500)

    RestGraph.new.delete('123').should == []
  end

  it 'would return true in authorized? if there is an access_token' do
    RestGraph.new(:access_token => '1').authorized?.should == true
    RestGraph.new(:access_token => nil).authorized?.should == false
  end

  it 'would convert query to string' do
    mock(o = Object.new).to_s{ 'i am mock' }
    stub_request(:get, "https://graph.facebook.com/search?q=i%20am%20mock").
      to_return(:body => 'ok')
    RestGraph.new(:auto_decode => false).get('search', :q => o).should == 'ok'
  end
end
