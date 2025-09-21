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
      # Type-safe attributes for AWS AMI resources
      class AmiAttributes < Dry::Struct
        # AMI name (required)
        attribute :name, Resources::Types::String

        # AMI description
        attribute :description, Resources::Types::String.optional

        # AMI architecture (x86_64, i386, arm64)
        attribute :architecture, Resources::Types::String.default("x86_64").constrained(included_in: ["x86_64", "i386", "arm64"])

        # Boot mode (legacy-bios, uefi)
        attribute :boot_mode, Resources::Types::String.optional.constrained(included_in: ["legacy-bios", "uefi"])

        # Deprecation time (ISO 8601 format)
        attribute :deprecation_time, Resources::Types::String.optional

        # Enhanced networking support
        attribute :ena_support, Resources::Types::Bool.optional

        # S3 bucket path for AMI
        attribute :image_location, Resources::Types::String.optional

        # Instance metadata service version (v1.0, v2.0)
        attribute :imds_support, Resources::Types::String.optional.constrained(included_in: ["v1.0", "v2.0"])

        # Kernel ID
        attribute :kernel_id, Resources::Types::String.optional

        # RAM disk ID
        attribute :ramdisk_id, Resources::Types::String.optional

        # Root device name
        attribute :root_device_name, Resources::Types::String.optional

        # SR-IOV networking support
        attribute :sriov_net_support, Resources::Types::String.optional.constrained(included_in: ["simple"])

        # TPM support (v2.0)
        attribute :tpm_support, Resources::Types::String.optional.constrained(included_in: ["v2.0"])

        # Virtualization type (hvm, paravirtual)
        attribute :virtualization_type, Resources::Types::String.default("hvm").constrained(included_in: ["hvm", "paravirtual"])

        # EBS block device mappings
        attribute :ebs_block_device, Resources::Types::Array.of(
          Types::Hash.schema(
            device_name: Types::String,
            delete_on_termination?: Types::Bool.optional,
            encrypted?: Types::Bool.optional,
            iops?: Types::Integer.optional,
            snapshot_id?: Types::String.optional,
            throughput?: Types::Integer.optional,
            volume_size?: Types::Integer.optional,
            volume_type?: Types::String.optional.constrained(included_in: ["gp2", "gp3", "io1", "io2", "st1", "sc1", "standard"]),
            kms_key_id?: Types::String.optional
          )
        ).default([].freeze)

        # Instance store block device mappings
        attribute :ephemeral_block_device, Resources::Types::Array.of(
          Types::Hash.schema(
            device_name: Types::String,
            virtual_name: Types::String
          )
        ).default([].freeze)

        # Tags
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate deprecation_time format if provided
          if attrs.deprecation_time
            begin
              Time.iso8601(attrs.deprecation_time)
            rescue ArgumentError
              raise Dry::Struct::Error, "deprecation_time must be in ISO 8601 format (e.g., '2024-12-31T23:59:59Z')"
            end
          end

          # Validate architecture and virtualization type compatibility
          if attrs.architecture == "i386" && attrs.virtualization_type == "hvm"
            raise Dry::Struct::Error, "i386 architecture is not compatible with hvm virtualization type"
          end

          # Validate boot mode compatibility
          if attrs.boot_mode == "uefi" && attrs.virtualization_type == "paravirtual"
            raise Dry::Struct::Error, "UEFI boot mode is only compatible with hvm virtualization type"
          end

          # Validate TPM support compatibility
          if attrs.tpm_support && attrs.virtualization_type == "paravirtual"
            raise Dry::Struct::Error, "TPM support is only compatible with hvm virtualization type"
          end

          # Validate IMDS support
          if attrs.imds_support && attrs.virtualization_type == "paravirtual"
            raise Dry::Struct::Error, "IMDS support is only compatible with hvm virtualization type"
          end

          attrs
        end

        # Helper method to check if AMI is modern (HVM with ENA support)
        def modern_ami?
          virtualization_type == "hvm" && ena_support == true
        end

        # Helper method to check if AMI supports SR-IOV
        def supports_sriov?
          !sriov_net_support.nil?
        end

        # Helper method to check if AMI is encrypted by default
        def encrypted_by_default?
          ebs_block_device.any? { |device| device[:encrypted] == true }
        end

        # Helper method to get root volume size
        def root_volume_size
          root_device = ebs_block_device.find { |device| device[:device_name] == root_device_name }
          root_device&.dig(:volume_size)
        end

        # Helper method to get total storage size
        def total_storage_size
          ebs_block_device.sum { |device| device[:volume_size] || 0 }
        end

        # Helper method to check if AMI has instance store
        def has_instance_store?
          ephemeral_block_device.any?
        end

        # Helper method to check boot mode compatibility with instance types
        def compatible_with_nitro?
          boot_mode != "legacy-bios" && virtualization_type == "hvm"
        end

        # Estimate monthly cost for typical usage
        def estimated_monthly_cost
          # Base AMI storage cost (rough estimate)
          storage_cost = total_storage_size * 0.10 # $0.10 per GB/month for AMI storage
          
          # Additional costs for features
          feature_cost = 0
          feature_cost += 10 if ena_support # Premium networking
          feature_cost += 5 if sriov_net_support # SR-IOV support
          
          storage_cost + feature_cost
        end

        # Get recommended instance types based on architecture
        def recommended_instance_types
          case architecture
          when "x86_64"
            %w[t3.micro t3.small m5.large c5.large r5.large]
          when "arm64"  
            %w[t4g.micro t4g.small m6g.large c6g.large r6g.large]
          when "i386"
            %w[t2.micro t2.small] # Limited instance types for i386
          else
            []
          end
        end
      end
    end
      end
    end
  end
end