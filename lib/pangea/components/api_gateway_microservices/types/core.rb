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
  module Components
    module ApiGatewayMicroservices
      # API method configuration
      class ApiMethodConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :path, Types::String
        attribute :method, Types::String.enum('GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS', 'HEAD', 'ANY')
        attribute :authorization, Types::String.default('NONE')
        attribute :api_key_required, Types::Bool.default(false)
        attribute :request_validator, Types::String.optional
        attribute :request_models, Types::Hash.default({}.freeze)
        attribute :request_parameters, Types::Hash.default({}.freeze)
      end

      # Service integration configuration
      class ServiceIntegration < Dry::Struct
        transform_keys(&:to_sym)

        attribute :type, Types::String.enum('HTTP', 'HTTP_PROXY', 'AWS', 'AWS_PROXY', 'MOCK')
        attribute :uri, Types::String
        attribute :connection_type, Types::String.enum('INTERNET', 'VPC_LINK').default('INTERNET')
        attribute :connection_id, Types::String.optional
        attribute :http_method, Types::String.default('ANY')
        attribute :timeout_milliseconds, Types::Integer.default(29_000)
        attribute :content_handling, Types::String.enum('CONVERT_TO_BINARY', 'CONVERT_TO_TEXT').optional
        attribute :passthrough_behavior, Types::String.default('WHEN_NO_MATCH')
        attribute :cache_key_parameters, Types::Array.of(Types::String).default([].freeze)
        attribute :cache_namespace, Types::String.optional
      end

      # Request/Response transformation
      class TransformationConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :request_templates, Types::Hash.default({}.freeze)
        attribute :response_templates, Types::Hash.default({}.freeze)
        attribute :response_parameters, Types::Hash.default({}.freeze)
        attribute :response_models, Types::Hash.default({}.freeze)
      end
    end
  end
end
