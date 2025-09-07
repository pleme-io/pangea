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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_ecs_task_definition/types'
require 'pangea/resource_registry'
require 'json'

module Pangea
  module Resources
    module AWS
      # Create an AWS ECS Task Definition with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] ECS task definition attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_ecs_task_definition(name, attributes = {})
        # Validate attributes using dry-struct
        task_attrs = AWS::Types::Types::EcsTaskDefinitionAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_ecs_task_definition, name) do
          # Family name
          family task_attrs.family
          
          # Container definitions as JSON
          container_definitions_json = task_attrs.container_definitions.map do |container|
            container_hash = {
              name: container.name,
              image: container.image,
              essential: container.essential
            }
            
            # Add optional fields only if present
            container_hash[:cpu] = container.cpu if container.cpu
            container_hash[:memory] = container.memory if container.memory
            container_hash[:memoryReservation] = container.memory_reservation if container.memory_reservation
            
            # Port mappings
            if container.port_mappings.any?
              container_hash[:portMappings] = container.port_mappings.map do |pm|
                pm_hash = { containerPort: pm[:container_port] }
                pm_hash[:hostPort] = pm[:host_port] if pm[:host_port]
                pm_hash[:protocol] = pm[:protocol] if pm[:protocol]
                pm_hash[:name] = pm[:name] if pm[:name]
                pm_hash[:appProtocol] = pm[:app_protocol] if pm[:app_protocol]
                pm_hash
              end
            end
            
            # Environment variables
            container_hash[:environment] = container.environment if container.environment.any?
            
            # Secrets
            container_hash[:secrets] = container.secrets.map { |s| { name: s[:name], valueFrom: s[:value_from] } } if container.secrets.any?
            
            # Log configuration
            if container.log_configuration
              log_config = { logDriver: container.log_configuration[:log_driver] }
              log_config[:options] = container.log_configuration[:options] if container.log_configuration[:options]
              log_config[:secretOptions] = container.log_configuration[:secret_options] if container.log_configuration[:secret_options]
              container_hash[:logConfiguration] = log_config
            end
            
            # Health check
            if container.health_check
              hc = { command: container.health_check[:command] }
              hc[:interval] = container.health_check[:interval] if container.health_check[:interval]
              hc[:timeout] = container.health_check[:timeout] if container.health_check[:timeout]
              hc[:retries] = container.health_check[:retries] if container.health_check[:retries]
              hc[:startPeriod] = container.health_check[:start_period] if container.health_check[:start_period]
              container_hash[:healthCheck] = hc
            end
            
            # Other container fields
            container_hash[:entryPoint] = container.entry_point if container.entry_point.any?
            container_hash[:command] = container.command if container.command.any?
            container_hash[:workingDirectory] = container.working_directory if container.working_directory
            container_hash[:links] = container.links if container.links.any?
            
            # Mount points
            if container.mount_points.any?
              container_hash[:mountPoints] = container.mount_points.map do |mp|
                mp_hash = { sourceVolume: mp[:source_volume], containerPath: mp[:container_path] }
                mp_hash[:readOnly] = mp[:read_only] unless mp[:read_only].nil?
                mp_hash
              end
            end
            
            # Volumes from
            if container.volumes_from.any?
              container_hash[:volumesFrom] = container.volumes_from.map do |vf|
                vf_hash = { sourceContainer: vf[:source_container] }
                vf_hash[:readOnly] = vf[:read_only] unless vf[:read_only].nil?
                vf_hash
              end
            end
            
            # Dependencies
            if container.depends_on.any?
              container_hash[:dependsOn] = container.depends_on.map do |dep|
                { containerName: dep[:container_name], condition: dep[:condition] }
              end
            end
            
            # Linux parameters
            if container.linux_parameters
              lp = {}
              lp[:capabilities] = container.linux_parameters[:capabilities] if container.linux_parameters[:capabilities]
              lp[:devices] = container.linux_parameters[:devices] if container.linux_parameters[:devices]
              lp[:initProcessEnabled] = container.linux_parameters[:init_process_enabled] unless container.linux_parameters[:init_process_enabled].nil?
              lp[:maxSwap] = container.linux_parameters[:max_swap] if container.linux_parameters[:max_swap]
              lp[:sharedMemorySize] = container.linux_parameters[:shared_memory_size] if container.linux_parameters[:shared_memory_size]
              lp[:swappiness] = container.linux_parameters[:swappiness] if container.linux_parameters[:swappiness]
              lp[:tmpfs] = container.linux_parameters[:tmpfs] if container.linux_parameters[:tmpfs]
              container_hash[:linuxParameters] = lp
            end
            
            # Other container attributes
            container_hash[:ulimits] = container.ulimits.map { |u| { name: u[:name], softLimit: u[:soft_limit], hardLimit: u[:hard_limit] } } if container.ulimits.any?
            container_hash[:user] = container.user if container.user
            container_hash[:privileged] = container.privileged if container.privileged
            container_hash[:readonlyRootFilesystem] = container.readonly_root_filesystem if container.readonly_root_filesystem
            container_hash[:dnsServers] = container.dns_servers if container.dns_servers.any?
            container_hash[:dnsSearchDomains] = container.dns_search_domains if container.dns_search_domains.any?
            container_hash[:extraHosts] = container.extra_hosts.map { |eh| { hostname: eh[:hostname], ipAddress: eh[:ip_address] } } if container.extra_hosts.any?
            container_hash[:dockerSecurityOptions] = container.docker_security_options if container.docker_security_options.any?
            container_hash[:dockerLabels] = container.docker_labels if container.docker_labels.any?
            container_hash[:systemControls] = container.system_controls if container.system_controls.any?
            
            # FireLens configuration
            if container.firelens_configuration
              container_hash[:firelensConfiguration] = {
                type: container.firelens_configuration[:type],
                options: container.firelens_configuration[:options]
              }.compact
            end
            
            container_hash
          end
          
          container_definitions JSON.pretty_generate(container_definitions_json)
          
          # Task and execution roles
          task_role_arn task_attrs.task_role_arn if task_attrs.task_role_arn
          execution_role_arn task_attrs.execution_role_arn if task_attrs.execution_role_arn
          
          # Network mode
          network_mode task_attrs.network_mode
          
          # Compatibility
          requires_compatibilities task_attrs.requires_compatibilities
          
          # CPU and memory
          cpu task_attrs.cpu if task_attrs.cpu
          memory task_attrs.memory if task_attrs.memory
          
          # Volumes
          task_attrs.volumes.each do |volume|
            volume do
              name volume[:name]
              
              # Host volume
              if volume[:host]
                host do
                  source_path volume[:host][:source_path] if volume[:host][:source_path]
                end
              end
              
              # Docker volume
              if volume[:docker_volume_configuration]
                docker_volume_configuration do
                  dvc = volume[:docker_volume_configuration]
                  scope dvc[:scope] if dvc[:scope]
                  autoprovision dvc[:autoprovision] unless dvc[:autoprovision].nil?
                  driver dvc[:driver] if dvc[:driver]
                  driver_opts dvc[:driver_opts] if dvc[:driver_opts]
                  labels dvc[:labels] if dvc[:labels]
                end
              end
              
              # EFS volume
              if volume[:efs_volume_configuration]
                efs_volume_configuration do
                  evc = volume[:efs_volume_configuration]
                  file_system_id evc[:file_system_id]
                  root_directory evc[:root_directory] if evc[:root_directory]
                  transit_encryption evc[:transit_encryption] if evc[:transit_encryption]
                  transit_encryption_port evc[:transit_encryption_port] if evc[:transit_encryption_port]
                  
                  if evc[:authorization_config]
                    authorization_config do
                      access_point_id evc[:authorization_config][:access_point_id] if evc[:authorization_config][:access_point_id]
                      iam evc[:authorization_config][:iam] if evc[:authorization_config][:iam]
                    end
                  end
                end
              end
              
              # FSx Windows volume
              if volume[:fsx_windows_file_server_volume_configuration]
                fsx_windows_file_server_volume_configuration do
                  fsx = volume[:fsx_windows_file_server_volume_configuration]
                  file_system_id fsx[:file_system_id]
                  root_directory fsx[:root_directory]
                  
                  authorization_config do
                    credentials_parameter fsx[:authorization_config][:credentials_parameter]
                    domain fsx[:authorization_config][:domain]
                  end
                end
              end
            end
          end
          
          # Placement constraints
          task_attrs.placement_constraints.each do |constraint|
            placement_constraints do
              type constraint[:type]
              expression constraint[:expression] if constraint[:expression]
            end
          end
          
          # IPC and PID mode
          ipc_mode task_attrs.ipc_mode if task_attrs.ipc_mode
          pid_mode task_attrs.pid_mode if task_attrs.pid_mode
          
          # Inference accelerators
          task_attrs.inference_accelerators.each do |accelerator|
            inference_accelerators do
              device_name accelerator[:device_name]
              device_type accelerator[:device_type]
            end
          end
          
          # Proxy configuration
          if task_attrs.proxy_configuration
            proxy_configuration do
              type task_attrs.proxy_configuration[:type] if task_attrs.proxy_configuration[:type]
              container_name task_attrs.proxy_configuration[:container_name]
              
              if task_attrs.proxy_configuration[:properties]
                properties task_attrs.proxy_configuration[:properties]
              end
            end
          end
          
          # Runtime platform
          if task_attrs.runtime_platform
            runtime_platform do
              operating_system_family task_attrs.runtime_platform[:operating_system_family] if task_attrs.runtime_platform[:operating_system_family]
              cpu_architecture task_attrs.runtime_platform[:cpu_architecture] if task_attrs.runtime_platform[:cpu_architecture]
            end
          end
          
          # Ephemeral storage
          if task_attrs.ephemeral_storage
            ephemeral_storage do
              size_in_gib task_attrs.ephemeral_storage[:size_in_gib]
            end
          end
          
          # Apply tags if present
          if task_attrs.tags.any?
            tags do
              task_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ref = ResourceReference.new(
          type: 'aws_ecs_task_definition',
          name: name,
          resource_attributes: task_attrs.to_h,
          outputs: {
            arn: "${aws_ecs_task_definition.#{name}.arn}",
            arn_without_revision: "${aws_ecs_task_definition.#{name}.arn_without_revision}",
            family: "${aws_ecs_task_definition.#{name}.family}",
            revision: "${aws_ecs_task_definition.#{name}.revision}",
            tags_all: "${aws_ecs_task_definition.#{name}.tags_all}",
            id: "${aws_ecs_task_definition.#{name}.id}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:fargate_compatible?) { task_attrs.fargate_compatible? }
        ref.define_singleton_method(:uses_efs?) { task_attrs.uses_efs? }
        ref.define_singleton_method(:total_memory_mb) { task_attrs.total_memory_mb }
        ref.define_singleton_method(:estimated_hourly_cost) { task_attrs.estimated_hourly_cost }
        ref.define_singleton_method(:main_container_name) { task_attrs.main_container.name }
        ref.define_singleton_method(:container_names) { task_attrs.container_definitions.map(&:name) }
        ref.define_singleton_method(:essential_container_count) { task_attrs.container_definitions.count(&:is_essential?) }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)