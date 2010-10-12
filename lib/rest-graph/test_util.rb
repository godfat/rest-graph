
require 'rest-graph'
require 'rr'

module RestGraph::TestUtil
  extend RR::Adapters::RRMethods

  Methods = [:gets, :deletes, :posts, :puts]

  module_function
  def setup
    any_instance_of(RestGraph){ |rg|
      stub(rg).fetch{ |meth, uri, payload|
        send("#{meth}s") << [uri, payload]
        '{"data":"ok"}'
      }
    }
  end
  alias_method :before, :setup

  def teardown
    RR::Injections::DoubleInjection.instances.delete(RestGraph)
    Methods.map{ |meth| send(meth) }.each(&:clear)
  end
  alias_method :after, :teardown

  Methods.each{ |meth|
    instance_eval <<-RUBY
      def #{meth}
        @#{meth} ||= []
      end
    RUBY
  }
end
