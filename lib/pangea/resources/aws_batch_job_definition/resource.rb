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
require_relative 'types'

module Pangea
  module Resources
    module AWS
      # AWS Batch Job Definition implementation
      # Provides type-safe function for creating job definitions
      def aws_batch_job_definition(name, attributes = {})
        # Validate attributes using dry-struct
        validated_attrs = Types::Types::BatchJobDefinitionAttributes.new(attributes)
        
        # Create reference that will be returned
        ref = ResourceReference.new(
          type: 'aws_batch_job_definition',
          name: name,
          resource_attributes: validated_attrs.to_h,
          outputs: {
            id: "${aws_batch_job_definition.#{name}.id}",
            arn: "${aws_batch_job_definition.#{name}.arn}",
            name: "${aws_batch_job_definition.#{name}.name}",
            revision: "${aws_batch_job_definition.#{name}.revision}",
            tags_all: "${aws_batch_job_definition.#{name}.tags_all}"
          }
        )
        
        # Synthesize the Terraform resource
        resource :aws_batch_job_definition, name do
          job_definition_name validated_attrs.job_definition_name
          type validated_attrs.type
          
          # Container properties for container jobs
          if validated_attrs.container_properties
            container_properties do
              image validated_attrs.container_properties[:image]
              
              if validated_attrs.container_properties[:vcpus]
                vcpus validated_attrs.container_properties[:vcpus]
              end
              
              if validated_attrs.container_properties[:memory]
                memory validated_attrs.container_properties[:memory]
              end
              
              if validated_attrs.container_properties[:job_role_arn]
                job_role_arn validated_attrs.container_properties[:job_role_arn]
              end
              
              if validated_attrs.container_properties[:execution_role_arn]
                execution_role_arn validated_attrs.container_properties[:execution_role_arn]
              end
              
              # Environment variables
              if validated_attrs.container_properties[:environment]
                validated_attrs.container_properties[:environment].each do |env_var|
                  environment do
                    name env_var[:name]
                    value env_var[:value]
                  end
                end
              end
              
              # Mount points
              if validated_attrs.container_properties[:mount_points]
                validated_attrs.container_properties[:mount_points].each do |mount_point|
                  mount_points do
                    source_volume mount_point[:source_volume]
                    container_path mount_point[:container_path]
                    read_only mount_point[:read_only] if mount_point.key?(:read_only)
                  end
                end
              end
              
              # Volumes
              if validated_attrs.container_properties[:volumes]
                validated_attrs.container_properties[:volumes].each do |volume|
                  volumes do
                    name volume[:name]
                    
                    if volume[:host]
                      host do
                        source_path volume[:host][:source_path] if volume[:host][:source_path]
                      end
                    end
                    
                    if volume[:efs_volume_configuration]
                      efs_volume_configuration do
                        file_system_id volume[:efs_volume_configuration][:file_system_id]
                        
                        if volume[:efs_volume_configuration][:root_directory]
                          root_directory volume[:efs_volume_configuration][:root_directory]
                        end
                        
                        if volume[:efs_volume_configuration][:transit_encryption]
                          transit_encryption volume[:efs_volume_configuration][:transit_encryption]
                        end
                        
                        if volume[:efs_volume_configuration][:authorization_config]
                          authorization_config do
                            access_point_id volume[:efs_volume_configuration][:authorization_config][:access_point_id]
                            iam volume[:efs_volume_configuration][:authorization_config][:iam] if volume[:efs_volume_configuration][:authorization_config][:iam]
                          end
                        end
                      end
                    end
                  end
                end
              end
              
              # Resource requirements
              if validated_attrs.container_properties[:resource_requirements]
                validated_attrs.container_properties[:resource_requirements].each do |requirement|
                  resource_requirements do
                    type requirement[:type]
                    value requirement[:value]
                  end
                end
              end
              
              # Network configuration (for Fargate)
              if validated_attrs.container_properties[:network_configuration]
                network_configuration do
                  assign_public_ip validated_attrs.container_properties[:network_configuration][:assign_public_ip]
                end
              end
              
              # Fargate platform configuration
              if validated_attrs.container_properties[:fargate_platform_configuration]
                fargate_platform_configuration do
                  platform_version validated_attrs.container_properties[:fargate_platform_configuration][:platform_version]
                end
              end
              
              # Other container properties
              if validated_attrs.container_properties[:command]
                command validated_attrs.container_properties[:command]
              end
              
              if validated_attrs.container_properties[:user]
                user validated_attrs.container_properties[:user]
              end
              
              if validated_attrs.container_properties[:instance_type]
                instance_type validated_attrs.container_properties[:instance_type]
              end
              
              if validated_attrs.container_properties[:privileged]
                privileged validated_attrs.container_properties[:privileged]
              end
              
              if validated_attrs.container_properties[:readonly_root_filesystem]
                readonly_root_filesystem validated_attrs.container_properties[:readonly_root_filesystem]
              end
            end
          end
          
          # Node properties for multinode jobs
          if validated_attrs.node_properties
            node_properties do
              main_node validated_attrs.node_properties[:main_node]
              num_nodes validated_attrs.node_properties[:num_nodes]
              
              validated_attrs.node_properties[:node_range_properties].each do |node_range|
                node_range_properties do
                  target_nodes node_range[:target_nodes]
                  
                  if node_range[:container]
                    container do
                      image node_range[:container][:image]
                      
                      if node_range[:container][:vcpus]
                        vcpus node_range[:container][:vcpus]
                      end
                      
                      if node_range[:container][:memory]
                        memory node_range[:container][:memory]
                      end
                      
                      if node_range[:container][:job_role_arn]
                        job_role_arn node_range[:container][:job_role_arn]
                      end
                      
                      # Environment variables for node
                      if node_range[:container][:environment]
                        node_range[:container][:environment].each do |env_var|
                          environment do
                            name env_var[:name]
                            value env_var[:value]
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
          
          # Retry strategy
          if validated_attrs.retry_strategy
            retry_strategy do
              attempts validated_attrs.retry_strategy[:attempts] if validated_attrs.retry_strategy[:attempts]
            end
          end
          
          # Timeout
          if validated_attrs.timeout
            timeout do
              attempt_duration_seconds validated_attrs.timeout[:attempt_duration_seconds]
            end
          end
          
          # Platform capabilities
          if validated_attrs.platform_capabilities
            platform_capabilities validated_attrs.platform_capabilities
          end
          
          # Propagate tags
          if validated_attrs.propagate_tags
            propagate_tags validated_attrs.propagate_tags
          end
          
          # Tags
          if validated_attrs.tags
            tags validated_attrs.tags
          end
        end
        
        # Return the reference
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)