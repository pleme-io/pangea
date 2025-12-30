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
      module KinesisAnalyticsApplication
        module Builders
          # Builds the flink_application_configuration block for Kinesis Analytics
          module FlinkBuilder
            extend self

            # Build the Flink application configuration block
            # @param context [Object] The DSL context for building Terraform blocks
            # @param flink_config [Hash] The Flink configuration hash
            def build(context, flink_config)
              return unless flink_config

              context.flink_application_configuration do
                build_checkpoint_configuration(self, flink_config[:checkpoint_configuration])
                build_monitoring_configuration(self, flink_config[:monitoring_configuration])
                build_parallelism_configuration(self, flink_config[:parallelism_configuration])
              end
            end

            private

            def build_checkpoint_configuration(context, checkpoint_config)
              return unless checkpoint_config

              context.checkpoint_configuration do
                configuration_type checkpoint_config[:configuration_type]
                checkpointing_enabled checkpoint_config[:checkpointing_enabled] if checkpoint_config.key?(:checkpointing_enabled)
                checkpoint_interval checkpoint_config[:checkpoint_interval] if checkpoint_config[:checkpoint_interval]
                min_pause_between_checkpoints checkpoint_config[:min_pause_between_checkpoints] if checkpoint_config[:min_pause_between_checkpoints]
              end
            end

            def build_monitoring_configuration(context, monitor_config)
              return unless monitor_config

              context.monitoring_configuration do
                configuration_type monitor_config[:configuration_type]
                log_level monitor_config[:log_level] if monitor_config[:log_level]
                metrics_level monitor_config[:metrics_level] if monitor_config[:metrics_level]
              end
            end

            def build_parallelism_configuration(context, parallel_config)
              return unless parallel_config

              context.parallelism_configuration do
                configuration_type parallel_config[:configuration_type]
                parallelism parallel_config[:parallelism] if parallel_config[:parallelism]
                parallelism_per_kpu parallel_config[:parallelism_per_kpu] if parallel_config[:parallelism_per_kpu]
                auto_scaling_enabled parallel_config[:auto_scaling_enabled] if parallel_config.key?(:auto_scaling_enabled)
              end
            end
          end
        end
      end
    end
  end
end
