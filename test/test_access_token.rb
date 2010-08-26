
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

  it 'would return true in authorized? if there is an access_token' do
    RestGraph.new(:access_token => '1').authorized?.should == true
    RestGraph.new(:access_token => nil).authorized?.should == false
  end

  it 'would treat oauth_token as access_token as well' do
    rg = RestGraph.new
    hate_facebook = 'why the hell two different name?'
    rg.data['oauth_token'] = hate_facebook
    rg.authorized?.should == true
    rg.access_token       == hate_facebook
  end
end
