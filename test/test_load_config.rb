
if respond_to?(:require_relative, true)
  require_relative 'common'
else
  require File.dirname(__FILE__) + '/common'
end

require 'rest-graph/load_config'

describe RestGraph::LoadConfig do
  it 'would honor rails config' do
    ::Rails = Object.new
    mock(Rails).env { 'test' }
    mock(Rails).root{ File.dirname(__FILE__) }

    begin
      RestGraph::LoadConfig.load_if_rails!
      RestGraph.default_app_id.should ==   41829
      RestGraph.default_secret.should == 'r41829'.reverse
      RestGraph.default_auto_decode   == false
      RestGraph.default_lang          == 'zh-tw'
    ensure
      RestGraph.send(:extend, RestGraph::DefaultAttributes.dup)
    end
  end
end
