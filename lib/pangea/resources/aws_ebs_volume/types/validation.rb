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
        # Validation logic for EBS Volume attributes
        module EbsVolumeValidation
          def validate_size_required(attrs)
            if !attrs.snapshot_id && !attrs.size && %w[gp2 gp3 st1 sc1].include?(attrs.type)
              raise Dry::Struct::Error, "Size is required for volume type '#{attrs.type}' when not creating from snapshot"
            end
          end

          def validate_iops(attrs)
            case attrs.type
            when 'io1', 'io2'
              validate_provisioned_iops(attrs)
            when 'gp3'
              validate_gp3_iops(attrs)
            when 'gp2', 'st1', 'sc1', 'standard'
              raise Dry::Struct::Error, "IOPS cannot be specified for volume type '#{attrs.type}'" if attrs.iops
            end
          end

          def validate_provisioned_iops(attrs)
            raise Dry::Struct::Error, "IOPS is required for volume type '#{attrs.type}'" unless attrs.iops

            return unless attrs.size && attrs.iops

            max_iops_per_gib = attrs.type == 'io1' ? 50 : 500
            max_allowed_iops = attrs.size * max_iops_per_gib

            return unless attrs.iops > max_allowed_iops

            raise Dry::Struct::Error,
                  "IOPS (#{attrs.iops}) exceeds maximum for #{attrs.type} volume of #{attrs.size} GiB (max: #{max_allowed_iops})"
          end

          def validate_gp3_iops(attrs)
            return unless attrs.iops && attrs.size

            max_iops = [16_000, attrs.size * 500].min
            return unless attrs.iops > max_iops

            raise Dry::Struct::Error,
                  "IOPS (#{attrs.iops}) exceeds maximum for gp3 volume of #{attrs.size} GiB (max: #{max_iops})"
          end

          def validate_throughput(attrs)
            return unless attrs.throughput

            raise Dry::Struct::Error, 'Throughput can only be specified for gp3 volumes' if attrs.type != 'gp3'

            return unless attrs.iops

            max_throughput = [1000, attrs.iops / 4 * 1000].min
            return unless attrs.throughput > max_throughput

            raise Dry::Struct::Error,
                  "Throughput (#{attrs.throughput}) exceeds maximum for gp3 volume with #{attrs.iops} IOPS (max: #{max_throughput})"
          end

          def validate_multi_attach(attrs)
            return unless attrs.multi_attach_enabled && !%w[io1 io2].include?(attrs.type)

            raise Dry::Struct::Error, 'Multi-Attach is only supported for io1 and io2 volume types'
          end

          def validate_size_limits(attrs)
            return unless attrs.size

            case attrs.type
            when 'gp2', 'gp3'
              validate_size_range(attrs.size, 1, 16_384, attrs.type)
            when 'io1', 'io2'
              validate_size_range(attrs.size, 4, 16_384, attrs.type)
            when 'st1', 'sc1'
              validate_size_range(attrs.size, 125, 16_384, attrs.type)
            when 'standard'
              validate_size_range(attrs.size, 1, 1024, attrs.type)
            end
          end

          def validate_size_range(size, min, max, type)
            return if size >= min && size <= max

            raise Dry::Struct::Error, "Size for #{type} volumes must be between #{min} and #{max} GiB"
          end

          def validate_encryption(attrs)
            return unless attrs.kms_key_id && !attrs.encrypted

            raise Dry::Struct::Error, 'kms_key_id can only be specified when encrypted is true'
          end
        end
      end
    end
  end
end
