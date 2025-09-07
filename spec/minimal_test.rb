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


# Minimal test runner that works with current environment
lib_path = File.expand_path('../lib', __dir__)
$LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)

puts "=== Running Minimal Pangea Tests ==="

# Test counter
tests_run = 0
tests_passed = 0

def test(description, &block)
  print "Testing #{description}... "
  begin
    result = yield
    if result
      puts "✓ PASS"
      $tests_passed += 1
    else
      puts "✗ FAIL"
    end
  rescue => e
    puts "✗ ERROR: #{e.message}"
  ensure
    $tests_run += 1
  end
end

# Initialize counters
$tests_run = 0
$tests_passed = 0

# Load core modules
require 'dry-types'
require 'dry-struct'
require 'pangea'
require 'pangea/resources'

puts "Successfully loaded all core modules\n\n"

# Test 1: Basic module structure
test("Pangea module structure") do
  Pangea.is_a?(Module) && 
  defined?(Pangea::Resources) && 
  Pangea::Resources.is_a?(Module)
end

# Test 2: Resources Types module
test("Resources::Types module") do
  defined?(Pangea::Resources::Types) &&
  Pangea::Resources::Types.respond_to?(:const_defined?) &&
  Pangea::Resources::Types.const_defined?(:String)
end

# Test 3: String type validation
test("String type validation") do
  string_type = Pangea::Resources::Types::String
  validated = string_type['hello world']
  validated == 'hello world'
end

# Test 4: Boolean type validation  
test("Bool type validation") do
  bool_type = Pangea::Resources::Types::Bool
  bool_type[true] == true && bool_type[false] == false
end

# Test 5: Integer type validation
test("Integer type validation") do
  int_type = Pangea::Resources::Types::Integer
  int_type[42] == 42
end

# Test 6: Hash type validation
test("Hash type validation") do
  hash_type = Pangea::Resources::Types::Hash
  test_hash = { name: 'test', value: 123 }
  hash_type[test_hash] == test_hash
end

# Test 7: AWS VPC module availability
test("AWS VPC module") do
  defined?(Pangea::Resources::AWS) &&
  Pangea::Resources::AWS.respond_to?(:instance_methods)
end

# Test 8: Resource Reference module
test("Resource Reference module") do
  defined?(Pangea::Resources::ResourceReference) &&
  Pangea::Resources::ResourceReference.is_a?(Class)
end

# Test 9: Configuration module
test("Configuration module") do
  # Just verify the configuration method exists, not its implementation
  Pangea.respond_to?(:configuration)
end

# Test 10: Basic dry-struct functionality
test("Dry-struct integration") do
  # Test that dry-struct works with our types
  class TestStruct < Dry::Struct
    attribute :name, Pangea::Resources::Types::String
    attribute :count, Pangea::Resources::Types::Integer
  end
  
  test_obj = TestStruct.new(name: 'test', count: 5)
  test_obj.name == 'test' && test_obj.count == 5
end

puts "\n=== Test Summary ==="
puts "Tests run: #{$tests_run}"
puts "Tests passed: #{$tests_passed}"
puts "Tests failed: #{$tests_run - $tests_passed}"

if $tests_passed == $tests_run
  puts "\n🎉 All tests passed!"
  exit 0
else
  puts "\n❌ Some tests failed"
  exit 1
end