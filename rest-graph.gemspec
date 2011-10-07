# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "rest-graph"
  s.version = "1.9.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = [
  "Cardinal Blue",
  "Lin Jen-Shin (godfat)"]
  s.date = "2011-10-07"
  s.description = "A lightweight Facebook Graph API client\n\nWe have moved the development from rest-graph to [rest-core][].\nBy now on, we would only fix bugs in rest-graph rather than adding\nfeatures, and we would only backport important changes from rest-core\nonce in a period. If you want the latest goodies, please see [rest-core][]\nOtherwise, you can stay with rest-graph with bugs fixes.\n\n[rest-core]: https://github.com/cardinalblue/rest-core"
  s.email = ["dev (XD) cardinalblue.com"]
  s.files = [
  ".gitignore",
  ".gitmodules",
  ".travis.yml",
  "CHANGES.md",
  "CONTRIBUTORS",
  "Gemfile",
  "LICENSE",
  "README.md",
  "Rakefile",
  "TODO.md",
  "doc/ToC.md",
  "doc/dependency.md",
  "doc/design.md",
  "doc/heroku-facebook.md",
  "doc/rails.md",
  "doc/test.md",
  "doc/tutorial.md",
  "example/multi/config.ru",
  "example/multi/rainbows.rb",
  "example/rails2/Gemfile",
  "example/rails2/README",
  "example/rails2/Rakefile",
  "example/rails2/app/controllers/application_controller.rb",
  "example/rails2/app/views/application/helper.html.erb",
  "example/rails2/config/boot.rb",
  "example/rails2/config/environment.rb",
  "example/rails2/config/environments/development.rb",
  "example/rails2/config/environments/production.rb",
  "example/rails2/config/environments/test.rb",
  "example/rails2/config/initializers/cookie_verification_secret.rb",
  "example/rails2/config/initializers/new_rails_defaults.rb",
  "example/rails2/config/initializers/session_store.rb",
  "example/rails2/config/preinitializer.rb",
  "example/rails2/config/rest-graph.yaml",
  "example/rails2/config/routes.rb",
  "example/rails2/log",
  "example/rails2/test/functional/application_controller_test.rb",
  "example/rails2/test/test_helper.rb",
  "example/rails2/test/unit/rails_util_test.rb",
  "example/rails3/Gemfile",
  "example/rails3/Rakefile",
  "example/rails3/app/controllers/application_controller.rb",
  "example/rails3/app/views/application/helper.html.erb",
  "example/rails3/config.ru",
  "example/rails3/config/application.rb",
  "example/rails3/config/boot.rb",
  "example/rails3/config/environment.rb",
  "example/rails3/config/environments/development.rb",
  "example/rails3/config/environments/production.rb",
  "example/rails3/config/environments/test.rb",
  "example/rails3/config/initializers/secret_token.rb",
  "example/rails3/config/initializers/session_store.rb",
  "example/rails3/config/rest-graph.yaml",
  "example/rails3/config/routes.rb",
  "example/rails3/test/functional/application_controller_test.rb",
  "example/rails3/test/test_helper.rb",
  "example/rails3/test/unit/rails_util_test.rb",
  "example/sinatra/config.ru",
  "init.rb",
  "lib/rest-graph.rb",
  "lib/rest-graph/config_util.rb",
  "lib/rest-graph/core.rb",
  "lib/rest-graph/facebook_util.rb",
  "lib/rest-graph/rails_util.rb",
  "lib/rest-graph/test_util.rb",
  "lib/rest-graph/version.rb",
  "rest-graph.gemspec",
  "task/.gitignore",
  "task/gemgem.rb",
  "test/common.rb",
  "test/config/rest-graph.yaml",
  "test/test_api.rb",
  "test/test_cache.rb",
  "test/test_default.rb",
  "test/test_error.rb",
  "test/test_facebook.rb",
  "test/test_handler.rb",
  "test/test_load_config.rb",
  "test/test_misc.rb",
  "test/test_multi.rb",
  "test/test_oauth.rb",
  "test/test_old.rb",
  "test/test_page.rb",
  "test/test_parse.rb",
  "test/test_rest-graph.rb",
  "test/test_serialize.rb",
  "test/test_test_util.rb",
  "test/test_timeout.rb"]
  s.homepage = "https://github.com/cardinalblue/rest-graph"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.11"
  s.summary = "A lightweight Facebook Graph API client"
  s.test_files = [
  "test/test_api.rb",
  "test/test_cache.rb",
  "test/test_default.rb",
  "test/test_error.rb",
  "test/test_facebook.rb",
  "test/test_handler.rb",
  "test/test_load_config.rb",
  "test/test_misc.rb",
  "test/test_multi.rb",
  "test/test_oauth.rb",
  "test/test_old.rb",
  "test/test_page.rb",
  "test/test_parse.rb",
  "test/test_rest-graph.rb",
  "test/test_serialize.rb",
  "test/test_test_util.rb",
  "test/test_timeout.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
