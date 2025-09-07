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


require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS Systems Manager Parameter resources
      class SsmParameterAttributes < Dry::Struct
        # Parameter name (required)
        attribute :name, Resources::Types::String

        # Parameter type
        attribute :type, Resources::Types::String.enum("String", "StringList", "SecureString")

        # Parameter value (required)
        attribute :value, Resources::Types::String

        # Parameter description
        attribute :description, Resources::Types::String.optional

        # KMS Key ID for SecureString parameters
        attribute :key_id, Resources::Types::String.optional

        # Parameter tier (Standard or Advanced)
        attribute :tier, Resources::Types::String.enum("Standard", "Advanced").default("Standard")

        # Allowed pattern for parameter value
        attribute :allowed_pattern, Resources::Types::String.optional

        # Data type for parameter
        attribute :data_type, Resources::Types::String.enum("text", "aws:ec2:image").optional

        # Overwrite existing parameter
        attribute :overwrite, Resources::Types::Bool.default(false)

        # Tags for the parameter
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate SecureString requirements
          if attrs.type == "SecureString"
            # KMS key validation for SecureString
            if attrs.key_id && !attrs.key_id.match?(/\A(alias\/[a-zA-Z0-9\/_-]+|arn:aws:kms:[a-z0-9-]+:\d{12}:key\/[a-f0-9-]{36}|[a-f0-9-]{36})\z/)
              raise Dry::Struct::Error, "key_id must be a valid KMS key ID, ARN, or alias"
            end
          elsif attrs.key_id
            raise Dry::Struct::Error, "key_id can only be specified for SecureString parameters"
          end

          # Validate StringList format
          if attrs.type == "StringList"
            # StringList should be comma-separated values
            unless attrs.value.include?(',') || attrs.value.match?(/\A[^,]+\z/)
              # Single value is OK, but validate it doesn't have invalid characters for lists
            end
          end

          # Validate parameter name format
          unless attrs.name.match?(/\A[a-zA-Z0-9\/_.-]+\z/)
            raise Dry::Struct::Error, "Parameter name can only contain letters, numbers, and the following symbols: /_.-"
          end

          # Validate parameter name length
          if attrs.name.length > 2048
            raise Dry::Struct::Error, "Parameter name cannot exceed 2048 characters"
          end

          # Validate parameter value size based on tier
          max_value_size = attrs.tier == "Advanced" ? 8192 : 4096
          if attrs.value.bytesize > max_value_size
            raise Dry::Struct::Error, "Parameter value cannot exceed #{max_value_size} bytes for #{attrs.tier} tier"
          end

          # Validate description length
          if attrs.description && attrs.description.length > 1024
            raise Dry::Struct::Error, "Parameter description cannot exceed 1024 characters"
          end

          # Validate allowed pattern if specified
          if attrs.allowed_pattern
            begin
              Regexp.new(attrs.allowed_pattern)
            rescue RegexpError => e
              raise Dry::Struct::Error, "Invalid allowed_pattern regular expression: #{e.message}"
            end
          end

          attrs
        end

        # Helper methods
        def is_secure_string?
          type == "SecureString"
        end

        def is_string_list?
          type == "StringList"
        end

        def is_string?
          type == "String"
        end

        def uses_kms_key?
          !key_id.nil?
        end

        def is_advanced_tier?
          tier == "Advanced"
        end

        def is_standard_tier?
          tier == "Standard"
        end

        def has_description?
          !description.nil?
        end

        def has_allowed_pattern?
          !allowed_pattern.nil?
        end

        def has_data_type?
          !data_type.nil?
        end

        def allows_overwrite?
          overwrite
        end

        def is_hierarchical?
          name.include?('/')
        end

        def parameter_path
          return '/' unless is_hierarchical?
          parts = name.split('/')[0...-1]
          parts.empty? ? '/' : parts.join('/')
        end

        def parameter_name_only
          return name unless is_hierarchical?
          name.split('/').last
        end

        def string_list_values
          return [] unless is_string_list?
          value.split(',').map(&:strip)
        end

        def estimated_monthly_cost
          # SSM Parameter Store pricing
          base_cost = 0.0
          
          if is_advanced_tier?
            base_cost = 0.05 # $0.05 per parameter per month for Advanced
          # Standard tier parameters are free
          end
          
          if is_advanced_tier?
            "~$#{base_cost}/month"
          else
            "Free (Standard tier)"
          end
        end
      end

      # Common SSM Parameter configurations
      module SsmParameterConfigs
        # Simple string parameter
        def self.string_parameter(name, value, description: nil)
          {
            name: name,
            type: "String",
            value: value,
            description: description,
            tier: "Standard"
          }.compact
        end

        # Secure string parameter with KMS encryption
        def self.secure_parameter(name, value, key_id: nil, description: nil)
          {
            name: name,
            type: "SecureString",
            value: value,
            key_id: key_id,
            description: description,
            tier: "Standard"
          }.compact
        end

        # String list parameter
        def self.string_list_parameter(name, values, description: nil)
          {
            name: name,
            type: "StringList",
            value: values.is_a?(Array) ? values.join(',') : values,
            description: description,
            tier: "Standard"
          }.compact
        end

        # Configuration parameter with validation pattern
        def self.config_parameter(name, value, pattern, description: nil)
          {
            name: name,
            type: "String",
            value: value,
            allowed_pattern: pattern,
            description: description,
            tier: "Standard"
          }.compact
        end

        # Advanced tier parameter for large values
        def self.advanced_parameter(name, value, description: nil)
          {
            name: name,
            type: "String",
            value: value,
            description: description,
            tier: "Advanced"
          }.compact
        end

        # Database connection parameter
        def self.database_config_parameter(name, connection_string, key_id: nil)
          {
            name: name,
            type: "SecureString",
            value: connection_string,
            key_id: key_id,
            description: "Database connection configuration",
            tier: "Standard"
          }.compact
        end

        # Application configuration parameter
        def self.app_config_parameter(name, config_json, description: nil)
          {
            name: name,
            type: "String",
            value: config_json,
            description: description,
            data_type: "text",
            tier: config_json.bytesize > 4096 ? "Advanced" : "Standard"
          }.compact
        end

        # AMI ID parameter
        def self.ami_parameter(name, ami_id, description: nil)
          {
            name: name,
            type: "String",
            value: ami_id,
            description: description,
            data_type: "aws:ec2:image",
            allowed_pattern: "^ami-[a-z0-9]{8,17}$"
          }.compact
        end
      end
    end
      end
    end
  end
end