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
        # Validation logic for BraketLocalSimulatorAttributes
        module BraketLocalSimulatorValidators
          SIMULATOR_DEVICE_MAP = {
            'braket_sv' => 'braket_sv_v2',
            'braket_dm' => 'braket_dm_v2',
            'braket_tn' => 'braket_tn1'
          }.freeze

          MIN_MEMORY_MB = {
            'braket_sv' => 2048,
            'braket_dm' => 4096,
            'braket_tn' => 1024
          }.freeze

          def validate_simulator_name(name)
            return if name.match?(/\A[a-zA-Z0-9\-_]{1,128}\z/)

            raise Dry::Struct::Error,
                  'simulator_name must be 1-128 characters long and contain only alphanumeric characters, hyphens, and underscores'
          end

          def validate_device_consistency(simulator_type, device_name)
            expected_device = SIMULATOR_DEVICE_MAP[simulator_type]
            return if device_name == expected_device

            raise Dry::Struct::Error,
                  "#{simulator_type} simulator type requires #{expected_device} device"
          end

          def validate_gpu_requirements(simulator_type, resource_config)
            return unless resource_config
            return unless resource_config[:gpu_count]&.positive?
            return unless simulator_type == 'braket_tn'

            raise Dry::Struct::Error,
                  'braket_tn simulator typically does not use GPU acceleration'
          end

          def validate_memory_requirements(simulator_type, resource_config)
            return unless resource_config

            memory_mb = resource_config[:memory_size_mb]
            min_memory = MIN_MEMORY_MB[simulator_type]
            return unless min_memory && memory_mb < min_memory

            simulator_name = simulator_type.sub('braket_', '').upcase
            raise Dry::Struct::Error,
                  "#{simulator_name_for_error(simulator_type)} requires at least #{min_memory / 1024}GB of memory"
          end

          def validate_shots(simulator_type, shots)
            return unless shots && simulator_type == 'braket_tn' && shots > 10_000

            raise Dry::Struct::Error,
                  'Tensor network simulators typically use fewer shots (<=10000)'
          end

          private

          def simulator_name_for_error(simulator_type)
            case simulator_type
            when 'braket_sv' then 'State vector simulator'
            when 'braket_dm' then 'Density matrix simulator'
            when 'braket_tn' then 'Tensor network simulator'
            else simulator_type
            end
          end
        end
      end
    end
  end
end
