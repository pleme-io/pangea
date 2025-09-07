# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS Managed Blockchain Accessor resources
      class ManagedBlockchainAccessorAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Accessor type (required)
        attribute :accessor_type, Resources::Types::String.enum(
          'BILLING_TOKEN'  # Current supported type for Ethereum
        )

        # Network type (optional)
        attribute? :network_type, Resources::Types::String.enum(
          'ETHEREUM_MAINNET',
          'ETHEREUM_GOERLI_TESTNET',
          'ETHEREUM_RINKEBY_TESTNET',
          'POLYGON_MAINNET', 
          'POLYGON_MUMBAI_TESTNET'
        ).optional

        # Billing token (optional)
        attribute? :billing_token, Resources::Types::String.optional

        # Tags (optional)
        attribute? :tags, Resources::Types::Hash.schema(
          Resources::Types::String => Resources::Types::String
        ).optional

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate billing token requirement for BILLING_TOKEN accessor type
          if attrs.accessor_type == 'BILLING_TOKEN'
            unless attrs.billing_token
              raise Dry::Struct::Error, "billing_token is required for BILLING_TOKEN accessor type"
            end
            
            unless attrs.billing_token.match?(/\A[a-zA-Z0-9\-_]{1,64}\z/)
              raise Dry::Struct::Error, "billing_token must be 1-64 characters long and contain only alphanumeric characters, hyphens, and underscores"
            end
          end

          # Validate network type consistency
          if attrs.network_type
            case attrs.network_type
            when 'ETHEREUM_MAINNET', 'ETHEREUM_GOERLI_TESTNET', 'ETHEREUM_RINKEBY_TESTNET'
              # Ethereum networks are supported
            when 'POLYGON_MAINNET', 'POLYGON_MUMBAI_TESTNET'
              # Polygon networks are supported
            else
              raise Dry::Struct::Error, "Unsupported network type: #{attrs.network_type}"
            end
          end

          attrs
        end

        # Helper methods
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

        def access_type
          case accessor_type
          when 'BILLING_TOKEN'
            'token_based'
          else
            'unknown'
          end
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
end