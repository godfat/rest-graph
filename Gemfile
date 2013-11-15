
source 'http://rubygems.org'

gemspec

gem 'rake'
gem 'bacon'
gem 'muack'
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
  gem 'rubysl-test-unit'  # required by activesupport
  gem 'rubysl-enumerator' # required by activesupport
  gem 'rubysl-rexml'      # required by webmock required by crack
  gem 'racc'              # required by journey required by actionpack
end

gem 'rails', '3.2.15' if ENV['RESTGRAPH'] == 'rails3'
