
source 'http://rubygems.org'

gemspec

gem 'rest-client'
gem 'em-http-request'

gem 'rake'
gem 'bacon'
gem 'muack'
gem 'webmock'

gem 'json'
gem 'json_pure'

gem 'rack'
gem 'ruby-hmac'

platforms :ruby do
  gem 'yajl-ruby'
end

platforms :rbx do
  gem 'rubysl-fiber'      # used in rest-core
  gem 'rubysl-singleton'  # used in rake
  gem 'rubysl-rexml'      # used in crack used in webmock
  gem 'rubysl-bigdecimal' # used in crack used in webmock
  gem 'rubysl-base64'     # used in em-socksify used in em-http-request
  gem 'rubysl-test-unit'  # used in activesupport
  gem 'rubysl-enumerator' # used in activesupport
  gem 'rubysl-benchmark'  # used in activesupport
  gem 'racc'              # used in journey used in actionpack
end

platforms :jruby do
  gem 'jruby-openssl'
end

gem 'rails', '3.2.16' if ENV['RESTGRAPH'] == 'rails3'
