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
require_relative 'types/stream_helpers'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS QLDB Stream resources
        class QldbStreamAttributes < Dry::Struct
          include QldbStreamHelpers

          transform_keys(&:to_sym)

          # Stream name (required)
          attribute :stream_name, Resources::Types::String

          # Ledger name (required)
          attribute :ledger_name, Resources::Types::String

          # Role ARN for stream to assume (required)
          attribute :role_arn, Resources::Types::String

          # Kinesis configuration (required)
          attribute :kinesis_configuration, Resources::Types::Hash.schema(
            stream_arn: Resources::Types::String,
            aggregation_enabled?: Resources::Types::Bool.default(true)
          )

          # Inclusive start time (required)
          attribute :inclusive_start_time, Resources::Types::String

          # Exclusive end time (optional)
          attribute? :exclusive_end_time, Resources::Types::String.optional

          # Tags (optional)
          attribute? :tags, Resources::Types::Hash.schema(
            Resources::Types::String => Resources::Types::String
          ).optional

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)

            # Validate stream name
            unless attrs.stream_name.match?(/\A[a-zA-Z0-9_-]+\z/)
              raise Dry::Struct::Error, 'stream_name must contain only alphanumeric characters, underscores, and hyphens'
            end

            if attrs.stream_name.length < 1 || attrs.stream_name.length > 64
              raise Dry::Struct::Error, 'stream_name must be between 1 and 64 characters'
            end

            # Validate ledger name
            unless attrs.ledger_name.match?(/\A[a-zA-Z][a-zA-Z0-9_-]*\z/)
              raise Dry::Struct::Error,
                    'ledger_name must start with a letter and contain only alphanumeric characters, underscores, and hyphens'
            end

            # Validate role ARN
            unless attrs.role_arn.match?(/\Aarn:aws[a-z\-]*:iam::\d{12}:role\/[\w+=,.@-]+\z/)
              raise Dry::Struct::Error, 'role_arn must be a valid IAM role ARN'
            end

            # Validate Kinesis stream ARN
            unless attrs.kinesis_configuration[:stream_arn].match?(/\Aarn:aws[a-z\-]*:kinesis:[a-z0-9\-]+:\d{12}:stream\/[\w-]+\z/)
              raise Dry::Struct::Error, 'kinesis stream_arn must be a valid Kinesis stream ARN'
            end

            # Validate timestamps
            validate_timestamps(attrs)

            attrs
          end

          def self.validate_timestamps(attrs)
            # Parse timestamps to ensure they're valid ISO 8601
            begin
              start_time = Time.parse(attrs.inclusive_start_time)
            rescue ArgumentError
              raise Dry::Struct::Error, 'inclusive_start_time must be a valid ISO 8601 timestamp'
            end

            if attrs.exclusive_end_time
              begin
                end_time = Time.parse(attrs.exclusive_end_time)
              rescue ArgumentError
                raise Dry::Struct::Error, 'exclusive_end_time must be a valid ISO 8601 timestamp'
              end

              if end_time <= start_time
                raise Dry::Struct::Error, 'exclusive_end_time must be after inclusive_start_time'
              end
            end
          end
        end
      end
    end
  end
end
