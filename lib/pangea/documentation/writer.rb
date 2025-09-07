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

require 'fileutils'

module Pangea
  module Documentation
    class Writer
      def initialize(base_path = 'docs/generated')
        @base_path = base_path
      end
      
      def write_resource_docs(resource_class, content)
        path = resource_path(resource_class)
        write_file(path, content)
      end
      
      def write_component_docs(component_class, content)
        path = component_path(component_class)
        write_file(path, content)
      end
      
      def write_architecture_docs(architecture_class, content)
        path = architecture_path(architecture_class)
        write_file(path, content)
      end
      
      def write_index(resources, components, architectures)
        content = generate_index(resources, components, architectures)
        write_file(File.join(@base_path, 'README.md'), content)
      end
      
      private
      
      def resource_path(resource_class)
        name = resource_class.name.split('::').last.underscore
        File.join(@base_path, 'resources', "#{name}.md")
      end
      
      def component_path(component_class)
        name = component_class.name.split('::').last.underscore
        File.join(@base_path, 'components', "#{name}.md")
      end
      
      def architecture_path(architecture_class)
        name = architecture_class.name.split('::').last.underscore
        File.join(@base_path, 'architectures', "#{name}.md")
      end
      
      def write_file(path, content)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, content)
        puts "Generated: #{path}"
      end
      
      def generate_index(resources, components, architectures)
        <<~MD
          # Pangea Generated Documentation
          
          ## Resources (#{resources.length})
          
          #{resources.map { |r| "- [#{r.name}](resources/#{r.name.underscore}.md)" }.join("\n")}
          
          ## Components (#{components.length})
          
          #{components.map { |c| "- [#{c.name}](components/#{c.name.underscore}.md)" }.join("\n")}
          
          ## Architectures (#{architectures.length})
          
          #{architectures.map { |a| "- [#{a.name}](architectures/#{a.name.underscore}.md)" }.join("\n")}
        MD
      end
    end
  end
end