
if respond_to?(:require_relative, true)
  require_relative 'common'
else
  require File.dirname(__FILE__) + '/common'
end

describe RestGraph do
  after do
    WebMock.reset!
    RR.verify
  end

  describe 'cache' do
    before do
      @url, @body = "https://graph.facebook.com/cache", '{"message":"ok"}'
      @cache = {}
      @rg = RestGraph.new(:cache => @cache, :auto_decode => false)
      stub_request(:get, @url).to_return(:body => @body).times(1)
    end

    should 'enable cache if passing cache' do
      3.times{ @rg.get('cache').should == @body }
      @cache.should == {@rg.send(:cache_key, @url) => @body}
    end

    should 'respect expires_in' do
      mock(@cache).method(:store){ mock!.arity{ -3 } }
      mock(@cache).store(@rg.send(:cache_key, @url), @body, :expires_in => 3)
      @rg.get('cache', {}, :expires_in => 3).should == @body
    end

    should 'update cache if there is cache option set to false' do
      @rg.get('cache')                     .should == @body
      stub_request(:get, @url).to_return(:body => @body.reverse).times(2)
      @rg.get('cache')                     .should == @body
      @rg.get('cache', {}, :cache => false).should == @body.reverse
      @rg.get('cache')                     .should == @body.reverse
      @rg.cache = nil
      @rg.get('cache', {}, :cache => false).should == @body.reverse
    end
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
