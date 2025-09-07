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
require 'pangea/resources/aws_instance/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS EC2 Instance with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] EC2 instance attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_instance(name, attributes = {})
        # Validate attributes using dry-struct
        instance_attrs = Types::InstanceAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_instance, name) do
          # Required attributes
          ami instance_attrs.ami
          instance_type instance_attrs.instance_type
          
          # Network configuration
          subnet_id instance_attrs.subnet_id if instance_attrs.subnet_id
          vpc_security_group_ids instance_attrs.vpc_security_group_ids if instance_attrs.vpc_security_group_ids.any?
          availability_zone instance_attrs.availability_zone if instance_attrs.availability_zone
          associate_public_ip_address instance_attrs.associate_public_ip_address unless instance_attrs.associate_public_ip_address.nil?
          
          # Instance configuration
          key_name instance_attrs.key_name if instance_attrs.key_name
          user_data instance_attrs.user_data if instance_attrs.user_data
          user_data_base64 instance_attrs.user_data_base64 if instance_attrs.user_data_base64
          iam_instance_profile instance_attrs.iam_instance_profile if instance_attrs.iam_instance_profile
          
          # Root block device
          if instance_attrs.root_block_device
            root_block_device do
              device = instance_attrs.root_block_device
              volume_type device[:volume_type] if device[:volume_type]
              volume_size device[:volume_size] if device[:volume_size]
              iops device[:iops] if device[:iops]
              throughput device[:throughput] if device[:throughput]
              delete_on_termination device[:delete_on_termination] unless device[:delete_on_termination].nil?
              encrypted device[:encrypted] unless device[:encrypted].nil?
              kms_key_id device[:kms_key_id] if device[:kms_key_id]
            end
          end
          
          # Additional EBS volumes
          instance_attrs.ebs_block_device.each do |ebs_device|
            ebs_block_device do
              device_name ebs_device[:device_name]
              volume_type ebs_device[:volume_type] if ebs_device[:volume_type]
              volume_size ebs_device[:volume_size] if ebs_device[:volume_size]
              iops ebs_device[:iops] if ebs_device[:iops]
              throughput ebs_device[:throughput] if ebs_device[:throughput]
              delete_on_termination ebs_device[:delete_on_termination] unless ebs_device[:delete_on_termination].nil?
              encrypted ebs_device[:encrypted] unless ebs_device[:encrypted].nil?
              kms_key_id ebs_device[:kms_key_id] if ebs_device[:kms_key_id]
              snapshot_id ebs_device[:snapshot_id] if ebs_device[:snapshot_id]
            end
          end
          
          # Instance behavior
          instance_initiated_shutdown_behavior instance_attrs.instance_initiated_shutdown_behavior if instance_attrs.instance_initiated_shutdown_behavior
          monitoring instance_attrs.monitoring
          ebs_optimized instance_attrs.ebs_optimized
          source_dest_check instance_attrs.source_dest_check unless instance_attrs.source_dest_check.nil?
          disable_api_termination instance_attrs.disable_api_termination
          
          # Apply tags if present
          if instance_attrs.tags.any?
            tags do
              instance_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_instance',
          name: name,
          resource_attributes: instance_attrs.to_h,
          outputs: {
            id: "${aws_instance.#{name}.id}",
            arn: "${aws_instance.#{name}.arn}",
            public_ip: "${aws_instance.#{name}.public_ip}",
            private_ip: "${aws_instance.#{name}.private_ip}",
            public_dns: "${aws_instance.#{name}.public_dns}",
            private_dns: "${aws_instance.#{name}.private_dns}",
            instance_state: "${aws_instance.#{name}.instance_state}",
            subnet_id: "${aws_instance.#{name}.subnet_id}",
            availability_zone: "${aws_instance.#{name}.availability_zone}",
            key_name: "${aws_instance.#{name}.key_name}",
            vpc_security_group_ids: "${aws_instance.#{name}.vpc_security_group_ids}"
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)