
require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'rack'     if RUBY_VERSION < '1.9.0' # autoload broken in 1.8?
require 'rest-graph'

require 'rr'
require 'webmock'
require 'bacon'

# for testing lighten (serialization)
require 'yaml'

include RR::Adapters::RRMethods
include WebMock
WebMock.disable_net_connect!
Bacon.summary_on_exit

module TestHelper
  module_function
  def ensure_rollback
    yield

  ensure # the defaults should remain the same!
    RestGraph.send(:extend, RestGraph::DefaultAttributes.dup)

    TestHelper.attrs_no_callback.each{ |name|
      RestGraph.new.send(name).should ==
        RestGraph::DefaultAttributes.send("default_#{name}")
    }
  end

  def normalize_query query
    '?' + query[1..-1].split('&').sort.join('&')
  end

  def normalize_url url
    url.sub(/\?.+/){ |query| TestHelper.normalize_query(query) }
  end

  def attrs_no_callback
    RestGraph::Attributes.reject{ |attr|
      attr.to_s =~ /_handler/
    }
  end
end
