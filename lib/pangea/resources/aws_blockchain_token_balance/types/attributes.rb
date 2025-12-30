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

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS Blockchain Token Balance data source
        class BlockchainTokenBalanceAttributes < Dry::Struct
          extend BlockchainTokenBalanceValidation
          include BlockchainTokenBalanceTokenHelpers
          include BlockchainTokenBalanceNetworkHelpers
          include BlockchainTokenBalanceQueryHelpers

          transform_keys(&:to_sym)

          # Blockchain network (required)
          attribute :blockchain_network, Resources::Types::String.enum(
            'ETHEREUM_MAINNET',
            'ETHEREUM_GOERLI_TESTNET',
            'BITCOIN_MAINNET',
            'BITCOIN_TESTNET',
            'POLYGON_MAINNET',
            'POLYGON_MUMBAI_TESTNET'
          )

          # Wallet address (optional, but required if token_contract_address not provided)
          attribute? :wallet_address, Resources::Types::String.optional

          # Token contract address (optional)
          attribute? :token_contract_address, Resources::Types::String.optional

          # Block number for historical queries (optional)
          attribute? :at_block_number, Resources::Types::Integer.constrained(gteq: 0).optional

          # Token standard (optional)
          attribute? :token_standard, Resources::Types::String.enum(
            'ERC20',
            'ERC721',
            'ERC1155',
            'BEP20',
            'NATIVE'
          ).optional

          def self.new(attributes = {})
            attrs = super(attributes)
            validate_required_address(attrs)
            validate_wallet_address(attrs)
            validate_token_contract_address(attrs)
            validate_token_standard_compatibility(attrs)
            validate_block_number(attrs)
            attrs
          end
        end
      end
    end
  end
end
