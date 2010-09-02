
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

  it 'would get the next/prev page' do
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
end
