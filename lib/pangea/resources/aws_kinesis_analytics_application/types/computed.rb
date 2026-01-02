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
        class KinesisAnalyticsApplicationAttributes
          # Computed properties for Kinesis Analytics Application
          module Computed
            COST_PER_KPU_HOUR = 0.11
            HOURS_PER_MONTH = 24 * 30

            def is_sql_application?
              runtime_environment == 'SQL-1_0'
            end

            def is_flink_application?
              runtime_environment.start_with?('FLINK')
            end

            def has_vpc_configuration?
              !application_configuration&.dig(:vpc_configuration).nil?
            end

            def has_code_from_s3?
              !application_configuration&.dig(:application_code_configuration, :code_content, :s3_content_location).nil?
            end

            def has_monitoring_enabled?
              flink_config = application_configuration&.dig(:flink_application_configuration, :monitoring_configuration)
              return false unless flink_config

              flink_config[:configuration_type] == 'CUSTOM'
            end

            def has_checkpointing_enabled?
              checkpoint_config = application_configuration&.dig(:flink_application_configuration,
                                                                 :checkpoint_configuration)
              return false unless checkpoint_config

              checkpoint_config[:configuration_type] == 'CUSTOM' && checkpoint_config[:checkpointing_enabled] == true
            end

            def parallelism_level
              parallel_config = application_configuration&.dig(:flink_application_configuration,
                                                               :parallelism_configuration)
              return nil unless parallel_config

              parallel_config[:parallelism] || 1
            end

            def auto_scaling_enabled?
              parallel_config = application_configuration&.dig(:flink_application_configuration,
                                                               :parallelism_configuration)
              return false unless parallel_config

              parallel_config[:auto_scaling_enabled] == true
            end

            def input_count
              return 0 unless is_sql_application?

              sql_config = application_configuration&.dig(:sql_application_configuration)
              sql_config&.dig(:inputs)&.length || 0
            end

            def output_count
              return 0 unless is_sql_application?

              sql_config = application_configuration&.dig(:sql_application_configuration)
              sql_config&.dig(:outputs)&.length || 0
            end

            def reference_data_source_count
              return 0 unless is_sql_application?

              sql_config = application_configuration&.dig(:sql_application_configuration)
              sql_config&.dig(:reference_data_sources)&.length || 0
            end

            def estimated_kpu_usage
              if is_sql_application?
                estimate_sql_kpu_usage
              elsif is_flink_application?
                estimate_flink_kpu_usage
              else
                1
              end
            end

            def estimated_monthly_cost_usd
              kpu_usage = estimated_kpu_usage
              monthly_cost = kpu_usage * HOURS_PER_MONTH * COST_PER_KPU_HOUR
              monthly_cost.round(2)
            end

            private

            def estimate_sql_kpu_usage
              base_kpu = 1
              additional_kpu = (input_count + output_count) * 0.1
              (base_kpu + additional_kpu).ceil
            end

            def estimate_flink_kpu_usage
              parallelism = parallelism_level || 1
              kpu_per_parallelism = application_configuration&.dig(
                :flink_application_configuration, :parallelism_configuration, :parallelism_per_kpu
              ) || 1
              (parallelism.to_f / kpu_per_parallelism).ceil
            end
          end
        end
      end
    end
  end
end
