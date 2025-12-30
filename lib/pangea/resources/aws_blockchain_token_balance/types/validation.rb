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
        # Validation class methods for BlockchainTokenBalanceAttributes
        module BlockchainTokenBalanceValidation
          ETHEREUM_ADDRESS_REGEX = /\A0x[a-fA-F0-9]{40}\z/
          MAX_BLOCK_NUMBER = 50_000_000

          def validate_required_address(attrs)
            return if attrs.wallet_address || attrs.token_contract_address

            raise Dry::Struct::Error,
                  'Either wallet_address or token_contract_address must be provided'
          end

          def validate_wallet_address(attrs)
            return unless attrs.wallet_address
            return if attrs.wallet_address.match?(ETHEREUM_ADDRESS_REGEX)

            raise Dry::Struct::Error,
                  'wallet_address must be a valid Ethereum-style address (0x followed by 40 hex characters)'
          end

          def validate_token_contract_address(attrs)
            return unless attrs.token_contract_address
            return if attrs.token_contract_address.match?(ETHEREUM_ADDRESS_REGEX)

            raise Dry::Struct::Error,
                  'token_contract_address must be a valid Ethereum-style address (0x followed by 40 hex characters)'
          end

          def validate_token_standard_compatibility(attrs)
            return unless attrs.token_standard

            case attrs.blockchain_network
            when /ETHEREUM|POLYGON/
              validate_evm_token_standard(attrs)
            when /BITCOIN/
              validate_bitcoin_token_standard(attrs)
            end
          end

          def validate_block_number(attrs)
            return unless attrs.at_block_number
            return if attrs.at_block_number <= MAX_BLOCK_NUMBER

            raise Dry::Struct::Error, 'at_block_number seems unreasonably high'
          end

          private

          def validate_evm_token_standard(attrs)
            valid_standards = %w[ERC20 ERC721 ERC1155 NATIVE]
            return if valid_standards.include?(attrs.token_standard)

            raise Dry::Struct::Error,
                  "#{attrs.blockchain_network} supports ERC20, ERC721, ERC1155, and NATIVE token standards"
          end

          def validate_bitcoin_token_standard(attrs)
            return if attrs.token_standard == 'NATIVE'

            raise Dry::Struct::Error, 'Bitcoin networks only support NATIVE token standard'
          end
        end
      end
    end
  end
end
