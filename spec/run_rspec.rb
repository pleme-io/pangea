#!/usr/bin/env ruby
# frozen_string_literal: true

# Run RSpec tests without bundler interference
lib_path = File.expand_path('../lib', __dir__)
$LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)

# Load RSpec
begin
  require 'rspec/core'
rescue LoadError
  puts "RSpec not available. Install with: gem install rspec"
  exit 1
end

# Configure RSpec
RSpec.configure do |config|
  config.pattern = 'spec/**/*_spec.rb'
  config.exclude_pattern = 'spec/pending/**/*_spec.rb'
  config.add_formatter 'documentation'
  config.color = true
end

# Run RSpec
puts "Running RSpec tests..."
exit_code = RSpec::Core::Runner.run(ARGV, $stderr, $stdout)
exit(exit_code)