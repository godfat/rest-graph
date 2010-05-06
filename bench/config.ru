
url = 'http://graph.facebook.com/spellbook'
times = 10
require 'open-uri'
require 'em-http'
require 'async-rack'

run Builder.new{
  use ContentType
  map('/async'){
    run lambda{ |env|
      multi = EM::MultiRequest.new
      times.times{
        multi.add(EM::HttpRequest.new(url).get)
      }
      multi.callback{
        env['async.callback'].call [200, {}, [
          multi.responses[:succeeded].first.response
        ]]
      }
      throw :async
    }
  }
  map('/sync'){
    run lambda{ |env|
      s = nil
      times.times{ s = open(url).read }
      [200, {}, [s]]
    }
  }
}
