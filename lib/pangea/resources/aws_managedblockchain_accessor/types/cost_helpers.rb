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
        # Cost and security helper methods for ManagedBlockchainAccessorAttributes
        module CostHelpers
          def has_billing_token?
            !billing_token.nil?
          end

          def estimated_monthly_cost
            # Base cost for blockchain access (rough estimates in USD)
            base_cost = case network_type
            when 'ETHEREUM_MAINNET'
              500.0  # Higher cost for mainnet access
            when 'ETHEREUM_GOERLI_TESTNET', 'ETHEREUM_RINKEBY_TESTNET'
              50.0   # Lower cost for testnet access
            when 'POLYGON_MAINNET'
              200.0  # Moderate cost for Polygon mainnet
            when 'POLYGON_MUMBAI_TESTNET'
              20.0   # Low cost for Polygon testnet
            else
              100.0  # Default cost
            end

            # Add billing token premium if applicable
            billing_premium = has_billing_token? ? 50.0 : 0.0

            base_cost + billing_premium
          end

          # Calculate security score based on network
          def security_score
            score = 100

            # Production networks are more secure
            score += 20 if is_production_network?
            score -= 10 if is_test_network?

            # Ethereum has higher security due to larger validator set
            score += 15 if blockchain_framework == 'ethereum'
            score += 10 if blockchain_framework == 'polygon'

            # Billing token adds security
            score += 5 if has_billing_token?

            [score, 0].max
          end
        end
      end
    end
  end
end
