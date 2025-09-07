#!/usr/bin/env ruby
# frozen_string_literal: true

# Run only passing tests to establish baseline
lib_path = File.expand_path('../lib', __dir__)
$LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)

require 'rspec/core'

# Configure RSpec to show only passes initially
RSpec.configure do |config|
  config.pattern = 'spec/**/*_spec.rb'
  config.exclude_pattern = 'spec/pending/**/*_spec.rb'
  config.formatter = :progress
  config.color = true
  
  # Filter to run only tests we know pass
  config.filter_run_excluding :failing => true
end

puts "Running tests to identify passing baseline..."
exit_code = RSpec::Core::Runner.run(['--require', './spec/spec_helper', '--format', 'json', '--out', 'spec/test_results.json'] + ARGV, $stderr, $stdout)

# Parse results
if File.exist?('spec/test_results.json')
  require 'json'
  results = JSON.parse(File.read('spec/test_results.json'))
  
  puts "\n=== Test Summary ==="
  puts "Total examples: #{results['summary']['example_count']}"
  puts "Passed: #{results['summary']['example_count'] - results['summary']['failure_count']}"
  puts "Failed: #{results['summary']['failure_count']}"
  puts "Pending: #{results['summary']['pending_count']}"
  
  if results['summary']['failure_count'] > 0
    puts "\n=== Failed Tests ==="
    results['examples'].select { |e| e['status'] == 'failed' }.each do |example|
      puts "- #{example['full_description']}"
    end
  end
end

exit(exit_code)