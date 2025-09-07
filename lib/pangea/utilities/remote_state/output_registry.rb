# lib/pangea/utilities/remote_state/output_registry.rb
require 'json'
require 'fileutils'
require 'time'

module Pangea
  module Utilities
    module RemoteState
      class OutputRegistry
        REGISTRY_DIR = '.pangea/outputs'
        
        def initialize
          FileUtils.mkdir_p(REGISTRY_DIR)
        end
        
        def register_outputs(template_name, outputs)
          validate_template_name!(template_name)
          validate_outputs!(outputs)
          
          registry_file = registry_path(template_name)
          
          data = {
            template: template_name.to_s,
            outputs: normalize_outputs(outputs),
            types: infer_output_types(outputs),
            updated_at: Time.now.iso8601
          }
          
          File.write(registry_file, JSON.pretty_generate(data))
          data
        end
        
        def available_outputs(template_name)
          registry_file = registry_path(template_name)
          return {} unless File.exist?(registry_file)
          
          JSON.parse(File.read(registry_file))
        rescue JSON::ParserError
          {}
        end
        
        def list_templates
          Dir.glob("#{REGISTRY_DIR}/*.json").map do |file|
            File.basename(file, '.json')
          end
        end
        
        def validate_output_exists!(template_name, output_name)
          outputs = available_outputs(template_name)
          
          unless outputs['outputs']&.key?(output_name.to_s)
            available = outputs['outputs']&.keys || []
            raise "Output '#{output_name}' not found in template '#{template_name}'. Available outputs: #{available.join(', ')}"
          end
        end
        
        def clear_registry
          FileUtils.rm_rf(REGISTRY_DIR)
          FileUtils.mkdir_p(REGISTRY_DIR)
        end
        
        private
        
        def registry_path(template_name)
          File.join(REGISTRY_DIR, "#{template_name}.json")
        end
        
        def validate_template_name!(name)
          raise ArgumentError, "Template name cannot be empty" if name.to_s.empty?
          raise ArgumentError, "Invalid template name format" unless name.to_s.match?(/\A[a-z][a-z0-9_]*\z/)
        end
        
        def validate_outputs!(outputs)
          raise ArgumentError, "Outputs must be a Hash" unless outputs.is_a?(Hash)
          raise ArgumentError, "Outputs cannot be empty" if outputs.empty?
        end
        
        def normalize_outputs(outputs)
          outputs.transform_keys(&:to_s).transform_values do |value|
            case value
            when String, Numeric, TrueClass, FalseClass, NilClass
              value
            else
              value.to_s
            end
          end
        end
        
        def infer_output_types(outputs)
          outputs.transform_keys(&:to_s).transform_values do |value|
            case value
            when String then 'string'
            when Integer then 'number'
            when Float then 'number'
            when TrueClass, FalseClass then 'boolean'
            when Array then 'list'
            when Hash then 'map'
            else 'unknown'
            end
          end
        end
      end
    end
  end
end