
require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'rack'     if RUBY_VERSION < '1.9.0' # autoload broken in 1.8?
require 'rest-graph'

require 'rr'
require 'webmock'
require 'bacon'

include RR::Adapters::RRMethods
include WebMock
WebMock.disable_net_connect!
Bacon.summary_on_exit
