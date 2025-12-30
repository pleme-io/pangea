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
require_relative 'types/s3_events'
require_relative 'types/notification_config'
require_relative 'types/validators'
require_relative 'types/helpers'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS S3 Bucket Notification Configuration resources
        class S3BucketNotificationAttributes < Dry::Struct
          include NotificationHelpers

          transform_keys(&:to_sym)

          # The name of the bucket to configure notifications for
          attribute :bucket, Resources::Types::String

          # CloudWatch topic configuration for object creation events
          attribute :cloudwatch_configuration, NotificationConfig::TopicConfigArray

          # Lambda function configurations for event processing
          attribute :lambda_function, NotificationConfig::LambdaConfigArray

          # SQS queue configurations for event queuing
          attribute :queue, NotificationConfig::QueueConfigArray

          # EventBridge configuration for advanced event routing
          attribute :eventbridge, Resources::Types::Bool.default(false)

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)

            NotificationValidators.validate_has_configuration!(attrs)
            NotificationValidators.validate_all_arns!(attrs)

            attrs
          end
        end
      end
    end
  end
end
