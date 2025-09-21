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


require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS EC2 Instance resources
      class InstanceAttributes < Dry::Struct
        # AMI ID (required)
        attribute :ami, Resources::Types::String

        # Instance type (required)
        attribute :instance_type, Resources::Types::String

        # Network configuration
        attribute :subnet_id, Resources::Types::String.optional
        attribute :vpc_security_group_ids, Resources::Types::Array.of(Types::String).default([].freeze)
        attribute :availability_zone, Resources::Types::String.optional
        attribute :associate_public_ip_address, Resources::Types::Bool.optional

        # Instance configuration
        attribute :key_name, Resources::Types::String.optional
        attribute :user_data, Resources::Types::String.optional
        attributeuser_data_base64 :, Resources::Types::String.optional
        attribute :iam_instance_profile, Resources::Types::String.optional

        # Storage configuration
        attribute :root_block_device, Resources::Types::Hash.schema(
          volume_type?: Types::String.enum("standard", "gp2", "gp3", "io1", "io2").optional,
          volume_size?: Types::Integer.optional,
          iops?: Types::Integer.optional,
          throughput?: Types::Integer.optional,
          delete_on_termination?: Types::Bool.optional,
          encrypted?: Types::Bool.optional,
          kms_key_id?: Types::String.optional
        ).optional

        # Additional block devices
        attribute :ebs_block_device, Resources::Types::Array.of(
          Types::Hash.schema(
            device_name: Types::String,
            volume_type?: Types::String.enum("standard", "gp2", "gp3", "io1", "io2").optional,
            volume_size?: Types::Integer.optional,
            iops?: Types::Integer.optional,
            throughput?: Types::Integer.optional,
            delete_on_termination?: Types::Bool.optional,
            encrypted?: Types::Bool.optional,
            kms_key_id?: Types::String.optional,
            snapshot_id?: Types::String.optional
          )
        ).default([].freeze)

        # Instance behavior
        attribute :instance_initiated_shutdown_behavior, Resources::Types::String.enum("stop", "terminate").optional
        attribute :monitoring, Resources::Types::Bool.default(false)
        attribute :ebs_optimized, Resources::Types::Bool.default(false)
        attribute :source_dest_check, Resources::Types::Bool.optional
        attribute :disable_api_termination, Resources::Types::Bool.default(false)

        # Tags
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate user_data exclusivity
          if attrs.user_data && attrs.user_data_base64
            raise Dry::Struct::Error, "Cannot specify both 'user_data' and 'user_data_base64'"
          end

          # Validate IOPS requirements
          if attrs.root_block_device
            device = attrs.root_block_device
            if device[:iops] && !%w[io1 io2].include?(device[:volume_type])
              raise Dry::Struct::Error, "IOPS can only be specified for io1 or io2 volume types"
            end
            if device[:throughput] && device[:volume_type] != "gp3"
              raise Dry::Struct::Error, "Throughput can only be specified for gp3 volume type"
            end
          end

          attrs
        end

        # Helper method to get instance family
        def instance_family
          instance_type.split('.').first
        end

        # Helper method to get instance size
        def instance_size
          instance_type.split('.').last
        end

        # Check if instance type supports EBS optimization
        def supports_ebs_optimization?
          # Most modern instance types support EBS optimization
          !%w[t2 t3].include?(instance_family)
        end

        # Check if instance will have public IP
        def will_have_public_ip?
          return associate_public_ip_address if !associate_public_ip_address.nil?
          # If not explicitly set, depends on subnet configuration
          nil
        end

        # Estimate hourly cost (very rough estimate)
        def estimated_hourly_cost
          # Simplified cost estimates
          base_costs = {
            "t3.micro" => 0.0104,
            "t3.small" => 0.0208,
            "t3.medium" => 0.0416,
            "t3.large" => 0.0832,
            "t3.xlarge" => 0.1664,
            "m5.large" => 0.096,
            "m5.xlarge" => 0.192,
            "m5.2xlarge" => 0.384,
            "c5.large" => 0.085,
            "c5.xlarge" => 0.17,
            "r5.large" => 0.126,
            "r5.xlarge" => 0.252
          }
          
          base_costs[instance_type] || 0.10  # Default estimate
        end
      end
    end
      end
    end
  end
end