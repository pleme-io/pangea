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