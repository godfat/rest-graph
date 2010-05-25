# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rest-graph}
  s.version = "1.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Cardinal Blue", "Lin Jen-Shin (aka godfat 真常)"]
  s.date = %q{2010-05-25}
  s.description = %q{ A super simple Facebook Open Graph API client}
  s.email = %q{dev (XD) cardinalblue.com}
  s.extra_rdoc_files = ["CHANGES", "LICENSE", "TODO", "rest-graph.gemspec"]
  s.files = ["CHANGES", "LICENSE", "README.rdoc", "Rakefile", "TODO", "init.rb", "lib/rest-graph.rb", "lib/rest-graph/auto_load.rb", "lib/rest-graph/load_config.rb", "lib/rest-graph/version.rb", "rest-graph.gemspec", "test/common.rb", "test/config/rest-graph.yaml", "test/test_load_config.rb", "test/test_oauth.rb", "test/test_rest-graph.rb"]
  s.homepage = %q{http://github.com/cardinalblue/rest-graph}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{rest-graph}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{A super simple Facebook Open Graph API client}
  s.test_files = ["test/test_load_config.rb", "test/test_oauth.rb", "test/test_rest-graph.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rest-client>, [">= 1.5.1"])
      s.add_development_dependency(%q<json>, [">= 1.4.3"])
      s.add_development_dependency(%q<rack>, [">= 1.1.0"])
      s.add_development_dependency(%q<rr>, [">= 0.10.11"])
      s.add_development_dependency(%q<webmock>, [">= 1.2.1"])
      s.add_development_dependency(%q<bacon>, [">= 1.1.0"])
      s.add_development_dependency(%q<bones>, [">= 3.4.3"])
    else
      s.add_dependency(%q<rest-client>, [">= 1.5.1"])
      s.add_dependency(%q<json>, [">= 1.4.3"])
      s.add_dependency(%q<rack>, [">= 1.1.0"])
      s.add_dependency(%q<rr>, [">= 0.10.11"])
      s.add_dependency(%q<webmock>, [">= 1.2.1"])
      s.add_dependency(%q<bacon>, [">= 1.1.0"])
      s.add_dependency(%q<bones>, [">= 3.4.3"])
    end
  else
    s.add_dependency(%q<rest-client>, [">= 1.5.1"])
    s.add_dependency(%q<json>, [">= 1.4.3"])
    s.add_dependency(%q<rack>, [">= 1.1.0"])
    s.add_dependency(%q<rr>, [">= 0.10.11"])
    s.add_dependency(%q<webmock>, [">= 1.2.1"])
    s.add_dependency(%q<bacon>, [">= 1.1.0"])
    s.add_dependency(%q<bones>, [">= 3.4.3"])
  end
end
