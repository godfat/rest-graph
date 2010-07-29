
id = 'spellbook'
times = 10
require 'open-uri'

require 'em-http-request'
require 'async-rack'

require 'rest-graph'

use ContentType
use Reloader

run Builder.new{
  map('/async'){
    run lambda{ |env|
      RestGraph.new.multi(*([[:get, id]]*times)){ |r|
        env['async.callback'].call [200, {}, r.map(&:inspect)]
      }
      throw :async
    }
  }
  map('/sync'){
    run lambda{ |env|
      [200, {}, (0...times).map{ RestGraph.new.get(id) }.map(&:inspect)]
    }
  }
}
