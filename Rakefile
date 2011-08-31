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

desc 'Run example tests'
task 'test:example' => ['gem:install'] do
  %w[rails3 rails2].each{ |framework|
    opts = Rake.application.options
    args = (opts.singleton_methods - [:rakelib, 'rakelib']).map{ |arg|
             if arg.to_s !~ /=$/ && opts.send(arg)
               "--#{arg}"
             else
               ''
             end
           }.join(' ')
    sh "cd example/#{framework}; #{Gem.ruby} -S rake test #{args}"
  }
end

desc 'Run all tests'
task 'test:all' => ['test', 'test:example']

desc 'Run different json test'
task 'test:json' do
  %w[yajl json].each{ |json|
    sh "#{Gem.ruby} -S rake -r #{json} test"
  }
end

task 'test:travis:prepare' do
  sh 'cd example/rails2; env BUNDLE_GEMFILE=Gemfile bundle install'
  sh 'cd example/rails3; env BUNDLE_GEMFILE=Gemfile bundle install'
end

task 'test:travis' => ['test:travis:prepare', 'test:all']
