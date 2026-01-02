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

require 'dry-struct'
require 'pangea/resources/types'
require_relative 'types/helpers'
require_relative 'types/validations'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS Braket Device resources
        class BraketDeviceAttributes < Dry::Struct
          include BraketDeviceHelpers
          transform_keys(&:to_sym)

          # Device name (required)
          attribute :device_name, Resources::Types::String

          # Device type (required)
          attribute :device_type, Resources::Types::String.enum('QPU', 'SIMULATOR')

          # Provider name (required)
          attribute :provider_name, Resources::Types::String.enum(
            'AMAZON', 'IONQ', 'RIGETTI', 'OQC', 'XANADU', 'QUERA'
          )

          # Device capabilities (required)
          attribute :device_capabilities, Resources::Types::Hash.schema(
            service: Resources::Types::Hash.schema(
              braketSchemaHeader: Resources::Types::Hash.schema(
                name: Resources::Types::String,
                version: Resources::Types::String
              ),
              executionWindows: Resources::Types::Array.of(
                Resources::Types::Hash.schema(
                  executionDay: Resources::Types::String.enum(
                    'Everyday', 'Weekdays', 'Weekend',
                    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
                  ),
                  windowStartHour: Resources::Types::String,
                  windowEndHour: Resources::Types::String
                )
              ).optional,
              shotsRange: Resources::Types::Array.of(Resources::Types::Integer).optional,
              deviceCost: Resources::Types::Hash.schema(
                price: Resources::Types::Float,
                unit: Resources::Types::String
              ).optional
            ),
            action: Resources::Types::Hash.schema(
              :"braket.ir.jaqcd.program" => Resources::Types::Hash.schema(
                supportedOperations: Resources::Types::Array.of(Resources::Types::String),
                supportedResultTypes: Resources::Types::Array.of(
                  Resources::Types::Hash.schema(
                    name: Resources::Types::String,
                    observables?: Resources::Types::Array.of(Resources::Types::String).optional,
                    minShots?: Resources::Types::Integer.optional,
                    maxShots?: Resources::Types::Integer.optional
                  )
                ).optional
              ).optional,
              :"braket.ir.openqasm.program" => Resources::Types::Hash.schema(
                supportedOperations: Resources::Types::Array.of(Resources::Types::String)
              ).optional
            ),
            deviceParameters?: Resources::Types::Hash.optional,
            paradigm: Resources::Types::Hash.schema(
              qubitCount: Resources::Types::Integer,
              nativeGateSet: Resources::Types::Array.of(Resources::Types::String).optional,
              connectivity: Resources::Types::Hash.schema(
                fullyConnected: Resources::Types::Bool,
                connectivityGraph?: Resources::Types::Hash.optional
              ).optional
            )
          )

          # Device ARN (optional - for existing devices)
          attribute? :device_arn, Resources::Types::String.optional

          # Device status (optional)
          attribute? :device_status, Resources::Types::String.enum('ONLINE', 'OFFLINE', 'RETIRED').optional

          # Tags (optional)
          attribute? :tags, Resources::Types::Hash.schema(
            Resources::Types::String => Resources::Types::String
          ).optional

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)
            BraketDeviceValidations.validate!(attrs)
            attrs
          end
        end
      end
    end
  end
end
