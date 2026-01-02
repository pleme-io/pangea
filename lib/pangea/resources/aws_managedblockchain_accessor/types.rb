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
require_relative 'types/network_helpers'
require_relative 'types/blockchain_helpers'
require_relative 'types/cost_helpers'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS Managed Blockchain Accessor resources
        class ManagedBlockchainAccessorAttributes < Dry::Struct
          include NetworkHelpers
          include BlockchainHelpers
          include CostHelpers

          transform_keys(&:to_sym)

          # Accessor type (required)
          attribute :accessor_type, Resources::Types::String.enum(
            'BILLING_TOKEN'  # Current supported type for Ethereum
          )

          # Network type (optional)
          attribute? :network_type, Resources::Types::String.enum(
            'ETHEREUM_MAINNET',
            'ETHEREUM_GOERLI_TESTNET',
            'ETHEREUM_RINKEBY_TESTNET',
            'POLYGON_MAINNET',
            'POLYGON_MUMBAI_TESTNET'
          ).optional

          # Billing token (optional)
          attribute? :billing_token, Resources::Types::String.optional

          # Tags (optional)
          attribute? :tags, Resources::Types::Hash.schema(
            Resources::Types::String => Resources::Types::String
          ).optional

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)

            # Validate billing token requirement for BILLING_TOKEN accessor type
            if attrs.accessor_type == 'BILLING_TOKEN'
              unless attrs.billing_token
                raise Dry::Struct::Error, "billing_token is required for BILLING_TOKEN accessor type"
              end

              unless attrs.billing_token.match?(/\A[a-zA-Z0-9\-_]{1,64}\z/)
                raise Dry::Struct::Error, "billing_token must be 1-64 characters long and contain only alphanumeric characters, hyphens, and underscores"
              end
            end

            # Validate network type consistency
            if attrs.network_type
              case attrs.network_type
              when 'ETHEREUM_MAINNET', 'ETHEREUM_GOERLI_TESTNET', 'ETHEREUM_RINKEBY_TESTNET'
                # Ethereum networks are supported
              when 'POLYGON_MAINNET', 'POLYGON_MUMBAI_TESTNET'
                # Polygon networks are supported
              else
                raise Dry::Struct::Error, "Unsupported network type: #{attrs.network_type}"
              end
            end

            attrs
          end
        end
      end
    end
  end
end
