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
require 'pangea/resources/aws_efs_mount_target/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Creates an AWS EFS Mount Target for VPC access to an EFS file system
      # 
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Mount target configuration
      # @return [ResourceReference] Reference to the created mount target
      def aws_efs_mount_target(name, attributes = {})
        validated_attrs = AWS::Types::Types::EfsMountTargetAttributes.new(attributes)
        
        resource_attributes = {
          file_system_id: validated_attrs.file_system_id,
          subnet_id: validated_attrs.subnet_id,
          security_groups: validated_attrs.security_groups
        }
        
        # Add optional IP address if specified
        resource_attributes[:ip_address] = validated_attrs.ip_address if validated_attrs.ip_address
        
        resource(:aws_efs_mount_target, name, resource_attributes)
        
        ResourceReference.new(
          type: :aws_efs_mount_target,
          name: name,
          attributes: validated_attrs,
          outputs: {
            id: "${aws_efs_mount_target.#{name}.id}",
            dns_name: "${aws_efs_mount_target.#{name}.dns_name}",
            file_system_arn: "${aws_efs_mount_target.#{name}.file_system_arn}",
            file_system_id: "${aws_efs_mount_target.#{name}.file_system_id}",
            ip_address: "${aws_efs_mount_target.#{name}.ip_address}",
            mount_target_dns_name: "${aws_efs_mount_target.#{name}.mount_target_dns_name}",
            network_interface_id: "${aws_efs_mount_target.#{name}.network_interface_id}",
            owner_id: "${aws_efs_mount_target.#{name}.owner_id}",
            security_groups: "${aws_efs_mount_target.#{name}.security_groups}",
            subnet_id: "${aws_efs_mount_target.#{name}.subnet_id}",
            availability_zone_id: "${aws_efs_mount_target.#{name}.availability_zone_id}",
            availability_zone_name: "${aws_efs_mount_target.#{name}.availability_zone_name}"
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)