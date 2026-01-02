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
        # Helper methods for S3 bucket replication configuration attributes
        module S3BucketReplicationHelpers
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
            factors = calculate_cost_factors
            categorize_cost(factors)
          end

          private

          def calculate_cost_factors
            [
              total_rules_count,
              cross_account_rules_count * 2,
              has_rtc_enabled? ? 3 : 0,
              has_metrics_enabled? ? 1 : 0,
              replicates_to_storage_classes.include?('GLACIER') ? 2 : 0
            ].sum
          end

          def categorize_cost(factors)
            case factors
            when 0..3 then 'low'
            when 4..8 then 'medium'
            else 'high'
            end
          end
        end
      end
    end
  end
end
