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
        # Methods for classifying Braket device type and provider
        module DeviceClassification
          def is_quantum_hardware?
            device_arn.include?('/qpu/')
          end

          def is_simulator?
            device_arn.include?('/quantum-simulator/')
          end

          def provider_type
            # Extract provider from ARN
            parts = device_arn.split('/')
            return 'unknown' if parts.length < 4

            case parts[2]
            when 'amazon'
              'AMAZON'
            when 'ionq'
              'IONQ'
            when 'rigetti'
              'RIGETTI'
            when 'oqc'
              'OQC'
            when 'xanadu'
              'XANADU'
            when 'quera'
              'QUERA'
            else
              parts[2].upcase
            end
          end

          def device_type
            if is_simulator?
              'SIMULATOR'
            elsif is_quantum_hardware?
              'QPU'
            else
              'UNKNOWN'
            end
          end
        end
      end
    end
  end
end
