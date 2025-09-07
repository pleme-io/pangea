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
require_relative 'complete_resource_data'

# Override the RESOURCE_DATA constant with our complete data
ResourceEnhancer.const_set(:RESOURCE_DATA, COMPLETE_RESOURCE_DATA)

# List of remaining resources to enhance
REMAINING_RESOURCES = COMPLETE_RESOURCE_DATA.keys

puts "🚀 Enhancing #{REMAINING_RESOURCES.size} remaining database resources..."
puts "-" * 60

successful = 0
failed = []

REMAINING_RESOURCES.each_with_index do |resource, index|
  print "[#{index + 1}/#{REMAINING_RESOURCES.size}] Enhancing #{resource}... "
  
  begin
    enhancer = ResourceEnhancer.new(resource)
    if enhancer.enhance!
      successful += 1
      puts "✅"
    else
      failed << { resource: resource, error: "Enhancement returned false" }
      puts "❌ (returned false)"
    end
  rescue => e
    failed << { resource: resource, error: e.message }
    puts "❌ (#{e.message})"
  end
end

puts "-" * 60
puts "\n📊 Summary:"
puts "   ✅ Successful: #{successful}"
puts "   ❌ Failed: #{failed.size}"

if failed.any?
  puts "\n❌ Failed resources:"
  failed.each do |failure|
    puts "   - #{failure[:resource]}: #{failure[:error]}"
  end
end