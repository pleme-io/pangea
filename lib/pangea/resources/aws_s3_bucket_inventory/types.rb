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
require_relative 'types/helpers'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS S3 Bucket Inventory Configuration resources
      class S3BucketInventoryAttributes < Dry::Struct
        include S3BucketInventory::Helpers
        transform_keys(&:to_sym)

        # The name of the bucket to configure inventory for
        attribute :bucket, Resources::Types::String

        # Unique name for the inventory configuration
        attribute :name, Resources::Types::String

        # Whether the inventory configuration is enabled
        attribute :enabled, Resources::Types::Bool.default(true)

        # Inventory output format
        attribute :format, Resources::Types::String.enum('CSV', 'ORC', 'Parquet').default('CSV')

        # How frequently inventory reports are generated
        attribute :frequency, Resources::Types::String.enum('Daily', 'Weekly').default('Weekly')

        # Object versions to include in inventory
        attribute :included_object_versions, Resources::Types::String.enum('All', 'Current').default('All')

        # Optional object prefix filter
        attribute? :prefix, Resources::Types::String.optional

        # Destination bucket configuration for inventory reports
        attribute :destination, Resources::Types::Hash.schema(
          bucket: Resources::Types::String,
          prefix?: Resources::Types::String.optional,
          account_id?: Resources::Types::String.optional,
          format: Resources::Types::String.enum('CSV', 'ORC', 'Parquet').default('CSV'),
          encryption?: Resources::Types::Hash.schema(
            sse_s3?: Resources::Types::Hash.schema(
              enabled: Resources::Types::Bool.default(true)
            ).optional,
            sse_kms?: Resources::Types::Hash.schema(
              key_id: Resources::Types::String
            ).optional
          ).optional
        )

        # Optional fields to include in inventory reports
        attribute :optional_fields, Resources::Types::Array.of(
          Resources::Types::String.enum(
            'Size',
            'LastModifiedDate', 
            'StorageClass',
            'ETag',
            'IsMultipartUploaded',
            'ReplicationStatus',
            'EncryptionStatus',
            'ObjectLockRetainUntilDate',
            'ObjectLockMode',
            'ObjectLockLegalHoldStatus',
            'IntelligentTieringAccessTier',
            'BucketKeyStatus',
            'ChecksumAlgorithm'
          )
        ).default([].freeze)

        # Schedule configuration for inventory generation
        attribute :schedule, Resources::Types::Hash.schema(
          frequency: Resources::Types::String.enum('Daily', 'Weekly').default('Weekly'),
          day_of_week?: Resources::Types::String.enum(
            'Sunday', 'Monday', 'Tuesday', 'Wednesday', 
            'Thursday', 'Friday', 'Saturday'
          ).optional
        ).default({ frequency: 'Weekly' })

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate destination bucket format matches top-level format
          if attrs.destination[:format] && attrs.destination[:format] != attrs.format
            raise Dry::Struct::Error, "Destination format (#{attrs.destination[:format]}) must match inventory format (#{attrs.format})"
          end

          # Validate KMS encryption has key_id
          if attrs.destination[:encryption]&.dig(:sse_kms) && 
             !attrs.destination[:encryption][:sse_kms][:key_id]
            raise Dry::Struct::Error, "KMS encryption requires key_id"
          end

          # Validate schedule consistency
          if attrs.schedule[:frequency] != attrs.frequency
            raise Dry::Struct::Error, "Schedule frequency must match top-level frequency"
          end

          # Validate day_of_week only for Weekly frequency
          if attrs.frequency == 'Daily' && attrs.schedule[:day_of_week]
            raise Dry::Struct::Error, "day_of_week cannot be specified for Daily frequency"
          end

          # Validate bucket ARN format if it looks like an ARN
          if attrs.bucket.start_with?('arn:')
            unless attrs.bucket.match?(/^arn:aws:s3:::[\w\-\.]+$/)
              raise Dry::Struct::Error, "Invalid S3 bucket ARN format"
            end
          end

          # Validate destination bucket ARN format if it looks like an ARN
          dest_bucket = attrs.destination[:bucket]
          if dest_bucket.start_with?('arn:')
            unless dest_bucket.match?(/^arn:aws:s3:::[\w\-\.]+$/)
              raise Dry::Struct::Error, "Invalid destination S3 bucket ARN format"
            end
          end

          # Validate optional fields combinations
          validate_optional_fields(attrs.optional_fields)

          attrs
        end

        private

        def self.validate_optional_fields(fields)
          # Object lock fields require versioning
          object_lock_fields = ['ObjectLockRetainUntilDate', 'ObjectLockMode', 'ObjectLockLegalHoldStatus']
          if (fields & object_lock_fields).any?
            # Note: This validation assumes versioning is enabled, but we can't validate 
            # cross-resource dependencies in types
          end

          # Intelligent Tiering field requires IT configuration
          if fields.include?('IntelligentTieringAccessTier')
            # Note: This would require IT configuration on the bucket
          end
        end

      end
      end
    end
  end
end