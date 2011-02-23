# encoding: utf-8

begin
  require 'bones'
rescue LoadError
  abort '### Please install the "bones" gem ###'
end

ensure_in_path 'lib'
proj = 'rest-graph'
require "#{proj}/version"

Bones{
  ruby_opts [''] # silence warning for now

  version RestGraph::VERSION

  depend_on 'rest-client'    , :development => true
  depend_on 'em-http-request', :development => true

  depend_on 'rack'     , :development => true

  depend_on 'yajl-ruby', :development => true
  depend_on 'json'     , :development => true
  depend_on 'json_pure', :development => true

  depend_on 'ruby-hmac', :development => true

  depend_on 'rr'       , :development => true
  depend_on 'webmock'  , :development => true
  depend_on 'bacon'    , :development => true

  name    proj
  url     "http://github.com/cardinalblue/#{proj}"
  authors ['Cardinal Blue', 'Lin Jen-Shin (aka godfat 真常)']
  email   'dev (XD) cardinalblue.com'

  history_file   'CHANGES'
   readme_file   'README.rdoc'
   ignore_file   '.gitignore'
  rdoc.include   ['\w+']
  rdoc.exclude   ['test', 'doc', 'Rakefile', 'example']
  rdoc.main      'README'
  rdoc.dir       'rdoc'
}

CLEAN.include Dir['**/*.rbc']

task :default do
  Rake.application.options.show_task_pattern = /./
  Rake.application.display_tasks_and_comments
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
