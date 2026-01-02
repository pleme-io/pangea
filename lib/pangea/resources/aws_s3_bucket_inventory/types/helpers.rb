# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        module S3BucketInventory
          # Helper methods for S3BucketInventoryAttributes
          module Helpers
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
