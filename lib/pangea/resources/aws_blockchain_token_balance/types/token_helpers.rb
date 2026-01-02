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
        # Token-related helper methods for BlockchainTokenBalanceAttributes
        module BlockchainTokenBalanceTokenHelpers
          def is_native_token?
            token_standard == 'NATIVE' || token_contract_address.nil?
          end

          def is_erc20_token?
            token_standard == 'ERC20'
          end

          def is_erc721_token?
            token_standard == 'ERC721'
          end

          def token_type
            case token_standard
            when 'ERC20', 'BEP20'
              'fungible_token'
            when 'ERC721'
              'non_fungible_token'
            when 'ERC1155'
              'multi_token'
            when 'NATIVE'
              'native_cryptocurrency'
            else
              'unknown'
            end
          end

          def supports_decimals?
            ['ERC20', 'BEP20', 'NATIVE'].include?(token_standard)
          end

          def supports_metadata?
            ['ERC721', 'ERC1155'].include?(token_standard)
          end

          def is_fungible?
            token_type == 'fungible_token' || token_type == 'native_cryptocurrency'
          end

          def is_non_fungible?
            token_type == 'non_fungible_token'
          end

          def typical_decimals
            case token_standard
            when 'ERC20', 'BEP20'
              18
            when 'NATIVE'
              case blockchain_protocol
              when 'ethereum', 'polygon'
                18
              when 'bitcoin'
                8
              else
                18
              end
            when 'ERC721', 'ERC1155'
              0
            else
              18
            end
          end
        end
      end
    end
  end
end
