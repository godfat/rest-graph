
require 'sinatra'
require 'rest-graph'

app_id = '123'
secret = 'abc'
config = {:app_id => app_id,
          :secret => secret}

post '/' do
  rg = RestGraph.new(config)
  rg.parse_signed_request!(params['signed_request'])
  "#{rg.get('me').inspect.gsub('<', '&lt;')}\n"
end

run Sinatra::Application
