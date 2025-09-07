# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS Blockchain Token Balance data source
      class BlockchainTokenBalanceAttributes < Dry::Struct
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

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # At least one of wallet_address or token_contract_address is required
          unless attrs.wallet_address || attrs.token_contract_address
            raise Dry::Struct::Error, "Either wallet_address or token_contract_address must be provided"
          end

          # Validate wallet address format if provided
          if attrs.wallet_address
            unless attrs.wallet_address.match?(/\A0x[a-fA-F0-9]{40}\z/)
              raise Dry::Struct::Error, "wallet_address must be a valid Ethereum-style address (0x followed by 40 hex characters)"
            end
          end

          # Validate token contract address format if provided
          if attrs.token_contract_address
            unless attrs.token_contract_address.match?(/\A0x[a-fA-F0-9]{40}\z/)
              raise Dry::Struct::Error, "token_contract_address must be a valid Ethereum-style address (0x followed by 40 hex characters)"
            end
          end

          # Validate token standard compatibility with network
          if attrs.token_standard
            case attrs.blockchain_network
            when /ETHEREUM|POLYGON/
              # Ethereum and Polygon support ERC standards
              unless ['ERC20', 'ERC721', 'ERC1155', 'NATIVE'].include?(attrs.token_standard)
                raise Dry::Struct::Error, "#{attrs.blockchain_network} supports ERC20, ERC721, ERC1155, and NATIVE token standards"
              end
            when /BITCOIN/
              # Bitcoin only supports native tokens
              unless attrs.token_standard == 'NATIVE'
                raise Dry::Struct::Error, "Bitcoin networks only support NATIVE token standard"
              end
            end
          end

          # Validate block number reasonableness
          if attrs.at_block_number
            if attrs.at_block_number > 50000000 # Sanity check for reasonable block numbers
              raise Dry::Struct::Error, "at_block_number seems unreasonably high"
            end
          end

          attrs
        end

        # Helper methods
        def is_native_token?
          token_standard == 'NATIVE' || token_contract_address.nil?
        end

        def is_erc20_token?
          token_standard == 'ERC20'
        end

        def is_erc721_token?
          token_standard == 'ERC721'
        end

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

        def is_historical_query?
          !at_block_number.nil?
        end

        def is_mainnet_query?
          blockchain_network.include?('MAINNET')
        end

        def estimated_query_cost
          # Base cost per network (USD)
          network_costs = {
            'ETHEREUM_MAINNET' => 0.02,
            'ETHEREUM_GOERLI_TESTNET' => 0.002,
            'BITCOIN_MAINNET' => 0.015,
            'BITCOIN_TESTNET' => 0.0015,
            'POLYGON_MAINNET' => 0.01,
            'POLYGON_MUMBAI_TESTNET' => 0.001
          }

          base_cost = network_costs[blockchain_network] || 0.01

          # Historical queries cost more
          historical_multiplier = is_historical_query? ? 2.0 : 1.0

          # Token contract queries cost slightly more than native
          token_multiplier = is_native_token? ? 1.0 : 1.5

          base_cost * historical_multiplier * token_multiplier
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

        def is_testnet_query?
          !is_mainnet_query?
        end

        def supports_decimals?
          # ERC20 and native tokens typically have decimals
          ['ERC20', 'BEP20', 'NATIVE'].include?(token_standard)
        end

        def supports_metadata?
          # NFT standards support metadata
          ['ERC721', 'ERC1155'].include?(token_standard)
        end

        def is_fungible?
          token_type == 'fungible_token' || token_type == 'native_cryptocurrency'
        end

        def is_non_fungible?
          token_type == 'non_fungible_token'
        end

        # Get network chain ID
        def chain_id
          case blockchain_network
          when 'ETHEREUM_MAINNET'
            1
          when 'ETHEREUM_GOERLI_TESTNET'
            5
          when 'POLYGON_MAINNET'
            137
          when 'POLYGON_MUMBAI_TESTNET'
            80001
          when 'BITCOIN_MAINNET'
            0 # Bitcoin doesn't use chain IDs like Ethereum
          when 'BITCOIN_TESTNET'
            1 # Bitcoin testnet
          else
            -1
          end
        end

        # Check if the query involves a wallet
        def has_wallet_address?
          !wallet_address.nil?
        end

        # Check if the query involves a specific token
        def has_token_contract?
          !token_contract_address.nil?
        end

        # Get query scope
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

        # Estimate result size
        def estimated_result_size
          case query_scope
          when 'wallet_token_balance'
            'small' # Single balance value
          when 'wallet_all_balances'
            'medium' # Multiple token balances for one wallet
          when 'token_holders'
            'large' # All holders of a token
          else
            'unknown'
          end
        end

        # Calculate privacy score (lower is more private)
        def privacy_score
          score = 50
          
          # Testnet queries are more private
          score -= 20 if is_testnet_query?
          
          # Historical queries can be less private (more analysis)
          score += 10 if is_historical_query?
          
          # Token contract queries expose less personal info than wallet queries
          score += 15 if has_wallet_address?
          score -= 5 if has_token_contract? && !has_wallet_address?
          
          # NFT queries are more identifiable
          score += 10 if is_non_fungible?
          
          [score, 0].max
        end

        # Check if query supports USD valuation
        def supports_usd_valuation?
          # Mainnet tokens typically have price feeds
          is_mainnet_query? && ['ERC20', 'NATIVE'].include?(token_standard)
        end

        # Get typical decimal places for the token type
        def typical_decimals
          case token_standard
          when 'ERC20', 'BEP20'
            18 # Most ERC20 tokens use 18 decimals
          when 'NATIVE'
            case blockchain_protocol
            when 'ethereum', 'polygon'
              18 # ETH and MATIC use 18 decimals
            when 'bitcoin'
              8 # Bitcoin uses 8 decimals (satoshis)
            else
              18
            end
          when 'ERC721', 'ERC1155'
            0 # NFTs don't use decimals
          else
            18
          end
        end
      end
    end
      end
    end
  end
end