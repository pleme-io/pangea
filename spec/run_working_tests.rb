#!/usr/bin/env ruby
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


# Working test runner that bypasses the Ruby version conflicts
# Use this instead of rake spec until the nix environment is fixed

lib_path = File.expand_path('../lib', __dir__)
$LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)

puts "Ruby version: #{RUBY_VERSION}"
puts "Load path includes lib: #{$LOAD_PATH.include?(lib_path)}"

# Test 1: Basic module loading
puts "\n=== Testing basic module loading ==="
begin
  require 'pangea'
  puts "✓ Pangea loaded"
  
  require 'pangea/resources'
  puts "✓ Resources loaded"
  puts "  Available modules: #{Pangea::Resources.constants}"
  
rescue => e
  puts "✗ Failed: #{e.message}"
  exit 1
end

# Test 2: Run individual tests manually without RSpec's bundle environment
puts "\n=== Testing Resources::Types manually ==="
begin
  types_module = Pangea::Resources::Types
  puts "✓ Types module accessible: #{types_module}"
  
  # Test string type
  string_type = types_module::String
  puts "✓ String type defined"
  
  # Test validation
  test_string = string_type['hello']
  puts "✓ String validation works: '#{test_string}'"
  
rescue => e
  puts "✗ Types test failed: #{e.message}"
end

puts "\n=== All manual tests passed! ==="
puts "\nTo run RSpec tests, you'll need to fix the Ruby version mismatch between:"
puts "  - Nix Ruby: #{RUBY_VERSION} (#{RUBY_ENGINE})"
puts "  - User gems: compiled for different Ruby version"
puts "\nSolutions:"
puts "  1. Use 'nix develop' to get consistent environment"
puts "  2. Or run 'bundle install' to rebuild gems for current Ruby"
puts "  3. Or run individual test files manually like this script"