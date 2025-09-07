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

require 'erb'
require 'fileutils'

module Pangea
  module Generators
    class TestGenerator
      TEMPLATES = {
        resource_spec: 'resource_spec.rb.erb',
        synthesis_spec: 'synthesis_spec.rb.erb',
        integration_spec: 'integration_spec.rb.erb'
      }.freeze
      
      def initialize(resource_name)
        @resource_name = resource_name
        @resource_type = "aws_#{resource_name}"
      end
      
      def generate_all
        output_dir = "spec/resources/#{@resource_type}"
        FileUtils.mkdir_p(output_dir)
        
        TEMPLATES.each do |spec_type, template_file|
          generate_spec(spec_type, output_dir)
        end
      end
      
      private
      
      def generate_spec(spec_type, output_dir)
        template_path = File.join(template_dir, TEMPLATES[spec_type])
        template = ERB.new(File.read(template_path))
        
        output_file = File.join(output_dir, TEMPLATES[spec_type].sub('.erb', ''))
        File.write(output_file, template.result(binding))
      end
      
      def template_dir
        'spec/templates'
      end
      
      def resource_class
        "AWS#{@resource_name.split('_').map(&:capitalize).join}"
      end
      
      def resource_method
        @resource_type
      end
      
      def resource_type
        @resource_type
      end
    end
  end
end