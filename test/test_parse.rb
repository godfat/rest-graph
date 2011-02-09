
if respond_to?(:require_relative, true)
  require_relative 'common'
else
  require File.dirname(__FILE__) + '/common'
end

describe RestGraph do

  should 'return nil if parse error, but not when call data directly' do
    rg = RestGraph.new
    rg.parse_cookies!({}).should == nil
    rg.data              .should == {}
  end

  should 'extract correct access_token or fail checking sig' do
    access_token = '1|2-5|f.'
    app_id       = '1829'
    secret       = app_id.reverse
    sig          = '398262caea8442bd8801e8fba7c55c8a'
    fbs          = "access_token=#{CGI.escape(access_token)}&expires=0&" \
                   "secret=abc&session_key=def-456&sig=#{sig}&uid=3"

    check = lambda{ |token, fbs|
      http_cookie =
        "__utma=123; __utmz=456.utmcsr=(d)|utmccn=(d)|utmcmd=(n); " \
        "fbs_#{app_id}=#{fbs}"

      rg  = RestGraph.new(:app_id => app_id, :secret => secret)
      rg.parse_rack_env!('HTTP_COOKIE' => http_cookie).
                      should.kind_of?(token ? Hash : NilClass)
      rg.access_token.should ==  token

      rg.parse_rack_env!('HTTP_COOKIE' => nil).should == nil
      rg.data.should == {}

      rg.parse_cookies!({"fbs_#{app_id}" => fbs}).
                      should.kind_of?(token ? Hash : NilClass)
      rg.access_token.should ==  token

      rg.parse_fbs!(fbs).
                      should.kind_of?(token ? Hash : NilClass)
      rg.access_token.should ==  token
    }
    check.call(access_token, fbs)
    check.call(access_token, "\"#{fbs}\"")
    fbs << '&inject=evil"'
    check.call(nil, fbs)
    check.call(nil, "\"#{fbs}\"")
  end

  should 'not pass if there is no secret, prevent from forgery' do
    rg = RestGraph.new
    rg.parse_fbs!('"feed=me&sig=bddd192cf27f22c05f61c8bea24fa4b7"').
      should == nil
  end

  should 'parse json correctly' do
    rg = RestGraph.new

    rg.parse_json!('bad json')    .should == nil
    rg.parse_json!('{"no":"sig"}').should == nil
    rg.parse_json!('{"feed":"me","sig":"bddd192cf27f22c05f61c8bea24fa4b7"}').
      should == nil

    rg = RestGraph.new(:secret => 'bread')
    rg.parse_json!('{"feed":"me","sig":"20393e7823730308938a86ecf1c88b14"}').
      should == {'feed' => 'me', 'sig' => "20393e7823730308938a86ecf1c88b14"}
    rg.data.empty?.should == false
    rg.parse_json!('bad json')
    rg.data.empty?.should == true
  end

  should 'parse signed_request' do
    secret = 'aloha'
    json   = RestGraph.json_encode('ooh' => 'dir', 'moo' => 'bar')
    encode = lambda{ |str|
      [str].pack('m').tr("\n=", '').tr('+/', '-_')
    }
    json_encoded = encode[json]
    sig = OpenSSL::HMAC.digest('sha256', secret, json_encoded)
    signed_request = "#{encode[sig]}.#{json_encoded}"

    rg = RestGraph.new(:secret => secret)
    rg.parse_signed_request!(signed_request)
    rg.data['ooh'].should == 'dir'
    rg.data['moo'].should == 'bar'

    signed_request = "#{encode[sig[0..-4]+'bad']}.#{json_encoded}"
    rg.parse_signed_request!(signed_request).should == nil
    rg.data                                 .should == {}
  end

  should 'fallback to ruby-hmac if Digest.new raise an runtime error' do
    key, data = 'top', 'secret'
    digest = OpenSSL::HMAC.digest('sha256', key, data)
    mock(OpenSSL::HMAC).digest('sha256', key, data){ raise 'boom' }
    RestGraph.hmac_sha256(key, data).should == digest
  end

  should 'generate correct fbs with correct sig' do
    RestGraph.new(:access_token => 'fake', :secret => 's').fbs.should ==
      "access_token=fake&sig=#{Digest::MD5.hexdigest('access_token=fakes')}"
  end

  should 'parse fbs from facebook response which lacks sig...' do
    rg = RestGraph.new(:access_token => 'a', :secret => 'z')
    rg.parse_fbs!(rg.fbs)                           .should.kind_of?(Hash)
    rg.data.empty?.should == false
    rg.parse_fbs!(rg.fbs.sub(/sig\=\w+/, 'sig=abc')).should == nil
    rg.data.empty?.should == true
  end

  should 'generate correct fbs with additional parameters' do
    rg = RestGraph.new(:access_token => 'a', :secret => 'z')
    rg.data['expires'] = '1234'
    rg.parse_fbs!(rg.fbs)                           .should.kind_of?(Hash)
    rg.data['access_token']                         .should == 'a'
    rg.data['expires']                              .should == '1234'
  end

end
