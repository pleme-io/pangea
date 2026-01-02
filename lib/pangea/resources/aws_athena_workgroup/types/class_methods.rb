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
        # Class methods for Athena Workgroup attributes
        module AthenaWorkgroupClassMethods
          # Generate default configuration for workgroup types
          def default_configuration_for_type(type, s3_output_location)
            base_config = build_base_config(s3_output_location)

            case type.to_s
            when 'production'
              production_config(base_config)
            when 'development'
              development_config(base_config)
            when 'cost_optimized'
              cost_optimized_config(base_config)
            when 'analytics'
              analytics_config(base_config)
            else
              base_config
            end
          end

          private

          def build_base_config(s3_output_location)
            {
              result_configuration: {
                output_location: s3_output_location
              },
              enforce_workgroup_configuration: true,
              publish_cloudwatch_metrics_enabled: true
            }
          end

          def production_config(base_config)
            base_config.merge({
              result_configuration: base_config[:result_configuration].merge({
                encryption_configuration: {
                  encryption_option: 'SSE_KMS'
                }
              }),
              bytes_scanned_cutoff_per_query: 1_073_741_824_000, # 1TB limit
              engine_version: {
                selected_engine_version: 'Athena engine version 3'
              }
            })
          end

          def development_config(base_config)
            base_config.merge({
              bytes_scanned_cutoff_per_query: 10_737_418_240, # 10GB limit
              enforce_workgroup_configuration: false
            })
          end

          def cost_optimized_config(base_config)
            base_config.merge({
              bytes_scanned_cutoff_per_query: 1_073_741_824, # 1GB limit
              requester_pays_enabled: true,
              result_configuration: base_config[:result_configuration].merge({
                encryption_configuration: {
                  encryption_option: 'SSE_S3'
                }
              })
            })
          end

          def analytics_config(base_config)
            base_config.merge({
              engine_version: {
                selected_engine_version: 'Athena engine version 3'
              },
              result_configuration: base_config[:result_configuration].merge({
                encryption_configuration: {
                  encryption_option: 'SSE_KMS'
                }
              })
            })
          end
        end
      end
    end
  end
end
