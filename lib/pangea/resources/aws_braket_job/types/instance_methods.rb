# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # Helper instance methods for BraketJobAttributes
        module BraketJobInstanceMethods
          def is_hybrid_job?
            device_config[:device].include?('hybrid')
          end

          def is_quantum_simulation?
            device_config[:device].include?('local') || device_config[:device].include?('simulator')
          end

          def estimated_cost_per_hour
            base_cost = BraketJobCosts.cost_for(instance_config[:instance_type])
            instance_count = instance_config[:instance_count] || 1
            base_cost * instance_count
          end

          def total_volume_size_gb
            instance_count = instance_config[:instance_count] || 1
            instance_config[:volume_size_in_gb] * instance_count
          end

          def max_runtime_hours
            stopping_condition[:max_runtime_in_seconds] / 3600.0
          end

          def has_checkpoints?
            !checkpoint_config.nil?
          end

          def has_input_data?
            input_data_config && !input_data_config.empty?
          end

          def instance_family
            instance_config[:instance_type].split('.')[1]
          end

          def compression_enabled?
            compression_type = algorithm_specification[:script_mode_config][:compression_type]
            compression_type && compression_type != 'NONE'
          end

          def algorithm_entry_script
            algorithm_specification[:script_mode_config][:entry_point]
          end

          def device_type
            device = device_config[:device]

            case device
            when /local/ then 'local_simulator'
            when /sv1/ then 'state_vector_simulator'
            when /tn1/ then 'tensor_network_simulator'
            when /dm1/ then 'density_matrix_simulator'
            when /qpu/ then 'quantum_processing_unit'
            else 'unknown'
            end
          end
        end
      end
    end
  end
end
