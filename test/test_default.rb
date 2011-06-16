
if respond_to?(:require_relative, true)
  require_relative 'common'
else
  require File.dirname(__FILE__) + '/common'
end

describe RestGraph do
  should 'honor default attributes' do
    RestGraph.members.reject{ |name|
      name.to_s =~ /method$|handler$|detector$/ }.each{ |name|
        RestGraph.new.send(name).should ==
        RestGraph    .send("default_#{name}")
    }
  end

  should 'use module to override default attributes' do
    klass = RestGraph.dup
    klass.send(:extend, Module.new do
      def default_app_id
        '1829'
      end
    end)

    klass.new.app_id.should == '1829'
  end
end
