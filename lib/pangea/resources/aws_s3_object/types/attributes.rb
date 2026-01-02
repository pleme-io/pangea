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
        # Type-safe attributes for AWS S3 Object resources
        class S3ObjectAttributes < Dry::Struct
          extend S3ObjectValidation
          include S3ObjectInstanceMethods

          transform_keys(&:to_sym)

          # Bucket name (required)
          attribute :bucket, Resources::Types::String

          # Object key (required)
          attribute :key, Resources::Types::String

          # Source file path (optional, mutually exclusive with content)
          attribute? :source, Resources::Types::String.optional

          # Content to upload (optional, mutually exclusive with source)
          attribute? :content, Resources::Types::String.optional

          # Content type (optional)
          attribute? :content_type, Resources::Types::String.optional

          # Content encoding (optional)
          attribute? :content_encoding, Resources::Types::String.optional

          # Content language (optional)
          attribute? :content_language, Resources::Types::String.optional

          # Content disposition (optional)
          attribute? :content_disposition, Resources::Types::String.optional

          # Cache control (optional)
          attribute? :cache_control, Resources::Types::String.optional

          # Expires header (optional)
          attribute? :expires, Resources::Types::String.optional

          # Storage class (optional)
          attribute? :storage_class, Resources::Types::String.enum(
            'STANDARD', 'REDUCED_REDUNDANCY', 'STANDARD_IA', 'ONEZONE_IA',
            'INTELLIGENT_TIERING', 'GLACIER', 'DEEP_ARCHIVE', 'GLACIER_IR'
          ).optional

          # Object ACL (optional)
          attribute? :acl, Resources::Types::String.enum(
            'private', 'public-read', 'public-read-write', 'authenticated-read',
            'aws-exec-read', 'bucket-owner-read', 'bucket-owner-full-control'
          ).optional

          # Server-side encryption (optional)
          attribute? :server_side_encryption, Resources::Types::String.enum('AES256', 'aws:kms').optional

          # KMS key ID for encryption (optional)
          attribute? :kms_key_id, Resources::Types::String.optional

          # Metadata (optional)
          attribute :metadata, Resources::Types::Hash.map(
            Resources::Types::String,
            Resources::Types::String
          ).default({}.freeze)

          # Tags (optional)
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          # Website redirect location (optional)
          attribute? :website_redirect, Resources::Types::String.optional

          # Object lock mode (optional)
          attribute? :object_lock_mode, Resources::Types::String.enum('GOVERNANCE', 'COMPLIANCE').optional

          # Object lock retain until date (optional)
          attribute? :object_lock_retain_until_date, Resources::Types::String.optional

          # Object lock legal hold status (optional)
          attribute? :object_lock_legal_hold_status, Resources::Types::String.enum('ON', 'OFF').optional

          # Expected bucket owner for multi-account scenarios
          attribute? :expected_bucket_owner, Resources::Types::String.optional

          def self.new(attributes = {})
            attrs = super(attributes)
            validate_content_source(attrs)
            validate_source_file_exists(attrs)
            validate_kms_encryption(attrs)
            validate_object_lock(attrs)
            attrs
          end
        end
      end
    end
  end
end
