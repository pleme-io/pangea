# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS Managed Blockchain Network resources
      class ManagedBlockchainNetworkAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Network name (required)
        attribute :name, Resources::Types::String

        # Description (optional)
        attribute? :description, Resources::Types::String.optional

        # Framework (required)
        attribute :framework, Resources::Types::String.enum(
          'HYPERLEDGER_FABRIC',
          'ETHEREUM'
        )

        # Framework version (required)
        attribute :framework_version, Resources::Types::String

        # Framework configuration (required for Hyperledger Fabric)
        attribute? :framework_configuration, Resources::Types::Hash.schema(
          network_fabric_configuration?: Resources::Types::Hash.schema(
            edition: Resources::Types::String.enum('STARTER', 'STANDARD')
          ).optional,
          network_ethereum_configuration?: Resources::Types::Hash.schema(
            chain_id: Resources::Types::String
          ).optional
        ).optional

        # Voting policy (required for Hyperledger Fabric)
        attribute? :voting_policy, Resources::Types::Hash.schema(
          approval_threshold_policy?: Resources::Types::Hash.schema(
            threshold_percentage?: Resources::Types::Integer.constrained(gteq: 0, lteq: 100).optional,
            proposal_duration_in_hours?: Resources::Types::Integer.constrained(gteq: 1, lteq: 168).optional,
            threshold_comparator?: Resources::Types::String.enum('GREATER_THAN', 'GREATER_THAN_OR_EQUAL_TO').optional
          ).optional
        ).optional

        # Member configuration (required)
        attribute :member_configuration, Resources::Types::Hash.schema(
          name: Resources::Types::String,
          description?: Resources::Types::String.optional,
          framework_configuration: Resources::Types::Hash.schema(
            member_fabric_configuration?: Resources::Types::Hash.schema(
              admin_username: Resources::Types::String,
              admin_password: Resources::Types::String
            ).optional
          ),
          log_publishing_configuration?: Resources::Types::Hash.schema(
            fabric?: Resources::Types::Hash.schema(
              ca_logs?: Resources::Types::Hash.schema(
                cloudwatch?: Resources::Types::Hash.schema(
                  enabled?: Resources::Types::Bool.optional
                ).optional
              ).optional
            ).optional
          ).optional,
          tags?: Resources::Types::Hash.schema(
            Resources::Types::String => Resources::Types::String
          ).optional
        )

        # Tags (optional)
        attribute? :tags, Resources::Types::Hash.schema(
          Resources::Types::String => Resources::Types::String
        ).optional

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate network name format
          unless attrs.name.match?(/\A[a-zA-Z][a-zA-Z0-9]*\z/)
            raise Dry::Struct::Error, "name must start with a letter and contain only alphanumeric characters"
          end

          # Validate name length
          if attrs.name.length < 1 || attrs.name.length > 64
            raise Dry::Struct::Error, "name must be between 1 and 64 characters"
          end

          # Framework-specific validations
          case attrs.framework
          when 'HYPERLEDGER_FABRIC'
            validate_fabric_configuration(attrs)
          when 'ETHEREUM'
            validate_ethereum_configuration(attrs)
          end

          # Validate member name
          member_name = attrs.member_configuration[:name]
          unless member_name.match?(/\A[a-zA-Z][a-zA-Z0-9]*\z/)
            raise Dry::Struct::Error, "member name must start with a letter and contain only alphanumeric characters"
          end

          attrs
        end

        def self.validate_fabric_configuration(attrs)
          # Fabric requires framework configuration
          if attrs.framework_configuration.nil? || attrs.framework_configuration[:network_fabric_configuration].nil?
            raise Dry::Struct::Error, "network_fabric_configuration is required for Hyperledger Fabric networks"
          end

          # Fabric requires voting policy
          if attrs.voting_policy.nil?
            raise Dry::Struct::Error, "voting_policy is required for Hyperledger Fabric networks"
          end

          # Validate framework version for Fabric
          valid_fabric_versions = ['1.2', '1.4', '2.2', '2.5']
          unless valid_fabric_versions.include?(attrs.framework_version)
            raise Dry::Struct::Error, "framework_version must be one of: #{valid_fabric_versions.join(', ')} for Hyperledger Fabric"
          end

          # Validate member configuration for Fabric
          member_fabric_config = attrs.member_configuration[:framework_configuration][:member_fabric_configuration]
          if member_fabric_config.nil?
            raise Dry::Struct::Error, "member_fabric_configuration is required for Hyperledger Fabric members"
          end

          # Validate admin credentials
          admin_username = member_fabric_config[:admin_username]
          admin_password = member_fabric_config[:admin_password]

          unless admin_username.match?(/\A[a-zA-Z0-9]+\z/)
            raise Dry::Struct::Error, "admin_username must contain only alphanumeric characters"
          end

          if admin_password.length < 8
            raise Dry::Struct::Error, "admin_password must be at least 8 characters long"
          end
        end

        def self.validate_ethereum_configuration(attrs)
          # Ethereum requires framework configuration
          if attrs.framework_configuration.nil? || attrs.framework_configuration[:network_ethereum_configuration].nil?
            raise Dry::Struct::Error, "network_ethereum_configuration is required for Ethereum networks"
          end

          # Validate framework version for Ethereum
          unless attrs.framework_version.match?(/\A(ETHEREUM_MAINNET|ETHEREUM_GOERLI|ETHEREUM_ROPSTEN|ETHEREUM_RINKEBY)\z/)
            raise Dry::Struct::Error, "framework_version must be a valid Ethereum network identifier"
          end

          # Ethereum doesn't support voting policy
          if attrs.voting_policy
            raise Dry::Struct::Error, "voting_policy is not supported for Ethereum networks"
          end
        end

        # Helper methods
        def is_hyperledger_fabric?
          framework == 'HYPERLEDGER_FABRIC'
        end

        def is_ethereum?
          framework == 'ETHEREUM'
        end

        def edition
          return nil unless is_hyperledger_fabric?
          framework_configuration&.dig(:network_fabric_configuration, :edition)
        end

        def is_starter_edition?
          edition == 'STARTER'
        end

        def is_standard_edition?
          edition == 'STANDARD'
        end

        def chain_id
          return nil unless is_ethereum?
          framework_configuration&.dig(:network_ethereum_configuration, :chain_id)
        end

        def approval_threshold
          voting_policy&.dig(:approval_threshold_policy, :threshold_percentage)
        end

        def proposal_duration_hours
          voting_policy&.dig(:approval_threshold_policy, :proposal_duration_in_hours)
        end

        def cloudwatch_logging_enabled?
          member_configuration.dig(:log_publishing_configuration, :fabric, :ca_logs, :cloudwatch, :enabled) || false
        end

        def estimated_monthly_cost
          base_cost = case framework
          when 'HYPERLEDGER_FABRIC'
            case edition
            when 'STARTER'
              0.45 # $0.45/hour for Starter
            when 'STANDARD'
              1.25 # $1.25/hour for Standard
            else
              0.0
            end
          when 'ETHEREUM'
            0.0 # Ethereum nodes have separate pricing
          else
            0.0
          end

          # Convert hourly to monthly (730 hours)
          base_cost * 730
        end

        def consensus_mechanism
          case framework
          when 'HYPERLEDGER_FABRIC'
            'RAFT (Ordering Service)'
          when 'ETHEREUM'
            case framework_version
            when 'ETHEREUM_MAINNET'
              'Proof of Stake (PoS)'
            else
              'Proof of Authority (PoA)' # Test networks
            end
          end
        end

        def network_type
          case framework
          when 'HYPERLEDGER_FABRIC'
            'Private Permissioned'
          when 'ETHEREUM'
            framework_version.include?('MAINNET') ? 'Public Permissionless' : 'Public Test Network'
          end
        end
      end
    end
      end
    end
  end
end