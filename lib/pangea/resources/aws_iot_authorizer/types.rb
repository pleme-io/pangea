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
    # AWS IoT Authorizer Types
    # 
    # Custom authorizers enable authentication and authorization using custom logic,
    # tokens, or third-party identity providers beyond X.509 certificates. This enables
    # flexible authentication patterns for diverse IoT use cases.
    module AwsIotAuthorizerTypes
      # Token key name configuration for custom tokens
      class TokenKeyName < Dry::Struct
        schema schema.strict

        # Name of the key to extract from the token
        attribute :key, Resources::Types::String
      end

      # Main attributes for IoT authorizer resource
      class Attributes < Dry::Struct
        schema schema.strict

        # Name of the custom authorizer
        attribute :name, Resources::Types::String

        # ARN of Lambda function that implements authorization logic
        attribute :authorizer_function_arn, Resources::Types::String

        # Signing disabled flag (if true, signature validation is skipped)
        attribute :signing_disabled, Resources::Types::Bool.optional

        # Status of the authorizer (ACTIVE or INACTIVE)
        attribute :status, Resources::Types::String.enum('ACTIVE', 'INACTIVE').optional

        # Token key name for extracting tokens from requests
        attribute :token_key_name, Resources::Types::String.optional

        # Token signing public keys for signature validation
        attribute :token_signing_public_keys, Resources::Types::Hash.map(Types::String, Types::String).optional

        # Whether to enable caching for authorizer results
        attribute :enable_caching_for_http, Resources::Types::Bool.optional

        # Resource tags for organization and billing
        attribute :tags, Resources::Types::Hash.map(Types::String, Types::String).optional
      end

      # Output attributes from authorizer resource
      class Outputs < Dry::Struct
        schema schema.strict

        # The authorizer ARN
        attribute :arn, Resources::Types::String

        # The authorizer name
        attribute :name, Resources::Types::String

        # The unique authorizer ID
        attribute :id, Resources::Types::String
      end
    end
  end
end