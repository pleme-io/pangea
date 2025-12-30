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
require_relative 'types/predicates'
require_relative 'types/uri_helpers'
require_relative 'types/factory_methods'
require_relative 'types/validators'

module Pangea
  module Resources
    module AWS
      module Types
        # API Gateway Integration attributes with validation
        class ApiGatewayIntegrationAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Include instance methods from modules
          include ApiGatewayIntegrationPredicates
          include ApiGatewayIntegrationUriHelpers

          # Extend with class factory methods
          extend ApiGatewayIntegrationFactoryMethods

          # Core attributes
          attribute :rest_api_id, Pangea::Resources::Types::String
          attribute :resource_id, Pangea::Resources::Types::String
          attribute :http_method, Pangea::Resources::Types::String.constrained(
            included_in: %w[GET POST PUT DELETE OPTIONS HEAD PATCH ANY]
          )

          # Integration type and configuration
          attribute :type, Pangea::Resources::Types::String.constrained(
            included_in: %w[MOCK HTTP HTTP_PROXY AWS AWS_PROXY]
          )
          attribute :integration_http_method, Pangea::Resources::Types::String.optional.default(nil)
          attribute :uri, Pangea::Resources::Types::String.optional.default(nil)

          # Connection details
          attribute :connection_type, Pangea::Resources::Types::String.default('INTERNET').constrained(
            included_in: %w[INTERNET VPC_LINK]
          )
          attribute :connection_id, Pangea::Resources::Types::String.optional.default(nil)

          # Credentials and caching
          attribute :credentials, Pangea::Resources::Types::String.optional.default(nil)
          attribute :cache_key_parameters, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::String
          ).default([].freeze)
          attribute :cache_namespace, Pangea::Resources::Types::String.optional.default(nil)

          # Request configuration
          attribute :request_templates, Pangea::Resources::Types::Hash.map(
            Pangea::Resources::Types::String, Pangea::Resources::Types::String
          ).default({}.freeze)

          attribute :request_parameters, Pangea::Resources::Types::Hash.map(
            Pangea::Resources::Types::String, Pangea::Resources::Types::String
          ).default({}.freeze)

          # Response passthrough for proxy integrations
          attribute :passthrough_behavior, Pangea::Resources::Types::String.default('WHEN_NO_MATCH').constrained(
            included_in: %w[WHEN_NO_MATCH WHEN_NO_TEMPLATES NEVER]
          )

          # Content handling
          attribute :content_handling, Pangea::Resources::Types::String.optional.default(nil)

          # Timeout configuration
          attribute :timeout_milliseconds, Pangea::Resources::Types::Integer.default(29_000).constrained(
            gteq: 50, lteq: 29_000
          )

          # Custom validation using extracted validators module
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            ApiGatewayIntegrationValidators.validate_attributes(attrs)
            super(attrs)
          end
        end
      end
    end
  end
end
