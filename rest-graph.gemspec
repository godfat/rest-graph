# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rest-graph}
  s.version = "1.8.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Cardinal Blue", "Lin Jen-Shin (godfat)"]
  s.date = %q{2011-03-08}
  s.description = %q{A lightweight Facebook Graph API client}
  s.email = ["dev (XD) cardinalblue.com"]
  s.extra_rdoc_files = ["CHANGES", "CONTRIBUTORS", "LICENSE", "TODO"]
  s.files = [".gitignore", "CHANGES", "CONTRIBUTORS", "Gemfile", "LICENSE", "README", "README.md", "Rakefile", "TODO", "doc/ToC.md", "doc/dependency.md", "doc/design.md", "doc/rails.md", "doc/test.md", "doc/tutorial.md", "example/multi/config.ru", "example/multi/rainbows.rb", "example/rails2/Gemfile", "example/rails2/Gemfile.lock", "example/rails2/README", "example/rails2/Rakefile", "example/rails2/app/controllers/application_controller.rb", "example/rails2/app/views/application/helper.html.erb", "example/rails2/config/boot.rb", "example/rails2/config/environment.rb", "example/rails2/config/environments/development.rb", "example/rails2/config/environments/production.rb", "example/rails2/config/environments/test.rb", "example/rails2/config/initializers/cookie_verification_secret.rb", "example/rails2/config/initializers/new_rails_defaults.rb", "example/rails2/config/initializers/session_store.rb", "example/rails2/config/preinitializer.rb", "example/rails2/config/rest-graph.yaml", "example/rails2/config/routes.rb", "example/rails2/log", "example/rails2/test/functional/application_controller_test.rb", "example/rails2/test/test_helper.rb", "example/rails2/test/unit/rails_util_test.rb", "example/rails3/Gemfile", "example/rails3/Gemfile.lock", "example/rails3/Rakefile", "example/rails3/app/controllers/application_controller.rb", "example/rails3/app/views/application/helper.html.erb", "example/rails3/config.ru", "example/rails3/config/application.rb", "example/rails3/config/environment.rb", "example/rails3/config/environments/development.rb", "example/rails3/config/environments/production.rb", "example/rails3/config/environments/test.rb", "example/rails3/config/initializers/secret_token.rb", "example/rails3/config/initializers/session_store.rb", "example/rails3/config/rest-graph.yaml", "example/rails3/config/routes.rb", "example/rails3/test/functional/application_controller_test.rb", "example/rails3/test/test_helper.rb", "example/rails3/test/unit/rails_util_test.rb", "init.rb", "lib/rest-graph.rb", "lib/rest-graph/auto_load.rb", "lib/rest-graph/autoload.rb", "lib/rest-graph/config_util.rb", "lib/rest-graph/core.rb", "lib/rest-graph/facebook_util.rb", "lib/rest-graph/rails_util.rb", "lib/rest-graph/test_util.rb", "lib/rest-graph/version.rb", "rest-graph.gemspec", "task/gemgem.rb", "test/common.rb", "test/config/rest-graph.yaml", "test/test_api.rb", "test/test_cache.rb", "test/test_default.rb", "test/test_error.rb", "test/test_facebook.rb", "test/test_handler.rb", "test/test_load_config.rb", "test/test_misc.rb", "test/test_multi.rb", "test/test_oauth.rb", "test/test_old.rb", "test/test_page.rb", "test/test_parse.rb", "test/test_rest-graph.rb", "test/test_serialize.rb", "test/test_test_util.rb", "test/test_timeout.rb"]
  s.homepage = %q{http://github.com/godfat/}
  s.rdoc_options = ["--main", "README"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.1}
  s.summary = %q{A lightweight Facebook Graph API client}
  s.test_files = ["test/test_api.rb", "test/test_cache.rb", "test/test_default.rb", "test/test_error.rb", "test/test_facebook.rb", "test/test_handler.rb", "test/test_load_config.rb", "test/test_misc.rb", "test/test_multi.rb", "test/test_oauth.rb", "test/test_old.rb", "test/test_page.rb", "test/test_parse.rb", "test/test_rest-graph.rb", "test/test_serialize.rb", "test/test_test_util.rb", "test/test_timeout.rb"]

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
