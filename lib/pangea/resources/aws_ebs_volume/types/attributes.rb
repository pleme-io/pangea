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

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS EBS Volume resources
        class EbsVolumeAttributes < Dry::Struct
          extend EbsVolumeValidation
          include EbsVolumeInstanceMethods

          # Availability zone where the volume will reside (required)
          attribute :availability_zone, Resources::Types::AwsAvailabilityZone

          # Size of the volume in GiB (conditional - required for gp3, gp2, st1, sc1)
          attribute? :size, Resources::Types::Integer.constrained(gteq: 1, lteq: 65_536)

          # Snapshot to create volume from (conditional)
          attribute? :snapshot_id, Resources::Types::String

          # Volume type (optional, default "gp3")
          attribute :type, Resources::Types::String.default('gp3').constrained(
            included_in: %w[gp2 gp3 io1 io2 st1 sc1 standard]
          )

          # IOPS for the volume (conditional - required for io1/io2, optional for gp3)
          attribute? :iops, Resources::Types::Integer.constrained(gteq: 100, lteq: 64_000)

          # Throughput for gp3 volumes (optional, 125-1000 MiB/s)
          attribute? :throughput, Resources::Types::Integer.constrained(gteq: 125, lteq: 1000)

          # Enable encryption (optional, default false)
          attribute :encrypted, Resources::Types::Bool.default(false)

          # KMS key for encryption (optional)
          attribute? :kms_key_id, Resources::Types::String

          # Enable Multi-Attach (optional, default false)
          attribute :multi_attach_enabled, Resources::Types::Bool.default(false)

          # Outpost ARN for Outpost volumes (optional)
          attribute? :outpost_arn, Resources::Types::String

          # Tags to apply to the resource
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)
            validate_size_required(attrs)
            validate_iops(attrs)
            validate_throughput(attrs)
            validate_multi_attach(attrs)
            validate_size_limits(attrs)
            validate_encryption(attrs)
            attrs
          end
        end
      end
    end
  end
end
