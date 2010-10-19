
id = 'spellbook'
times = 10
require 'open-uri'

require 'em-http-request'
require 'async-rack'

require 'rest-graph'

use Rack::ContentType
use Rack::Reloader

module RG
  module_function
  def create env
    RestGraph.new(:log_handler =>
      RG.method(:log).to_proc.curry[env['rack.logger']])
  end

  def log logger, event
    message = "DEBUG: RestGraph: spent #{sprintf('%f', event.duration)} "
    case event
      when RestGraph::Event::Requested
        logger.debug(message + "requesting #{event.url}")

      when RestGraph::Event::CacheHit
        logger.debug(message + "cache hit' #{event.url}")
    end
  end
end

run Rack::Builder.new{
  map('/async'){
    run lambda{ |env|
      RG.create(env).multi(*([[:get, id]]*times)){ |r|
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
}
