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
      # Type-safe attributes for AWS EBS Volume resources
      class EbsVolumeAttributes < Dry::Struct
        # Availability zone where the volume will reside (required)
        attribute :availability_zone, Resources::Types::AwsAvailabilityZone
        
        # Size of the volume in GiB (conditional - required for gp3, gp2, st1, sc1)
        attribute :size, Resources::Types::Integer.constrained(gteq: 1, lteq: 65536)
        
        # Snapshot to create volume from (conditional)
        attribute :snapshot_id, Resources::Types::String.optional
        
        # Volume type (optional, default "gp3")
        attribute :type, Resources::Types::String.default("gp3").constrained(included_in: ["gp2", "gp3", "io1", "io2", "st1", "sc1", "standard"])
        
        # IOPS for the volume (conditional - required for io1/io2, optional for gp3)
        attribute :iops, Resources::Types::Integer.constrained(gteq: 100, lteq: 64000)
        
        # Throughput for gp3 volumes (optional, 125-1000 MiB/s)
        attribute :throughput, Resources::Types::Integer.constrained(gteq: 125, lteq: 1000)
        
        # Enable encryption (optional, default false)
        attribute :encrypted, Resources::Types::Bool.default(false)
        
        # KMS key for encryption (optional)
        attribute :kms_key_id, Resources::Types::String.optional
        
        # Enable Multi-Attach (optional, default false)
        attribute :multi_attach_enabled, Resources::Types::Bool.default(false)
        
        # Outpost ARN for Outpost volumes (optional)
        attribute :outpost_arn, Resources::Types::String.optional
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Size is required when creating from scratch (not from snapshot)
          if !attrs.snapshot_id && !attrs.size && ['gp2', 'gp3', 'st1', 'sc1'].include?(attrs.type)
            raise Dry::Struct::Error, "Size is required for volume type '#{attrs.type}' when not creating from snapshot"
          end
          
          # IOPS validation by volume type
          case attrs.type
          when 'io1', 'io2'
            if !attrs.iops
              raise Dry::Struct::Error, "IOPS is required for volume type '#{attrs.type}'"
            end
            
            # io1: 100-64000 IOPS, up to 50 IOPS per GiB
            # io2: 100-64000 IOPS, up to 500 IOPS per GiB
            if attrs.size && attrs.iops
              max_iops_per_gib = attrs.type == 'io1' ? 50 : 500
              max_allowed_iops = attrs.size * max_iops_per_gib
              
              if attrs.iops > max_allowed_iops
                raise Dry::Struct::Error, "IOPS (#{attrs.iops}) exceeds maximum for #{attrs.type} volume of #{attrs.size} GiB (max: #{max_allowed_iops})"
              end
            end
            
          when 'gp3'
            # gp3: 3000 baseline, up to 16000 IOPS, ratio of 500 IOPS per GiB
            if attrs.iops && attrs.size
              max_iops = [16000, attrs.size * 500].min
              if attrs.iops > max_iops
                raise Dry::Struct::Error, "IOPS (#{attrs.iops}) exceeds maximum for gp3 volume of #{attrs.size} GiB (max: #{max_iops})"
              end
            end
            
          when 'gp2', 'st1', 'sc1', 'standard'
            if attrs.iops
              raise Dry::Struct::Error, "IOPS cannot be specified for volume type '#{attrs.type}'"
            end
          end
          
          # Throughput validation
          if attrs.throughput
            if attrs.type != 'gp3'
              raise Dry::Struct::Error, "Throughput can only be specified for gp3 volumes"
            end
            
            # gp3 throughput ratio validation (up to 4:1 ratio with IOPS)
            if attrs.iops
              max_throughput = [1000, attrs.iops / 4 * 1000].min
              if attrs.throughput > max_throughput
                raise Dry::Struct::Error, "Throughput (#{attrs.throughput}) exceeds maximum for gp3 volume with #{attrs.iops} IOPS (max: #{max_throughput})"
              end
            end
          end
          
          # Multi-attach validation
          if attrs.multi_attach_enabled && !['io1', 'io2'].include?(attrs.type)
            raise Dry::Struct::Error, "Multi-Attach is only supported for io1 and io2 volume types"
          end
          
          # Size limits by volume type
          if attrs.size
            case attrs.type
            when 'gp2', 'gp3'
              if attrs.size < 1 || attrs.size > 16384
                raise Dry::Struct::Error, "Size for #{attrs.type} volumes must be between 1 and 16384 GiB"
              end
            when 'io1', 'io2'
              if attrs.size < 4 || attrs.size > 16384
                raise Dry::Struct::Error, "Size for #{attrs.type} volumes must be between 4 and 16384 GiB"
              end
            when 'st1'
              if attrs.size < 125 || attrs.size > 16384
                raise Dry::Struct::Error, "Size for st1 volumes must be between 125 and 16384 GiB"
              end
            when 'sc1'
              if attrs.size < 125 || attrs.size > 16384
                raise Dry::Struct::Error, "Size for sc1 volumes must be between 125 and 16384 GiB"
              end
            when 'standard'
              if attrs.size < 1 || attrs.size > 1024
                raise Dry::Struct::Error, "Size for standard volumes must be between 1 and 1024 GiB"
              end
            end
          end
          
          # Encryption validation
          if attrs.kms_key_id && !attrs.encrypted
            raise Dry::Struct::Error, "kms_key_id can only be specified when encrypted is true"
          end
          
          attrs
        end

        # Check if volume supports encryption
        def supports_encryption?
          true  # All modern EBS volume types support encryption
        end
        
        # Check if volume supports multi-attach
        def supports_multi_attach?
          ['io1', 'io2'].include?(type)
        end
        
        # Check if volume is provisioned IOPS
        def provisioned_iops?
          ['io1', 'io2'].include?(type)
        end
        
        # Check if volume is gp3
        def gp3?
          type == 'gp3'
        end
        
        # Check if volume is throughput optimized
        def throughput_optimized?
          type == 'st1'
        end
        
        # Check if volume is cold storage
        def cold_storage?
          type == 'sc1'
        end
        
        # Check if created from snapshot
        def from_snapshot?
          !snapshot_id.nil?
        end
        
        # Get default IOPS for volume type and size
        def default_iops
          return nil unless size
          
          case type
          when 'gp2'
            # gp2: 3 IOPS per GiB, minimum 100, maximum 16000
            [100, [size * 3, 16000].min].max
          when 'gp3'
            # gp3: 3000 baseline IOPS
            3000
          when 'io1', 'io2'
            # These require explicit IOPS specification
            nil
          else
            nil
          end
        end
        
        # Get default throughput for gp3 volumes
        def default_throughput
          return nil unless type == 'gp3'
          125  # MiB/s baseline for gp3
        end
        
        # Calculate estimated cost per month (rough estimate)
        def estimated_monthly_cost_usd
          return 0.0 unless size
          
          base_cost = case type
          when 'gp2'
            size * 0.10  # $0.10 per GB-month
          when 'gp3'
            size * 0.08  # $0.08 per GB-month
          when 'io1'
            size * 0.125 + (iops || 0) * 0.065  # $0.125/GB + $0.065/IOPS
          when 'io2'
            size * 0.125 + (iops || 0) * 0.065  # Same as io1
          when 'st1'
            size * 0.045  # $0.045 per GB-month
          when 'sc1'
            size * 0.015  # $0.015 per GB-month
          when 'standard'
            size * 0.05  # $0.05 per GB-month
          else
            0.0
          end
          
          # Add gp3 throughput cost if applicable
          if type == 'gp3' && throughput && throughput > 125
            additional_throughput = throughput - 125
            base_cost += additional_throughput * 0.04  # $0.04 per MiB/s per month
          end
          
          base_cost.round(2)
        end
      end
    end
      end
    end
  end
end