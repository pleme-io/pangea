# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS Braket Device resources
      class BraketDeviceAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Device name (required)
        attribute :device_name, Resources::Types::String

        # Device type (required)
        attribute :device_type, Resources::Types::String.enum(
          'QPU',           # Quantum Processing Unit
          'SIMULATOR'      # Quantum Simulator
        )

        # Provider name (required)
        attribute :provider_name, Resources::Types::String.enum(
          'AMAZON',        # Amazon Braket simulators
          'IONQ',          # IonQ quantum computers
          'RIGETTI',       # Rigetti quantum processors
          'OQC',           # Oxford Quantum Circuits
          'XANADU',        # Xanadu photonic quantum
          'QUERA'          # QuEra neutral atom quantum
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
                executionDay: Resources::Types::String.enum('Everyday', 'Weekdays', 'Weekend', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
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
            braket.ir.jaqcd.program?: Resources::Types::Hash.schema(
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
            braket.ir.openqasm.program?: Resources::Types::Hash.schema(
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
        attribute? :device_status, Resources::Types::String.enum(
          'ONLINE',
          'OFFLINE', 
          'RETIRED'
        ).optional

        # Tags (optional)
        attribute? :tags, Resources::Types::Hash.schema(
          Resources::Types::String => Resources::Types::String
        ).optional

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate device name format
          unless attrs.device_name.match?(/\A[a-zA-Z0-9][a-zA-Z0-9\-_]*[a-zA-Z0-9]\z/)
            raise Dry::Struct::Error, "device_name must start and end with alphanumeric characters and can contain hyphens and underscores"
          end

          # Validate QPU providers
          if attrs.device_type == 'QPU' && attrs.provider_name == 'AMAZON'
            raise Dry::Struct::Error, "AMAZON provider only offers simulators, not QPUs"
          end

          # Validate simulator providers
          if attrs.device_type == 'SIMULATOR' && !['AMAZON'].include?(attrs.provider_name)
            raise Dry::Struct::Error, "Only AMAZON provider currently offers simulators in Braket"
          end

          # Validate qubit count
          qubit_count = attrs.device_capabilities[:paradigm][:qubitCount]
          if qubit_count <= 0
            raise Dry::Struct::Error, "qubitCount must be positive"
          end

          # Validate execution windows if provided
          if attrs.device_capabilities[:service][:executionWindows]
            attrs.device_capabilities[:service][:executionWindows].each do |window|
              start_hour = window[:windowStartHour].to_i
              end_hour = window[:windowEndHour].to_i
              
              if start_hour < 0 || start_hour > 23 || end_hour < 0 || end_hour > 23
                raise Dry::Struct::Error, "Execution window hours must be between 0 and 23"
              end
            end
          end

          attrs
        end

        # Helper methods
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
          device_capabilities[:service][:shotsRange] || [1, 100000]
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
end