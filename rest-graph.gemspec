# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rest-graph}
  s.version = "1.6.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Cardinal Blue", "Lin Jen-Shin (aka godfat 真常)"]
  s.date = %q{2010-12-22}
  s.description = %q{A super simple Facebook Open Graph API client}
  s.email = %q{dev (XD) cardinalblue.com}
  s.extra_rdoc_files = ["CHANGES", "CONTRIBUTORS", "Gemfile", "Gemfile.lock", "LICENSE", "README", "TODO", "rest-graph.gemspec"]
  s.files = ["CHANGES", "CONTRIBUTORS", "Gemfile", "Gemfile.lock", "LICENSE", "README", "README.rdoc", "Rakefile", "TODO", "example/multi/config.ru", "example/multi/rainbows.rb", "example/rails2/README", "example/rails2/Rakefile", "example/rails2/app/controllers/application_controller.rb", "example/rails2/config/boot.rb", "example/rails2/config/environment.rb", "example/rails2/config/environments/development.rb", "example/rails2/config/environments/production.rb", "example/rails2/config/environments/test.rb", "example/rails2/config/initializers/cookie_verification_secret.rb", "example/rails2/config/initializers/new_rails_defaults.rb", "example/rails2/config/initializers/session_store.rb", "example/rails2/config/rest-graph.yaml", "example/rails2/config/routes.rb", "example/rails2/log", "example/rails2/script/console", "example/rails2/script/server", "example/rails2/test/functional/application_controller_test.rb", "example/rails2/test/test_helper.rb", "example/rails2/test/unit/rails_util_test.rb", "init.rb", "lib/rest-graph.rb", "lib/rest-graph/auto_load.rb", "lib/rest-graph/load_config.rb", "lib/rest-graph/rails_util.rb", "lib/rest-graph/test_util.rb", "lib/rest-graph/version.rb", "rest-graph.gemspec", "test/common.rb", "test/config/rest-graph.yaml", "test/test_api.rb", "test/test_cache.rb", "test/test_default.rb", "test/test_error.rb", "test/test_handler.rb", "test/test_load_config.rb", "test/test_misc.rb", "test/test_multi.rb", "test/test_oauth.rb", "test/test_old.rb", "test/test_page.rb", "test/test_parse.rb", "test/test_rest-graph.rb", "test/test_serialize.rb", "test/test_test_util.rb", "test/test_timeout.rb"]
  s.homepage = %q{http://github.com/cardinalblue/rest-graph}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{rest-graph}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{A super simple Facebook Open Graph API client}
  s.test_files = ["test/test_api.rb", "test/test_cache.rb", "test/test_default.rb", "test/test_error.rb", "test/test_handler.rb", "test/test_load_config.rb", "test/test_misc.rb", "test/test_multi.rb", "test/test_oauth.rb", "test/test_old.rb", "test/test_page.rb", "test/test_parse.rb", "test/test_rest-graph.rb", "test/test_serialize.rb", "test/test_test_util.rb", "test/test_timeout.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rest-client>, [">= 1.6.1"])
      s.add_development_dependency(%q<em-http-request>, [">= 0.2.15"])
      s.add_development_dependency(%q<rack>, [">= 1.2.1"])
      s.add_development_dependency(%q<yajl-ruby>, [">= 0.7.8"])
      s.add_development_dependency(%q<json>, [">= 1.4.6"])
      s.add_development_dependency(%q<json_pure>, [">= 1.4.6"])
      s.add_development_dependency(%q<ruby-hmac>, [">= 0.4.0"])
      s.add_development_dependency(%q<rr>, [">= 1.0.2"])
      s.add_development_dependency(%q<webmock>, [">= 1.6.1"])
      s.add_development_dependency(%q<bacon>, [">= 1.1.0"])
      s.add_development_dependency(%q<bones>, [">= 3.5.4"])
    else
      s.add_dependency(%q<rest-client>, [">= 1.6.1"])
      s.add_dependency(%q<em-http-request>, [">= 0.2.15"])
      s.add_dependency(%q<rack>, [">= 1.2.1"])
      s.add_dependency(%q<yajl-ruby>, [">= 0.7.8"])
      s.add_dependency(%q<json>, [">= 1.4.6"])
      s.add_dependency(%q<json_pure>, [">= 1.4.6"])
      s.add_dependency(%q<ruby-hmac>, [">= 0.4.0"])
      s.add_dependency(%q<rr>, [">= 1.0.2"])
      s.add_dependency(%q<webmock>, [">= 1.6.1"])
      s.add_dependency(%q<bacon>, [">= 1.1.0"])
      s.add_dependency(%q<bones>, [">= 3.5.4"])
    end
  else
    s.add_dependency(%q<rest-client>, [">= 1.6.1"])
    s.add_dependency(%q<em-http-request>, [">= 0.2.15"])
    s.add_dependency(%q<rack>, [">= 1.2.1"])
    s.add_dependency(%q<yajl-ruby>, [">= 0.7.8"])
    s.add_dependency(%q<json>, [">= 1.4.6"])
    s.add_dependency(%q<json_pure>, [">= 1.4.6"])
    s.add_dependency(%q<ruby-hmac>, [">= 0.4.0"])
    s.add_dependency(%q<rr>, [">= 1.0.2"])
    s.add_dependency(%q<webmock>, [">= 1.6.1"])
    s.add_dependency(%q<bacon>, [">= 1.1.0"])
    s.add_dependency(%q<bones>, [">= 3.5.4"])
  end
end
