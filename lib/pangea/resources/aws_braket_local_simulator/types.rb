# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS Braket Local Simulator resources
      class BraketLocalSimulatorAttributes < Dry::Struct
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
            shots?: Resources::Types::Integer.constrained(gteq: 1, lteq: 100000).optional,
            max_parallel_shots?: Resources::Types::Integer.constrained(gteq: 1, lteq: 10000).optional,
            seed?: Resources::Types::Integer.optional
          ),
          resource_configuration?: Resources::Types::Hash.schema(
            cpu_count: Resources::Types::Integer.constrained(gteq: 1, lteq: 96),
            memory_size_mb: Resources::Types::Integer.constrained(gteq: 1024, lteq: 768000), # 1GB to 750GB
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

          # Validate simulator name
          unless attrs.simulator_name.match?(/\A[a-zA-Z0-9\-_]{1,128}\z/)
            raise Dry::Struct::Error, "simulator_name must be 1-128 characters long and contain only alphanumeric characters, hyphens, and underscores"
          end

          # Validate simulator type and device name consistency
          device_name = attrs.configuration[:backend_configuration][:device_name]
          case attrs.simulator_type
          when 'braket_sv'
            unless device_name == 'braket_sv_v2'
              raise Dry::Struct::Error, "braket_sv simulator type requires braket_sv_v2 device"
            end
          when 'braket_dm'
            unless device_name == 'braket_dm_v2'
              raise Dry::Struct::Error, "braket_dm simulator type requires braket_dm_v2 device"
            end
          when 'braket_tn'
            unless device_name == 'braket_tn1'
              raise Dry::Struct::Error, "braket_tn simulator type requires braket_tn1 device"
            end
          end

          # Validate GPU requirements for different simulator types
          resource_config = attrs.configuration[:resource_configuration]
          if resource_config && resource_config[:gpu_count] && resource_config[:gpu_count] > 0
            case attrs.simulator_type
            when 'braket_dm'
              # Density matrix simulator can benefit from GPU
            when 'braket_sv'
              # State vector simulator can benefit from GPU for large circuits
            when 'braket_tn'
              # Tensor network simulator typically doesn't use GPU
              raise Dry::Struct::Error, "braket_tn simulator typically does not use GPU acceleration"
            end
          end

          # Validate memory requirements based on simulator type
          if resource_config
            memory_mb = resource_config[:memory_size_mb]
            case attrs.simulator_type
            when 'braket_sv'
              # State vector needs exponential memory: 2^n qubits * 16 bytes (complex128)
              if memory_mb < 2048
                raise Dry::Struct::Error, "State vector simulator requires at least 2GB of memory"
              end
            when 'braket_dm'
              # Density matrix needs even more memory: 2^(2n) elements
              if memory_mb < 4096
                raise Dry::Struct::Error, "Density matrix simulator requires at least 4GB of memory"
              end
            when 'braket_tn'
              # Tensor network simulator can work with less memory
              if memory_mb < 1024
                raise Dry::Struct::Error, "Tensor network simulator requires at least 1GB of memory"
              end
            end
          end

          # Validate shots parameter
          shots = attrs.configuration[:backend_configuration][:shots]
          if shots && attrs.simulator_type == 'braket_tn'
            # Tensor network simulators have different shot semantics
            if shots > 10000
              raise Dry::Struct::Error, "Tensor network simulators typically use fewer shots (≤10000)"
            end
          end

          attrs
        end

        # Helper methods
        def is_state_vector?
          simulator_type == 'braket_sv'
        end

        def is_density_matrix?
          simulator_type == 'braket_dm'
        end

        def is_tensor_network?
          simulator_type == 'braket_tn'
        end

        def max_qubits
          # Estimate maximum qubits based on simulator type and memory
          memory_mb = configuration[:resource_configuration]&.[](:memory_size_mb) || 8192
          
          case simulator_type
          when 'braket_sv'
            # State vector: 2^n * 16 bytes per amplitude
            Math.log2(memory_mb * 1024 * 1024 / 16).floor
          when 'braket_dm'
            # Density matrix: 2^(2n) * 16 bytes per element
            Math.log2(memory_mb * 1024 * 1024 / 16).floor / 2
          when 'braket_tn'
            # Tensor network can handle more qubits with less memory
            40 # Typically up to ~40 qubits
          else
            20
          end
        end

        def supports_gpu?
          resource_config = configuration[:resource_configuration]
          resource_config && resource_config[:gpu_count] && resource_config[:gpu_count] > 0
        end

        def memory_requirement_gb
          memory_mb = configuration[:resource_configuration]&.[](:memory_size_mb) || 8192
          memory_mb / 1024.0
        end

        def estimated_cost_per_hour
          # Base cost for compute resources (rough estimates)
          base_cost = 0.0
          
          resource_config = configuration[:resource_configuration]
          if resource_config
            # CPU cost: ~$0.05 per vCPU per hour
            cpu_cost = resource_config[:cpu_count] * 0.05
            
            # Memory cost: ~$0.005 per GB per hour
            memory_cost = memory_requirement_gb * 0.005
            
            # GPU cost: ~$1.00 per GPU per hour
            gpu_cost = (resource_config[:gpu_count] || 0) * 1.00
            
            base_cost = cpu_cost + memory_cost + gpu_cost
          else
            # Default configuration cost
            base_cost = 0.50
          end
          
          # Apply simulator type multiplier
          case simulator_type
          when 'braket_sv'
            base_cost * 1.0 # Standard cost
          when 'braket_dm'
            base_cost * 1.5 # Higher cost due to complexity
          when 'braket_tn'
            base_cost * 0.8 # Lower cost due to efficiency
          else
            base_cost
          end
        end

        def parallelization_enabled?
          advanced_config = configuration[:advanced_configuration]
          advanced_config && advanced_config[:enable_parallelization] == true
        end

        def optimization_level
          advanced_config = configuration[:advanced_configuration]
          advanced_config&.[](:optimization_level) || 1
        end

        def precision_type
          advanced_config = configuration[:advanced_configuration]
          advanced_config&.[](:precision) || 'double'
        end

        def has_custom_environment?
          !execution_environment.nil?
        end

        def simulator_backend
          configuration[:backend_configuration][:device_name]
        end

        def shots_configured
          configuration[:backend_configuration][:shots] || 1000
        end

        def max_parallel_shots
          configuration[:backend_configuration][:max_parallel_shots] || 1
        end

        def cpu_count
          resource_config = configuration[:resource_configuration]
          resource_config&.[](:cpu_count) || 4
        end

        def gpu_count
          resource_config = configuration[:resource_configuration]
          resource_config&.[](:gpu_count) || 0
        end

        # Calculate efficiency score based on configuration
        def efficiency_score
          score = 100
          
          # Bonus for appropriate resource allocation
          if simulator_type == 'braket_sv' && memory_requirement_gb >= 8
            score += 10
          end
          
          if simulator_type == 'braket_dm' && memory_requirement_gb >= 16
            score += 10
          end
          
          # Bonus for GPU usage where appropriate
          if supports_gpu? && (simulator_type == 'braket_sv' || simulator_type == 'braket_dm')
            score += 15
          end
          
          # Bonus for parallelization
          score += 5 if parallelization_enabled?
          
          # Bonus for optimization
          score += optimization_level * 3
          
          # Penalty for overallocation
          score -= 20 if cpu_count > 32 && simulator_type != 'braket_dm'
          
          [score, 0].max
        end
      end
    end
      end
    end
  end
end