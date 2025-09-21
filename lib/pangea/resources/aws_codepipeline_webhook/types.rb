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
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS CodePipeline Webhook resources
      class CodePipelineWebhookAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Webhook name (required)
        attribute :name, Resources::Types::String.constrained(
          format: /\A[A-Za-z0-9][A-Za-z0-9\-_]*\z/,
          min_size: 1,
          max_size: 100
        )

        # Target pipeline (required)
        attribute :target_pipeline, Resources::Types::String

        # Target action (required)
        attribute :target_action, Resources::Types::String

        # Authentication type
        attribute :authentication, Resources::Types::String.enum('GITHUB_HMAC', 'IP', 'UNAUTHENTICATED').default('GITHUB_HMAC')

        # Authentication configuration
        attribute :authentication_configuration, Resources::Types::Hash.schema(
          secret_token?: Resources::Types::String.optional,
          allowed_ip_range?: Resources::Types::String.optional
        ).default({}.freeze)

        # Filters
        attribute :filters, Resources::Types::Array.of(
          Resources::Types::Hash.schema(
            json_path: Resources::Types::String,
            match_equals?: Resources::Types::String.optional
          )
        ).constrained(min_size: 1)

        # Tags
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate authentication configuration
          case attrs.authentication
          when 'GITHUB_HMAC'
            if attrs.authentication_configuration[:secret_token].nil?
              raise Dry::Struct::Error, "GITHUB_HMAC authentication requires secret_token"
            end
          when 'IP'
            if attrs.authentication_configuration[:allowed_ip_range].nil?
              raise Dry::Struct::Error, "IP authentication requires allowed_ip_range"
            end
          when 'UNAUTHENTICATED'
            if attrs.authentication_configuration.any?
              raise Dry::Struct::Error, "UNAUTHENTICATED cannot have authentication_configuration"
            end
          end

          # Validate filters have valid JSON paths
          attrs.filters.each do |filter|
            unless filter[:json_path].start_with?('$')
              raise Dry::Struct::Error, "JSON path must start with '$': #{filter[:json_path]}"
            end
          end

          attrs
        end

        # Helper methods
        def github_authentication?
          authentication == 'GITHUB_HMAC'
        end

        def ip_authentication?
          authentication == 'IP'
        end

        def unauthenticated?
          authentication == 'UNAUTHENTICATED'
        end

        def filter_count
          filters.size
        end

        def has_secret?
          authentication_configuration[:secret_token].present?
        end

        def filter_descriptions
          filters.map do |filter|
            if filter[:match_equals]
              "#{filter[:json_path]} equals '#{filter[:match_equals]}'"
            else
              "#{filter[:json_path]} exists"
            end
          end
        end

        def security_level
          case authentication
          when 'GITHUB_HMAC' then 'High (HMAC signature)'
          when 'IP' then 'Medium (IP allowlist)'
          when 'UNAUTHENTICATED' then 'Low (no authentication)'
          end
        end
      end
    end
      end
    end
  end
end