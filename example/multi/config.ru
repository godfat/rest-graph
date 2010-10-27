
id = '4'
times = 10

require 'async-rack'
require 'rest-graph'

use Rack::ContentType
use Rack::Reloader

module RG
  module_function
  def create env
    RestGraph.new(:log_method => env['rack.logger'].method(:debug))
  end
end

run Rack::Builder.new{
  map('/async'){
    run lambda{ |env|
      RG.create(env).multi([[:get, id]] * times){ |r|
        env['async.callback'].call [200, {}, r.map(&:inspect)]
      }
      throw :async
    }
  }
  map('/sync'){
    run lambda{ |env|
      [200, {}, (0...times).map{ RG.create(env).get(id) }.map(&:inspect)]
    }
  }
  map('/'){
    run lambda{ |env|
      [200, {'Content-Type' => 'text/html'},
        [<<-HTML
<html><body>
  go to <a href="/async">/async</a> for em-http-request (multi) result,<br/>
  go to <a href="/sync">/sync</a> for rest-client result.<br/>
</body></html>
HTML
        ]]
    }
  }
}
