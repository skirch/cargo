require 'rubygems'
require 'rake/gempackagetask'
require 'rake/rdoctask'

module Cargo
  NAME     = 'cargo'
  VERSION  = '0.3.3'
  GEM_NAME = "#{NAME}-#{VERSION}.gem"
end

# Packaging

spec = Gem::Specification.new do |s|
  s.name        = Cargo::NAME
  s.version     = Cargo::VERSION
  s.platform    = Gem::Platform::RUBY
  s.author      = 'Sam Kirchmeier'
  s.email       = 'sam.kirchmeier@gmail.com'
  s.homepage    = 'http://code.yieldself.com/doc/cargo/'
  s.summary     = 'An Active Record extension that provides a basic way to ' \
                  'save file data along side an Active Record object'
  s.description = s.summary
  s.add_dependency('activerecord', '>= 2.1.1')
  s.require_path = 'lib'
  s.files =
    %w(CHANGELOG LICENSE README Rakefile) +
    FileList['lib/**/*.rb'] +
    FileList['spec/**/*.rb']
  s.has_rdoc = true
  s.extra_rdoc_files = %w(CHANGELOG README LICENSE)
  s.rdoc_options |= %w(--inline-source --line-numbers --main README)
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

# Release

desc 'Build and release gem + rdoc'
task :release => %w(release:gem_file release:doc) do
  print "\n==== Remember to commit and tag this release.\n\n"
end

namespace :release do
  desc 'Upload gem and update gem index'
  task :gem_file => :gem do
    sh "scp -r pkg/#{Cargo::GEM_NAME} yieldself.com:code/gems/"
    sh "ssh yieldself.com 'code/update_gem_index.sh'"
  end

  desc 'Sync online documentation with latest rdoc'
  task :doc => :rdoc do
    sh "rsync -azq --delete doc/ yieldself.com:code/doc/#{Cargo::NAME}/"
  end
end

# Documentation

Rake::RDocTask.new do |rdoc|
  files = %w(CHANGELOG README LICENSE lib/**/*.rb)
  rdoc.rdoc_files.add(files)
  rdoc.main = 'README'
  rdoc.title = 'Cargo Documentation'
  rdoc.rdoc_dir = 'doc'
  rdoc.options |= %w(--inline-source --line-numbers)
end

# Tests

begin
  require 'spec/rake/spectask'
rescue LoadError
  puts 'RSpec is required to run tests.'
else
  desc 'Run all specs + rcov'
  Spec::Rake::SpecTask.new(:specs) do |t|
    t.spec_opts = %w(--format specdoc --colour)
    t.spec_files = FileList['spec/**/*_spec.rb']
    t.rcov = true
    t.rcov_opts = %w(--exclude ".*" --include-file "^lib/" --text-report)
  end
  task :default => :specs
end
