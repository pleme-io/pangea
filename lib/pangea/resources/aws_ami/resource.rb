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
require 'pangea/resources/aws_ami/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS AMI with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] AMI attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_ami(name, attributes = {})
        # Validate attributes using dry-struct
        ami_attrs = Types::AmiAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_ami, name) do
          # Required attributes
          self.name ami_attrs.name
          
          # Optional basic attributes
          description ami_attrs.description if ami_attrs.description
          architecture ami_attrs.architecture
          boot_mode ami_attrs.boot_mode if ami_attrs.boot_mode
          deprecation_time ami_attrs.deprecation_time if ami_attrs.deprecation_time
          ena_support ami_attrs.ena_support unless ami_attrs.ena_support.nil?
          image_location ami_attrs.image_location if ami_attrs.image_location
          imds_support ami_attrs.imds_support if ami_attrs.imds_support
          kernel_id ami_attrs.kernel_id if ami_attrs.kernel_id
          ramdisk_id ami_attrs.ramdisk_id if ami_attrs.ramdisk_id
          root_device_name ami_attrs.root_device_name if ami_attrs.root_device_name
          sriov_net_support ami_attrs.sriov_net_support if ami_attrs.sriov_net_support
          tpm_support ami_attrs.tpm_support if ami_attrs.tpm_support
          virtualization_type ami_attrs.virtualization_type
          
          # EBS block devices
          ami_attrs.ebs_block_device.each do |ebs_device|
            ebs_block_device do
              device_name ebs_device[:device_name]
              delete_on_termination ebs_device[:delete_on_termination] unless ebs_device[:delete_on_termination].nil?
              encrypted ebs_device[:encrypted] unless ebs_device[:encrypted].nil?
              iops ebs_device[:iops] if ebs_device[:iops]
              snapshot_id ebs_device[:snapshot_id] if ebs_device[:snapshot_id]
              throughput ebs_device[:throughput] if ebs_device[:throughput]
              volume_size ebs_device[:volume_size] if ebs_device[:volume_size]
              volume_type ebs_device[:volume_type] if ebs_device[:volume_type]
              kms_key_id ebs_device[:kms_key_id] if ebs_device[:kms_key_id]
            end
          end
          
          # Ephemeral block devices
          ami_attrs.ephemeral_block_device.each do |ephemeral_device|
            ephemeral_block_device do
              device_name ephemeral_device[:device_name]
              virtual_name ephemeral_device[:virtual_name]
            end
          end
          
          # Apply tags if present
          if ami_attrs.tags.any?
            tags do
              ami_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_ami',
          name: name,
          resource_attributes: ami_attrs.to_h,
          outputs: {
            id: "${aws_ami.#{name}.id}",
            arn: "${aws_ami.#{name}.arn}",
            name: "${aws_ami.#{name}.name}",
            description: "${aws_ami.#{name}.description}",
            architecture: "${aws_ami.#{name}.architecture}",
            boot_mode: "${aws_ami.#{name}.boot_mode}",
            creation_date: "${aws_ami.#{name}.creation_date}",
            deprecation_time: "${aws_ami.#{name}.deprecation_time}",
            ena_support: "${aws_ami.#{name}.ena_support}",
            hypervisor: "${aws_ami.#{name}.hypervisor}",
            image_location: "${aws_ami.#{name}.image_location}",
            image_owner_alias: "${aws_ami.#{name}.image_owner_alias}",
            image_type: "${aws_ami.#{name}.image_type}",
            imds_support: "${aws_ami.#{name}.imds_support}",
            kernel_id: "${aws_ami.#{name}.kernel_id}",
            manage_ebs_snapshots: "${aws_ami.#{name}.manage_ebs_snapshots}",
            owner_id: "${aws_ami.#{name}.owner_id}",
            platform: "${aws_ami.#{name}.platform}",
            platform_details: "${aws_ami.#{name}.platform_details}",
            public: "${aws_ami.#{name}.public}",
            ramdisk_id: "${aws_ami.#{name}.ramdisk_id}",
            root_device_name: "${aws_ami.#{name}.root_device_name}",
            root_device_type: "${aws_ami.#{name}.root_device_type}",
            root_snapshot_id: "${aws_ami.#{name}.root_snapshot_id}",
            sriov_net_support: "${aws_ami.#{name}.sriov_net_support}",
            state: "${aws_ami.#{name}.state}",
            tags_all: "${aws_ami.#{name}.tags_all}",
            tpm_support: "${aws_ami.#{name}.tpm_support}",
            usage_operation: "${aws_ami.#{name}.usage_operation}",
            virtualization_type: "${aws_ami.#{name}.virtualization_type}"
          },
          computed_properties: {
            modern_ami: ami_attrs.modern_ami?,
            supports_sriov: ami_attrs.supports_sriov?,
            encrypted_by_default: ami_attrs.encrypted_by_default?,
            root_volume_size: ami_attrs.root_volume_size,
            total_storage_size: ami_attrs.total_storage_size,
            has_instance_store: ami_attrs.has_instance_store?,
            compatible_with_nitro: ami_attrs.compatible_with_nitro?,
            estimated_monthly_cost: ami_attrs.estimated_monthly_cost,
            recommended_instance_types: ami_attrs.recommended_instance_types
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)