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
        # Validation methods for BraketDeviceAttributes
        module BraketDeviceValidations
          DEVICE_NAME_PATTERN = /\A[a-zA-Z0-9][a-zA-Z0-9\-_]*[a-zA-Z0-9]\z/

          def self.validate!(attrs)
            validate_device_name!(attrs)
            validate_provider_device_type!(attrs)
            validate_qubit_count!(attrs)
            validate_execution_windows!(attrs)
          end

          def self.validate_device_name!(attrs)
            return if attrs.device_name.match?(DEVICE_NAME_PATTERN)

            raise Dry::Struct::Error,
                  'device_name must start and end with alphanumeric characters and can contain hyphens and underscores'
          end

          def self.validate_provider_device_type!(attrs)
            if attrs.device_type == 'QPU' && attrs.provider_name == 'AMAZON'
              raise Dry::Struct::Error, 'AMAZON provider only offers simulators, not QPUs'
            end

            return unless attrs.device_type == 'SIMULATOR' && attrs.provider_name != 'AMAZON'

            raise Dry::Struct::Error, 'Only AMAZON provider currently offers simulators in Braket'
          end

          def self.validate_qubit_count!(attrs)
            qubit_count = attrs.device_capabilities[:paradigm][:qubitCount]
            return if qubit_count.positive?

            raise Dry::Struct::Error, 'qubitCount must be positive'
          end

          def self.validate_execution_windows!(attrs)
            windows = attrs.device_capabilities[:service][:executionWindows]
            return unless windows

            windows.each do |window|
              validate_window_hours!(window)
            end
          end

          def self.validate_window_hours!(window)
            start_hour = window[:windowStartHour].to_i
            end_hour = window[:windowEndHour].to_i

            return if valid_hour?(start_hour) && valid_hour?(end_hour)

            raise Dry::Struct::Error, 'Execution window hours must be between 0 and 23'
          end

          def self.valid_hour?(hour)
            hour >= 0 && hour <= 23
          end
        end
      end
    end
  end
end
