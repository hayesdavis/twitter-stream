# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{hayesdavis-twitter-stream}
  s.version = "0.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Vladimir Kolesnikov"]
  s.date = %q{2011-3-1}
  s.description = %q{This is @hayesdavis' fork. Simple Ruby client library for twitter streaming API. Uses EventMachine for connection handling. Adheres to twitter's reconnection guidline. JSON format only.}
  s.email = %q{voloko@gmail.com}
  s.extra_rdoc_files = [
    "README.markdown"
  ]
  s.files = [
    ".gitignore",
     "README.markdown",
     "Rakefile",
     "VERSION",
     "examples/reader.rb",
     "fixtures/twitter/tweets.txt",
     "lib/twitter/json_stream.rb",
     "spec/spec_helper.rb",
     "spec/twitter/json_stream.rb",
     "twitter-stream.gemspec"
  ]
  s.homepage = %q{http://github.com/hayesdavis/twitter-stream}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{@hayesdavis' fork of twitter-stream, the Twitter realtime API client}
  s.test_files = [
    "spec/spec_helper.rb",
     "spec/twitter/json_stream.rb",
     "examples/reader.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<eventmachine>, [">= 0.12.8"])
      s.add_runtime_dependency(%q<roauth>, [">= 0.0.2"])
      s.add_runtime_dependency(%q<http_parser.rb>, [">= 0.5.1"])
      s.add_development_dependency(%q<rspec>, [">= 1.2.8"])
    else
      s.add_dependency(%q<eventmachine>, [">= 0.12.8"])
      s.add_dependency(%q<roauth>, [">= 0.0.2"])
      s.add_dependency(%q<http_parser.rb>, [">= 0.5.1"])
      s.add_dependency(%q<rspec>, [">= 1.2.8"])
    end
  else
    s.add_dependency(%q<eventmachine>, [">= 0.12.8"])
    s.add_dependency(%q<roauth>, [">= 0.0.2"])
    s.add_dependency(%q<http_parser.rb>, [">= 0.5.1"])
    s.add_dependency(%q<rspec>, [">= 1.2.8"])
  end
end

