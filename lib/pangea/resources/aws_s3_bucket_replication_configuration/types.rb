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
      # Type-safe attributes for AWS S3 Bucket Replication Configuration resources
      class S3BucketReplicationConfigurationAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # The name of the bucket for which replication configuration is set
        attribute :bucket, Resources::Types::String

        # IAM role ARN that S3 can assume to replicate objects
        attribute :role, Resources::Types::String

        # Array of replication rules
        attribute :rule, Resources::Types::Array.of(
          Resources::Types::Hash.schema(
            # Unique identifier for the rule
            id?: Resources::Types::String.optional,
            
            # Priority of the rule (required when multiple rules)
            priority?: Resources::Types::Integer.constrained(gteq: 0).optional,
            
            # Rule status (Enabled or Disabled)
            status: Resources::Types::String.enum('Enabled', 'Disabled').default('Enabled'),
            
            # Filter to determine which objects to replicate
            filter?: Resources::Types::Hash.schema(
              prefix?: Resources::Types::String.optional,
              tag?: Resources::Types::Hash.schema(
                key: Resources::Types::String,
                value: Resources::Types::String
              ).optional,
              and?: Resources::Types::Hash.schema(
                prefix?: Resources::Types::String.optional,
                tags?: Resources::Types::Hash.optional
              ).optional
            ).optional,
            
            # Destination configuration
            destination: Resources::Types::Hash.schema(
              bucket: Resources::Types::String, # ARN of destination bucket
              storage_class?: Resources::Types::String.enum(
                'STANDARD', 'REDUCED_REDUNDANCY', 'STANDARD_IA', 'ONEZONE_IA',
                'INTELLIGENT_TIERING', 'GLACIER', 'DEEP_ARCHIVE', 'OUTPOSTS',
                'GLACIER_IR'
              ).optional,
              account_id?: Resources::Types::String.optional,
              
              # Access control translation for cross-account replication
              access_control_translation?: Resources::Types::Hash.schema(
                owner: Resources::Types::String.enum('Destination').default('Destination')
              ).optional,
              
              # Encryption configuration for replicated objects
              encryption_configuration?: Resources::Types::Hash.schema(
                replica_kms_key_id: Resources::Types::String
              ).optional,
              
              # Metrics configuration
              metrics?: Resources::Types::Hash.schema(
                status: Resources::Types::String.enum('Enabled', 'Disabled').default('Disabled'),
                event_threshold?: Resources::Types::Hash.schema(
                  minutes: Resources::Types::Integer.constrained(gteq: 15)
                ).optional
              ).optional,
              
              # Replication time control
              replication_time?: Resources::Types::Hash.schema(
                status: Resources::Types::String.enum('Enabled', 'Disabled').default('Disabled'),
                time?: Resources::Types::Hash.schema(
                  minutes: Resources::Types::Integer.constrained(gteq: 15)
                ).optional
              ).optional
            ),
            
            # Delete marker replication
            delete_marker_replication?: Resources::Types::Hash.schema(
              status: Resources::Types::String.enum('Enabled', 'Disabled').default('Disabled')
            ).optional,
            
            # Existing object replication
            existing_object_replication?: Resources::Types::Hash.schema(
              status: Resources::Types::String.enum('Enabled', 'Disabled').default('Disabled')
            ).optional,
            
            # Source selection criteria
            source_selection_criteria?: Resources::Types::Hash.schema(
              replica_modifications?: Resources::Types::Hash.schema(
                status: Resources::Types::String.enum('Enabled', 'Disabled').default('Disabled')
              ).optional,
              sse_kms_encrypted_objects?: Resources::Types::Hash.schema(
                status: Resources::Types::String.enum('Enabled', 'Disabled').default('Disabled')
              ).optional
            ).optional
          )
        ).constrained(min_size: 1)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate IAM role ARN format
          unless attrs.role.match?(/^arn:aws:iam::\d{12}:role\/[\w+=,.@-]+$/)
            raise Dry::Struct::Error, "Role must be a valid IAM role ARN"
          end

          # Validate rule priorities when multiple rules exist
          if attrs.rule.size > 1
            validate_rule_priorities(attrs.rule)
          end

          # Validate destination bucket ARNs
          attrs.rule.each_with_index do |rule, index|
            validate_destination_bucket_arn(rule[:destination][:bucket], index)
            validate_cross_account_requirements(rule, index)
            validate_replication_time_consistency(rule, index)
            validate_metrics_and_rtc_consistency(rule, index)
          end

          # Validate filter combinations
          attrs.rule.each_with_index do |rule, index|
            validate_filter_configuration(rule[:filter], index) if rule[:filter]
          end

          attrs
        end

        private

        def self.validate_rule_priorities(rules)
          priorities = rules.filter_map { |rule| rule[:priority] }
          
          if priorities.size != rules.size
            raise Dry::Struct::Error, "All rules must have priority when multiple rules are defined"
          end

          if priorities.size != priorities.uniq.size
            raise Dry::Struct::Error, "Rule priorities must be unique"
          end
        end

        def self.validate_destination_bucket_arn(bucket_arn, rule_index)
          unless bucket_arn.match?(/^arn:aws:s3:::[\w.\-]+$/)
            raise Dry::Struct::Error, "Rule #{rule_index}: destination bucket must be a valid S3 bucket ARN"
          end
        end

        def self.validate_cross_account_requirements(rule, rule_index)
          destination = rule[:destination]
          
          # If account_id is specified, access_control_translation should be configured
          if destination[:account_id] && !destination[:access_control_translation]
            raise Dry::Struct::Error, "Rule #{rule_index}: cross-account replication requires access_control_translation"
          end
        end

        def self.validate_replication_time_consistency(rule, rule_index)
          destination = rule[:destination]
          rtc = destination[:replication_time]
          metrics = destination[:metrics]
          
          # If RTC is enabled, time must be specified
          if rtc&.dig(:status) == 'Enabled' && !rtc[:time]
            raise Dry::Struct::Error, "Rule #{rule_index}: replication_time requires time when enabled"
          end
          
          # If RTC is enabled, metrics should also be enabled
          if rtc&.dig(:status) == 'Enabled' && metrics&.dig(:status) != 'Enabled'
            raise Dry::Struct::Error, "Rule #{rule_index}: replication_time requires metrics to be enabled"
          end
        end

        def self.validate_metrics_and_rtc_consistency(rule, rule_index)
          destination = rule[:destination]
          metrics = destination[:metrics]
          
          # If metrics is enabled, event_threshold should be specified
          if metrics&.dig(:status) == 'Enabled' && !metrics[:event_threshold]
            raise Dry::Struct::Error, "Rule #{rule_index}: metrics requires event_threshold when enabled"
          end
        end

        def self.validate_filter_configuration(filter, rule_index)
          # Cannot have both single condition and 'and' condition
          single_conditions = [filter[:prefix], filter[:tag]].compact.size
          and_condition = filter[:and] ? 1 : 0
          
          if single_conditions > 0 && and_condition > 0
            raise Dry::Struct::Error, "Rule #{rule_index}: filter cannot have both single conditions and 'and' condition"
          end

          # 'and' condition must have at least one sub-condition
          if filter[:and]
            and_conditions = [filter[:and][:prefix], filter[:and][:tags]].compact.size
            if and_conditions == 0
              raise Dry::Struct::Error, "Rule #{rule_index}: 'and' filter must have at least one condition"
            end
          end
        end

        # Helper methods
        def total_rules_count
          rule.size
        end

        def enabled_rules_count
          rule.count { |r| r[:status] == 'Enabled' }
        end

        def disabled_rules_count  
          rule.count { |r| r[:status] == 'Disabled' }
        end

        def cross_region_rules_count
          # This would require comparing source and destination regions
          # For now, assume all replications are cross-region
          enabled_rules_count
        end

        def cross_account_rules_count
          rule.count { |r| r[:destination][:account_id].present? }
        end

        def has_delete_marker_replication?
          rule.any? { |r| r[:delete_marker_replication]&.dig(:status) == 'Enabled' }
        end

        def has_existing_object_replication?
          rule.any? { |r| r[:existing_object_replication]&.dig(:status) == 'Enabled' }
        end

        def has_rtc_enabled?
          rule.any? { |r| r[:destination][:replication_time]&.dig(:status) == 'Enabled' }
        end

        def has_metrics_enabled?
          rule.any? { |r| r[:destination][:metrics]&.dig(:status) == 'Enabled' }
        end

        def has_encryption_in_transit?
          rule.any? { |r| r[:destination][:encryption_configuration].present? }
        end

        def has_kms_replication?
          rule.any? { |r| r[:source_selection_criteria]&.dig(:sse_kms_encrypted_objects, :status) == 'Enabled' }
        end

        def replicates_to_storage_classes
          rule.filter_map { |r| r[:destination][:storage_class] }.uniq
        end

        def has_filtered_replication?
          rule.any? { |r| r[:filter].present? }
        end

        def max_rtc_minutes
          rtc_times = rule.filter_map { |r| r[:destination][:replication_time]&.dig(:time, :minutes) }
          rtc_times.max || 0
        end

        def estimated_replication_cost_category
          factors = [
            total_rules_count,
            cross_account_rules_count * 2, # Cross-account costs more
            has_rtc_enabled? ? 3 : 0, # RTC costs more
            has_metrics_enabled? ? 1 : 0,
            replicates_to_storage_classes.include?('GLACIER') ? 2 : 0
          ].sum

          case factors
          when 0..3
            'low'
          when 4..8
            'medium'
          else
            'high'
          end
        end
      end
    end
      end
    end
  end
end