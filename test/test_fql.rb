
if respond_to?(:require_relative, true)
  require_relative 'common'
else
  require File.dirname(__FILE__) + '/common'
end

describe RestGraph do
  before do
    reset_webmock
  end

  after do
    RR.verify
  end

  it 'would do fql query with/without access_token' do
    fql = 'SELECT name FROM likes where id="123"'
    query = "format=json&query=#{CGI.escape(fql)}"
    stub_request(:get, "https://api.facebook.com/method/fql.query?#{query}").
      to_return(:body => '[]')

    RestGraph.new.fql(fql).should == []

    token = 'token'.reverse
    stub_request(:get, "https://api.facebook.com/method/fql.query?#{query}" \
      "&access_token=#{token}").
      to_return(:body => '[]')

    RestGraph.new(:access_token => token).fql(fql).should == []
  end

  it 'would do fql.mutilquery correctly' do
    f0 = 'SELECT display_name FROM application WHERE app_id="233082465238"'
    f1 = 'SELECT display_name FROM application WHERE app_id="110225210740"'
    f0q, f1q = "\"#{f0.gsub('"', '\\"')}\"", "\"#{f1.gsub('"', '\\"')}\""
    q = "format=json&queries=#{CGI.escape("{\"f0\":#{f0q},\"f1\":#{f1q}}")}"

    stub_multi = lambda{
      stub_request(:get,
        "https://api.facebook.com/method/fql.multiquery?#{q}").
        to_return(:body => '[]')
    }

    stub_multi.call

    queries = {:f0 => f0, :f1 => f1}
    RestGraph.new.fql_multi(queries).should == []

    # FIXME: didn't work
    # mock(queries).respond_to?(:json){ false }
    # mock.proxy(queries).inject
    def queries.respond_to? msg
      msg == :to_json ? false : super(msg)
    end

    stub_multi.call
    RestGraph.new.fql_multi(queries).should == []
  end

  it 'would do facebook old rest api' do
    body = 'hate facebook inconsistent'
    stub_request(:get,
      'https://api.facebook.com/method/notes.create?format=json').
      to_return(:body => body)

    RestGraph.new.old_rest('notes.create', {}, :suppress_decode => true).
      should == body
  end
end
