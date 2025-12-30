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
        # Validation methods for BraketJobQueue attributes
        module BraketJobQueueValidators
          QUEUE_NAME_PATTERN = /\A[a-zA-Z0-9\-_]{1,128}\z/
          DEVICE_ARN_PATTERN = /\Aarn:aws:braket:[a-z0-9\-]+:\d{12}:device\/[a-z]+\/[a-zA-Z0-9\-_]+\/[a-zA-Z0-9\-_]+\z/
          IAM_ROLE_PATTERN = /\Aarn:aws:iam::\d{12}:role\/.*\z/
          SCHEDULING_POLICY_PATTERN = /\Aarn:aws:batch:[a-z0-9\-]+:\d{12}:scheduling-policy\/.*\z/

          def validate_queue_name(queue_name)
            return if queue_name.match?(QUEUE_NAME_PATTERN)

            raise Dry::Struct::Error,
                  'queue_name must be 1-128 characters long and contain only alphanumeric characters, hyphens, and underscores'
          end

          def validate_device_arn(device_arn)
            return if device_arn.match?(DEVICE_ARN_PATTERN)

            raise Dry::Struct::Error, 'device_arn must be a valid Braket device ARN'
          end

          def validate_service_role(service_role)
            return if service_role.nil?
            return if service_role.match?(IAM_ROLE_PATTERN)

            raise Dry::Struct::Error, 'service_role must be a valid IAM role ARN'
          end

          def validate_scheduling_policy_arn(scheduling_policy_arn)
            return if scheduling_policy_arn.nil?
            return if scheduling_policy_arn.match?(SCHEDULING_POLICY_PATTERN)

            raise Dry::Struct::Error, 'scheduling_policy_arn must be a valid AWS Batch scheduling policy ARN'
          end

          def validate_compute_environment_order(compute_environment_order)
            orders = compute_environment_order.map { |env| env[:order] }
            if orders.uniq.length != orders.length
              raise Dry::Struct::Error, 'compute_environment_order must have unique order values'
            end

            compute_environment_order.each do |env|
              next if env[:compute_environment].match?(QUEUE_NAME_PATTERN)

              raise Dry::Struct::Error,
                    'compute_environment names must be 1-128 characters long and contain only alphanumeric characters, hyphens, and underscores'
            end
          end
        end
      end
    end
  end
end
