
begin
  require "#{dir = File.dirname(__FILE__)}/task/gemgem"
rescue LoadError
  sh 'git submodule update --init'
  exec Gem.ruby, '-S', $PROGRAM_NAME, *ARGV
end

Gemgem.init(dir) do |s|
  require 'rest-graph/version'
  s.name     = 'rest-graph'
  s.version  = RestGraph::VERSION
  s.homepage = 'https://github.com/godfat/rest-graph'

  %w[].each{ |g| s.add_runtime_dependency(g) }
  %w[].each{ |g| s.add_development_dependency(g) }

  s.authors  = ['Cardinal Blue', 'Lin Jen-Shin (godfat)']
end

module Gemgem
  module_function
  def test_rails *rails
    rails.each{ |framework|
      opts = Rake.application.options
      args = (opts.singleton_methods - [:rakelib, :trace_output]).map{ |arg|
               if arg.to_s !~ /=$/ && opts.send(arg)
                 "--#{arg}"
               else
                 ''
               end
             }.join(' ')
      Rake.sh "cd example/#{framework}; #{Gem.ruby} -S rake test #{args}"
    }
  end
end

desc 'Run example tests'
task 'test:example' do
  Gemgem.test_rails('rails3')
end

desc 'Run all tests'
task 'test:all' => ['test', 'test:example']

desc 'Run different json test'
task 'test:json' do
  %w[yajl json].each{ |json|
    Rake.sh "#{Gem.ruby} -S rake -r #{json} test"
  }
end

task 'test:travis' do
  case ENV['RESTGRAPH']
  when 'rails3'; Gemgem.test_rails('rails3')
  else         ; Rake::Task['test'].invoke
  end
end
