
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

  describe 'log handler' do
    should 'log whenever doing network request' do
      stub_request(:get, 'https://graph.facebook.com/me').
        to_return(:body => '{}')

      mock(Time).now{ 666 }
      mock(Time).now{ 999 }

      logger = []
      rg = RestGraph.new(:log_handler => lambda{ |e|
                                           logger << [e.duration, e.url] })
      rg.get('me')

      logger.last.should == [333, 'https://graph.facebook.com/me']
    end
  end

  describe 'with Graph API' do
    before do
      @id    = lambda{ |obj, url| obj }
      @error = '{"error":{"type":"Exception","message":"(#2500)"}}'
      @error_hash = RestGraph.json_decode(@error)

      stub_request(:get, 'https://graph.facebook.com/me').
        to_return(:body => @error)
    end

    should 'call error_handler if error occurred' do
      RestGraph.new(:error_handler => @id).get('me').should == @error_hash
    end

    should 'raise ::RestGraph::Error in default error_handler' do
      begin
        RestGraph.new.get('me')
      rescue ::RestGraph::Error => e
        e.error  .should == @error_hash
        e.message.should ==
          "#{@error_hash.inspect} from https://graph.facebook.com/me"
      end
    end
  end

  describe 'with FQL API' do
    # Example of an actual response (without newline)
    # {"error_code":603,"error_msg":"Unknown table: bad_table",
    #  "request_args":[{"key":"method","value":"fql.query"},
    #                  {"key":"format","value":"json"},
    #                  {"key":"query","value":
    #                     "SELECT name FROM bad_table WHERE uid=12345"}]}
    before do
      @id             = lambda{ |obj, url| obj }
      @fql_error      = '{"error_code":603,"error_msg":"Unknown table: bad"}'
      @fql_error_hash = RestGraph.json_decode(@fql_error)

      @bad_fql_query  = 'SELECT name FROM bad_table WHERE uid="12345"'
      bad_fql_request = "https://api.facebook.com/method/fql.query?" \
                        "format=json&query=#{CGI.escape(@bad_fql_query)}"

      stub_request(:get, bad_fql_request).to_return(:body => @fql_error)
    end

    should 'call error_handler if error occurred' do
      RestGraph.new(:error_handler => @id).fql(@bad_fql_query).
        should == @fql_error_hash
    end

    should 'raise ::RestGraph::Error in default error_handler' do
      begin
        RestGraph.new.fql(@bad_fql_query)
      rescue ::RestGraph::Error => e
        e.error  .should == @fql_error_hash
        e.message.should.start_with?(
          "#{@fql_error_hash.inspect} from "          \
          "https://api.facebook.com/method/fql.query?")
      end
    end
  end
end
