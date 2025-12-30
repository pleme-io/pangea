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
        class BatchJobDefinitionAttributes
          # Common container configurations
          module Configurations
            def self.standard_environment_variables(options = {})
              base_vars = [
                { name: 'AWS_DEFAULT_REGION', value: options[:region] || 'us-east-1' },
                { name: 'BATCH_JOB_ID', value: '${AWS_BATCH_JOB_ID}' },
                { name: 'BATCH_JOB_ATTEMPT', value: '${AWS_BATCH_JOB_ATTEMPT}' }
              ]

              base_vars.concat(options[:custom_vars]) if options[:custom_vars]

              base_vars
            end

            def self.common_resource_requirements(gpu_count = nil)
              requirements = []

              requirements << { type: 'GPU', value: gpu_count.to_s } if gpu_count

              requirements
            end

            def self.efs_volume(volume_name, file_system_id, options = {})
              {
                name: volume_name,
                efs_volume_configuration: {
                  file_system_id: file_system_id,
                  root_directory: options[:root_directory] || '/',
                  transit_encryption: options[:transit_encryption] || 'ENABLED',
                  authorization_config: options[:authorization_config]
                }.compact
              }
            end

            def self.host_volume(volume_name, host_path)
              {
                name: volume_name,
                host: { source_path: host_path }
              }
            end

            def self.standard_mount_point(volume_name, container_path, read_only = false)
              {
                source_volume: volume_name,
                container_path: container_path,
                read_only: read_only
              }
            end
          end
        end
      end
    end
  end
end
