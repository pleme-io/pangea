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

require 'dry-validation'
require 'pangea/errors'
require 'pangea/validation/common_validation_rules'

module Pangea
  module Validation
    # Base validator for all resources
    class BaseValidator < Dry::Validation::Contract
      # Registry of resource-specific validators
      class Registry
        class << self
          def validators
            @validators ||= {}
          end
          
          def register(resource_type, validator_class)
            validators[resource_type.to_sym] = validator_class
          end
          
          def get(resource_type)
            validators[resource_type.to_sym] || BaseValidator
          end
          
          def validate(resource_type, attributes)
            validator = get(resource_type).new
            validator.call(attributes)
          end
        end
      end
      
      # Create validator for specific resource type
      def self.for_resource(resource_type, &block)
        Class.new(self) do
          # Include common rules
          extend CommonValidationRules
          
          # Allow custom configuration
          class_eval(&block) if block_given?
          
          # Auto-register with the registry
          Registry.register(resource_type, self)
        end
      end
      
      # Validate resource and raise on errors
      def validate!(attributes)
        result = call(attributes)
        
        return attributes if result.success?
        
        # Build detailed error message
        errors = result.errors.to_h
        error_messages = build_error_messages(errors)
        
        raise Errors::ValidationError.new(
          "Resource validation failed",
          context: {
            resource_type: self.class.name,
            errors: errors,
            messages: error_messages
          }
        )
      end
      
      private
      
      def build_error_messages(errors, prefix = nil)
        messages = []
        
        errors.each do |key, value|
          full_key = prefix ? "#{prefix}.#{key}" : key.to_s
          
          case value
          when Hash
            # Nested errors
            messages.concat(build_error_messages(value, full_key))
          when Array
            # Multiple errors for same key
            value.each { |msg| messages << "#{full_key}: #{msg}" }
          else
            messages << "#{full_key}: #{value}"
          end
        end
        
        messages
      end
    end
  end
end