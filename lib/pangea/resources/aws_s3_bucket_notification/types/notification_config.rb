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

require 'pangea/resources/types'
require_relative 's3_events'

module Pangea
  module Resources
    module AWS
      module Types
        # Builder module for notification configuration schemas
        module NotificationConfig
          # Builds a notification configuration schema with the specified ARN key
          # @param arn_key [Symbol] The key for the ARN attribute (e.g., :topic_arn, :queue_arn)
          # @return [Dry::Types::Type] The configured schema type
          def self.build_schema(arn_key)
            Resources::Types::Hash.schema(
              id?: Resources::Types::String.optional,
              arn_key => Resources::Types::String,
              events: S3Events::EventsArray,
              filter_prefix?: Resources::Types::String.optional,
              filter_suffix?: Resources::Types::String.optional
            )
          end

          # CloudWatch/SNS topic configuration schema
          TopicConfigSchema = Resources::Types::Hash.schema(
            id?: Resources::Types::String.optional,
            topic_arn: Resources::Types::String,
            events: S3Events::EventsArray,
            filter_prefix?: Resources::Types::String.optional,
            filter_suffix?: Resources::Types::String.optional
          )

          # Lambda function configuration schema
          LambdaConfigSchema = Resources::Types::Hash.schema(
            id?: Resources::Types::String.optional,
            lambda_function_arn: Resources::Types::String,
            events: S3Events::EventsArray,
            filter_prefix?: Resources::Types::String.optional,
            filter_suffix?: Resources::Types::String.optional
          )

          # SQS queue configuration schema
          QueueConfigSchema = Resources::Types::Hash.schema(
            id?: Resources::Types::String.optional,
            queue_arn: Resources::Types::String,
            events: S3Events::EventsArray,
            filter_prefix?: Resources::Types::String.optional,
            filter_suffix?: Resources::Types::String.optional
          )

          # Array types for each configuration
          TopicConfigArray = Resources::Types::Array.of(TopicConfigSchema).default([].freeze)
          LambdaConfigArray = Resources::Types::Array.of(LambdaConfigSchema).default([].freeze)
          QueueConfigArray = Resources::Types::Array.of(QueueConfigSchema).default([].freeze)
        end
      end
    end
  end
end
