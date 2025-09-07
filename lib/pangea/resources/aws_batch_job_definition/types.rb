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


require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # AWS Batch Job Definition attributes with validation
        class BatchJobDefinitionAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Core attributes
          attribute :job_definition_name, Resources::Types::String
          attribute :type, Resources::Types::String
          
          # Optional attributes
          attribute? :container_properties, Resources::Types::Hash.optional
          attribute? :node_properties, Resources::Types::Hash.optional
          attribute? :retry_strategy, Resources::Types::Hash.optional
          attribute? :timeout, Resources::Types::Hash.optional
          attribute? :propagate_tags, Resources::Types::Bool.optional
          attribute? :platform_capabilities, Resources::Types::Array.optional
          attribute? :tags, Resources::Types::Hash.optional
          
          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate job definition name
            if attrs[:job_definition_name]
              validate_job_definition_name(attrs[:job_definition_name])
            end
            
            # Validate job type
            if attrs[:type] && !%w[container multinode].include?(attrs[:type])
              raise Dry::Struct::Error, "Job definition type must be 'container' or 'multinode'"
            end
            
            # Validate container properties for container jobs
            if attrs[:type] == "container" && attrs[:container_properties]
              validate_container_properties(attrs[:container_properties])
            end
            
            # Validate node properties for multinode jobs
            if attrs[:type] == "multinode" && attrs[:node_properties]
              validate_node_properties(attrs[:node_properties])
            end
            
            # Validate retry strategy
            if attrs[:retry_strategy]
              validate_retry_strategy(attrs[:retry_strategy])
            end
            
            # Validate timeout
            if attrs[:timeout]
              validate_timeout(attrs[:timeout])
            end
            
            # Validate platform capabilities
            if attrs[:platform_capabilities]
              validate_platform_capabilities(attrs[:platform_capabilities])
            end
            
            super(attrs)
          end
          
          def self.validate_job_definition_name(name)
            # Name must be 1-128 characters
            if name.length < 1 || name.length > 128
              raise Dry::Struct::Error, "Job definition name must be between 1 and 128 characters"
            end
            
            # Must contain only alphanumeric, hyphens, and underscores
            unless name.match?(/^[a-zA-Z0-9\-_]+$/)
              raise Dry::Struct::Error, "Job definition name can only contain letters, numbers, hyphens, and underscores"
            end
            
            true
          end
          
          def self.validate_container_properties(properties)
            unless properties.is_a?(Hash)
              raise Dry::Struct::Error, "Container properties must be a hash"
            end
            
            # Validate required image field
            unless properties[:image] && properties[:image].is_a?(String) && !properties[:image].empty?
              raise Dry::Struct::Error, "Container properties must include a non-empty 'image' field"
            end
            
            # Validate vCPUs
            if properties[:vcpus]
              unless properties[:vcpus].is_a?(Integer) && properties[:vcpus] > 0
                raise Dry::Struct::Error, "vCPUs must be a positive integer"
              end
            end
            
            # Validate memory
            if properties[:memory]
              unless properties[:memory].is_a?(Integer) && properties[:memory] > 0
                raise Dry::Struct::Error, "Memory must be a positive integer (MB)"
              end
            end
            
            # Validate job role ARN format
            if properties[:job_role_arn] && !properties[:job_role_arn].match?(/^arn:aws:iam::/)
              raise Dry::Struct::Error, "Job role ARN must be a valid IAM role ARN"
            end
            
            # Validate execution role ARN format
            if properties[:execution_role_arn] && !properties[:execution_role_arn].match?(/^arn:aws:iam::/)
              raise Dry::Struct::Error, "Execution role ARN must be a valid IAM role ARN"
            end
            
            # Validate environment variables
            if properties[:environment]
              validate_environment_variables(properties[:environment])
            end
            
            # Validate mount points
            if properties[:mount_points]
              validate_mount_points(properties[:mount_points])
            end
            
            # Validate volumes
            if properties[:volumes]
              validate_volumes(properties[:volumes])
            end
            
            true
          end
          
          def self.validate_node_properties(properties)
            unless properties.is_a?(Hash)
              raise Dry::Struct::Error, "Node properties must be a hash"
            end
            
            # Validate main node
            unless properties[:main_node] && properties[:main_node].is_a?(Integer) && properties[:main_node] >= 0
              raise Dry::Struct::Error, "Node properties must include a non-negative main_node index"
            end
            
            # Validate number of nodes
            unless properties[:num_nodes] && properties[:num_nodes].is_a?(Integer) && properties[:num_nodes] > 0
              raise Dry::Struct::Error, "Node properties must include a positive num_nodes value"
            end
            
            # Validate node range properties
            unless properties[:node_range_properties] && properties[:node_range_properties].is_a?(Array)
              raise Dry::Struct::Error, "Node properties must include node_range_properties array"
            end
            
            properties[:node_range_properties].each_with_index do |node_range, index|
              unless node_range.is_a?(Hash)
                raise Dry::Struct::Error, "Node range property #{index} must be a hash"
              end
              
              unless node_range[:target_nodes] && node_range[:target_nodes].is_a?(String)
                raise Dry::Struct::Error, "Node range property #{index} must include target_nodes string"
              end
              
              if node_range[:container] 
                validate_container_properties(node_range[:container])
              end
            end
            
            true
          end
          
          def self.validate_environment_variables(env_vars)
            unless env_vars.is_a?(Array)
              raise Dry::Struct::Error, "Environment variables must be an array"
            end
            
            env_vars.each_with_index do |env_var, index|
              unless env_var.is_a?(Hash) && env_var[:name] && env_var.key?(:value)
                raise Dry::Struct::Error, "Environment variable #{index} must have 'name' and 'value' fields"
              end
            end
            
            true
          end
          
          def self.validate_mount_points(mount_points)
            unless mount_points.is_a?(Array)
              raise Dry::Struct::Error, "Mount points must be an array"
            end
            
            mount_points.each_with_index do |mount_point, index|
              unless mount_point.is_a?(Hash)
                raise Dry::Struct::Error, "Mount point #{index} must be a hash"
              end
              
              required_fields = %i[source_volume container_path]
              required_fields.each do |field|
                unless mount_point[field] && mount_point[field].is_a?(String) && !mount_point[field].empty?
                  raise Dry::Struct::Error, "Mount point #{index} must include non-empty '#{field}'"
                end
              end
            end
            
            true
          end
          
          def self.validate_volumes(volumes)
            unless volumes.is_a?(Array)
              raise Dry::Struct::Error, "Volumes must be an array"
            end
            
            volumes.each_with_index do |volume, index|
              unless volume.is_a?(Hash) && volume[:name] && volume[:name].is_a?(String)
                raise Dry::Struct::Error, "Volume #{index} must have a 'name' field"
              end
            end
            
            true
          end
          
          def self.validate_retry_strategy(retry_strategy)
            unless retry_strategy.is_a?(Hash)
              raise Dry::Struct::Error, "Retry strategy must be a hash"
            end
            
            if retry_strategy[:attempts]
              unless retry_strategy[:attempts].is_a?(Integer) && retry_strategy[:attempts] >= 1 && retry_strategy[:attempts] <= 10
                raise Dry::Struct::Error, "Retry attempts must be between 1 and 10"
              end
            end
            
            true
          end
          
          def self.validate_timeout(timeout)
            unless timeout.is_a?(Hash)
              raise Dry::Struct::Error, "Timeout must be a hash"
            end
            
            if timeout[:attempt_duration_seconds]
              unless timeout[:attempt_duration_seconds].is_a?(Integer) && timeout[:attempt_duration_seconds] >= 60
                raise Dry::Struct::Error, "Timeout duration must be at least 60 seconds"
              end
            end
            
            true
          end
          
          def self.validate_platform_capabilities(capabilities)
            unless capabilities.is_a?(Array)
              raise Dry::Struct::Error, "Platform capabilities must be an array"
            end
            
            valid_capabilities = %w[EC2 FARGATE]
            capabilities.each do |capability|
              unless valid_capabilities.include?(capability)
                raise Dry::Struct::Error, "Invalid platform capability '#{capability}'. Valid: #{valid_capabilities.join(', ')}"
              end
            end
            
            true
          end
          
          # Computed properties
          def is_container_job?
            type == "container"
          end
          
          def is_multinode_job?
            type == "multinode"
          end
          
          def supports_ec2?
            platform_capabilities.nil? || platform_capabilities.include?("EC2")
          end
          
          def supports_fargate?
            platform_capabilities&.include?("FARGATE")
          end
          
          def has_retry_strategy?
            !retry_strategy.nil?
          end
          
          def has_timeout?
            !timeout.nil?
          end
          
          def estimated_memory_mb
            return nil unless container_properties&.dig(:memory)
            container_properties[:memory]
          end
          
          def estimated_vcpus
            return nil unless container_properties&.dig(:vcpus)
            container_properties[:vcpus]
          end
          
          # Job definition templates
          def self.simple_container_job(name, image, options = {})
            {
              job_definition_name: name,
              type: "container",
              container_properties: {
                image: image,
                vcpus: options[:vcpus] || 1,
                memory: options[:memory] || 512,
                job_role_arn: options[:job_role_arn]
              }.compact,
              retry_strategy: options[:retry_attempts] ? { attempts: options[:retry_attempts] } : nil,
              timeout: options[:timeout_seconds] ? { attempt_duration_seconds: options[:timeout_seconds] } : nil,
              platform_capabilities: options[:platform_capabilities],
              tags: options[:tags] || {}
            }.compact
          end
          
          def self.fargate_container_job(name, image, options = {})
            {
              job_definition_name: name,
              type: "container",
              platform_capabilities: ["FARGATE"],
              container_properties: {
                image: image,
                vcpus: options[:vcpus] || 1,
                memory: options[:memory] || 512,
                execution_role_arn: options[:execution_role_arn], # Required for Fargate
                job_role_arn: options[:job_role_arn],
                network_configuration: {
                  assign_public_ip: options[:assign_public_ip] || "DISABLED"
                },
                fargate_platform_configuration: {
                  platform_version: options[:platform_version] || "LATEST"
                }
              }.compact,
              retry_strategy: options[:retry_attempts] ? { attempts: options[:retry_attempts] } : nil,
              timeout: options[:timeout_seconds] ? { attempt_duration_seconds: options[:timeout_seconds] } : nil,
              tags: options[:tags] || {}
            }.compact
          end
          
          def self.gpu_container_job(name, image, options = {})
            {
              job_definition_name: name,
              type: "container",
              container_properties: {
                image: image,
                vcpus: options[:vcpus] || 4,
                memory: options[:memory] || 8192,
                job_role_arn: options[:job_role_arn],
                resource_requirements: [
                  {
                    type: "GPU",
                    value: (options[:gpu_count] || 1).to_s
                  }
                ]
              }.compact,
              retry_strategy: options[:retry_attempts] ? { attempts: options[:retry_attempts] } : nil,
              timeout: options[:timeout_seconds] ? { attempt_duration_seconds: options[:timeout_seconds] } : nil,
              tags: (options[:tags] || {}).merge(Hardware: "gpu"),
              platform_capabilities: ["EC2"] # GPU only supported on EC2
            }.compact
          end
          
          def self.multinode_job(name, image, num_nodes, options = {})
            {
              job_definition_name: name,
              type: "multinode",
              node_properties: {
                main_node: options[:main_node] || 0,
                num_nodes: num_nodes,
                node_range_properties: [
                  {
                    target_nodes: "0:#{num_nodes - 1}",
                    container: {
                      image: image,
                      vcpus: options[:vcpus] || 2,
                      memory: options[:memory] || 2048,
                      job_role_arn: options[:job_role_arn]
                    }.compact
                  }
                ]
              },
              retry_strategy: options[:retry_attempts] ? { attempts: options[:retry_attempts] } : nil,
              timeout: options[:timeout_seconds] ? { attempt_duration_seconds: options[:timeout_seconds] } : nil,
              platform_capabilities: ["EC2"], # Multinode only on EC2
              tags: (options[:tags] || {}).merge(Type: "multinode")
            }.compact
          end
          
          # Workload-specific templates
          def self.data_processing_job(name, image, options = {})
            simple_container_job(
              name,
              image,
              {
                vcpus: options[:vcpus] || 2,
                memory: options[:memory] || 4096,
                retry_attempts: options[:retry_attempts] || 3,
                timeout_seconds: options[:timeout_seconds] || 3600, # 1 hour
                job_role_arn: options[:job_role_arn],
                platform_capabilities: options[:platform_capabilities],
                tags: (options[:tags] || {}).merge(
                  Workload: "data-processing",
                  Type: "cpu-intensive"
                )
              }
            )
          end
          
          def self.ml_training_job(name, image, options = {})
            gpu_container_job(
              name,
              image,
              {
                vcpus: options[:vcpus] || 8,
                memory: options[:memory] || 16384,
                gpu_count: options[:gpu_count] || 1,
                retry_attempts: options[:retry_attempts] || 2,
                timeout_seconds: options[:timeout_seconds] || 14400, # 4 hours
                job_role_arn: options[:job_role_arn],
                tags: (options[:tags] || {}).merge(
                  Workload: "ml-training",
                  Hardware: "gpu",
                  Type: "gpu-intensive"
                )
              }
            )
          end
          
          def self.batch_processing_job(name, image, options = {})
            simple_container_job(
              name,
              image,
              {
                vcpus: options[:vcpus] || 1,
                memory: options[:memory] || 1024,
                retry_attempts: options[:retry_attempts] || 5, # High retry for batch jobs
                timeout_seconds: options[:timeout_seconds] || 7200, # 2 hours
                job_role_arn: options[:job_role_arn],
                platform_capabilities: options[:platform_capabilities] || ["EC2"], # Prefer EC2 for batch
                tags: (options[:tags] || {}).merge(
                  Workload: "batch-processing",
                  Priority: "background",
                  Type: "background"
                )
              }
            )
          end
          
          def self.real_time_job(name, image, options = {})
            fargate_container_job(
              name,
              image,
              {
                vcpus: options[:vcpus] || 2,
                memory: options[:memory] || 2048,
                retry_attempts: options[:retry_attempts] || 1, # Minimal retry for real-time
                timeout_seconds: options[:timeout_seconds] || 300, # 5 minutes
                execution_role_arn: options[:execution_role_arn],
                job_role_arn: options[:job_role_arn],
                assign_public_ip: options[:assign_public_ip],
                tags: (options[:tags] || {}).merge(
                  Workload: "real-time",
                  Latency: "critical",
                  Type: "latency-sensitive"
                )
              }
            )
          end
          
          # Common container configurations
          def self.standard_environment_variables(options = {})
            base_vars = [
              { name: "AWS_DEFAULT_REGION", value: options[:region] || "us-east-1" },
              { name: "BATCH_JOB_ID", value: "${AWS_BATCH_JOB_ID}" },
              { name: "BATCH_JOB_ATTEMPT", value: "${AWS_BATCH_JOB_ATTEMPT}" }
            ]
            
            # Add custom environment variables
            if options[:custom_vars]
              base_vars.concat(options[:custom_vars])
            end
            
            base_vars
          end
          
          def self.common_resource_requirements(gpu_count = nil)
            requirements = []
            
            if gpu_count
              requirements << {
                type: "GPU",
                value: gpu_count.to_s
              }
            end
            
            requirements
          end
          
          # Volume configurations
          def self.efs_volume(volume_name, file_system_id, options = {})
            {
              name: volume_name,
              efs_volume_configuration: {
                file_system_id: file_system_id,
                root_directory: options[:root_directory] || "/",
                transit_encryption: options[:transit_encryption] || "ENABLED",
                authorization_config: options[:authorization_config]
              }.compact
            }
          end
          
          def self.host_volume(volume_name, host_path)
            {
              name: volume_name,
              host: {
                source_path: host_path
              }
            }
          end
          
          # Mount point configurations
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