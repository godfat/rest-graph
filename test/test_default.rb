
if respond_to?(:require_relative, true)
  require_relative 'common'
else
  require File.dirname(__FILE__) + '/common'
end

describe RestGraph do
  should 'honor default attributes' do
    TestHelper.attrs_no_callback.each{ |name|
      RestGraph.new.send(name).should ==
        RestGraph.send("default_#{name}")

      RestGraph.new.send(name).should ==
        RestGraph::DefaultAttributes.send("default_#{name}")
    }
  end

  should 'use module to override default attributes' do
    module BlahAttributes
      def default_app_id
        '1829'
      end
    end

    TestHelper.ensure_rollback{
      RestGraph.send(:extend, BlahAttributes)
      RestGraph.default_app_id.should == '1829'
    }
  end
end
