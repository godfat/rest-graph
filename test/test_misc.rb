
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

  should 'return true in authorized? if there is an access_token' do
    RestGraph.new(:access_token => '1').authorized?.should == true
    RestGraph.new(:access_token => nil).authorized?.should == false
  end

  should 'treat oauth_token as access_token as well' do
    rg = RestGraph.new
    hate_facebook = 'why the hell two different name?'
    rg.data['oauth_token'] = hate_facebook
    rg.authorized?.should == true
    rg.access_token       == hate_facebook
  end

  should 'build correct headers' do
    rg = RestGraph.new(:accept => 'text/html',
                       :lang   => 'zh-tw')
    rg.send(:build_headers).should == {'Accept'          => 'text/html',
                                       'Accept-Language' => 'zh-tw'}
  end

  should 'build empty query string' do
    RestGraph.new.send(:build_query_string).should == ''
  end

  should 'create access_token in query string' do
    RestGraph.new(:access_token => 'token').send(:build_query_string).
      should == '?access_token=token'
  end

  should 'build correct query string' do
    TestHelper.normalize_query(
    RestGraph.new(:access_token => 'token').send(:build_query_string,
                                                 :message => 'hi!!')).
      should == '?access_token=token&message=hi%21%21'

    TestHelper.normalize_query(
    RestGraph.new.send(:build_query_string, :message => 'hi!!',
                                            :subject => '(&oh&)')).
      should == '?message=hi%21%21&subject=%28%26oh%26%29'
  end

  should 'auto decode json' do
    RestGraph.new(:auto_decode => true).
      send(:post_request, '[]', '', {}).should == []
  end

  should 'not auto decode json' do
    RestGraph.new(:auto_decode => false).
      send(:post_request, '[]', '', {}).should == '[]'
  end

  should 'give better inspect string' do
    RestGraph.new(:auto_decode => false).inspect.should =~ Regexp.new(
    '#<struct RestGraph auto_decode=false,'                          \
                      ' strict=false,'                               \
                      ' timeout=10,'                                 \
                      ' graph_server="https://graph.facebook.com/",' \
                      ' old_server="https://api.facebook.com/",'     \
                      ' accept="text/javascript",'                   \
                      ' lang="en-us",'                               \
                      ' app_id=nil,'                                 \
                      ' secret=nil,'                                 \
                      ' data=\{\},'                                  \
                      ' cache=nil,'                                  \
                      ' log_method=nil,'                             \
                      ' log_handler=nil,'                            \
                      ' error_handler=#<Proc:.+>>')
  end
end
