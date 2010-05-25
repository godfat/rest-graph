
if respond_to?(:require_relative, true)
  require_relative 'common'
else
  require File.dirname(__FILE__) + '/common'
end

require 'json'

describe RestGraph do
  before do
    @id    = lambda{ |obj| obj }
    @error = '{"error":{"type":"Exception","message":"(#2500)"}}'
    @error_hash = JSON.parse(@error)

    reset_webmock
    stub_request(:get, 'https://graph.facebook.com/me').
      to_return(:body => @error)
  end

  it 'would call error_callback if error occurred' do
    RestGraph.new(:error_callback => @id).get('me').should == @error_hash
  end

  it 'would raise ::RestGraph::Error in default error_callback' do
    begin
      RestGraph.new.get('me')
    rescue ::RestGraph::Error => e
      e.message.should == @error_hash
    end
  end
end
