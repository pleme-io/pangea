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
          # Validation methods for batch job definitions
          module Validation
            def self.validate_job_definition_name(name)
              raise Dry::Struct::Error, 'Job definition name must be between 1 and 128 characters' if name.length < 1 || name.length > 128

              raise Dry::Struct::Error, 'Job definition name can only contain letters, numbers, hyphens, and underscores' unless name.match?(/^[a-zA-Z0-9\-_]+$/)

              true
            end

            def self.validate_container_properties(properties)
              raise Dry::Struct::Error, 'Container properties must be a hash' unless properties.is_a?(Hash)

              raise Dry::Struct::Error, "Container properties must include a non-empty 'image' field" unless properties[:image] && properties[:image].is_a?(String) && !properties[:image].empty?

              validate_vcpus(properties[:vcpus]) if properties[:vcpus]
              validate_memory(properties[:memory]) if properties[:memory]
              validate_role_arns(properties)
              validate_environment_variables(properties[:environment]) if properties[:environment]
              validate_mount_points(properties[:mount_points]) if properties[:mount_points]
              validate_volumes(properties[:volumes]) if properties[:volumes]

              true
            end

            def self.validate_vcpus(vcpus)
              raise Dry::Struct::Error, 'vCPUs must be a positive integer' unless vcpus.is_a?(Integer) && vcpus.positive?
            end

            def self.validate_memory(memory)
              raise Dry::Struct::Error, 'Memory must be a positive integer (MB)' unless memory.is_a?(Integer) && memory.positive?
            end

            def self.validate_role_arns(properties)
              raise Dry::Struct::Error, 'Job role ARN must be a valid IAM role ARN' if properties[:job_role_arn] && !properties[:job_role_arn].match?(/^arn:aws:iam::/)

              raise Dry::Struct::Error, 'Execution role ARN must be a valid IAM role ARN' if properties[:execution_role_arn] && !properties[:execution_role_arn].match?(/^arn:aws:iam::/)
            end

            def self.validate_node_properties(properties)
              raise Dry::Struct::Error, 'Node properties must be a hash' unless properties.is_a?(Hash)

              raise Dry::Struct::Error, 'Node properties must include a non-negative main_node index' unless properties[:main_node] && properties[:main_node].is_a?(Integer) && properties[:main_node] >= 0

              raise Dry::Struct::Error, 'Node properties must include a positive num_nodes value' unless properties[:num_nodes] && properties[:num_nodes].is_a?(Integer) && properties[:num_nodes].positive?

              raise Dry::Struct::Error, 'Node properties must include node_range_properties array' unless properties[:node_range_properties] && properties[:node_range_properties].is_a?(Array)

              validate_node_range_properties(properties[:node_range_properties])

              true
            end

            def self.validate_node_range_properties(node_ranges)
              node_ranges.each_with_index do |node_range, index|
                raise Dry::Struct::Error, "Node range property #{index} must be a hash" unless node_range.is_a?(Hash)

                raise Dry::Struct::Error, "Node range property #{index} must include target_nodes string" unless node_range[:target_nodes] && node_range[:target_nodes].is_a?(String)

                validate_container_properties(node_range[:container]) if node_range[:container]
              end
            end

            def self.validate_environment_variables(env_vars)
              raise Dry::Struct::Error, 'Environment variables must be an array' unless env_vars.is_a?(Array)

              env_vars.each_with_index do |env_var, index|
                raise Dry::Struct::Error, "Environment variable #{index} must have 'name' and 'value' fields" unless env_var.is_a?(Hash) && env_var[:name] && env_var.key?(:value)
              end

              true
            end

            def self.validate_mount_points(mount_points)
              raise Dry::Struct::Error, 'Mount points must be an array' unless mount_points.is_a?(Array)

              mount_points.each_with_index do |mount_point, index|
                raise Dry::Struct::Error, "Mount point #{index} must be a hash" unless mount_point.is_a?(Hash)

                %i[source_volume container_path].each do |field|
                  raise Dry::Struct::Error, "Mount point #{index} must include non-empty '#{field}'" unless mount_point[field] && mount_point[field].is_a?(String) && !mount_point[field].empty?
                end
              end

              true
            end

            def self.validate_volumes(volumes)
              raise Dry::Struct::Error, 'Volumes must be an array' unless volumes.is_a?(Array)

              volumes.each_with_index do |volume, index|
                raise Dry::Struct::Error, "Volume #{index} must have a 'name' field" unless volume.is_a?(Hash) && volume[:name] && volume[:name].is_a?(String)
              end

              true
            end

            def self.validate_retry_strategy(retry_strategy)
              raise Dry::Struct::Error, 'Retry strategy must be a hash' unless retry_strategy.is_a?(Hash)

              if retry_strategy[:attempts]
                raise Dry::Struct::Error, 'Retry attempts must be between 1 and 10' unless retry_strategy[:attempts].is_a?(Integer) && retry_strategy[:attempts] >= 1 && retry_strategy[:attempts] <= 10
              end

              true
            end

            def self.validate_timeout(timeout)
              raise Dry::Struct::Error, 'Timeout must be a hash' unless timeout.is_a?(Hash)

              if timeout[:attempt_duration_seconds]
                raise Dry::Struct::Error, 'Timeout duration must be at least 60 seconds' unless timeout[:attempt_duration_seconds].is_a?(Integer) && timeout[:attempt_duration_seconds] >= 60
              end

              true
            end

            def self.validate_platform_capabilities(capabilities)
              raise Dry::Struct::Error, 'Platform capabilities must be an array' unless capabilities.is_a?(Array)

              valid_capabilities = %w[EC2 FARGATE]
              capabilities.each do |capability|
                raise Dry::Struct::Error, "Invalid platform capability '#{capability}'. Valid: #{valid_capabilities.join(', ')}" unless valid_capabilities.include?(capability)
              end

              true
            end
          end
        end
      end
    end
  end
end
