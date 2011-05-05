# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rest-graph}
  s.version = "1.8.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{Cardinal Blue}, %q{Lin Jen-Shin (godfat)}]
  s.date = %q{2011-05-05}
  s.description = %q{A lightweight Facebook Graph API client}
  s.email = [%q{dev (XD) cardinalblue.com}]
  s.extra_rdoc_files = [%q{CHANGES}, %q{CONTRIBUTORS}, %q{LICENSE}, %q{TODO}]
  s.files = [%q{.gitignore}, %q{CHANGES}, %q{CONTRIBUTORS}, %q{Gemfile}, %q{LICENSE}, %q{README}, %q{README.md}, %q{Rakefile}, %q{TODO}, %q{doc/ToC.md}, %q{doc/dependency.md}, %q{doc/design.md}, %q{doc/heroku-facebook.md}, %q{doc/rails.md}, %q{doc/test.md}, %q{doc/tutorial.md}, %q{example/multi/config.ru}, %q{example/multi/rainbows.rb}, %q{example/rails2/Gemfile}, %q{example/rails2/Gemfile.lock}, %q{example/rails2/README}, %q{example/rails2/Rakefile}, %q{example/rails2/app/controllers/application_controller.rb}, %q{example/rails2/app/views/application/helper.html.erb}, %q{example/rails2/config/boot.rb}, %q{example/rails2/config/environment.rb}, %q{example/rails2/config/environments/development.rb}, %q{example/rails2/config/environments/production.rb}, %q{example/rails2/config/environments/test.rb}, %q{example/rails2/config/initializers/cookie_verification_secret.rb}, %q{example/rails2/config/initializers/new_rails_defaults.rb}, %q{example/rails2/config/initializers/session_store.rb}, %q{example/rails2/config/preinitializer.rb}, %q{example/rails2/config/rest-graph.yaml}, %q{example/rails2/config/routes.rb}, %q{example/rails2/log}, %q{example/rails2/test/functional/application_controller_test.rb}, %q{example/rails2/test/test_helper.rb}, %q{example/rails2/test/unit/rails_util_test.rb}, %q{example/rails3/Gemfile}, %q{example/rails3/Gemfile.lock}, %q{example/rails3/Rakefile}, %q{example/rails3/app/controllers/application_controller.rb}, %q{example/rails3/app/views/application/helper.html.erb}, %q{example/rails3/config.ru}, %q{example/rails3/config/application.rb}, %q{example/rails3/config/environment.rb}, %q{example/rails3/config/environments/development.rb}, %q{example/rails3/config/environments/production.rb}, %q{example/rails3/config/environments/test.rb}, %q{example/rails3/config/initializers/secret_token.rb}, %q{example/rails3/config/initializers/session_store.rb}, %q{example/rails3/config/rest-graph.yaml}, %q{example/rails3/config/routes.rb}, %q{example/rails3/test/functional/application_controller_test.rb}, %q{example/rails3/test/test_helper.rb}, %q{example/rails3/test/unit/rails_util_test.rb}, %q{example/sinatra/config.ru}, %q{init.rb}, %q{lib/rest-graph.rb}, %q{lib/rest-graph/auto_load.rb}, %q{lib/rest-graph/autoload.rb}, %q{lib/rest-graph/config_util.rb}, %q{lib/rest-graph/core.rb}, %q{lib/rest-graph/facebook_util.rb}, %q{lib/rest-graph/rails_util.rb}, %q{lib/rest-graph/test_util.rb}, %q{lib/rest-graph/version.rb}, %q{rest-graph.gemspec}, %q{task/gemgem.rb}, %q{test/common.rb}, %q{test/config/rest-graph.yaml}, %q{test/test_api.rb}, %q{test/test_cache.rb}, %q{test/test_default.rb}, %q{test/test_error.rb}, %q{test/test_facebook.rb}, %q{test/test_handler.rb}, %q{test/test_load_config.rb}, %q{test/test_misc.rb}, %q{test/test_multi.rb}, %q{test/test_oauth.rb}, %q{test/test_old.rb}, %q{test/test_page.rb}, %q{test/test_parse.rb}, %q{test/test_rest-graph.rb}, %q{test/test_serialize.rb}, %q{test/test_test_util.rb}, %q{test/test_timeout.rb}]
  s.homepage = %q{http://github.com/godfat/}
  s.rdoc_options = [%q{--main}, %q{README}]
  s.require_paths = [%q{lib}]
  s.rubygems_version = %q{1.8.0}
  s.summary = %q{A lightweight Facebook Graph API client}
  s.test_files = [%q{test/test_api.rb}, %q{test/test_cache.rb}, %q{test/test_default.rb}, %q{test/test_error.rb}, %q{test/test_facebook.rb}, %q{test/test_handler.rb}, %q{test/test_load_config.rb}, %q{test/test_misc.rb}, %q{test/test_multi.rb}, %q{test/test_oauth.rb}, %q{test/test_old.rb}, %q{test/test_page.rb}, %q{test/test_parse.rb}, %q{test/test_rest-graph.rb}, %q{test/test_serialize.rb}, %q{test/test_test_util.rb}, %q{test/test_timeout.rb}]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rest-client>, [">= 0"])
      s.add_development_dependency(%q<em-http-request>, [">= 0"])
      s.add_development_dependency(%q<rack>, [">= 0"])
      s.add_development_dependency(%q<yajl-ruby>, [">= 0"])
      s.add_development_dependency(%q<json>, [">= 0"])
      s.add_development_dependency(%q<json_pure>, [">= 0"])
      s.add_development_dependency(%q<ruby-hmac>, [">= 0"])
      s.add_development_dependency(%q<webmock>, [">= 0"])
      s.add_development_dependency(%q<bacon>, [">= 0"])
      s.add_development_dependency(%q<rr>, [">= 0"])
    else
      s.add_dependency(%q<rest-client>, [">= 0"])
      s.add_dependency(%q<em-http-request>, [">= 0"])
      s.add_dependency(%q<rack>, [">= 0"])
      s.add_dependency(%q<yajl-ruby>, [">= 0"])
      s.add_dependency(%q<json>, [">= 0"])
      s.add_dependency(%q<json_pure>, [">= 0"])
      s.add_dependency(%q<ruby-hmac>, [">= 0"])
      s.add_dependency(%q<webmock>, [">= 0"])
      s.add_dependency(%q<bacon>, [">= 0"])
      s.add_dependency(%q<rr>, [">= 0"])
    end
  else
    s.add_dependency(%q<rest-client>, [">= 0"])
    s.add_dependency(%q<em-http-request>, [">= 0"])
    s.add_dependency(%q<rack>, [">= 0"])
    s.add_dependency(%q<yajl-ruby>, [">= 0"])
    s.add_dependency(%q<json>, [">= 0"])
    s.add_dependency(%q<json_pure>, [">= 0"])
    s.add_dependency(%q<ruby-hmac>, [">= 0"])
    s.add_dependency(%q<webmock>, [">= 0"])
    s.add_dependency(%q<bacon>, [">= 0"])
    s.add_dependency(%q<rr>, [">= 0"])
  end
end
