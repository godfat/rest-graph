
if respond_to?(:require_relative, true)
  require_relative 'common'
else
  require File.dirname(__FILE__) + '/common'
end

describe 'RestGraph#multi' do
  after do
    WebMock.reset!
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

  should 'for_pages' do
    rg = RestGraph.new

    args = [is_a(Hash), is_a(Array)]
    mock.proxy(rg).request_em(*args) # at least one time
    stub.proxy(rg).request_em(*args)

    %w[next previous].each{ |type|
      kind = "#{type}_page"
      data = {'paging' => {type => 'http://z'}, 'data' => ['z']}

      # invalid pages or just the page itself
      # not really need network
      nils = 0
      ranges = -1..1
      ranges.each{ |page|
        rg.for_pages(data, page, {:async => true}, kind){ |r|
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
        stub_request(:get, 'z').to_return(:body => '{"data":["y"]}')
        expects = [{'data' => %w[y]}, nil]

        EM.run{
          rg.for_pages(data, pages, {:async => true}, kind){ |r|
            r.should == expects.shift
            EM.stop if expects.empty?
          }
        }

        # this data cannot be merged
        stub_request(:get, 'z').to_return(:body => '{"data":"y"}')
        expects = [{'data' => 'y'}, nil]

        EM.run{
          rg.for_pages(data, pages, {:async => true}, kind){ |r|
            r.should == expects.shift
            EM.stop if expects.empty?
          }
        }
      }

      stub_request(:get, 'z').to_return(:body =>
        '{"paging":{"'+type+'":"http://yyy"},"data":["y"]}')
      stub_request(:get, 'yyy').to_return(:body => '{"data":["x"]}')
      expects = [{'data' => %w[y]}, {'data' => %w[x]}, nil]

      EM.run{
        rg.for_pages(data, 3, {:async => true}, kind){ |rr|
          rr.frozen?.should == true unless rr.nil? && RUBY_VERSION < '1.9.2'
          if rr
            r = rr.dup
            r.delete('paging')
          else
            r = rr
          end
          r.should == expects.shift
          EM.stop if expects.empty?
        }
      }
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
