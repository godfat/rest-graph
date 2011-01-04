
if respond_to?(:require_relative, true)
  require_relative 'common'
else
  require File.dirname(__FILE__) + '/common'
end

require 'rest-graph/facebook_util'

describe RestGraph::FacebookUtil do
  after do
    RR.verify
  end

  before do
    @res = [{'publish_stream' => 1, 'email' => 0}]
  end

  should 'fix_permission' do
    RestGraph.new.fix_permissions(@res).should == %w[publish_stream]
  end

  should 'fix_fql_multi' do
    RestGraph.new.fix_fql_multi([{'name'=>'a', 'fql_result_set'=> @res}]).
      should == {'a' => @res}
  end

  should 'permissions' do
    mock(rg = RestGraph.new).fql(
      rg.permissions_fql(1234,
      RestGraph::FacebookUtil::PERMISSIONS), {}, :secret => true
    ){ @res }

    rg.permissions(1234).should == %w[publish_stream]
  end
end
