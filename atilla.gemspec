# frozen_string_literal: true

require_relative "lib/atilla/version"

Gem::Specification.new do |spec|
  spec.name = "atilla"
  spec.version = Atilla::VERSION
  spec.authors = ["Bhargav Raut"]
  spec.email = ["bhargav.r.raut@gmail.com"]

  spec.summary = "Ruby SEO gem that crawls any website to warm its caches,provides useful SEO metrics, and a visual sitemap, embeddable in your page."
  spec.description = "Point it at any url to crawl the whole website. It will generate useful metrics about each page, crawl the whole website and as a byproduc warm your caches if you use a caching layer. It also generates a force directed visual sitemap of your website, embeddable in any page using D3js as a visualizer."
  spec.homepage = "https://www.github/com/wordjelly/atilla"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.4.0"

  spec.metadata["allowed_push_host"] = "rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://www.github.com/wordjelly/atilla"
  spec.metadata["changelog_uri"] = "https://www.github.com/wordjelly/atilla/CHANGELOG"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
=begin
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
=end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "typhoeus"
  spec.add_dependency "activesupport"
  spec.add_dependency "byebug"
  spec.add_dependency "nokogiri"
  spec.add_dependency "rack"
  spec.add_dependency 'ruby-limiter'
  spec.add_dependency 'addressable'
  spec.add_dependency 'elasticsearch-persistence','5.0.2'
  spec.add_dependency "normalize_url"
  spec.add_dependency "ruby-progressbar"
  spec.add_dependency "concurrent-ruby"
  spec.add_dependency "sitemap-parser"
  spec.add_dependency "robotstxt-parser"
  spec.add_dependency "metainspector", '~> 5.9.0'
  #spec.add_dependency "public_suffix"
  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
