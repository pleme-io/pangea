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
require_relative 'types/cost_estimation'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS Braket Job Queue resources
        class BraketJobQueueAttributes < Dry::Struct
          extend BraketJobQueueValidators
          include BraketJobQueueHelpers
          include BraketJobQueueCostEstimation

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

          # Job timeout in seconds (optional) - 1 min to 30 days
          attribute? :job_timeout_in_seconds,
                     Resources::Types::Integer.constrained(gteq: 60, lteq: 2_592_000).optional

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

            validate_queue_name(attrs.queue_name)
            validate_device_arn(attrs.device_arn)
            validate_service_role(attrs.service_role)
            validate_scheduling_policy_arn(attrs.scheduling_policy_arn)
            validate_compute_environment_order(attrs.compute_environment_order)

            attrs
          end
        end
      end
    end
  end
end
