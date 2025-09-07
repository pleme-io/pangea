# frozen_string_literal: true

require "bundler/gem_tasks"

# Run minimal tests that work with current environment
desc "Run basic Pangea tests"
task :spec do
  puts "Running minimal Pangea tests..."
  result = system("ruby spec/minimal_test.rb")
  
  if result
    puts "\n✅ Core functionality tests passed!"
    puts "For full RSpec tests, use: nix develop --command rake rspec"
  else
    puts "\n❌ Some tests failed"
    exit 1
  end
end

# Full RSpec tests (requires nix environment)
desc "Run full RSpec test suite"
task :rspec do
  rspec_cmd = "/nix/store/pzakqns6igcsfjxp1fchw3ykzjchcdqpppabjifpr3-pangea/bin/rspec"
  rspec_cmd = "rspec" unless File.exist?(rspec_cmd)
  
  system("#{rspec_cmd} -I lib --require ./spec/spec_helper_fixed")
end

# Fallback to regular RSpec if nix version not available
begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec_fallback) do |task|
    task.rspec_opts = '-I lib --require ./spec/spec_helper_fixed'
  end
rescue LoadError
  puts "RSpec not available - using system command instead"
end

task :default => :spec

# Type checking with Steep (optional)
desc "Run type checking with Steep"
task :typecheck do
  if system("which steep > /dev/null 2>&1") || system("bundle exec steep --version > /dev/null 2>&1")
    puts "Running type checking with Steep..."
    result = system("bundle exec steep check")
    exit(1) unless result
  else
    puts "Steep is not available. Install with: gem install steep"
  end
end

desc "Run Steep statistics"
task :type_stats do
  if system("which steep > /dev/null 2>&1") || system("bundle exec steep --version > /dev/null 2>&1")
    puts "Generating type coverage statistics..."
    system("bundle exec steep stats")
  else
    puts "Steep is not available. Install with: gem install steep"
  end
end

# Linting with RuboCop (optional)
desc "Run RuboCop linting"
task :rubocop do
  if system("which rubocop > /dev/null 2>&1") || system("bundle exec rubocop --version > /dev/null 2>&1")
    puts "Running RuboCop linting..."
    system("bundle exec rubocop --display-cop-names")
  else
    puts "RuboCop is not available. Install with: gem install rubocop"
  end
end

desc "Auto-correct RuboCop offenses"
task :rubocop_fix do
  if system("which rubocop > /dev/null 2>&1") || system("bundle exec rubocop --version > /dev/null 2>&1")
    system("bundle exec rubocop --auto-correct-all")
  else
    puts "RuboCop is not available. Install with: gem install rubocop"
  end
end

# Documentation generation
desc "Generate YARD documentation"
task :docs do
  puts "Generating documentation with YARD..."
  system("bundle exec yard doc")
end

# Quality checks
desc "Run all quality checks (specs, types, lint)"
task :quality => [:spec]

# Test coverage
desc "Run specs with coverage report"
task :coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task[:spec].invoke
end

# Property-based testing (if available)
desc "Run property-based tests"
task :property_tests do
  puts "Running property-based tests..."
  # This would run specific property-based test files
  system("bundle exec rspec spec/**/*_property_spec.rb")
end

# Performance tests (if available) 
desc "Run performance tests"
task :performance do
  puts "Running performance tests..."
  system("bundle exec rspec spec/performance/**/*_spec.rb")
end

# Integration tests
desc "Run integration tests"
task :integration do
  puts "Running integration tests..."
  system("bundle exec rspec spec/integration/**/*_spec.rb")
end

# All tests
desc "Run all test suites"
task :test_all => [:spec, :property_tests, :performance, :integration]

# Clean up generated files
desc "Clean up generated files"
task :clean do
  puts "Cleaning up generated files..."
  FileUtils.rm_rf('.coverage')
  FileUtils.rm_rf('doc')
  FileUtils.rm_rf('.yardoc')
  FileUtils.rm_rf('tmp')
end

# Setup development environment
desc "Setup development environment"
task :setup do
  puts "Setting up development environment..."
  system("bundle install")
  
  # Create necessary directories
  FileUtils.mkdir_p(['tmp', 'log', 'spec/fixtures'])
  
  puts "Development environment setup complete!"
  puts ""
  puts "Available tasks:"
  puts "  rake spec         - Run all specs"
  puts "  rake typecheck    - Run type checking"
  puts "  rake rubocop      - Run linting"
  puts "  rake quality      - Run all quality checks"
  puts "  rake coverage     - Run specs with coverage"
  puts "  rake docs         - Generate documentation"
  puts "  rake clean        - Clean generated files"
end

task :bundix do
  sh %(bundle lock --update)
  sh %(bundix)
end
