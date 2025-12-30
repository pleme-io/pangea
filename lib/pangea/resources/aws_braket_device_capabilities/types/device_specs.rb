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
        # Methods for Braket device specifications and metadata
        module DeviceSpecs
          def cost_per_shot_usd
            case provider_type
            when 'AMAZON'
              case device_type
              when 'SIMULATOR'
                0.075 / 60.0 / 1000.0 # ~$0.075 per minute, estimate per shot
              else
                0.0
              end
            when 'IONQ'
              0.01 # $0.01 per shot
            when 'RIGETTI'
              0.00035 # $0.00035 per shot
            when 'OQC'
              0.00035 # Similar to Rigetti
            else
              0.0
            end
          end

          # Estimate qubit count based on device type and provider
          def estimated_qubit_count
            case provider_type
            when 'AMAZON'
              case device_type
              when 'SIMULATOR'
                34 # SV1 has 34 qubits, DM1 has 17, TN1 varies
              else
                0
              end
            when 'IONQ'
              32 # IonQ Forte has 32 qubits
            when 'RIGETTI'
              80 # Rigetti Ankaa-2 has 84 qubits
            when 'OQC'
              8 # OQC Lucy has 8 qubits
            else
              0
            end
          end

          # Get device generation/version
          def device_generation
            device_name = device_arn.split('/').last

            case device_name
            when /v2$/
              'v2'
            when /v1$/
              'v1'
            when /\d+$/
              device_name.match(/(\d+)$/)[1]
            else
              'unknown'
            end
          end

          # Check if device is currently available
          def likely_available?
            case provider_type
            when 'AMAZON'
              true # Simulators are always available
            else
              # QPUs have limited availability
              false
            end
          end
        end
      end
    end
  end
end
