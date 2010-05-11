# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rest-graph}
  s.version = "1.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Cardinal Blue", "Lin Jen-Shin (aka godfat 真常)"]
  s.date = %q{2010-05-11}
  s.description = %q{ super simple facebook open graph api client}
  s.email = %q{godfat (XD) cardinalblue.com}
  s.extra_rdoc_files = ["CHANGES", "LICENSE", "README", "TODO", "bench/config.ru"]
  s.files = ["CHANGES", "LICENSE", "README", "Rakefile", "TODO", "bench/config.ru", "init.rb", "lib/rest-graph.rb", "lib/rest-graph/load_config.rb", "lib/rest-graph/version.rb", "test/common.rb", "test/config/rest-graph.yaml", "test/test_load_config.rb", "test/test_rest-graph.rb"]
  s.homepage = %q{http://github.com/cardinalblue/rest-graph}
  s.rdoc_options = ["--main", "README"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{rest-graph}
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{super simple facebook open graph api client}
  s.test_files = ["test/test_load_config.rb", "test/test_rest-graph.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rest-client>, [">= 1.5.0"])
      s.add_development_dependency(%q<json>, [">= 1.4.3"])
      s.add_development_dependency(%q<rack>, [">= 1.1.0"])
      s.add_development_dependency(%q<rr>, [">= 0.10.11"])
      s.add_development_dependency(%q<webmock>, [">= 1.1.0"])
      s.add_development_dependency(%q<bacon>, [">= 1.1.0"])
      s.add_development_dependency(%q<bones>, [">= 3.4.1"])
    else
      s.add_dependency(%q<rest-client>, [">= 1.5.0"])
      s.add_dependency(%q<json>, [">= 1.4.3"])
      s.add_dependency(%q<rack>, [">= 1.1.0"])
      s.add_dependency(%q<rr>, [">= 0.10.11"])
      s.add_dependency(%q<webmock>, [">= 1.1.0"])
      s.add_dependency(%q<bacon>, [">= 1.1.0"])
      s.add_dependency(%q<bones>, [">= 3.4.1"])
    end
  else
    s.add_dependency(%q<rest-client>, [">= 1.5.0"])
    s.add_dependency(%q<json>, [">= 1.4.3"])
    s.add_dependency(%q<rack>, [">= 1.1.0"])
    s.add_dependency(%q<rr>, [">= 0.10.11"])
    s.add_dependency(%q<webmock>, [">= 1.1.0"])
    s.add_dependency(%q<bacon>, [">= 1.1.0"])
    s.add_dependency(%q<bones>, [">= 3.4.1"])
  end
end
