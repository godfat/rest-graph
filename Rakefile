# encoding: utf-8

require "#{dir = File.dirname(__FILE__)}/task/gemgem"
Gemgem.dir = dir

($LOAD_PATH << File.expand_path("#{Gemgem.dir}/lib" )).uniq!

desc 'Generate gemspec'
task 'gem:spec' do
  Gemgem.spec = Gemgem.create do |s|
    require 'rest-graph/version'
    s.name        = 'rest-graph'
    s.version     = RestGraph::VERSION
    s.homepage    = 'https://github.com/cardinalblue/rest-graph'
    # s.executables = [s.name]

    %w[].each{ |g| s.add_runtime_dependency(g) }
    %w[rest-client rack yajl-ruby json json_pure ruby-hmac
       webmock bacon rr rake].each{ |g| s.add_development_dependency(g) }
    s.add_development_dependency('em-http-request', '<1')

    s.authors     = ['Cardinal Blue', 'Lin Jen-Shin (godfat)']
    s.email       = ['dev (XD) cardinalblue.com']
  end

  Gemgem.write
end

module Gemgem
  module_function
  def test_rails *rails
    rails.each{ |framework|
      opts = Rake.application.options
      args = (opts.singleton_methods - [:rakelib, 'rakelib']).map{ |arg|
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
task 'test:example' => ['gem:install'] do
  Gemgem.test_rails('rails3', 'rails2')
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
  case ENV['TEST']
  when 'rails3'; Gemgem.test_rails('rails3')
  when 'rails2'; Gemgem.test_rails('rails2')
  else         ; Rake::Task['test'].invoke
  end
end
