
if respond_to?(:require_relative, true)
  require_relative 'common'
else
  require File.dirname(__FILE__) + '/common'
end

describe RestGraph do
  after do
    WebMock.reset_webmock
    RR.verify
  end

  should 'enable cache if passing cache' do
    url, body = "https://graph.facebook.com/cache", '{"message":"ok"}'
    stub_request(:get, url).to_return(:body => body).times(1)

    cache = {}
    rg = RestGraph.new(:cache => cache, :auto_decode => false)
    3.times{ rg.get('cache').should == body }
    cache.should == {rg.send(:cache_key, url) => body}
  end

  should 'not cache post/put/delete' do
    [:put, :post, :delete].each{ |meth|
      url, body = "https://graph.facebook.com/cache", '{"message":"ok"}'
      stub_request(meth, url).to_return(:body => body).times(3)

      cache = {}
      rg = RestGraph.new(:cache => cache)
      3.times{
        if meth == :delete
          rg.send(meth, 'cache').should == {'message' => 'ok'}
        else
          rg.send(meth, 'cache', 'payload').should == {'message' => 'ok'}
        end
      }
      cache.should == {}
    }
  end
end
