
require 'erb'
require 'yaml'

require 'rest-graph'

class RestGraph < RestGraphStruct
  module LoadConfig
    module_function
    def auto_load!
      LoadConfig.load_if_rails!
    end

    def load_if_rails!
      return unless Object.const_defined?(:Rails)
      root = Rails.root
      file = ["#{root}/config/rest-graph.yaml", # YAML should use .yaml
              "#{root}/config/rest-graph.yml"].find{|path| File.exist?(path)}
      return unless file

      LoadConfig.load_config!(file, Rails.env)
    end

    def load_config! file, env
      config   = YAML.load(ERB.new(File.read(file)).result(binding))
      defaults = config[env]
      return unless defaults

      mod = Module.new
      mod.module_eval(defaults.inject([]){ |r, (k, v)|
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

RestGraph::LoadConfig.auto_load!
