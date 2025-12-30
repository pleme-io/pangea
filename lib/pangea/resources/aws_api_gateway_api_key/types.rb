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
require_relative 'types/configs'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS API Gateway API Key resources
        class ApiGatewayApiKeyAttributes < Dry::Struct
          # Name for the API key
          attribute :name, Resources::Types::String

          # Description of the API key
          attribute :description, Resources::Types::String.optional

          # Whether the API key is enabled
          attribute :enabled, Resources::Types::Bool.default(true)

          # API key value (if provided, otherwise auto-generated)
          attribute :value, Resources::Types::String.optional

          # Tags to apply to the API key
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)

            # Validate name format
            unless attrs.name.match?(/\A[a-zA-Z0-9\-_]{1,128}\z/)
              raise Dry::Struct::Error, "API key name must be 1-128 characters and contain only alphanumeric, hyphens, and underscores"
            end

            # Validate API key value format if provided
            if attrs.value
              unless attrs.value.match?(/\A[a-zA-Z0-9]{20,128}\z/)
                raise Dry::Struct::Error, "API key value must be 20-128 characters and contain only alphanumeric characters"
              end
            end

            # Set default description if not provided
            unless attrs.description
              status = attrs.enabled ? "Active" : "Disabled"
              attrs = attrs.copy_with(description: "#{status} API key for #{attrs.name}")
            end

            attrs
          end

          # Helper methods
          def active?
            enabled
          end

          def disabled?
            !enabled
          end

          def custom_value?
            !value.nil?
          end

          def auto_generated_value?
            value.nil?
          end

          def estimated_monthly_cost
            "$0.00 (no additional charge for API keys)"
          end

          def validate_configuration
            warnings = []

            if disabled?
              warnings << "API key is disabled - remember to enable for production use"
            end

            if name.length < 3
              warnings << "Very short API key name - consider more descriptive naming"
            end

            if custom_value? && value.length < 32
              warnings << "Short custom API key value - consider longer keys for better security"
            end

            unless description&.include?(name) || description&.include?('purpose')
              warnings << "API key description should include purpose or context"
            end

            warnings
          end

          # Get security assessment
          def security_level
            return 'low' if disabled?

            if custom_value?
              case value.length
              when 20..31
                'medium'
              when 32..63
                'high'
              else
                'very_high'
              end
            else
              'high' # AWS-generated keys are secure
            end
          end

          # Check if suitable for production
          def production_ready?
            enabled && name.length >= 5
          end

          # Get key status
          def status
            enabled ? 'active' : 'disabled'
          end

          # Get key type
          def key_type
            custom_value? ? 'custom' : 'auto_generated'
          end
        end
      end
    end
  end
end
