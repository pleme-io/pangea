require 'erb'
require 'fileutils'

module Pangea
  module Generators
    class ResourceGenerator
      TEMPLATE_PATH = File.expand_path('../resources/templates/resource_template.rb.erb', __dir__)
      
      attr_reader :service_name, :resource_name, :description, :attributes
      
      def initialize(service_name, resource_name, description, attributes = {})
        @service_name = service_name
        @resource_name = resource_name
        @description = description
        @attributes = attributes
      end
      
      def generate
        template = ERB.new(File.read(TEMPLATE_PATH))
        template.result(binding)
      end
      
      def write_to_file(path)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, generate)
      end
      
      private
      
      def service_lower
        service_name.downcase
      end
      
      def resource_lower
        resource_name.underscore
      end
      
      def example_name
        resource_lower
      end
      
      def example_attributes
        attributes.map { |k, v| "#{k}: #{v.inspect}" }.join(",\n    ")
      end
      
      def resource_outputs
        # Define based on resource type
        []
      end
      
      def validations
        # Define based on attributes
        ""
      end
    end
  end
end

# Add underscore method if not available
class String
  def underscore
    self.gsub(/::/, '/').
         gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
         gsub(/([a-z\d])([A-Z])/,'\1_\2').
         tr("-", "_").
         downcase
  end unless method_defined?(:underscore)
end