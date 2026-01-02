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

module Pangea
  module Resources
    module AWS
      module Types
        # Validators for S3 bucket replication configuration
        module S3BucketReplicationValidators
          IAM_ROLE_ARN_PATTERN = /^arn:aws:iam::\d{12}:role\/[\w+=,.@-]+$/
          S3_BUCKET_ARN_PATTERN = /^arn:aws:s3:::[\w.\-]+$/

          def self.validate_role_arn(role)
            return if role.match?(IAM_ROLE_ARN_PATTERN)

            raise Dry::Struct::Error, 'Role must be a valid IAM role ARN'
          end

          def self.validate_rule_priorities(rules)
            return unless rules.size > 1

            priorities = rules.filter_map { |rule| rule[:priority] }

            if priorities.size != rules.size
              raise Dry::Struct::Error, 'All rules must have priority when multiple rules are defined'
            end

            return unless priorities.size != priorities.uniq.size

            raise Dry::Struct::Error, 'Rule priorities must be unique'
          end

          def self.validate_destination_bucket_arn(bucket_arn, rule_index)
            return if bucket_arn.match?(S3_BUCKET_ARN_PATTERN)

            raise Dry::Struct::Error, "Rule #{rule_index}: destination bucket must be a valid S3 bucket ARN"
          end

          def self.validate_cross_account_requirements(rule, rule_index)
            destination = rule[:destination]
            return unless destination[:account_id] && !destination[:access_control_translation]

            raise Dry::Struct::Error, "Rule #{rule_index}: cross-account replication requires access_control_translation"
          end

          def self.validate_replication_time_consistency(rule, rule_index)
            destination = rule[:destination]
            rtc = destination[:replication_time]
            metrics = destination[:metrics]

            if rtc&.dig(:status) == 'Enabled' && !rtc[:time]
              raise Dry::Struct::Error, "Rule #{rule_index}: replication_time requires time when enabled"
            end

            return unless rtc&.dig(:status) == 'Enabled' && metrics&.dig(:status) != 'Enabled'

            raise Dry::Struct::Error, "Rule #{rule_index}: replication_time requires metrics to be enabled"
          end

          def self.validate_metrics_and_rtc_consistency(rule, rule_index)
            metrics = rule[:destination][:metrics]
            return unless metrics&.dig(:status) == 'Enabled' && !metrics[:event_threshold]

            raise Dry::Struct::Error, "Rule #{rule_index}: metrics requires event_threshold when enabled"
          end

          def self.validate_filter_configuration(filter, rule_index)
            return unless filter

            single_conditions = [filter[:prefix], filter[:tag]].compact.size
            and_condition = filter[:and] ? 1 : 0

            if single_conditions.positive? && and_condition.positive?
              raise Dry::Struct::Error,
                    "Rule #{rule_index}: filter cannot have both single conditions and 'and' condition"
            end

            return unless filter[:and]

            and_conditions = [filter[:and][:prefix], filter[:and][:tags]].compact.size
            return unless and_conditions.zero?

            raise Dry::Struct::Error, "Rule #{rule_index}: 'and' filter must have at least one condition"
          end

          def self.validate_all(attrs)
            validate_role_arn(attrs.role)
            validate_rule_priorities(attrs.rule)

            attrs.rule.each_with_index do |rule, index|
              validate_destination_bucket_arn(rule[:destination][:bucket], index)
              validate_cross_account_requirements(rule, index)
              validate_replication_time_consistency(rule, index)
              validate_metrics_and_rtc_consistency(rule, index)
              validate_filter_configuration(rule[:filter], index)
            end
          end
        end
      end
    end
  end
end
