# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS S3 Bucket resources
      class S3BucketAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Bucket name (optional - AWS will generate if not provided)
        attribute? :bucket, Resources::Types::String.optional

        # Bucket ACL (private, public-read, public-read-write, authenticated-read, log-delivery-write)
        attribute :acl, Resources::Types::String.default('private').enum('private', 'public-read', 'public-read-write', 'authenticated-read', 'log-delivery-write')

        # Bucket versioning configuration
        attribute :versioning, Resources::Types::Hash.schema(
          enabled: Resources::Types::Bool.default(false),
          mfa_delete?: Resources::Types::Bool.optional
        ).default({ enabled: false })

        # Server-side encryption configuration
        attribute :server_side_encryption_configuration, Resources::Types::Hash.schema(
          rule: Resources::Types::Hash.schema(
            apply_server_side_encryption_by_default: Resources::Types::Hash.schema(
              sse_algorithm: Resources::Types::String.default('AES256').enum('AES256', 'aws:kms'),
              kms_master_key_id?: Resources::Types::String.optional
            ),
            bucket_key_enabled?: Resources::Types::Bool.optional
          )
        ).default({
          rule: {
            apply_server_side_encryption_by_default: {
              sse_algorithm: 'AES256'
            }
          }
        })

        # Lifecycle rules
        attribute :lifecycle_rule, Resources::Types::Array.of(
          Resources::Types::Hash.schema(
            id: Resources::Types::String,
            enabled: Resources::Types::Bool.default(true),
            prefix?: Resources::Types::String.optional,
            tags?: Resources::Types::Hash.optional,
            transition?: Resources::Types::Array.of(
              Resources::Types::Hash.schema(
                days: Resources::Types::Integer,
                storage_class: Resources::Types::String.enum('STANDARD_IA', 'INTELLIGENT_TIERING', 'ONEZONE_IA', 'GLACIER', 'DEEP_ARCHIVE')
              )
            ).optional,
            expiration?: Resources::Types::Hash.schema(
              days?: Resources::Types::Integer.optional,
              expired_object_delete_marker?: Resources::Types::Bool.optional
            ).optional,
            noncurrent_version_transition?: Resources::Types::Array.of(
              Resources::Types::Hash.schema(
                days: Resources::Types::Integer,
                storage_class: Resources::Types::String.enum('STANDARD_IA', 'INTELLIGENT_TIERING', 'ONEZONE_IA', 'GLACIER', 'DEEP_ARCHIVE')
              )
            ).optional,
            noncurrent_version_expiration?: Resources::Types::Hash.schema(
              days: Resources::Types::Integer
            ).optional
          )
        ).default([])

        # CORS configuration
        attribute :cors_rule, Resources::Types::Array.of(
          Resources::Types::Hash.schema(
            allowed_headers?: Resources::Types::Array.of(Resources::Types::String).optional,
            allowed_methods: Resources::Types::Array.of(Resources::Types::String.enum('GET', 'PUT', 'POST', 'DELETE', 'HEAD')),
            allowed_origins: Resources::Types::Array.of(Resources::Types::String),
            expose_headers?: Resources::Types::Array.of(Resources::Types::String).optional,
            max_age_seconds?: Resources::Types::Integer.optional
          )
        ).default([])

        # Website configuration
        attribute :website, Resources::Types::Hash.schema(
          index_document?: Resources::Types::String.optional,
          error_document?: Resources::Types::String.optional,
          redirect_all_requests_to?: Resources::Types::Hash.schema(
            host_name: Resources::Types::String,
            protocol?: Resources::Types::String.enum('http', 'https').optional
          ).optional,
          routing_rules?: Resources::Types::String.optional
        ).default({})

        # Logging configuration
        attribute :logging, Resources::Types::Hash.schema(
          target_bucket?: Resources::Types::String.optional,
          target_prefix?: Resources::Types::String.optional
        ).default({})

        # Object lock configuration
        attribute :object_lock_configuration, Resources::Types::Hash.schema(
          object_lock_enabled?: Resources::Types::String.enum('Enabled').optional,
          rule?: Resources::Types::Hash.schema(
            default_retention: Resources::Types::Hash.schema(
              mode: Resources::Types::String.enum('COMPLIANCE', 'GOVERNANCE'),
              days?: Resources::Types::Integer.optional,
              years?: Resources::Types::Integer.optional
            )
          ).optional
        ).default({})

        # Public access block configuration
        attribute :public_access_block_configuration, Resources::Types::Hash.schema(
          block_public_acls?: Resources::Types::Bool.optional,
          block_public_policy?: Resources::Types::Bool.optional,
          ignore_public_acls?: Resources::Types::Bool.optional,
          restrict_public_buckets?: Resources::Types::Bool.optional
        ).default({})

        # Bucket policy (as JSON string)
        attribute? :policy, Resources::Types::String.optional

        # Tags
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate KMS key is provided when using aws:kms encryption
          sse_config = attrs.server_side_encryption_configuration
          if sse_config[:rule][:apply_server_side_encryption_by_default][:sse_algorithm] == 'aws:kms' &&
             sse_config[:rule][:apply_server_side_encryption_by_default][:kms_master_key_id].nil?
            raise Dry::Struct::Error, "kms_master_key_id is required when using aws:kms encryption"
          end

          # Validate lifecycle rules have at least one action
          attrs.lifecycle_rule.each do |rule|
            unless rule[:transition] || rule[:expiration] || rule[:noncurrent_version_transition] || rule[:noncurrent_version_expiration]
              raise Dry::Struct::Error, "Lifecycle rule '#{rule[:id]}' must have at least one action (transition, expiration, etc.)"
            end
          end

          # Validate object lock requires versioning
          if attrs.object_lock_configuration[:object_lock_enabled] && !attrs.versioning[:enabled]
            raise Dry::Struct::Error, "Object lock requires versioning to be enabled"
          end

          # Validate website configuration
          if attrs.website.any?
            if attrs.website[:redirect_all_requests_to] && (attrs.website[:index_document] || attrs.website[:error_document])
              raise Dry::Struct::Error, "Cannot specify both redirect_all_requests_to and index/error documents"
            end
          end

          attrs
        end

        # Helper methods
        def encryption_enabled?
          !server_side_encryption_configuration.dig(:rule, :apply_server_side_encryption_by_default, :sse_algorithm).nil?
        end

        def kms_encrypted?
          server_side_encryption_configuration.dig(:rule, :apply_server_side_encryption_by_default, :sse_algorithm) == 'aws:kms'
        end

        def versioning_enabled?
          versioning[:enabled]
        end

        def website_enabled?
          !website[:index_document].nil? || !website[:redirect_all_requests_to].nil?
        end

        def lifecycle_rules_count
          lifecycle_rule.size
        end

        def public_access_blocked?
          pac = public_access_block_configuration
          pac[:block_public_acls] == true &&
            pac[:block_public_policy] == true &&
            pac[:ignore_public_acls] == true &&
            pac[:restrict_public_buckets] == true
        end
      end
    end
      end
    end
  end
end