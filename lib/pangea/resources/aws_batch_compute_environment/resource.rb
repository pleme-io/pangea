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
      # AWS Batch Compute Environment implementation
      # Provides type-safe function for creating compute environments
      def aws_batch_compute_environment(name, attributes = {})
        # Validate attributes using dry-struct
        validated_attrs = Types::Types::BatchComputeEnvironmentAttributes.new(attributes)
        
        # Create reference that will be returned
        ref = ResourceReference.new(
          type: 'aws_batch_compute_environment',
          name: name,
          resource_attributes: validated_attrs.to_h,
          outputs: {
            id: "${aws_batch_compute_environment.#{name}.id}",
            arn: "${aws_batch_compute_environment.#{name}.arn}",
            name: "${aws_batch_compute_environment.#{name}.name}",
            ecs_cluster_arn: "${aws_batch_compute_environment.#{name}.ecs_cluster_arn}",
            status: "${aws_batch_compute_environment.#{name}.status}",
            status_reason: "${aws_batch_compute_environment.#{name}.status_reason}",
            tags_all: "${aws_batch_compute_environment.#{name}.tags_all}"
          }
        )
        
        # Synthesize the Terraform resource
        resource :aws_batch_compute_environment, name do
          compute_environment_name validated_attrs.compute_environment_name
          type validated_attrs.type
          state validated_attrs.state if validated_attrs.state
          
          # Service role for managed environments
          if validated_attrs.service_role
            service_role validated_attrs.service_role
          end
          
          # Compute resources for managed environments
          if validated_attrs.compute_resources
            compute_resources do
              type validated_attrs.compute_resources[:type]
              
              # Allocation strategy
              if validated_attrs.compute_resources[:allocation_strategy]
                allocation_strategy validated_attrs.compute_resources[:allocation_strategy]
              end
              
              # vCPU configuration
              if validated_attrs.compute_resources[:min_vcpus]
                min_vcpus validated_attrs.compute_resources[:min_vcpus]
              end
              
              if validated_attrs.compute_resources[:max_vcpus]
                max_vcpus validated_attrs.compute_resources[:max_vcpus]
              end
              
              if validated_attrs.compute_resources[:desired_vcpus]
                desired_vcpus validated_attrs.compute_resources[:desired_vcpus]
              end
              
              # Instance configuration
              if validated_attrs.compute_resources[:instance_types]
                instance_types validated_attrs.compute_resources[:instance_types]
              end
              
              if validated_attrs.compute_resources[:instance_role]
                instance_role validated_attrs.compute_resources[:instance_role]
              end
              
              # Spot configuration
              if validated_attrs.compute_resources[:spot_iam_fleet_request_role]
                spot_iam_fleet_request_role validated_attrs.compute_resources[:spot_iam_fleet_request_role]
              end
              
              if validated_attrs.compute_resources[:bid_percentage]
                bid_percentage validated_attrs.compute_resources[:bid_percentage]
              end
              
              # Networking
              if validated_attrs.compute_resources[:subnets]
                subnets validated_attrs.compute_resources[:subnets]
              end
              
              if validated_attrs.compute_resources[:security_group_ids]
                security_group_ids validated_attrs.compute_resources[:security_group_ids]
              end
              
              # Platform capabilities
              if validated_attrs.compute_resources[:platform_capabilities]
                platform_capabilities validated_attrs.compute_resources[:platform_capabilities]
              end
              
              # EC2 configuration
              if validated_attrs.compute_resources[:ec2_key_pair]
                ec2_key_pair validated_attrs.compute_resources[:ec2_key_pair]
              end
              
              if validated_attrs.compute_resources[:image_id]
                image_id validated_attrs.compute_resources[:image_id]
              end
              
              # Launch template
              if validated_attrs.compute_resources[:launch_template]
                launch_template do
                  if validated_attrs.compute_resources[:launch_template][:launch_template_id]
                    launch_template_id validated_attrs.compute_resources[:launch_template][:launch_template_id]
                  end
                  
                  if validated_attrs.compute_resources[:launch_template][:launch_template_name]
                    launch_template_name validated_attrs.compute_resources[:launch_template][:launch_template_name]
                  end
                  
                  if validated_attrs.compute_resources[:launch_template][:version]
                    version validated_attrs.compute_resources[:launch_template][:version]
                  end
                end
              end
              
              # Tags for compute resources
              if validated_attrs.compute_resources[:tags]
                tags validated_attrs.compute_resources[:tags]
              end
            end
          end
          
          # Top-level tags
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