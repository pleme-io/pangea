# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS S3 Bucket Inventory Configuration resources
      class S3BucketInventoryAttributes < Dry::Struct
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
        ).default([])

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

        # Helper methods
        def daily_frequency?
          frequency == 'Daily'
        end

        def weekly_frequency?
          frequency == 'Weekly'
        end

        def includes_current_versions_only?
          included_object_versions == 'Current'
        end

        def includes_all_versions?
          included_object_versions == 'All'
        end

        def has_prefix_filter?
          !prefix.nil? && !prefix.empty?
        end

        def csv_format?
          format == 'CSV'
        end

        def orc_format?
          format == 'ORC'
        end

        def parquet_format?
          format == 'Parquet'
        end

        def encrypted_destination?
          destination[:encryption].present?
        end

        def kms_encrypted_destination?
          destination.dig(:encryption, :sse_kms).present?
        end

        def s3_encrypted_destination?
          destination.dig(:encryption, :sse_s3).present?
        end

        def cross_account_destination?
          destination[:account_id].present?
        end

        def has_optional_fields?
          optional_fields.any?
        end

        def includes_size_field?
          optional_fields.include?('Size')
        end

        def includes_encryption_status?
          optional_fields.include?('EncryptionStatus')
        end

        def includes_object_lock_fields?
          object_lock_fields = ['ObjectLockRetainUntilDate', 'ObjectLockMode', 'ObjectLockLegalHoldStatus']
          (optional_fields & object_lock_fields).any?
        end

        def includes_replication_status?
          optional_fields.include?('ReplicationStatus')
        end

        def estimated_report_size_category
          case optional_fields.size
          when 0..2
            'small'
          when 3..6
            'medium' 
          else
            'large'
          end
        end

        def destination_bucket_name
          bucket = destination[:bucket]
          if bucket.start_with?('arn:')
            bucket.split(':').last
          else
            bucket
          end
        end

        def source_bucket_name
          if bucket.start_with?('arn:')
            bucket.split(':').last
          else
            bucket
          end
        end
      end
    end
      end
    end
  end
end