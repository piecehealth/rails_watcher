$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rails_watcher/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rails_watcher"
  s.version     = RailsWatcher::VERSION
  s.authors     = ["piecehealth"]
  s.email       = ["piecehealth@sina.com"]
  s.homepage    = "https://github.com/piecehealth/rails_watcher"
  s.summary     = "A profiling tool for Rails application."
  s.description = "Help developers to understand, analyze your Rails application."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5"
end
