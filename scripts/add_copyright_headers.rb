#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'date'

HEADER = <<~HEADER
# Copyright #{Date.today.year} The Pangea Authors
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

HEADER

def add_header_to_file(file_path)
  return if file_path.include?('vendor/')
  return if file_path.include?('tmp/')
  
  content = File.read(file_path)
  
  # Skip if already has copyright
  return if content.include?('Copyright') && content.include?('Apache License')
  
  lines = content.lines
  new_content = []
  
  # Preserve shebang if present
  if lines.first&.start_with?('#!')
    new_content << lines.shift
  end
  
  # Preserve frozen_string_literal if present
  if lines.first&.strip == '# frozen_string_literal: true'
    new_content << lines.shift
    new_content << "\n" if lines.first&.strip != ""
  end
  
  # Add copyright header
  new_content << HEADER
  new_content.concat(lines)
  
  File.write(file_path, new_content.join)
  puts "Added header to: #{file_path}"
end

# Find all Ruby files
Dir.glob('**/*.rb').each do |file|
  add_header_to_file(file)
end

# Also add to exe/pangea
if File.exist?('exe/pangea')
  add_header_to_file('exe/pangea')
end

puts "\nCopyright headers added successfully!"