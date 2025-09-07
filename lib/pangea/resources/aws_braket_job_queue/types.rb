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
      # Type-safe attributes for AWS Braket Job Queue resources
      class BraketJobQueueAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Queue name (required)
        attribute :queue_name, Resources::Types::String

        # Device ARN (required)
        attribute :device_arn, Resources::Types::String

        # Priority (required)
        attribute :priority, Resources::Types::Integer.constrained(gteq: 0, lteq: 1000)

        # State (required)
        attribute :state, Resources::Types::String.enum('ENABLED', 'DISABLED')

        # Compute environment order (required)
        attribute :compute_environment_order, Resources::Types::Array.of(
          Resources::Types::Hash.schema(
            order: Resources::Types::Integer.constrained(gteq: 1),
            compute_environment: Resources::Types::String
          )
        )

        # Job timeout in seconds (optional)
        attribute? :job_timeout_in_seconds, Resources::Types::Integer.constrained(gteq: 60, lteq: 2592000).optional # 1 min to 30 days

        # Service role (optional)
        attribute? :service_role, Resources::Types::String.optional

        # Scheduling policy ARN (optional)
        attribute? :scheduling_policy_arn, Resources::Types::String.optional

        # Tags (optional)
        attribute? :tags, Resources::Types::Hash.schema(
          Resources::Types::String => Resources::Types::String
        ).optional

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate queue name
          unless attrs.queue_name.match?(/\A[a-zA-Z0-9\-_]{1,128}\z/)
            raise Dry::Struct::Error, "queue_name must be 1-128 characters long and contain only alphanumeric characters, hyphens, and underscores"
          end

          # Validate device ARN
          unless attrs.device_arn.match?(/\Aarn:aws:braket:[a-z0-9\-]+:\d{12}:device\/[a-z]+\/[a-zA-Z0-9\-_]+\/[a-zA-Z0-9\-_]+\z/)
            raise Dry::Struct::Error, "device_arn must be a valid Braket device ARN"
          end

          # Validate service role ARN if provided
          if attrs.service_role
            unless attrs.service_role.match?(/\Aarn:aws:iam::\d{12}:role\/.*\z/)
              raise Dry::Struct::Error, "service_role must be a valid IAM role ARN"
            end
          end

          # Validate scheduling policy ARN if provided
          if attrs.scheduling_policy_arn
            unless attrs.scheduling_policy_arn.match?(/\Aarn:aws:batch:[a-z0-9\-]+:\d{12}:scheduling-policy\/.*\z/)
              raise Dry::Struct::Error, "scheduling_policy_arn must be a valid AWS Batch scheduling policy ARN"
            end
          end

          # Validate compute environment order uniqueness
          orders = attrs.compute_environment_order.map { |env| env[:order] }
          if orders.uniq.length != orders.length
            raise Dry::Struct::Error, "compute_environment_order must have unique order values"
          end

          # Validate compute environment names
          attrs.compute_environment_order.each do |env|
            unless env[:compute_environment].match?(/\A[a-zA-Z0-9\-_]{1,128}\z/)
              raise Dry::Struct::Error, "compute_environment names must be 1-128 characters long and contain only alphanumeric characters, hyphens, and underscores"
            end
          end

          attrs
        end

        # Helper methods
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
          # Extract provider from device ARN: arn:aws:braket:region:account:device/quantum-simulator/amazon/sv1
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

        def estimated_cost_factor
          # Cost factors based on device type and provider
          case device_provider
          when 'AMAZON'
            case device_type
            when 'SIMULATOR'
              0.075 # Per minute for simulators
            else
              1.0
            end
          when 'IONQ'
            case device_type
            when 'QPU'
              0.01 # Per shot for IonQ QPU
            else
              1.0
            end
          when 'RIGETTI'
            case device_type
            when 'QPU'
              0.00035 # Per shot for Rigetti QPU
            else
              1.0
            end
          when 'OQC'
            case device_type
            when 'QPU'
              0.00035 # Per shot for OQC QPU
            else
              1.0
            end
          else
            1.0
          end
        end

        # Get primary compute environment
        def primary_compute_environment
          sorted_envs = compute_environment_order.sort_by { |env| env[:order] }
          sorted_envs.first[:compute_environment] if sorted_envs.any?
        end

        # Check if queue supports high priority jobs
        def supports_high_priority?
          priority >= 500
        end

        # Get queue efficiency score based on configuration
        def efficiency_score
          score = 100
          
          # Reduce score for disabled queues
          score -= 50 if is_disabled?
          
          # Reduce score for very low priority
          score -= 20 if priority < 100
          
          # Add score for proper timeout configuration
          score += 10 if has_timeout? && timeout_hours > 0 && timeout_hours < 24
          
          # Add score for multiple compute environments (load balancing)
          score += 15 if compute_environment_count > 1
          
          # Add score for scheduling policy
          score += 5 if has_scheduling_policy?
          
          [score, 0].max
        end
      end
    end
      end
    end
  end
end