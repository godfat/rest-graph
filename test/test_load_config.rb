
if respond_to?(:require_relative, true)
  require_relative 'common'
else
  require File.dirname(__FILE__) + '/common'
end

require 'rest-graph/config_util'

describe RestGraph::ConfigUtil do

  after do
    RR.verify
  end

  should 'honor rails config' do
    ::Rails = Object.new
    mock(Rails).env { 'test' }
    mock(Rails).root{ File.dirname(__FILE__) }

    check = lambda{
      RestGraph.default_app_id.should ==   41829
      RestGraph.default_secret.should == 'r41829'.reverse
      RestGraph.default_auto_decode.should == false
      RestGraph.default_lang.should        == 'zh-tw'
    }

    TestHelper.ensure_rollback{
      RestGraph::ConfigUtil.load_config_for_rails
      check.call
    }

    TestHelper.ensure_rollback{
      RestGraph::ConfigUtil.load_config(
        "#{File.dirname(__FILE__)}/config/rest-graph.yaml",
        'test')
      check.call
    }
  end
end
