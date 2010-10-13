
require 'rest-graph'
require 'rr'

module RestGraph::TestUtil
  extend RR::Adapters::RRMethods

  Methods = [:gets, :deletes, :posts, :puts]

  module_function
  def setup
    any_instance_of(RestGraph){ |rg|
      stub(rg).data{default_data}

      stub(rg).fetch{ |meth, uri, payload|
        send("#{meth}s") << [uri, payload]
        RestGraph.json_encode(default_response)
      }
    }
  end
  alias_method :before, :setup

  def teardown
    RR::Injections::DoubleInjection.instances.delete(RestGraph)
    Methods.map{ |meth| send(meth) }.each(&:clear)
  end
  alias_method :after, :teardown

  def default_response
    @default_response ||= {'data' => []}
  end

  def default_data
    @default_data ||= {'uid' => 1234}
  end

  self.class.module_eval{
    attr_writer :default_response, :default_data
  }

  Methods.each{ |meth|
    instance_eval <<-RUBY
      def #{meth}
        @#{meth} ||= []
      end
    RUBY
  }
end
