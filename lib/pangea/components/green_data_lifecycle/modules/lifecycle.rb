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
  module Components
    module GreenDataLifecycle
      # Lifecycle configuration and rules for Green Data Lifecycle component
      module Lifecycle
        private

        def create_lifecycle_configuration(input, bucket)
          rules = build_lifecycle_rules(input)
          rules << expiration_rule(input) if input.expire_days

          aws_s3_bucket_lifecycle_configuration(:"#{input.name}-lifecycle", {
            bucket: bucket.id,
            rule: rules
          })
        end

        def build_lifecycle_rules(input)
          case input.lifecycle_strategy
          when 'carbon_optimized'
            create_carbon_optimized_rules(input)
          when 'access_pattern_based'
            create_access_pattern_rules(input)
          when 'time_based'
            create_time_based_rules(input)
          when 'size_based'
            create_size_based_rules(input)
          when 'cost_optimized'
            create_cost_optimized_rules(input)
          else
            []
          end
        end

        def expiration_rule(input)
          {
            id: "expire-old-objects",
            status: "Enabled",
            expiration: { days: input.expire_days }
          }
        end

        def create_carbon_optimized_rules(input)
          [
            {
              id: "carbon-optimize-standard-to-ia",
              status: "Enabled",
              transition: [{
                days: input.transition_to_ia_days,
                storage_class: "STANDARD_IA"
              }],
              noncurrent_version_transition: [{
                noncurrent_days: input.transition_to_ia_days / 2,
                storage_class: "STANDARD_IA"
              }]
            },
            {
              id: "carbon-optimize-ia-to-glacier-ir",
              status: "Enabled",
              transition: [{
                days: input.transition_to_glacier_ir_days,
                storage_class: "GLACIER_IR"
              }]
            },
            {
              id: "carbon-optimize-to-deep-archive",
              status: "Enabled",
              transition: [{
                days: input.transition_to_deep_archive_days,
                storage_class: "DEEP_ARCHIVE"
              }]
            }
          ]
        end

        def create_access_pattern_rules(_input)
          [
            {
              id: "access-pattern-optimization",
              status: "Enabled",
              transition: [{ days: 30, storage_class: "INTELLIGENT_TIERING" }]
            }
          ]
        end

        def create_time_based_rules(input)
          [
            {
              id: "time-based-transitions",
              status: "Enabled",
              transition: [
                { days: input.transition_to_ia_days, storage_class: "STANDARD_IA" },
                { days: input.transition_to_glacier_days, storage_class: "GLACIER_FLEXIBLE" }
              ]
            }
          ]
        end

        def create_size_based_rules(input)
          [
            {
              id: "large-object-archive",
              status: "Enabled",
              filter: {
                object_size_greater_than: input.large_object_threshold_mb * 1024 * 1024
              },
              transition: [{
                days: input.archive_large_objects_days,
                storage_class: "GLACIER_IR"
              }]
            }
          ]
        end

        def create_cost_optimized_rules(_input)
          [
            {
              id: "cost-optimize-all",
              status: "Enabled",
              transition: [
                { days: 30, storage_class: "STANDARD_IA" },
                { days: 90, storage_class: "GLACIER_FLEXIBLE" }
              ]
            }
          ]
        end

        def create_intelligent_tiering_configuration(input, bucket)
          aws_s3_bucket_intelligent_tiering_configuration(:"#{input.name}-intelligent-tiering", {
            bucket: bucket.id,
            name: "#{input.name}-tiering",
            status: "Enabled",
            filter: { prefix: "" },
            tiering: [
              { days: 90, access_tier: "ARCHIVE_ACCESS" },
              { days: 180, access_tier: "DEEP_ARCHIVE_ACCESS" }
            ]
          })
        end
      end
    end
  end
end
