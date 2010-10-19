
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

  should 'get the next/prev page' do
    rg = RestGraph.new
    %w[next previous].each{ |type|
      kind = "#{type}_page"
      rg.send(kind, {})              .should == nil
      rg.send(kind, {'paging' => []}).should == nil
      rg.send(kind, {'paging' => {}}).should == nil

      mock(rg).request(:get, 'zzz', {}){ 'ok' }
      rg.send(kind, {'paging' => {type => 'zzz'}}).should == 'ok'
    }
  end

  should 'merge all pages into one' do
    rg = RestGraph.new
    %w[next previous].each{ |type|
      kind = "#{type}_page"
      data = {'paging' => {type => 'zzz'}, 'data' => ['z']}

      # invalid pages or just the page itself
      (-1..1).each{ |page|
        rg.for_pages(data, page, kind).should == data
      }

      (2..4).each{ |pages|
        # merge data
        mock(rg).request(:get, 'zzz', {}){ {'data' => ['y']} }
        rg.for_pages(data, pages, kind).should == {'data' => %w[z y]}

        # this data cannot be merged
        mock(rg).request(:get, 'zzz', {}){ {'data' => 'y'} }
        rg.for_pages(data, pages, kind).should == {'data' => %w[z]}
      }

      mock(rg).request(:get, 'zzz', {}){ {'paging' => {type => 'yyy'},
                                          'data' => ['y']} }
      mock(rg).request(:get, 'yyy', {}){ {'data' => ['x']} }
      rg.for_pages(data, 3, kind).should == {'data' => %w[z y x]}
    }
  end
end
