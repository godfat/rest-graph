
require 'rubygems' if RUBY_VERSION < '1.9.2'
require 'rack'     if RUBY_VERSION < '1.9.2' # autoload broken in 1.8?
require 'rest-graph'

# need to require this before webmock in order to enable mocking in em-http
require 'em-http-request'

require 'rr'
require 'webmock'
require 'bacon'

# for testing lighten (serialization)
require 'yaml'

include RR::Adapters::RRMethods
include WebMock::API
WebMock.disable_net_connect!
Bacon.summary_on_exit

module TestHelper
  module_function
  def ensure_rollback
    yield

  ensure # the defaults should remain the same!
    [RestCore, RestGraph].each{ |mod|
      RestGraph.send(:extend, mod.const_get(:DefaultAttributes).dup)
    }
    test_defaults
  end

  def normalize_query query
    '?' + query[1..-1].split('&').sort.join('&')
  end

  def normalize_url url
    url.sub(/\?.+/){ |query| TestHelper.normalize_query(query) }
  end

  def test_defaults
    members = RestGraph::DefaultAttributes.instance_methods.map{ |name|
      name.to_s.sub('default_', '')
    }

    members_core = RestCore::DefaultAttributes.instance_methods.map{ |name|
      name.to_s.sub('default_', '')
    } - members

    [[members_core, RestCore:: DefaultAttributes],
     [members     , RestGraph::DefaultAttributes]].

    map{ |(attrs, mod)|
      [attrs.reject{ |attr| attr.to_s =~ /_handler$/ }, mod]
    }.each{ |(names, mod)| names.each{ |name|
      RestGraph.new.send(name).should == mod.send("default_#{name}")
      yield(name, mod) if block_given?}}
  end
end
