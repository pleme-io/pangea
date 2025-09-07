# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_qldb_ledger/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS QLDB Ledger with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] QLDB ledger attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_qldb_ledger(name, attributes = {})
        # Validate attributes using dry-struct
        ledger_attrs = Types::QldbLedgerAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_qldb_ledger, name) do
          # Set ledger name
          name ledger_attrs.name
          
          # Set permissions mode
          permissions_mode ledger_attrs.permissions_mode
          
          # Set deletion protection
          deletion_protection ledger_attrs.deletion_protection
          
          # Set KMS key if provided
          kms_key ledger_attrs.kms_key if ledger_attrs.kms_key
          
          # Set tags if provided
          if ledger_attrs.tags && !ledger_attrs.tags.empty?
            tags ledger_attrs.tags
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_qldb_ledger',
          name: name,
          resource_attributes: ledger_attrs.to_h,
          outputs: {
            id: "${aws_qldb_ledger.#{name}.id}",
            arn: "${aws_qldb_ledger.#{name}.arn}",
            name: "${aws_qldb_ledger.#{name}.name}",
            state: "${aws_qldb_ledger.#{name}.state}",
            creation_date_time: "${aws_qldb_ledger.#{name}.creation_date_time}",
            permissions_mode: "${aws_qldb_ledger.#{name}.permissions_mode}",
            deletion_protection: "${aws_qldb_ledger.#{name}.deletion_protection}",
            kms_key_id: "${aws_qldb_ledger.#{name}.kms_key}"
          },
          computed: {
            uses_standard_permissions: ledger_attrs.uses_standard_permissions?,
            uses_allow_all_permissions: ledger_attrs.uses_allow_all_permissions?,
            is_encrypted: ledger_attrs.is_encrypted?,
            uses_aws_managed_key: ledger_attrs.uses_aws_managed_key?,
            deletion_protected: ledger_attrs.deletion_protected?,
            estimated_monthly_cost: ledger_attrs.estimated_monthly_cost,
            compliance_level: ledger_attrs.compliance_level,
            security_features: ledger_attrs.security_features,
            ledger_capabilities: ledger_attrs.ledger_capabilities,
            recommended_use_cases: ledger_attrs.recommended_use_cases,
            query_performance_tier: ledger_attrs.query_performance_tier
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)