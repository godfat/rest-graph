
require 'rest-graph/core'
require 'rr'

require 'uri'

module RestGraph::TestUtil
  extend RR::Adapters::RRMethods

  Methods = [:get, :delete, :post, :put]

  module_function
  def setup
    any_instance_of(RestGraph){ |rg|
      stub(rg).data{default_data}

      stub(rg).fetch{ |meth, uri, payload|
        history << [meth, uri, payload]
        http     = 'https?://[\w\d]+(\.[\w\d]+)+/'
        response = case uri
                     when %r{#{http}method/fql.multiquery}
                       RestGraph.json_decode(
                         Rack::Utils.parse_query(
                           URI.parse(uri).query)['queries']).keys.map{ |q|
                             {'name' => q,
                               'fql_result_set' => [default_response]}
                           }
                     when %r{#{http}method/\w+\.\w+}
                       [default_response]
                     else
                       default_response
                   end
        RestGraph.json_encode(response)
      }
    }
    self
  end
  alias_method :before, :setup

  def teardown
    history.clear
    [:default_response, :default_data].each{ |meth| send("#{meth}=", nil) }
    RR::Injections::DoubleInjection.instances[RestGraph].keys.each{ |meth|
      RR::Injections::DoubleInjection.reset_double(RestGraph, meth)
    }
    self
  end
  alias_method :after, :teardown

  def default_response
    @default_response ||= {'data' => []}
  end

  def default_data
    @default_data ||= {'uid' => '1234'}
  end

  self.class.module_eval{
    attr_writer :default_response, :default_data
  }

  def history
    @history ||= []
  end

  def login id=default_data['uid']
    teardown
    setup

             uid = id.to_s
         expires = '123456789'
          app_id = RestGraph.default_app_id || '5678'
     session_key = "2.random_string.3600.#{expires}-#{uid}"
            salt = 'random-salt'
    access_token = "#{app_id}|#{session_key}|#{salt}"

    self.default_data = {         'uid' =>          uid,
                         'access_token' => access_token,
                          'session_key' =>  session_key}

    get('me'){ user(uid) }
    self
  end

  def user id
    {         'id' => id,
            'name' => 'rest-graph stubbed-user',
      'first_name' => 'rest-graph',
       'last_name' => 'stubbed-user',
            'link' => 'http://www.facebook.com/rest-graph',
           'about' => 'this is a stubbed user in rest-graph',
        'hometown' => {'id' => id*2, 'name' => 'Taiwan'},
             'bio' => 'A super simple Facebook Open Graph API client',
          'quotes' => 'Write programs that do one thing and do it well.',
        'timezone' => 8,
          'locale' => 'en_US',
        'verified' => true,
    'updated_time' => '2010-05-07T15:04:08+0000'}
  end

  instance_eval(s = Methods.map{ |meth|
    <<-RUBY
      def #{meth} *args, &block
        any_instance_of(RestGraph){ |rg|
          stub.proxy(rg).#{meth}(*args, &block)
          stub.proxy(rg).#{meth}
        }
      end
    RUBY
  }.join("\n"))
end
