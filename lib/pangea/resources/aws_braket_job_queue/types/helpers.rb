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
        # Helper methods for BraketJobQueue attributes
        module BraketJobQueueHelpers
          def is_quantum_device?
            device_arn.include?('/qpu/')
          end

          def is_simulator?
            device_arn.include?('/quantum-simulator/')
          end

          def is_enabled?
            state == 'ENABLED'
          end

          def is_disabled?
            state == 'DISABLED'
          end

          def has_timeout?
            !job_timeout_in_seconds.nil?
          end

          def device_provider
            parts = device_arn.split('/')
            return 'unknown' if parts.length < 4

            provider_mapping(parts[2])
          end

          def device_type
            if device_arn.include?('/quantum-simulator/')
              'SIMULATOR'
            elsif device_arn.include?('/qpu/')
              'QPU'
            else
              'UNKNOWN'
            end
          end

          def timeout_hours
            return 0 unless job_timeout_in_seconds

            job_timeout_in_seconds / 3600.0
          end

          def compute_environment_count
            compute_environment_order.length
          end

          def has_scheduling_policy?
            !scheduling_policy_arn.nil?
          end

          def primary_compute_environment
            sorted_envs = compute_environment_order.sort_by { |env| env[:order] }
            sorted_envs.first[:compute_environment] if sorted_envs.any?
          end

          def supports_high_priority?
            priority >= 500
          end

          private

          def provider_mapping(provider_name)
            providers = {
              'amazon' => 'AMAZON',
              'ionq' => 'IONQ',
              'rigetti' => 'RIGETTI',
              'oqc' => 'OQC',
              'xanadu' => 'XANADU',
              'quera' => 'QUERA'
            }
            providers.fetch(provider_name, provider_name.upcase)
          end
        end
      end
    end
  end
end
