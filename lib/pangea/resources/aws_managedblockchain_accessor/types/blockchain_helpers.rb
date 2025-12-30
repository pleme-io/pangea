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
        # Blockchain characteristics helper methods for ManagedBlockchainAccessorAttributes
        module BlockchainHelpers
          def access_type
            case accessor_type
            when 'BILLING_TOKEN'
              'token_based'
            else
              'unknown'
            end
          end

          # Check if accessor supports smart contracts
          def supports_smart_contracts?
            # All Ethereum and Polygon networks support smart contracts
            ['ethereum', 'polygon'].include?(blockchain_framework)
          end

          # Get the native token for the network
          def native_token
            case blockchain_framework
            when 'ethereum'
              'ETH'
            when 'polygon'
              'MATIC'
            else
              'UNKNOWN'
            end
          end

          # Estimate transaction throughput (TPS)
          def estimated_tps
            case blockchain_framework
            when 'ethereum'
              15  # Ethereum mainnet ~15 TPS
            when 'polygon'
              7000  # Polygon can handle ~7000 TPS
            else
              100
            end
          end

          # Get block confirmation time in seconds
          def block_confirmation_time_seconds
            case blockchain_framework
            when 'ethereum'
              12  # Ethereum block time ~12 seconds
            when 'polygon'
              2   # Polygon block time ~2 seconds
            else
              15
            end
          end
        end
      end
    end
  end
end
