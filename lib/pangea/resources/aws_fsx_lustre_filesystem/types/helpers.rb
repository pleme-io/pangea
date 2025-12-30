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
        # Helper methods for FSx Lustre filesystem attributes
        module FsxLustreHelpers
          def is_persistent?
            deployment_type.start_with?('PERSISTENT')
          end

          def is_scratch?
            deployment_type.start_with?('SCRATCH')
          end

          def supports_backups?
            is_persistent?
          end

          def supports_throughput_configuration?
            is_persistent?
          end

          def supports_drive_cache?
            storage_type == 'HDD'
          end

          def estimated_baseline_throughput
            case deployment_type
            when 'SCRATCH_1'
              200 * (storage_capacity / 1200)
            when 'SCRATCH_2'
              240 * (storage_capacity / 1200)
            when 'PERSISTENT_1', 'PERSISTENT_2'
              calculate_persistent_throughput
            end
          end

          def estimated_monthly_cost
            storage_cost = calculate_storage_cost
            throughput_cost = calculate_throughput_cost
            { storage: storage_cost.round(2), throughput: throughput_cost.round(2), total: (storage_cost + throughput_cost).round(2) }
          end

          private

          def calculate_persistent_throughput
            if per_unit_storage_throughput
              (per_unit_storage_throughput * storage_capacity) / 1024
            elsif storage_type == 'SSD'
              50 * (storage_capacity / 1024)
            else
              12 * (storage_capacity / 1024)
            end
          end

          def calculate_storage_cost
            case [storage_type, deployment_type]
            when ['SSD', 'SCRATCH_2']
              storage_capacity * 0.140
            when ['HDD', 'PERSISTENT_1'], ['HDD', 'PERSISTENT_2']
              storage_capacity * 0.015
            when ['SSD', 'PERSISTENT_1'], ['SSD', 'PERSISTENT_2']
              storage_capacity * 0.145
            else
              storage_capacity * 0.140
            end
          end

          def calculate_throughput_cost
            return 0 unless is_persistent? && per_unit_storage_throughput && storage_type == 'SSD'

            throughput_multiplier = case per_unit_storage_throughput
                                    when 50 then 0
                                    when 100 then 0.035
                                    when 200 then 0.070
                                    when 500 then 0.175
                                    when 1000 then 0.350
                                    else 0
                                    end
            (storage_capacity / 1024.0) * throughput_multiplier * 730
          end
        end
      end
    end
  end
end
