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


require_relative 'resource_enhancer'
require_relative 'database_resource_data'

# Extend ResourceEnhancer to use our enhanced data
class DatabaseResourceEnhancer < ResourceEnhancer
  # Override the RESOURCE_DATA constant with our enhanced data
  def self.const_missing(name)
    if name == :RESOURCE_DATA
      ENHANCED_RESOURCE_DATA
    else
      super
    end
  end
end

# Monkey patch to use our data
ResourceEnhancer.const_set(:RESOURCE_DATA, ENHANCED_RESOURCE_DATA)

# List of resources to enhance
RESOURCES = ENHANCED_RESOURCE_DATA.keys

puts "🚀 Enhancing #{RESOURCES.size} database resources..."
puts "-" * 50

successful = 0
failed = []

RESOURCES.each_with_index do |resource, index|
  print "[#{index + 1}/#{RESOURCES.size}] Enhancing #{resource}... "
  
  begin
    enhancer = ResourceEnhancer.new(resource)
    enhancer.enhance!
    successful += 1
    puts "✅"
  rescue => e
    failed << { resource: resource, error: e.message }
    puts "❌ (#{e.message})"
  end
end

puts "-" * 50
puts "\n📊 Summary:"
puts "   ✅ Successful: #{successful}"
puts "   ❌ Failed: #{failed.size}"

if failed.any?
  puts "\n❌ Failed resources:"
  failed.each do |failure|
    puts "   - #{failure[:resource]}: #{failure[:error]}"
  end
end