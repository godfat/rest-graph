
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
gem 'em-http-request'

platforms(:ruby) do
  gem 'yajl-ruby'
end

platforms(:jruby) do
  gem 'jruby-openssl'
end

platforms(:rbx) do
  gem 'rubysl-rexml' # required by webmock required by crack
end

gem 'rails', '2.3.18' if ENV['RESTGRAPH'] == 'rails2'
gem 'rails', '3.2.15' if ENV['RESTGRAPH'] == 'rails3'
