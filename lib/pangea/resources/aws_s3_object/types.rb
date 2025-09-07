# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'
require 'pathname'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS S3 Object resources
      class S3ObjectAttributes < Dry::Struct
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
        attribute :metadata, Resources::Types::Hash.map(Resources::Types::String, Resources::Types::String).default({})

        # Tags (optional)
        attribute :tags, Resources::Types::AwsTags.default({})

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

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate mutually exclusive content sources
          if attrs.source && attrs.content
            raise Dry::Struct::Error, "source and content are mutually exclusive - specify only one"
          end

          # Validate at least one content source is provided
          unless attrs.source || attrs.content
            raise Dry::Struct::Error, "either source or content must be specified"
          end

          # Validate source file exists if provided
          if attrs.source && !File.exist?(attrs.source)
            raise Dry::Struct::Error, "source file '#{attrs.source}' does not exist"
          end

          # Validate KMS encryption configuration
          if attrs.server_side_encryption == 'aws:kms' && attrs.kms_key_id.nil?
            raise Dry::Struct::Error, "kms_key_id is required when using aws:kms encryption"
          end

          # Validate object lock configuration consistency
          if attrs.object_lock_mode && attrs.object_lock_retain_until_date.nil?
            raise Dry::Struct::Error, "object_lock_retain_until_date is required when object_lock_mode is specified"
          end

          if attrs.object_lock_retain_until_date && attrs.object_lock_mode.nil?
            raise Dry::Struct::Error, "object_lock_mode is required when object_lock_retain_until_date is specified"
          end

          attrs
        end

        # Helper methods
        def has_source_file?
          !source.nil?
        end

        def has_inline_content?
          !content.nil?
        end

        def encrypted?
          !server_side_encryption.nil?
        end

        def kms_encrypted?
          server_side_encryption == 'aws:kms'
        end

        def has_metadata?
          metadata.any?
        end

        def has_tags?
          tags.any?
        end

        def object_lock_enabled?
          !object_lock_mode.nil?
        end

        def legal_hold_enabled?
          object_lock_legal_hold_status == 'ON'
        end

        def is_website_redirect?
          !website_redirect.nil?
        end

        def source_file_extension
          return nil unless source
          File.extname(source).downcase
        end

        def inferred_content_type
          return content_type if content_type
          return nil unless source

          # Basic MIME type inference based on file extension
          case source_file_extension
          when '.html', '.htm' then 'text/html'
          when '.css' then 'text/css'
          when '.js' then 'application/javascript'
          when '.json' then 'application/json'
          when '.xml' then 'application/xml'
          when '.pdf' then 'application/pdf'
          when '.jpg', '.jpeg' then 'image/jpeg'
          when '.png' then 'image/png'
          when '.gif' then 'image/gif'
          when '.svg' then 'image/svg+xml'
          when '.txt' then 'text/plain'
          when '.md' then 'text/markdown'
          when '.zip' then 'application/zip'
          else 'application/octet-stream'
          end
        end

        def estimated_size
          return content.bytesize if content
          return File.size(source) if source && File.exist?(source)
          nil
        end

        def content_source_type
          return 'file' if source
          return 'inline' if content
          'unknown'
        end
      end
    end
      end
    end
  end
end