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

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS Braket Device Capabilities data source
      class BraketDeviceCapabilitiesAttributes < Dry::Struct
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

        # Helper methods
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

        def connectivity_graph_available?
          # Most QPUs have connectivity graphs
          is_quantum_hardware?
        end

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

        # Check if device supports variational algorithms
        def supports_variational_algorithms?
          # Most devices support variational quantum algorithms
          true
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
end