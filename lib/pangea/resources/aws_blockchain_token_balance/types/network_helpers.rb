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
        # Network-related helper methods for BlockchainTokenBalanceAttributes
        module BlockchainTokenBalanceNetworkHelpers
          def blockchain_protocol
            case blockchain_network
            when /ETHEREUM/
              'ethereum'
            when /BITCOIN/
              'bitcoin'
            when /POLYGON/
              'polygon'
            else
              'unknown'
            end
          end

          def is_mainnet_query?
            blockchain_network.include?('MAINNET')
          end

          def is_testnet_query?
            !is_mainnet_query?
          end

          def network_native_symbol
            case blockchain_protocol
            when 'ethereum'
              'ETH'
            when 'bitcoin'
              'BTC'
            when 'polygon'
              'MATIC'
            else
              'UNKNOWN'
            end
          end

          def chain_id
            case blockchain_network
            when 'ETHEREUM_MAINNET'
              1
            when 'ETHEREUM_GOERLI_TESTNET'
              5
            when 'POLYGON_MAINNET'
              137
            when 'POLYGON_MUMBAI_TESTNET'
              80_001
            when 'BITCOIN_MAINNET'
              0
            when 'BITCOIN_TESTNET'
              1
            else
              -1
            end
          end

          def supports_usd_valuation?
            is_mainnet_query? && ['ERC20', 'NATIVE'].include?(token_standard)
          end
        end
      end
    end
  end
end
