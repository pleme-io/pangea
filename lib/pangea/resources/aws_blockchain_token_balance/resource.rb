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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_blockchain_token_balance/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Query AWS Blockchain Token Balance for cryptocurrency and token analysis
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Token balance query attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_blockchain_token_balance(name, attributes = {})
        # Validate attributes using dry-struct
        balance_attrs = Types::BlockchainTokenBalanceAttributes.new(attributes)
        
        # Generate terraform data source block via terraform-synthesizer
        data(:aws_blockchain_token_balance, name) do
          # Set blockchain network
          blockchain_network balance_attrs.blockchain_network
          
          # Set wallet address or token contract
          if balance_attrs.wallet_address
            wallet_address balance_attrs.wallet_address
          end
          
          if balance_attrs.token_contract_address
            token_contract_address balance_attrs.token_contract_address
          end
          
          # Set block number for historical queries
          if balance_attrs.at_block_number
            at_block_number balance_attrs.at_block_number
          end
          
          # Set token standard if provided
          if balance_attrs.token_standard
            token_standard balance_attrs.token_standard
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_blockchain_token_balance',
          name: name,
          resource_attributes: balance_attrs.to_h,
          outputs: {
            id: "${data.aws_blockchain_token_balance.#{name}.id}",
            wallet_address: "${data.aws_blockchain_token_balance.#{name}.wallet_address}",
            token_contract_address: "${data.aws_blockchain_token_balance.#{name}.token_contract_address}",
            balance: "${data.aws_blockchain_token_balance.#{name}.balance}",
            token_symbol: "${data.aws_blockchain_token_balance.#{name}.token_symbol}",
            token_name: "${data.aws_blockchain_token_balance.#{name}.token_name}",
            token_decimals: "${data.aws_blockchain_token_balance.#{name}.token_decimals}",
            block_number: "${data.aws_blockchain_token_balance.#{name}.block_number}",
            block_timestamp: "${data.aws_blockchain_token_balance.#{name}.block_timestamp}",
            balance_usd_value: "${data.aws_blockchain_token_balance.#{name}.balance_usd_value}"
          },
          computed: {
            is_native_token: balance_attrs.is_native_token?,
            is_erc20_token: balance_attrs.is_erc20_token?,
            is_erc721_token: balance_attrs.is_erc721_token?,
            blockchain_protocol: balance_attrs.blockchain_protocol,
            is_historical_query: balance_attrs.is_historical_query?,
            is_mainnet_query: balance_attrs.is_mainnet_query?,
            estimated_query_cost: balance_attrs.estimated_query_cost,
            token_type: balance_attrs.token_type,
            network_native_symbol: balance_attrs.network_native_symbol
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)