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
  # ruby_opts [''] # silence warning for now

  version RestGraph::VERSION

  depend_on 'rest-client'
  depend_on 'bacon', :development => true
  depend_on 'rr',    :development => true

  name    proj
  url     "http://github.com/godfat/#{proj}"
  authors 'Lin Jen-Shin (aka godfat 真常)'
  email   'godfat (XD) godfat.org'

  history_file   'CHANGES'
   readme_file   'README'
   ignore_file   '.gitignore'
  rdoc.include   ['\w+']
  rdoc.exclude   ['test', 'doc', 'Rakefile']
}

CLEAN.include Dir['**/*.rbc']

task :default do
  Rake.application.options.show_task_pattern = /./
  Rake.application.display_tasks_and_comments
end

task 'doc:rdoc' do
  sh 'cp -r ~/.gem/ruby/1.9.1/gems/rdoc-2.5.6/lib/rdoc/generator/template/darkfish/* doc/'
end
