
if respond_to?(:require_relative, true)
  require_relative 'common'
else
  require File.dirname(__FILE__) + '/common'
end

describe RestGraph do
  after do
    reset_webmock
    RR.verify
  end

  it 'could be serialized with lighten' do
    marshal = RUBY_VERSION >= '1.9' ? Marshal : nil
    [YAML, marshal].compact.each{ |engine|
      test = lambda{ |obj| engine.load(engine.dump(obj)) }
        rg = RestGraph.new(:log_handler => lambda{})
      lambda{ test[rg] }.should.raise(TypeError)
      test[rg.lighten].should == rg.lighten
      lambda{ test[rg] }.should.raise(TypeError)
      rg.lighten!
      test[rg.lighten].should == rg
    }
  end
end
