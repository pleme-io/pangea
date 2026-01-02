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

# Sub-types
require_relative 'types/lifecycle_rule'
require_relative 'types/bucket_configs'
require_relative 'types/feature_configs'
require_relative 'types/monitoring_configs'

module Pangea
  module Components
    module SecureS3Bucket
      # Main Secure S3 Bucket component attributes
      class SecureS3BucketAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Basic bucket configuration
        attribute :bucket_name, Types::String.optional.constructor { |value|
          next value unless value

          # S3 bucket naming validation
          unless value.match?(/\A[a-z0-9][a-z0-9\-\.]{1,61}[a-z0-9]\z/)
            raise Dry::Types::ConstraintError, "Invalid S3 bucket name format"
          end

          # Additional validation
          if value.include?('..')
            raise Dry::Types::ConstraintError, "Bucket name cannot contain consecutive periods"
          end

          if value.match?(/\A\d+\.\d+\.\d+\.\d+\z/)
            raise Dry::Types::ConstraintError, "Bucket name cannot be formatted as IP address"
          end

          value
        }

        # Bucket configuration
        attribute :force_destroy, Types::Bool.default(false)
        attribute :object_lock_enabled, Types::Bool.default(false)

        # Versioning
        attribute :versioning, VersioningConfig.default({})

        # Encryption
        attribute :encryption, EncryptionConfig.default({})

        # Public access
        attribute :public_access_block, PublicAccessBlockConfig.default({})

        # Lifecycle management
        attribute :lifecycle_rules, Types::Array.of(LifecycleRule).default([
          # Default intelligent tiering rule
          LifecycleRule.new({
            id: "intelligent-tiering",
            status: "Enabled",
            transitions: [{
              days: 0,
              storage_class: "INTELLIGENT_TIERING"
            }]
          })
        ].freeze)

        # Cross-region replication
        attribute :replication, ReplicationConfig.default({})

        # Notifications
        attribute :notifications, NotificationConfig.default({})

        # CORS configuration
        attribute :cors, CorsConfig.default({})

        # Access logging
        attribute :logging, LoggingConfig.default({})

        # Transfer acceleration
        attribute :acceleration, AccelerationConfig.default({})

        # Analytics
        attribute :analytics, AnalyticsConfig.default({})

        # Inventory reporting
        attribute :inventory, InventoryConfig.default({})

        # Metrics and monitoring
        attribute :metrics, MetricsConfig.default({})

        # Object lock configuration
        attribute :object_lock_configuration, Types::Hash.optional

        # Common tags
        attribute :tags, Types::AwsTags.default({}.freeze)

        # Request payer configuration
        attribute :request_payer, Types::String.default("BucketOwner").enum('BucketOwner', 'Requester')

        # Website configuration
        attribute :website_configuration, Types::Hash.optional

        # Policy document (JSON string)
        attribute :policy, Types::String.optional.constructor { |value|
          next value unless value

          begin
            JSON.parse(value)
            value
          rescue JSON::ParserError
            raise Dry::Types::ConstraintError, "Bucket policy must be valid JSON"
          end
        }

        # Custom validation for conflicting configurations
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate object lock requires versioning
          if attrs.object_lock_enabled && attrs.versioning.status != 'Enabled'
            raise Dry::Types::ConstraintError, "Object Lock requires versioning to be enabled"
          end

          # Validate KMS configuration
          if attrs.encryption.sse_algorithm.start_with?('aws:kms') && !attrs.encryption.kms_key_id
            raise Dry::Types::ConstraintError, "KMS key ID required for KMS encryption"
          end

          # Validate replication requirements
          if attrs.replication.enabled
            unless attrs.replication.role_arn
              raise Dry::Types::ConstraintError, "Replication role ARN required when replication is enabled"
            end

            unless attrs.versioning.status == 'Enabled'
              raise Dry::Types::ConstraintError, "Versioning must be enabled for replication"
            end
          end

          # Validate logging configuration
          if attrs.logging.enabled && !attrs.logging.target_bucket
            raise Dry::Types::ConstraintError, "Target bucket required when logging is enabled"
          end

          attrs
        end
      end
    end
  end
end
