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
        # Query-related helper methods for BlockchainTokenBalanceAttributes
        module BlockchainTokenBalanceQueryHelpers
          def is_historical_query?
            !at_block_number.nil?
          end

          def has_wallet_address?
            !wallet_address.nil?
          end

          def has_token_contract?
            !token_contract_address.nil?
          end

          def query_scope
            if has_wallet_address? && has_token_contract?
              'wallet_token_balance'
            elsif has_wallet_address?
              'wallet_all_balances'
            elsif has_token_contract?
              'token_holders'
            else
              'unknown'
            end
          end

          def estimated_result_size
            case query_scope
            when 'wallet_token_balance'
              'small'
            when 'wallet_all_balances'
              'medium'
            when 'token_holders'
              'large'
            else
              'unknown'
            end
          end

          def estimated_query_cost
            base_cost = network_costs[blockchain_network] || 0.01
            historical_multiplier = is_historical_query? ? 2.0 : 1.0
            token_multiplier = is_native_token? ? 1.0 : 1.5

            base_cost * historical_multiplier * token_multiplier
          end

          def privacy_score
            score = 50
            score -= 20 if is_testnet_query?
            score += 10 if is_historical_query?
            score += 15 if has_wallet_address?
            score -= 5 if has_token_contract? && !has_wallet_address?
            score += 10 if is_non_fungible?
            [score, 0].max
          end

          private

          def network_costs
            {
              'ETHEREUM_MAINNET' => 0.02,
              'ETHEREUM_GOERLI_TESTNET' => 0.002,
              'BITCOIN_MAINNET' => 0.015,
              'BITCOIN_TESTNET' => 0.0015,
              'POLYGON_MAINNET' => 0.01,
              'POLYGON_MUMBAI_TESTNET' => 0.001
            }
          end
        end
      end
    end
  end
end
