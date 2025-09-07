module Pangea
  module Documentation
    class Generator
      def self.for_resource(resource_class)
        ResourceDocGenerator.new(resource_class)
      end
      
      def self.for_component(component_class)
        ComponentDocGenerator.new(component_class)
      end
      
      def self.for_architecture(architecture_class)
        ArchitectureDocGenerator.new(architecture_class)
      end
    end
    
    class BaseDocGenerator
      attr_reader :klass
      
      def initialize(klass)
        @klass = klass
      end
      
      def generate_markdown
        raise NotImplementedError
      end
      
      protected
      
      def format_type(type)
        case type
        when Class
          "`#{type.name.split('::').last}`"
        when Symbol
          "`#{type}`"
        else
          "`#{type}`"
        end
      end
      
      def format_example(code)
        ["```ruby", code.strip, "```"].join("\n")
      end
    end
    
    class ResourceDocGenerator < BaseDocGenerator
      def generate_markdown
        doc = []
        
        doc << "# #{resource_name}"
        doc << ""
        doc << description
        doc << ""
        doc << "## Usage"
        doc << ""
        doc << format_example(basic_example)
        doc << ""
        doc << "## Required Attributes"
        doc << ""
        
        required_attributes.each do |attr|
          doc << "- **#{attr[:name]}** (#{format_type(attr[:type])}): #{attr[:description]}"
        end
        
        doc << ""
        doc << "## Optional Attributes"
        doc << ""
        
        optional_attributes.each do |attr|
          doc << "- **#{attr[:name]}** (#{format_type(attr[:type])}): #{attr[:description]}"
          doc << "  - Default: `#{attr[:default]}`" if attr[:default]
        end
        
        doc << ""
        doc << "## Outputs"
        doc << ""
        
        outputs.each do |output|
          doc << "- **#{output[:name]}**: #{output[:description]}"
        end
        
        doc.join("\n")
      end
      
      private
      
      def resource_name
        @klass.name.split('::').last
      end
      
      def description
        # Extract from YARD comments or default
        "AWS #{resource_name} resource"
      end
      
      def basic_example
        # Generate from attributes
        "#{resource_method}(:my_#{resource_name.downcase},\n  # attributes here\n)"
      end
      
      def resource_method
        "aws_#{resource_name.underscore}"
      end
      
      def required_attributes
        # Extract from type definitions
        []
      end
      
      def optional_attributes
        # Extract from type definitions
        []
      end
      
      def outputs
        # Standard outputs plus resource-specific
        [
          { name: :id, description: "Resource ID" },
          { name: :arn, description: "Resource ARN" },
          { name: :tags, description: "Resource tags" }
        ]
      end
    end
  end
end