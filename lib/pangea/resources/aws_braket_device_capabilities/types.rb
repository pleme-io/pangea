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
require_relative 'types/device_classification'
require_relative 'types/capability_support'
require_relative 'types/execution_params'
require_relative 'types/device_specs'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS Braket Device Capabilities data source
        class BraketDeviceCapabilitiesAttributes < Dry::Struct
          include DeviceClassification
          include CapabilitySupport
          include ExecutionParams
          include DeviceSpecs

          transform_keys(&:to_sym)

          # Device ARN (required)
          attribute :device_arn, Resources::Types::String

          # Capability filters (optional)
          attribute? :capability_filters, Resources::Types::Array.of(
            Resources::Types::Hash.schema(
              name: Resources::Types::String.enum(
                'device-type',
                'provider-name',
                'device-status',
                'qubit-count',
                'gate-set',
                'connectivity',
                'execution-windows'
              ),
              values: Resources::Types::Array.of(Resources::Types::String)
            )
          ).optional

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)

            # Validate device ARN
            unless attrs.device_arn.match?(/\Aarn:aws:braket:[a-z0-9\-]+:\d{12}:device\/.*\z/)
              raise Dry::Struct::Error, "device_arn must be a valid Braket device ARN"
            end

            # Validate filter combinations
            if attrs.capability_filters
              filter_names = attrs.capability_filters.map { |f| f[:name] }
              if filter_names.uniq.length != filter_names.length
                raise Dry::Struct::Error, "capability_filters cannot have duplicate filter names"
              end
            end

            attrs
          end
        end
      end
    end
  end
end
