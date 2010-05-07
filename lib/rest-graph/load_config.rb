
require 'rest-graph'

class RestGraph < RestGraphStruct
  module LoadConfig
    module_function
    def load!
      load_if_rails!
    end

    def load_if_rails!
      return unless Object.const_defined?(:Rails)
      root = Rails.root
      file = ["#{root}/config/rest-graph.yaml", # YAML should use .yaml
              "#{root}/config/rest-graph.yml"].find{|path| File.exist?(path)}
      return unless file

      config   = YAML.load(ERB.new(File.read(file)).result(binding))
      defaults = config[Rails.env]
      return unless defaults

      mod = Module.new
      mod.module_eval(s=defaults.inject([]){ |r, (k, v)|
        r << <<-RUBY
               def default_#{k}
                 # quote strings, leave others free (e.g. false, numbers, etc)
                 #{v.kind_of?(String) ? "'#{v}'" : v}
               end
               RUBY
      }.join)

      RestGraph.send(:extend, mod)
    end
  end
end

RestGraph::LoadConfig.load!
