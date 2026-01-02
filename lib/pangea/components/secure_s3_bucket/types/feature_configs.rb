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
  module Components
    module SecureS3Bucket
      # Notification configuration for events
      class NotificationConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :enabled, Types::Bool.default(false)
        attribute :lambda_configurations, Types::Array.default([].freeze)
        attribute :topic_configurations, Types::Array.default([].freeze)
        attribute :queue_configurations, Types::Array.default([].freeze)
      end

      # CORS configuration
      class CorsConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :enabled, Types::Bool.default(false)
        attribute :cors_rules, Types::Array.default([].freeze)
      end

      # Replication configuration
      class ReplicationConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :enabled, Types::Bool.default(false)
        attribute :role_arn, Types::String.optional.constrained(format: /\Aarn:aws:iam::\d{12}:role\//)
        attribute :rules, Types::Array.default([].freeze)
      end

      # Logging configuration
      class LoggingConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :enabled, Types::Bool.default(false)
        attribute :target_bucket, Types::String.optional
        attribute :target_prefix, Types::String.default("access-logs/")
        attribute :target_object_key_format, Types::String.optional.enum('SimplePrefix', 'PartitionedPrefix')
      end
    end
  end
end
