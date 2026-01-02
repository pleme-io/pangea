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
        # Helper methods for BraketDeviceAttributes
        module BraketDeviceHelpers
          def is_quantum_hardware?
            device_type == 'QPU'
          end

          def is_simulator?
            device_type == 'SIMULATOR'
          end

          def qubit_count
            device_capabilities[:paradigm][:qubitCount]
          end

          def supported_gates
            gates = []
            action = device_capabilities[:action]

            if action[:'braket.ir.jaqcd.program']
              gates.concat(action[:'braket.ir.jaqcd.program'][:supportedOperations] || [])
            end

            if action[:'braket.ir.openqasm.program']
              gates.concat(action[:'braket.ir.openqasm.program'][:supportedOperations] || [])
            end

            gates.uniq
          end

          def connectivity_type
            connectivity = device_capabilities[:paradigm][:connectivity]
            return :unknown unless connectivity

            connectivity[:fullyConnected] ? :fully_connected : :limited_connectivity
          end

          def cost_per_shot
            cost_info = device_capabilities[:service][:deviceCost]
            return 0.0 unless cost_info

            cost_info[:price]
          end

          def cost_unit
            cost_info = device_capabilities[:service][:deviceCost]
            return 'unknown' unless cost_info

            cost_info[:unit]
          end

          def shots_range
            device_capabilities[:service][:shotsRange] || [1, 100_000]
          end

          def min_shots
            shots_range[0]
          end

          def max_shots
            shots_range[1]
          end

          def execution_windows
            windows = device_capabilities[:service][:executionWindows] || []
            windows.map do |window|
              {
                day: window[:executionDay],
                start: window[:windowStartHour],
                end: window[:windowEndHour]
              }
            end
          end

          def is_available_24_7?
            windows = execution_windows
            windows.empty? || windows.any? { |w| w[:day] == 'Everyday' && w[:start] == '00:00' && w[:end] == '23:59' }
          end

          def native_gate_set
            device_capabilities[:paradigm][:nativeGateSet] || []
          end

          def supports_openqasm?
            device_capabilities[:action].key?(:'braket.ir.openqasm.program')
          end

          def supports_jaqcd?
            device_capabilities[:action].key?(:'braket.ir.jaqcd.program')
          end
        end
      end
    end
  end
end
