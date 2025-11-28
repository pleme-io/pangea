# frozen_string_literal: true
# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Coverage reporting
require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'

  track_files 'lib/**/*.rb'

  # No minimum coverage requirement - coverage is tracked but not enforced

  if ENV['CI']
    require 'simplecov-lcov'
    SimpleCov::Formatter::LcovFormatter.config do |c|
      c.report_with_single_file = true
      c.single_report_path = 'coverage/lcov.info'
    end
    SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::LcovFormatter
    ])
  end
end

# Spec helper for Pangea testing framework
lib_path = File.expand_path('../lib', __dir__)
$LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)

require 'rspec'

# Load dependencies
begin
  require 'dry-types'
  require 'dry-struct'  
  require 'terraform-synthesizer'
  require 'json'
rescue LoadError => e
  puts "Warning: Could not load dependency: #{e.message}"
end

# Load Pangea
begin
  require 'pangea'
rescue LoadError => e
  puts "Warning: Could not load Pangea: #{e.message}"
end

# Load support files
Dir[File.join(__dir__, 'support', '**', '*.rb')].each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on Module and main
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Include test helpers
  config.include SynthesisTestHelpers if defined?(SynthesisTestHelpers)
  config.include ComponentTestHelpers if defined?(ComponentTestHelpers)
  config.include ArchitectureTestHelpers if defined?(ArchitectureTestHelpers)
  config.include TestConfigurations if defined?(TestConfigurations)

  # Test environment setup
  config.before(:suite) do
    ENV['PANGEA_ENV'] = 'test'
  end

  config.before(:each) do
    # Reset any global state between tests
    reset_terraform_synthesizer_state if respond_to?(:reset_terraform_synthesizer_state)
  end

  config.after(:each) do
    # Clean up after each test
    cleanup_test_resources if respond_to?(:cleanup_test_resources)
  end

  # Configure RSpec output
  config.formatter = :progress
  config.color = true

  # Test filtering
  config.filter_run_when_matching :focus
  config.run_all_when_everything_filtered = true

  # Random test order
  config.order = :random
  Kernel.srand config.seed

  # Warnings
  config.warnings = false
end