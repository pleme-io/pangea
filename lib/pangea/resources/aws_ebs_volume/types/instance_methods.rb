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
        # Instance methods for EBS Volume attributes
        module EbsVolumeInstanceMethods
          # Check if volume supports encryption
          def supports_encryption?
            true # All modern EBS volume types support encryption
          end

          # Check if volume supports multi-attach
          def supports_multi_attach?
            %w[io1 io2].include?(type)
          end

          # Check if volume is provisioned IOPS
          def provisioned_iops?
            %w[io1 io2].include?(type)
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
              [100, [size * 3, 16_000].min].max
            when 'gp3'
              # gp3: 3000 baseline IOPS
              3000
            else
              nil
            end
          end

          # Get default throughput for gp3 volumes
          def default_throughput
            return nil unless type == 'gp3'

            125 # MiB/s baseline for gp3
          end

          # Calculate estimated cost per month (rough estimate)
          def estimated_monthly_cost_usd
            return 0.0 unless size

            base_cost = calculate_base_cost
            base_cost += calculate_gp3_throughput_cost if type == 'gp3'
            base_cost.round(2)
          end

          private

          def calculate_base_cost
            case type
            when 'gp2'
              size * 0.10 # $0.10 per GB-month
            when 'gp3'
              size * 0.08 # $0.08 per GB-month
            when 'io1', 'io2'
              size * 0.125 + (iops || 0) * 0.065 # $0.125/GB + $0.065/IOPS
            when 'st1'
              size * 0.045 # $0.045 per GB-month
            when 'sc1'
              size * 0.015 # $0.015 per GB-month
            when 'standard'
              size * 0.05 # $0.05 per GB-month
            else
              0.0
            end
          end

          def calculate_gp3_throughput_cost
            return 0.0 unless throughput && throughput > 125

            additional_throughput = throughput - 125
            additional_throughput * 0.04 # $0.04 per MiB/s per month
          end
        end
      end
    end
  end
end
