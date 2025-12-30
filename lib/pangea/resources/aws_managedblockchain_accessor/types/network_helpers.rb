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
        # Network-related helper methods for ManagedBlockchainAccessorAttributes
        module NetworkHelpers
          def is_ethereum_accessor?
            return true unless network_type
            network_type.include?('ETHEREUM')
          end

          def is_hyperledger_accessor?
            # Currently, accessors are primarily for Ethereum
            # This method is future-proofed for Hyperledger support
            false
          end

          def supports_mainnet?
            return true unless network_type
            network_type.include?('MAINNET')
          end

          def supports_testnet?
            return true unless network_type
            network_type.include?('TESTNET') || network_type.include?('GOERLI') || network_type.include?('MUMBAI')
          end

          def blockchain_framework
            return 'unknown' unless network_type

            case network_type
            when /ETHEREUM/
              'ethereum'
            when /POLYGON/
              'polygon'
            else
              'unknown'
            end
          end

          def network_environment
            return 'unknown' unless network_type

            if supports_mainnet?
              'production'
            elsif supports_testnet?
              'testing'
            else
              'unknown'
            end
          end

          def is_production_network?
            network_environment == 'production'
          end

          def is_test_network?
            network_environment == 'testing'
          end

          # Get the specific testnet name if applicable
          def testnet_name
            return nil unless supports_testnet?

            case network_type
            when 'ETHEREUM_GOERLI_TESTNET'
              'goerli'
            when 'ETHEREUM_RINKEBY_TESTNET'
              'rinkeby'
            when 'POLYGON_MUMBAI_TESTNET'
              'mumbai'
            else
              'unknown'
            end
          end
        end
      end
    end
  end
end
