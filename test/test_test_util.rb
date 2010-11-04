
if respond_to?(:require_relative, true)
  require_relative 'common'
else
  require File.dirname(__FILE__) + '/common'
end

require 'rest-graph/test_util'

describe RestGraph::TestUtil do
  before do
    RestGraph::TestUtil.setup
  end

  after do
    RestGraph::TestUtil.teardown
  end

  should 'stub requests and store result and teardown do cleanup' do
    RestGraph.new.get('me')        .should == {'data' => []}
    RestGraph::TestUtil.history    .should ==
      [[:get, "https://graph.facebook.com/me", nil]]

    RestGraph::TestUtil.teardown

    RestGraph::TestUtil.history.should == []
    begin
      RestGraph.new.get('me')
    rescue => e
      e.should.kind_of?(WebMock::NetConnectNotAllowedError)
    end
  end

  should 'have default response' do
    default = {'meta' => []}
    RestGraph::TestUtil.default_response = default
    RestGraph.new.get('me')     .should == default
  end

  should 'have default data' do
    rg = RestGraph.new
    rg.data['uid']           .should == '1234'
    RestGraph::TestUtil.default_data  = {'uid' => '4321'}
    rg.data['uid']           .should == '4321'
    RestGraph.new.data['uid'].should == '4321'
  end

  should 'be easy to stub data' do
    response = {'data' => 'me'}
    RestGraph::TestUtil.get('me'){ response }
    RestGraph.new.get('me').should == response
    RestGraph.new.get('he').should == RestGraph::TestUtil.default_response
  end

  should 'emulate login' do
    RestGraph::TestUtil.login(1829)
    rg = RestGraph.new
    rg.data['uid'].should == '1829'
    rg.authorized?.should == true
    rg.get('me').should == RestGraph::TestUtil.user('1829')
  end

  should 'reset before login' do
    RestGraph::TestUtil.login(1234).login(1829)
    rg = RestGraph.new
    rg.data['uid'].should == '1829'
    rg.authorized?.should == true
    rg.get('me').should == RestGraph::TestUtil.user('1829')
    RestGraph::TestUtil.login(1234)
    rg.data['uid'].should == '1234'
    rg.authorized?.should == true
    rg.get('me').should == RestGraph::TestUtil.user('1234')
  end
end
