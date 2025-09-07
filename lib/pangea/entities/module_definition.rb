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


require 'dry-struct'
require 'pangea/types'

module Pangea
  module Entities
    # ModuleDefinition represents a reusable Pangea module
    # Modules can provide resources, functions, or both
    class ModuleDefinition < Dry::Struct
      # Module types
      module Type
        RESOURCE = :resource   # Provides Terraform resources
        FUNCTION = :function   # Provides helper functions only
        COMPOSITE = :composite # Combines resources and functions
      end
      
      # Module metadata
      attribute :name, Types::ModuleName
      attribute :version, Types::Version.optional.default("0.0.1")
      attribute :description, Types::OptionalString.default(nil)
      attribute :author, Types::OptionalString.default(nil)
      
      # Module configuration
      attribute :type, Types::Strict::Symbol.default(:resource).enum(:resource, :function, :composite)
      attribute :source, Types::FilePath.optional.default(nil)
      attribute :path, Types::DirectoryPath.optional.default(nil)
      
      # Module interface
      attribute :inputs, Types::SymbolizedHash.default({}.freeze)
      attribute :outputs, Types::SymbolizedHash.default({}.freeze)
      attribute :dependencies, Types::ModuleArray.default([].freeze)
      
      # Runtime configuration
      attribute :ruby_version, Types::Version.optional.default(nil)
      attribute :required_gems, Types::SymbolizedHash.default({}.freeze)
      
      # Check if this is a resource module
      def resource_module?
        type == Type::RESOURCE || type == Type::COMPOSITE
      end
      
      # Check if this is a function module
      def function_module?
        type == Type::FUNCTION || type == Type::COMPOSITE
      end
      
      # Get the module load path
      def load_path
        return path if path
        return File.dirname(source) if source
        
        # Default module path
        "modules/#{name}"
      end
      
      # Get required input names
      def required_inputs
        inputs.select { |_, config| config[:required] }.keys
      end
      
      # Get optional input names
      def optional_inputs
        inputs.reject { |_, config| config[:required] }.keys
      end
      
      # Validate input configuration against provided values
      def validate_inputs(provided_inputs)
        errors = []
        provided = provided_inputs.keys.map(&:to_sym)
        
        # Check required inputs
        required_inputs.each do |input|
          unless provided.include?(input)
            errors << "Missing required input: #{input}"
          end
        end
        
        # Check for unknown inputs
        provided.each do |input|
          unless inputs.key?(input)
            errors << "Unknown input: #{input}"
          end
        end
        
        # Type validation
        provided_inputs.each do |key, value|
          if inputs[key.to_sym] && inputs[key.to_sym][:type]
            expected_type = inputs[key.to_sym][:type]
            # Type checking would go here
          end
        end
        
        raise ValidationError, errors.join(", ") unless errors.empty?
        true
      end
      
      # Generate module documentation
      def to_documentation
        doc = ["# Module: #{name}"]
        doc << "Version: #{version}" if version
        doc << "\n#{description}" if description
        doc << "\nAuthor: #{author}" if author
        
        if inputs.any?
          doc << "\n## Inputs"
          inputs.each do |name, config|
            required = config[:required] ? " (required)" : ""
            doc << "- `#{name}`#{required}: #{config[:description] || 'No description'}"
            doc << "  - Type: #{config[:type]}" if config[:type]
            doc << "  - Default: #{config[:default]}" if config[:default]
          end
        end
        
        if outputs.any?
          doc << "\n## Outputs"
          outputs.each do |name, config|
            doc << "- `#{name}`: #{config[:description] || 'No description'}"
          end
        end
        
        doc.join("\n")
      end
    end
  end
end