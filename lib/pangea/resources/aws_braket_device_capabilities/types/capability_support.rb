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
        # Methods for checking Braket device capability support
        module CapabilitySupport
          def supports_openqasm?
            # Based on device type and provider
            case provider_type
            when 'AMAZON'
              true # All Amazon simulators support OpenQASM
            when 'IONQ', 'RIGETTI', 'OQC'
              true # Most QPUs support OpenQASM
            else
              false
            end
          end

          def supports_jaqcd?
            # JSON Amazon Quantum Circuit Description support
            case provider_type
            when 'AMAZON'
              true # Amazon simulators support JAQCD
            when 'IONQ'
              true # IonQ supports JAQCD
            else
              false
            end
          end

          def connectivity_graph_available?
            # Most QPUs have connectivity graphs
            is_quantum_hardware?
          end

          # Check if device supports variational algorithms
          def supports_variational_algorithms?
            # Most devices support variational quantum algorithms
            true
          end
        end
      end
    end
  end
end
