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
        # Validation helpers for S3 bucket notification attributes
        module NotificationValidators
          # Validates that at least one notification configuration exists
          # @param attrs [S3BucketNotificationAttributes] The attributes to validate
          # @raise [Dry::Struct::Error] If no configurations are specified
          def self.validate_has_configuration!(attrs)
            total = attrs.cloudwatch_configuration.size +
                    attrs.lambda_function.size +
                    attrs.queue.size +
                    (attrs.eventbridge ? 1 : 0)

            return unless total.zero?

            raise Dry::Struct::Error,
                  'At least one notification configuration (cloudwatch, lambda, queue, or eventbridge) must be specified'
          end

          # Validates ARN format for a collection of configurations
          # @param configurations [Array<Hash>] The configurations to validate
          # @param arn_key [Symbol] The key containing the ARN
          # @param expected_service [String] The expected AWS service name
          # @raise [Dry::Struct::Error] If any ARN is invalid
          def self.validate_arn_format!(configurations, arn_key, expected_service)
            configurations.each do |config|
              arn = config[arn_key]
              next if arn.start_with?("arn:aws:#{expected_service}:")

              raise Dry::Struct::Error,
                    "#{arn_key} must be a valid #{expected_service.upcase} ARN"
            end
          end

          # Validates all ARNs in the attributes
          # @param attrs [S3BucketNotificationAttributes] The attributes to validate
          def self.validate_all_arns!(attrs)
            validate_arn_format!(attrs.cloudwatch_configuration, :topic_arn, 'sns')
            validate_arn_format!(attrs.lambda_function, :lambda_function_arn, 'lambda')
            validate_arn_format!(attrs.queue, :queue_arn, 'sqs')
          end
        end
      end
    end
  end
end
