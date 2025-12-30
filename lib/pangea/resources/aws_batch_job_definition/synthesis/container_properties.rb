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
      # Synthesis helpers for AWS Batch Job Definition container properties
      module BatchJobDefinitionContainerSynthesis
        private

        def synthesize_container_properties(container_props)
          container_properties do
            image container_props[:image]

            synthesize_container_resources(container_props)
            synthesize_container_roles(container_props)
            synthesize_container_environment(container_props)
            synthesize_container_mounts(container_props)
            synthesize_container_volumes(container_props)
            synthesize_container_resource_requirements(container_props)
            synthesize_container_network_config(container_props)
            synthesize_container_fargate_config(container_props)
            synthesize_container_misc(container_props)
          end
        end

        def synthesize_container_resources(props)
          vcpus props[:vcpus] if props[:vcpus]
          memory props[:memory] if props[:memory]
        end

        def synthesize_container_roles(props)
          job_role_arn props[:job_role_arn] if props[:job_role_arn]
          execution_role_arn props[:execution_role_arn] if props[:execution_role_arn]
        end

        def synthesize_container_environment(props)
          return unless props[:environment]

          props[:environment].each do |env_var|
            environment do
              name env_var[:name]
              value env_var[:value]
            end
          end
        end

        def synthesize_container_mounts(props)
          return unless props[:mount_points]

          props[:mount_points].each do |mount_point|
            mount_points do
              source_volume mount_point[:source_volume]
              container_path mount_point[:container_path]
              read_only mount_point[:read_only] if mount_point.key?(:read_only)
            end
          end
        end

        def synthesize_container_volumes(props)
          return unless props[:volumes]

          props[:volumes].each do |volume|
            volumes do
              name volume[:name]
              synthesize_volume_host(volume[:host]) if volume[:host]
              synthesize_volume_efs(volume[:efs_volume_configuration]) if volume[:efs_volume_configuration]
            end
          end
        end

        def synthesize_volume_host(host_config)
          host do
            source_path host_config[:source_path] if host_config[:source_path]
          end
        end

        def synthesize_volume_efs(efs_config)
          efs_volume_configuration do
            file_system_id efs_config[:file_system_id]
            root_directory efs_config[:root_directory] if efs_config[:root_directory]
            transit_encryption efs_config[:transit_encryption] if efs_config[:transit_encryption]
            synthesize_efs_authorization(efs_config[:authorization_config]) if efs_config[:authorization_config]
          end
        end

        def synthesize_efs_authorization(auth_config)
          authorization_config do
            access_point_id auth_config[:access_point_id]
            iam auth_config[:iam] if auth_config[:iam]
          end
        end

        def synthesize_container_resource_requirements(props)
          return unless props[:resource_requirements]

          props[:resource_requirements].each do |requirement|
            resource_requirements do
              type requirement[:type]
              value requirement[:value]
            end
          end
        end

        def synthesize_container_network_config(props)
          return unless props[:network_configuration]

          network_configuration do
            assign_public_ip props[:network_configuration][:assign_public_ip]
          end
        end

        def synthesize_container_fargate_config(props)
          return unless props[:fargate_platform_configuration]

          fargate_platform_configuration do
            platform_version props[:fargate_platform_configuration][:platform_version]
          end
        end

        def synthesize_container_misc(props)
          command props[:command] if props[:command]
          user props[:user] if props[:user]
          instance_type props[:instance_type] if props[:instance_type]
          privileged props[:privileged] if props[:privileged]
          readonly_root_filesystem props[:readonly_root_filesystem] if props[:readonly_root_filesystem]
        end
      end
    end
  end
end
