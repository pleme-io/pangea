# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS Managed Blockchain Member resources
      class ManagedBlockchainMemberAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Network ID (required)
        attribute :network_id, Resources::Types::String

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

        # Invitation ID (required for joining existing networks)
        attribute? :invitation_id, Resources::Types::String.optional

        # Tags (optional)
        attribute? :tags, Resources::Types::Hash.schema(
          Resources::Types::String => Resources::Types::String
        ).optional

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate network ID format
          unless attrs.network_id.match?(/\An-[A-Z0-9]{26}\z/)
            raise Dry::Struct::Error, "network_id must be in format 'n-XXXXXXXXXXXXXXXXXXXXXXXXXXXX'"
          end

          # Validate invitation ID format if provided
          if attrs.invitation_id && !attrs.invitation_id.match?(/\Ai-[A-Z0-9]{26}\z/)
            raise Dry::Struct::Error, "invitation_id must be in format 'i-XXXXXXXXXXXXXXXXXXXXXXXXXXXX'"
          end

          # Validate member name
          member_name = attrs.member_configuration[:name]
          unless member_name.match?(/\A[a-zA-Z][a-zA-Z0-9]*\z/)
            raise Dry::Struct::Error, "member name must start with a letter and contain only alphanumeric characters"
          end

          if member_name.length < 1 || member_name.length > 64
            raise Dry::Struct::Error, "member name must be between 1 and 64 characters"
          end

          # Validate Fabric configuration if provided
          if attrs.member_configuration[:framework_configuration][:member_fabric_configuration]
            validate_fabric_configuration(attrs.member_configuration[:framework_configuration][:member_fabric_configuration])
          end

          attrs
        end

        def self.validate_fabric_configuration(fabric_config)
          # Validate admin username
          admin_username = fabric_config[:admin_username]
          unless admin_username.match?(/\A[a-zA-Z0-9]+\z/)
            raise Dry::Struct::Error, "admin_username must contain only alphanumeric characters"
          end

          if admin_username.length < 1 || admin_username.length > 16
            raise Dry::Struct::Error, "admin_username must be between 1 and 16 characters"
          end

          # Validate admin password
          admin_password = fabric_config[:admin_password]
          if admin_password.length < 8 || admin_password.length > 32
            raise Dry::Struct::Error, "admin_password must be between 8 and 32 characters"
          end

          # Check password complexity
          unless admin_password.match?(/[A-Z]/) && admin_password.match?(/[a-z]/) && 
                 admin_password.match?(/[0-9]/) && admin_password.match?(/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/)
            raise Dry::Struct::Error, "admin_password must contain uppercase, lowercase, number, and special character"
          end
        end

        # Helper methods
        def member_name
          member_configuration[:name]
        end

        def member_description
          member_configuration[:description]
        end

        def is_fabric_member?
          member_configuration[:framework_configuration][:member_fabric_configuration].present?
        end

        def admin_username
          member_configuration.dig(:framework_configuration, :member_fabric_configuration, :admin_username)
        end

        def ca_logging_enabled?
          member_configuration.dig(:log_publishing_configuration, :fabric, :ca_logs, :cloudwatch, :enabled) || false
        end

        def is_joining_existing_network?
          !invitation_id.nil?
        end

        def is_founding_member?
          invitation_id.nil?
        end

        def member_type
          if is_founding_member?
            :founding_member
          else
            :invited_member
          end
        end

        def estimated_monthly_cost
          # Base member cost (varies by network type)
          base_cost = if is_fabric_member?
            0.10 # $0.10/hour for Fabric member
          else
            0.00 # Ethereum members don't have member-specific costs
          end

          # Add CA logging cost if enabled
          if ca_logging_enabled?
            base_cost += 0.01 # Approximate logging cost
          end

          # Convert to monthly (730 hours)
          base_cost * 730
        end

        def member_capabilities
          capabilities = []
          
          if is_fabric_member?
            capabilities << :certificate_authority
            capabilities << :peer_node_creation
            capabilities << :chaincode_deployment
            capabilities << :channel_creation
          end

          if ca_logging_enabled?
            capabilities << :ca_audit_logging
          end

          capabilities
        end

        def security_features
          features = []

          if is_fabric_member?
            features << :x509_certificates
            features << :msp_identity_management
            features << :tls_encryption
          end

          if admin_username
            features << :admin_credentials
          end

          features
        end

        def compliance_features
          features = []

          if ca_logging_enabled?
            features << :audit_trail
            features << :cloudwatch_integration
          end

          if member_configuration[:tags]
            features << :resource_tagging
          end

          features
        end
      end
    end
      end
    end
  end
end