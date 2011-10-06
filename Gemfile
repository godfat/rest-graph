
source 'http://rubygems.org'

gemspec

gem 'rake'
gem 'bacon'
gem 'rr'
gem 'webmock'

gem 'json'
gem 'json_pure'

gem 'rack'
gem 'ruby-hmac'

gem 'rest-client'
gem 'em-http-request', '<1'

platforms(:ruby) do
  gem 'yajl-ruby'
end

platforms(:jruby) do
  gem 'jruby-openssl'
end

gem 'rails', '2.3.14' if ENV['RESTGRAPH'] == 'rails2'
gem 'rails', '3.0.9'  if ENV['RESTGRAPH'] == 'rails3'
