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
        # Methods for Braket device execution parameters
        module ExecutionParams
          def has_execution_windows?
            is_quantum_hardware? # QPUs typically have execution windows
          end

          def max_shots
            case provider_type
            when 'AMAZON'
              case device_type
              when 'SIMULATOR'
                100000 # High for simulators
              else
                10000
              end
            when 'IONQ'
              10000
            when 'RIGETTI'
              100000
            else
              10000
            end
          end

          def min_shots
            case provider_type
            when 'AMAZON'
              1
            when 'IONQ'
              1
            when 'RIGETTI'
              1
            else
              1
            end
          end
        end
      end
    end
  end
end
