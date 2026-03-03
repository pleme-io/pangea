#!/usr/bin/env ruby
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


class ResourceDiscoverer
  def self.discover_all_resources
    resources = []
    
    # Find all resource.rb files
    Dir.glob("lib/pangea/resources/*/resource.rb").each do |file|
      resource_name = extract_resource_name(file)
      resources << {
        name: resource_name,
        file_path: file,
        test_dir: "spec/resources/#{resource_name}",
        function_name: resource_name
      }
    end
    
    resources.sort_by { |r| r[:name] }
  end
  
  def self.extract_resource_name(file_path)
    File.dirname(file_path).split('/').last
  end
  
  def self.generate_task_list
    resources = discover_all_resources
    
    puts "Found #{resources.length} resources to test:"
    resources.each_with_index do |resource, index|
      puts "#{index + 1}. #{resource[:name]}"
    end
    
    resources
  end
end

if __FILE__ == $0
  ResourceDiscoverer.generate_task_list
end