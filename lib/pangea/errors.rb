module Pangea
  module Errors
    class PangeaError < StandardError; end
    
    class ValidationError < PangeaError
      def self.invalid_attribute(resource, attribute, value, expected)
        new("#{resource}: Invalid #{attribute} '#{value}'. Expected: #{expected}")
      end
      
      def self.missing_required(resource, attribute)
        new("#{resource}: Missing required attribute '#{attribute}'")
      end
      
      def self.invalid_reference(source, target, reason)
        new("#{source}: Invalid reference to #{target}. Reason: #{reason}")
      end
      
      def self.invalid_type(resource, attribute, expected_type, actual_type)
        new("#{resource}: Invalid type for '#{attribute}'. Expected: #{expected_type}, Got: #{actual_type}")
      end
      
      def self.out_of_range(resource, attribute, value, range)
        new("#{resource}: Value '#{value}' for '#{attribute}' is out of range. Expected: #{range}")
      end
    end
    
    class ConfigurationError < PangeaError
      def self.invalid_namespace(namespace)
        new("Invalid namespace '#{namespace}'. Check pangea.yaml for available namespaces.")
      end
      
      def self.missing_config_file
        new("Missing pangea.yaml configuration file. Run 'pangea init' to create one.")
      end
    end
    
    class SynthesisError < PangeaError
      def self.invalid_template(template_name, reason)
        new("Failed to synthesize template '#{template_name}': #{reason}")
      end
      
      def self.circular_dependency(resource1, resource2)
        new("Circular dependency detected between #{resource1} and #{resource2}")
      end
    end
    
    class ResourceNotFoundError < PangeaError
      def self.new(resource_type, resource_name)
        super("Resource not found: #{resource_type}.#{resource_name}")
      end
    end
  end
end