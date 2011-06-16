
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

  should 'respect timeout' do
    stub_request(:get, 'https://graph.facebook.com/me').
      to_return(:body => '{}')
    mock.proxy(Timeout).timeout(numeric)
    RestGraph.new.get('me').should == {}
  end

  should 'override timeout' do
    mock(Timeout).timeout(99){ true }
    RestGraph.new(:timeout => 1).get('me', {}, :timeout => 99).should == true
  end
end
