
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
    RR.verify
  end

  should 'do multi query with em-http-request' do
    url = 'https://graph.facebook.com/me'
    stub_request(:get, url).to_return(:body => '{"data":"get"}')
    stub_request(:put, url).to_return(:body => '{"data":"put"}')
    rg = RestGraph.new
    mock.proxy(rg).request_em(anything, anything)
    EM.run{
      rg.multi([[:get, 'me'], [:put, 'me']]){ |results|
        results.should == [{'data' => 'get'}, {'data' => 'put'}]
        EM.stop
      }
    }
  end

  should 'call aget, aput family with multi' do
    url = 'https://graph.facebook.com/me'
    %w[aget adelete apost aput].each{ |meth|
      stub_request("#{meth[1..-1]}".to_sym, url).
        to_return(:body => "{\"data\":\"#{meth}\"}")
      rg = RestGraph.new
      mock.proxy(rg).request_em(anything, anything)
      EM.run{
        rg.send(meth, 'me', {}){ |result|
          result.should == {'data' => meth.to_s}
          EM.stop
        }
      }
    }
  end

  should 'for_pages with callback' do
    rg = RestGraph.new
    %w[next previous].each{ |type|
      kind = "#{type}_page"
      data = {'paging' => {type => 'zzz'}, 'data' => ['z']}

      # invalid pages or just the page itself
      nils = 0
      ranges = -1..1
      ranges.each{ |page|
        rg.for_pages(data, page, {}, kind){ |r|
          if r
            r.should == data
          else
            nils += 1
          end
        }.should == data
      }
      nils.should == ranges.to_a.size

      (2..4).each{ |pages|
        # merge data
        stub_request(:get, 'zzz').to_return(:body => '{"data":["y"]}')
        expects = [{'data' => %w[y]}, nil]
        rg.for_pages(data, pages, {}, kind){ |r|
          r.should == expects.shift
        }.should == {'data' => %w[z y]}
        expects.empty?.should == true

        # this data cannot be merged
        stub_request(:get, 'zzz').to_return(:body => '{"data":"y"}')
        expects = [{'data' => 'y'}, nil]
        rg.for_pages(data, pages, {}, kind){ |r|
          r.should == expects.shift
        }.should == {'data' => %w[z]}
        expects.empty?.should == true
      }

      stub_request(:get, 'zzz').to_return(:body =>
        '{"paging":{"'+type+'":"yyy"},"data":["y"]}')
      stub_request(:get, 'yyy').to_return(:body => '{"data":["x"]}')

      expects = [{'data' => %w[y]}, {'data' => %w[x]}, nil]
      rg.for_pages(data, 3, {}, kind){ |rr|
        if rr
          r = rr.dup
          r.delete('paging')
        else
          r = rr
        end
        r.should == expects.shift
      }.should == {'data' => %w[z y x]}
    }
  end

  # should 'cache in multi' do
  # end
  #
  # should 'logging' do
  # end
  #
  # should 'error handler?' do
  # end
end
