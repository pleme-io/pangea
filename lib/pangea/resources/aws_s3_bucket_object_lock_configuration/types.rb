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
      # Type-safe attributes for AWS S3 Bucket Object Lock Configuration resources
      class S3BucketObjectLockConfigurationAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # The name of the bucket for which object lock configuration is set
        attribute :bucket, Resources::Types::String

        # Expected bucket owner (optional for cross-account scenarios)
        attribute? :expected_bucket_owner, Resources::Types::String.optional

        # Object lock configuration status (Enabled is the only valid value)
        attribute :object_lock_enabled, Resources::Types::String.enum('Enabled').default('Enabled')

        # Token for making updates (prevents concurrent modification issues)
        attribute? :token, Resources::Types::String.optional

        # Default retention rule configuration
        attribute :rule, Resources::Types::Hash.schema(
          default_retention: Resources::Types::Hash.schema(
            # Retention mode: GOVERNANCE allows privileged users to modify/delete
            # COMPLIANCE prevents any modifications until retention period expires
            mode: Resources::Types::String.enum('GOVERNANCE', 'COMPLIANCE'),
            
            # Retention period - must specify either days OR years, not both
            days?: Resources::Types::Integer.constrained(gteq: 1, lteq: 36500).optional, # Max ~100 years
            years?: Resources::Types::Integer.constrained(gteq: 1, lteq: 100).optional
          )
        ).default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate bucket name format (basic validation)
          validate_bucket_name(attrs.bucket)

          # Validate expected bucket owner if provided
          if attrs.expected_bucket_owner
            validate_aws_account_id(attrs.expected_bucket_owner)
          end

          # Validate default retention configuration
          if attrs.rule[:default_retention]
            validate_default_retention(attrs.rule[:default_retention])
          end

          attrs
        end

        private

        def self.validate_bucket_name(bucket_name)
          # Basic bucket name validation
          if bucket_name.length < 3 || bucket_name.length > 63
            raise Dry::Struct::Error, "Bucket name must be between 3 and 63 characters"
          end

          # Check for invalid characters (basic check)
          unless bucket_name.match?(/^[a-z0-9][a-z0-9\-]*[a-z0-9]$/)
            raise Dry::Struct::Error, "Invalid bucket name format"
          end
        end

        def self.validate_aws_account_id(account_id)
          unless account_id.match?(/^\d{12}$/)
            raise Dry::Struct::Error, "Expected bucket owner must be a 12-digit AWS account ID"
          end
        end

        def self.validate_default_retention(retention_config)
          days = retention_config[:days]
          years = retention_config[:years]

          # Must specify either days or years, but not both
          if days && years
            raise Dry::Struct::Error, "Cannot specify both days and years in default retention"
          end

          if !days && !years
            raise Dry::Struct::Error, "Must specify either days or years in default retention"
          end

          # Validate retention period ranges
          if days && (days < 1 || days > 36500)
            raise Dry::Struct::Error, "Retention days must be between 1 and 36500 (approximately 100 years)"
          end

          if years && (years < 1 || years > 100)
            raise Dry::Struct::Error, "Retention years must be between 1 and 100"
          end

          # Check for logical consistency between days and years
          if days && days > 36500  # More than ~100 years
            raise Dry::Struct::Error, "Retention period of #{days} days exceeds maximum recommended period"
          end
        end

        # Helper methods
        def has_default_retention?
          rule[:default_retention].present?
        end

        def governance_mode?
          rule.dig(:default_retention, :mode) == 'GOVERNANCE'
        end

        def compliance_mode?
          rule.dig(:default_retention, :mode) == 'COMPLIANCE'
        end

        def retention_period_in_days
          if rule.dig(:default_retention, :days)
            rule[:default_retention][:days]
          elsif rule.dig(:default_retention, :years)
            rule[:default_retention][:years] * 365
          else
            0
          end
        end

        def retention_period_in_years
          if rule.dig(:default_retention, :years)
            rule[:default_retention][:years]
          elsif rule.dig(:default_retention, :days)
            (rule[:default_retention][:days] / 365.0).round(2)
          else
            0.0
          end
        end

        def short_term_retention?
          retention_period_in_days <= 365 # 1 year or less
        end

        def medium_term_retention?
          days = retention_period_in_days
          days > 365 && days <= 2555 # 1-7 years
        end

        def long_term_retention?
          retention_period_in_days > 2555 # More than 7 years
        end

        def compliance_grade_retention?
          # High-grade retention typically means compliance mode with long periods
          compliance_mode? && (retention_period_in_days >= 2555)
        end

        def allows_privileged_deletion?
          # GOVERNANCE mode allows privileged users to modify/delete objects
          governance_mode?
        end

        def prevents_all_deletion?
          # COMPLIANCE mode prevents all deletion until retention expires
          compliance_mode?
        end

        def estimated_storage_cost_impact
          # Longer retention periods and compliance mode increase storage costs
          days = retention_period_in_days
          
          base_impact = case days
                       when 0..365
                         'low'
                       when 366..2555
                         'medium'
                       else
                         'high'
                       end
          
          # Compliance mode typically means higher compliance/audit costs
          compliance_mode? ? "#{base_impact}_compliance" : base_impact
        end

        def retention_category
          case retention_period_in_days
          when 0..30
            'monthly'
          when 31..365
            'yearly'
          when 366..2555
            'multi_year'
          else
            'long_term_archive'
          end
        end

        def cross_account_scenario?
          expected_bucket_owner.present?
        end

        def bucket_name_only
          # Extract bucket name if ARN is provided
          if bucket.start_with?('arn:')
            bucket.split(':').last
          else
            bucket
          end
        end

        def estimated_compliance_level
          if compliance_mode? && long_term_retention?
            'maximum'
          elsif compliance_mode? || (governance_mode? && medium_term_retention?)
            'high'
          elsif governance_mode? && short_term_retention?
            'standard'
          else
            'minimal'
          end
        end
      end
    end
      end
    end
  end
end