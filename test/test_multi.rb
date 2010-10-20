
if respond_to?(:require_relative, true)
  require_relative 'common'
else
  require File.dirname(__FILE__) + '/common'
end

require 'em-http-request'
load 'webmock/http_lib_adapters/em_http_request.rb'

describe 'RestGraph#multi' do
  after do
    WebMock.reset_webmock
  end

  should 'do multi query with em-http-request' do
    # TODO: wait for Addressable::URI#normalize! remove trailing ?
    # http://github.com/sporkmonger/addressable/issues/5
    url = 'https://graph.facebook.com/me?'
    stub_request(:get, url).to_return(:body => '{"data":"get"}')
    stub_request(:put, url).to_return(:body => '{"data":"put"}')
    EM.run{
      RestGraph.new.multi([:get, 'me'], [:put, 'me']){ |results|
        results.should == [{'data' => 'get'}, {'data' => 'put'}]
        EM.stop
      }
    }
  end

  should 'call aget, aput family with multi' do
    url = 'https://graph.facebook.com/me?'
    %w[aget adelete apost aput].each{ |meth|
      stub_request("#{meth[1..-1]}".to_sym, url).
        to_return(:body => "{\"data\":\"#{meth}\"}")
      EM.run{
        RestGraph.new.send(meth, 'me', {}){ |result|
          result.should == {'data' => meth.to_s}
          EM.stop
        }
      }
    }
  end
end
