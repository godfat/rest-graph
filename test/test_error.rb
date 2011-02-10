
if respond_to?(:require_relative, true)
  require_relative 'common'
else
  require File.dirname(__FILE__) + '/common'
end

describe RestGraph::Error do
  after do
    WebMock.reset!
    RR.verify
  end

  should 'have the right ancestors' do
    RestGraph::Error::AccessToken       .should < RestGraph::Error

    RestGraph::Error::InvalidAccessToken.should <
      RestGraph::Error::AccessToken

    RestGraph::Error::MissingAccessToken.should <
      RestGraph::Error::AccessToken
  end

  should 'parse right' do
    %w[OAuthInvalidTokenException OAuthException].each{ |type|
      RestGraph::Error.parse('error' => {'type' => type}).
        should.kind_of?(RestGraph::Error::InvalidAccessToken)
    }

    RestGraph::Error.parse('error' => {'type' => 'QueryParseException',
                                    'message' => 'An active access token..'}).
      should.kind_of?(RestGraph::Error::MissingAccessToken)

    RestGraph::Error.parse('error' => {'type' => 'QueryParseException',
                                    'message' => 'Oh active access token..'}).
      should.not.kind_of?(RestGraph::Error::MissingAccessToken)

    RestGraph::Error.parse('error_code' => 190).
      should.kind_of?(RestGraph::Error::InvalidAccessToken)

    RestGraph::Error.parse('error_code' => 104).
      should.kind_of?(RestGraph::Error::MissingAccessToken)

    RestGraph::Error.parse('error_code' => 999).
      should.not.kind_of?(RestGraph::Error::AccessToken)

    error = RestGraph::Error.parse(['not a hash'])
    error.should.not.kind_of?(RestGraph::Error::AccessToken)
    error.should    .kind_of?(RestGraph::Error)
  end

  should 'nuke cache upon errors' do
    stub_request(:get, 'https://graph.facebook.com/me').
      to_return(:body => '{"error":"wrong"}').times(2)

    rg = RestGraph.new(:cache => {}, :error_handler => lambda{|e,u|})
    rg.get('me'); rg.get('me')
    rg.cache.values.should == [nil]
  end
end
