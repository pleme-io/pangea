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


require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS QLDB Ledger resources
      class QldbLedgerAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Ledger name (required)
        attribute :name, Resources::Types::String

        # Permissions mode (required)
        attribute :permissions_mode, Resources::Types::String.enum(
          'ALLOW_ALL',    # Deprecated, allows all users full access
          'STANDARD'      # Recommended, uses IAM permissions
        )

        # Deletion protection (optional)
        attribute? :deletion_protection, Resources::Types::Bool.default(true)

        # KMS key for encryption (optional)
        attribute? :kms_key, Resources::Types::String.optional

        # Tags (optional)
        attribute? :tags, Resources::Types::Hash.schema(
          Resources::Types::String => Resources::Types::String
        ).optional

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate ledger name
          unless attrs.name.match?(/\A[a-zA-Z][a-zA-Z0-9_-]*\z/)
            raise Dry::Struct::Error, "name must start with a letter and contain only alphanumeric characters, underscores, and hyphens"
          end

          if attrs.name.length < 1 || attrs.name.length > 32
            raise Dry::Struct::Error, "name must be between 1 and 32 characters"
          end

          # Validate KMS key format if provided
          if attrs.kms_key && !attrs.kms_key.match?(/\Aarn:aws[a-z\-]*:kms:[a-z0-9\-]+:\d{12}:key\/[a-f0-9\-]+\z/)
            raise Dry::Struct::Error, "kms_key must be a valid KMS key ARN"
          end

          # Warn about deprecated permissions mode
          if attrs.permissions_mode == 'ALLOW_ALL'
            warn "ALLOW_ALL permissions mode is deprecated. Consider using STANDARD mode with IAM policies."
          end

          attrs
        end

        # Helper methods
        def uses_standard_permissions?
          permissions_mode == 'STANDARD'
        end

        def uses_allow_all_permissions?
          permissions_mode == 'ALLOW_ALL'
        end

        def is_encrypted?
          !kms_key.nil?
        end

        def uses_aws_managed_key?
          kms_key.nil?
        end

        def deletion_protected?
          deletion_protection
        end

        def estimated_monthly_cost
          # Base costs
          journal_storage_gb = 1.0 # Minimum estimate
          indexed_storage_gb = 0.5 # Estimate
          
          # Storage costs
          journal_cost = journal_storage_gb * 0.03 # $0.03 per GB-month
          indexed_cost = indexed_storage_gb * 0.25 # $0.25 per GB-month
          
          # IO costs (estimated based on typical usage)
          read_ios_millions = 1.0 # 1 million read IOs
          write_ios_millions = 0.5 # 500k write IOs
          
          read_io_cost = read_ios_millions * 0.12 # $0.12 per million read IOs
          write_io_cost = write_ios_millions * 0.12 # $0.12 per million write IOs
          
          # Total monthly cost
          journal_cost + indexed_cost + read_io_cost + write_io_cost
        end

        def compliance_level
          if uses_standard_permissions? && is_encrypted? && deletion_protected?
            :high
          elsif uses_standard_permissions? && (is_encrypted? || deletion_protected?)
            :medium
          else
            :low
          end
        end

        def security_features
          features = []
          
          features << :iam_authentication if uses_standard_permissions?
          features << :encryption_at_rest if is_encrypted?
          features << :customer_managed_keys if is_encrypted? && !uses_aws_managed_key?
          features << :deletion_protection if deletion_protected?
          features << :cryptographic_verification
          features << :immutable_journal
          
          features
        end

        def ledger_capabilities
          [
            :acid_transactions,
            :cryptographic_verification,
            :immutable_history,
            :partiql_queries,
            :document_revisions,
            :merkle_tree_proofs,
            :streaming_to_kinesis,
            :journal_export_to_s3
          ]
        end

        def recommended_use_cases
          [
            :financial_transactions,
            :supply_chain_tracking,
            :regulatory_compliance,
            :healthcare_records,
            :insurance_claims,
            :identity_verification,
            :voting_systems,
            :audit_logs
          ]
        end

        def query_performance_tier
          # QLDB performance is primarily based on IO operations
          :serverless # Automatically scales based on workload
        end
      end
    end
      end
    end
  end
end