
require 'erb'
require 'yaml'

require 'rest-graph'
require 'rest-graph/rails_util' if Object.const_defined?(:Rails)

module RestGraph::LoadConfig
  module_function
  def autoload
    RestGraph::LoadConfig.load_if_rails
  end

  def load_if_rails
    return unless Object.const_defined?(:Rails)
    root = Rails.root
    file = ["#{root}/config/rest-graph.yaml", # YAML should use .yaml
            "#{root}/config/rest-graph.yml"].find{|path| File.exist?(path)}
    return unless file

    RestGraph::LoadConfig.load_config(file, Rails.env)
  end

  def load_config file, env
    config   = YAML.load(ERB.new(File.read(file)).result(binding))
    defaults = config[env]
    return unless defaults

    mod = Module.new
    mod.module_eval(defaults.inject([]){ |r, (k, v)|
      # quote strings, leave others free (e.g. false, numbers, etc)
      r << <<-RUBY
        def default_#{k}
          #{v.kind_of?(String) ? "'#{v}'" : v}
        end
      RUBY
    }.join)

    RestGraph.send(:extend, mod)
  end
end
