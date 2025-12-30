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
      # Block builders for AWS Lambda Function resource
      # Extracts complex nested block building logic for cleaner resource definition
      module LambdaBlockBuilders
        extend self

        def apply_environment(ctx, env_config)
          return unless env_config && env_config[:variables]

          ctx.environment do
            variables do
              env_config[:variables].each do |key, value|
                public_send(key, value)
              end
            end
          end
        end

        def apply_vpc_config(ctx, vpc_config)
          return unless vpc_config

          ctx.vpc_config do
            subnet_ids vpc_config[:subnet_ids]
            security_group_ids vpc_config[:security_group_ids]
          end
        end

        def apply_dead_letter_config(ctx, dlq_config)
          return unless dlq_config

          ctx.dead_letter_config do
            target_arn dlq_config[:target_arn]
          end
        end

        def apply_file_system_configs(ctx, fs_configs)
          return unless fs_configs.any?

          fs_configs.each do |fs_config|
            ctx.file_system_config do
              arn fs_config[:arn]
              local_mount_path fs_config[:local_mount_path]
            end
          end
        end

        def apply_tracing_config(ctx, tracing_config)
          return unless tracing_config

          ctx.tracing_config do
            mode tracing_config[:mode]
          end
        end

        def apply_ephemeral_storage(ctx, storage_config)
          return unless storage_config

          ctx.ephemeral_storage do
            size storage_config[:size]
          end
        end

        def apply_snap_start(ctx, snap_start_config)
          return unless snap_start_config

          ctx.snap_start do
            apply_on snap_start_config[:apply_on]
          end
        end

        def apply_logging_config(ctx, logging_config)
          return unless logging_config

          ctx.logging_config do
            log_format logging_config[:log_format] if logging_config[:log_format]
            log_group logging_config[:log_group] if logging_config[:log_group]
            system_log_level logging_config[:system_log_level] if logging_config[:system_log_level]
            application_log_level logging_config[:application_log_level] if logging_config[:application_log_level]
          end
        end

        def apply_tags(ctx, tags)
          return unless tags.any?

          ctx.tags do
            tags.each do |key, value|
              public_send(key, value)
            end
          end
        end
      end
    end
  end
end
