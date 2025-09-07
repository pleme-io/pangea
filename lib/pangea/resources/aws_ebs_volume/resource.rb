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
require 'pangea/resources/aws_ebs_volume/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS EBS Volume with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_ebs_volume(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::EbsVolumeAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_ebs_volume, name) do
          # Availability zone is always required
          availability_zone attrs.availability_zone
          
          # Size (required for most volume types when not from snapshot)
          size attrs.size if attrs.size
          
          # Snapshot ID (alternative to size)
          snapshot_id attrs.snapshot_id if attrs.snapshot_id
          
          # Volume type (defaults to gp3)
          type attrs.type
          
          # IOPS (required for io1/io2, optional for gp3)
          iops attrs.iops if attrs.iops
          
          # Throughput (gp3 only)
          throughput attrs.throughput if attrs.throughput
          
          # Encryption settings
          encrypted attrs.encrypted if attrs.encrypted
          kms_key_id attrs.kms_key_id if attrs.kms_key_id
          
          # Multi-attach (io1/io2 only)
          multi_attach_enabled attrs.multi_attach_enabled if attrs.multi_attach_enabled
          
          # Outpost ARN
          outpost_arn attrs.outpost_arn if attrs.outpost_arn
          
          # Apply tags if present
          if attrs.tags.any?
            tags do
              attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_ebs_volume',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_ebs_volume.#{name}.id}",
            arn: "${aws_ebs_volume.#{name}.arn}",
            availability_zone: "${aws_ebs_volume.#{name}.availability_zone}",
            encrypted: "${aws_ebs_volume.#{name}.encrypted}",
            final_snapshot: "${aws_ebs_volume.#{name}.final_snapshot}",
            iops: "${aws_ebs_volume.#{name}.iops}",
            kms_key_id: "${aws_ebs_volume.#{name}.kms_key_id}",
            multi_attach_enabled: "${aws_ebs_volume.#{name}.multi_attach_enabled}",
            outpost_arn: "${aws_ebs_volume.#{name}.outpost_arn}",
            size: "${aws_ebs_volume.#{name}.size}",
            snapshot_id: "${aws_ebs_volume.#{name}.snapshot_id}",
            tags_all: "${aws_ebs_volume.#{name}.tags_all}",
            throughput: "${aws_ebs_volume.#{name}.throughput}",
            type: "${aws_ebs_volume.#{name}.type}"
          },
          computed_properties: {
            supports_encryption: attrs.supports_encryption?,
            supports_multi_attach: attrs.supports_multi_attach?,
            provisioned_iops: attrs.provisioned_iops?,
            gp3: attrs.gp3?,
            throughput_optimized: attrs.throughput_optimized?,
            cold_storage: attrs.cold_storage?,
            from_snapshot: attrs.from_snapshot?,
            default_iops: attrs.default_iops,
            default_throughput: attrs.default_throughput,
            estimated_monthly_cost_usd: attrs.estimated_monthly_cost_usd
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)