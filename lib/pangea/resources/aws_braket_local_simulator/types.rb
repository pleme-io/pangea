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
require_relative 'types/validators'
require_relative 'types/helpers'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS Braket Local Simulator resources
        class BraketLocalSimulatorAttributes < Dry::Struct
          extend BraketLocalSimulatorValidators
          include BraketLocalSimulatorHelpers

          transform_keys(&:to_sym)

          # Simulator name (required)
          attribute :simulator_name, Resources::Types::String

          # Simulator type (required)
          attribute :simulator_type, Resources::Types::String.enum(
            'braket_sv',     # State vector simulator
            'braket_dm',     # Density matrix simulator
            'braket_tn'      # Tensor network simulator
          )

          # Configuration (required)
          attribute :configuration, Resources::Types::Hash.schema(
            backend_configuration: Resources::Types::Hash.schema(
              device_name: Resources::Types::String.enum(
                'braket_sv_v2',
                'braket_dm_v2',
                'braket_tn1'
              ),
              shots?: Resources::Types::Integer.constrained(gteq: 1, lteq: 100_000).optional,
              max_parallel_shots?: Resources::Types::Integer.constrained(gteq: 1, lteq: 10_000).optional,
              seed?: Resources::Types::Integer.optional
            ),
            resource_configuration?: Resources::Types::Hash.schema(
              cpu_count: Resources::Types::Integer.constrained(gteq: 1, lteq: 96),
              memory_size_mb: Resources::Types::Integer.constrained(gteq: 1024, lteq: 768_000),
              gpu_count?: Resources::Types::Integer.constrained(gteq: 0, lteq: 8).optional
            ).optional,
            advanced_configuration?: Resources::Types::Hash.schema(
              enable_parallelization?: Resources::Types::Bool.optional,
              optimization_level?: Resources::Types::Integer.constrained(gteq: 0, lteq: 3).optional,
              precision?: Resources::Types::String.enum('single', 'double').optional
            ).optional
          )

          # Execution environment (optional)
          attribute? :execution_environment, Resources::Types::Hash.schema(
            docker_image?: Resources::Types::String.optional,
            python_version?: Resources::Types::String.enum('3.8', '3.9', '3.10', '3.11').optional,
            environment_variables?: Resources::Types::Hash.schema(
              Resources::Types::String => Resources::Types::String
            ).optional
          ).optional

          # Tags (optional)
          attribute? :tags, Resources::Types::Hash.schema(
            Resources::Types::String => Resources::Types::String
          ).optional

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)

            validate_simulator_name(attrs.simulator_name)

            device_name = attrs.configuration[:backend_configuration][:device_name]
            validate_device_consistency(attrs.simulator_type, device_name)

            resource_config = attrs.configuration[:resource_configuration]
            validate_gpu_requirements(attrs.simulator_type, resource_config)
            validate_memory_requirements(attrs.simulator_type, resource_config)

            shots = attrs.configuration[:backend_configuration][:shots]
            validate_shots(attrs.simulator_type, shots)

            attrs
          end
        end
      end
    end
  end
end
