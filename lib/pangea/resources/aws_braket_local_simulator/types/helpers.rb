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
        # Helper methods for BraketLocalSimulatorAttributes
        module BraketLocalSimulatorHelpers
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
            memory_mb = configuration[:resource_configuration]&.[](:memory_size_mb) || 8192
            case simulator_type
            when 'braket_sv' then Math.log2(memory_mb * 1024 * 1024 / 16).floor
            when 'braket_dm' then Math.log2(memory_mb * 1024 * 1024 / 16).floor / 2
            when 'braket_tn' then 40
            else 20
            end
          end

          def supports_gpu?
            resource_config = configuration[:resource_configuration]
            resource_config && resource_config[:gpu_count]&.positive?
          end

          def memory_requirement_gb
            memory_mb = configuration[:resource_configuration]&.[](:memory_size_mb) || 8192
            memory_mb / 1024.0
          end

          def estimated_cost_per_hour
            base_cost = calculate_base_cost
            apply_simulator_multiplier(base_cost)
          end

          def parallelization_enabled?
            advanced_config = configuration[:advanced_configuration]
            advanced_config && advanced_config[:enable_parallelization] == true
          end

          def optimization_level
            configuration[:advanced_configuration]&.[](:optimization_level) || 1
          end

          def precision_type
            configuration[:advanced_configuration]&.[](:precision) || 'double'
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
            configuration[:resource_configuration]&.[](:cpu_count) || 4
          end

          def gpu_count
            configuration[:resource_configuration]&.[](:gpu_count) || 0
          end

          def efficiency_score
            score = 100
            score += memory_efficiency_bonus
            score += gpu_efficiency_bonus
            score += 5 if parallelization_enabled?
            score += optimization_level * 3
            score -= 20 if cpu_count > 32 && simulator_type != 'braket_dm'
            [score, 0].max
          end

          private

          def calculate_base_cost
            resource_config = configuration[:resource_configuration]
            return 0.50 unless resource_config

            cpu_cost = resource_config[:cpu_count] * 0.05
            memory_cost = memory_requirement_gb * 0.005
            gpu_cost = (resource_config[:gpu_count] || 0) * 1.00
            cpu_cost + memory_cost + gpu_cost
          end

          def apply_simulator_multiplier(base_cost)
            case simulator_type
            when 'braket_sv' then base_cost * 1.0
            when 'braket_dm' then base_cost * 1.5
            when 'braket_tn' then base_cost * 0.8
            else base_cost
            end
          end

          def memory_efficiency_bonus
            return 10 if simulator_type == 'braket_sv' && memory_requirement_gb >= 8
            return 10 if simulator_type == 'braket_dm' && memory_requirement_gb >= 16

            0
          end

          def gpu_efficiency_bonus
            return 15 if supports_gpu? && %w[braket_sv braket_dm].include?(simulator_type)

            0
          end
        end
      end
    end
  end
end
