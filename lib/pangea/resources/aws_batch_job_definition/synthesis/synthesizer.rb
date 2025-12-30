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
      # Synthesizer class to handle complex nested block synthesis for Batch Job Definition
      class BatchJobDefinitionSynthesizer
        class << self
          def synthesize_container(ctx, props)
            ctx.image props[:image]
            ctx.vcpus props[:vcpus] if props[:vcpus]
            ctx.memory props[:memory] if props[:memory]
            ctx.job_role_arn props[:job_role_arn] if props[:job_role_arn]
            ctx.execution_role_arn props[:execution_role_arn] if props[:execution_role_arn]
            ctx.command props[:command] if props[:command]
            ctx.user props[:user] if props[:user]
            ctx.instance_type props[:instance_type] if props[:instance_type]
            ctx.privileged props[:privileged] if props[:privileged]
            ctx.readonly_root_filesystem props[:readonly_root_filesystem] if props[:readonly_root_filesystem]

            synthesize_environment(ctx, props[:environment])
            synthesize_mount_points(ctx, props[:mount_points])
            synthesize_volumes(ctx, props[:volumes])
            synthesize_resource_requirements(ctx, props[:resource_requirements])
            synthesize_network_config(ctx, props[:network_configuration])
            synthesize_fargate_config(ctx, props[:fargate_platform_configuration])
          end

          def synthesize_nodes(ctx, props)
            ctx.main_node props[:main_node]
            ctx.num_nodes props[:num_nodes]

            props[:node_range_properties]&.each do |node_range|
              ctx.node_range_properties do
                target_nodes node_range[:target_nodes]
                synthesize_node_container(self, node_range[:container]) if node_range[:container]
              end
            end
          end

          private

          def synthesize_environment(ctx, env_vars)
            return unless env_vars

            env_vars.each do |env|
              ctx.environment { name env[:name]; value env[:value] }
            end
          end

          def synthesize_mount_points(ctx, mounts)
            return unless mounts

            mounts.each do |mp|
              ctx.mount_points do
                source_volume mp[:source_volume]
                container_path mp[:container_path]
                read_only mp[:read_only] if mp.key?(:read_only)
              end
            end
          end

          def synthesize_volumes(ctx, volumes)
            return unless volumes

            volumes.each { |vol| synthesize_single_volume(ctx, vol) }
          end

          def synthesize_single_volume(ctx, vol)
            ctx.volumes do
              name vol[:name]
              synthesize_host_config(self, vol[:host]) if vol[:host]
              synthesize_efs_config(self, vol[:efs_volume_configuration]) if vol[:efs_volume_configuration]
            end
          end

          def synthesize_host_config(ctx, host)
            ctx.host { source_path host[:source_path] if host[:source_path] }
          end

          def synthesize_efs_config(ctx, efs)
            ctx.efs_volume_configuration do
              file_system_id efs[:file_system_id]
              root_directory efs[:root_directory] if efs[:root_directory]
              transit_encryption efs[:transit_encryption] if efs[:transit_encryption]
              if efs[:authorization_config]
                authorization_config do
                  access_point_id efs[:authorization_config][:access_point_id]
                  iam efs[:authorization_config][:iam] if efs[:authorization_config][:iam]
                end
              end
            end
          end

          def synthesize_resource_requirements(ctx, reqs)
            return unless reqs

            reqs.each do |req|
              ctx.resource_requirements { type req[:type]; value req[:value] }
            end
          end

          def synthesize_network_config(ctx, config)
            return unless config

            ctx.network_configuration { assign_public_ip config[:assign_public_ip] }
          end

          def synthesize_fargate_config(ctx, config)
            return unless config

            ctx.fargate_platform_configuration { platform_version config[:platform_version] }
          end

          def synthesize_node_container(ctx, container)
            ctx.container do
              image container[:image]
              vcpus container[:vcpus] if container[:vcpus]
              memory container[:memory] if container[:memory]
              job_role_arn container[:job_role_arn] if container[:job_role_arn]
              container[:environment]&.each do |env|
                environment { name env[:name]; value env[:value] }
              end
            end
          end
        end
      end
    end
  end
end
