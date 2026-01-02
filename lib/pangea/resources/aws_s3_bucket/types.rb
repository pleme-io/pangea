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
require_relative 'types/lifecycle_rule'
require_relative 'types/server_side_encryption'
require_relative 'types/cors_rule'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS S3 Bucket resources
        class S3BucketAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Bucket name (optional - AWS will generate if not provided)
          attribute? :bucket, Resources::Types::String.optional

          # Bucket ACL
          attribute :acl, Resources::Types::String.default('private').enum(
            'private', 'public-read', 'public-read-write', 'authenticated-read', 'log-delivery-write'
          )

          # Bucket versioning configuration
          attribute :versioning, Resources::Types::Hash.schema(
            enabled: Resources::Types::Bool.default(false),
            mfa_delete?: Resources::Types::Bool.optional
          ).default({ enabled: false })

          # Server-side encryption configuration
          attribute :server_side_encryption_configuration,
                    ServerSideEncryptionConfiguration.default(DEFAULT_SSE_CONFIG)

          # Lifecycle rules
          attribute :lifecycle_rule, Resources::Types::Array.of(LifecycleRule).default([].freeze)

          # CORS configuration
          attribute :cors_rule, Resources::Types::Array.of(CorsRule).default([].freeze)

          # Website configuration
          attribute :website, Resources::Types::Hash.schema(
            index_document?: Resources::Types::String.optional,
            error_document?: Resources::Types::String.optional,
            redirect_all_requests_to?: Resources::Types::Hash.schema(
              host_name: Resources::Types::String,
              protocol?: Resources::Types::String.enum('http', 'https').optional
            ).optional,
            routing_rules?: Resources::Types::String.optional
          ).default({}.freeze)

          # Logging configuration
          attribute :logging, Resources::Types::Hash.schema(
            target_bucket?: Resources::Types::String.optional,
            target_prefix?: Resources::Types::String.optional
          ).default({}.freeze)

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
          ).default({}.freeze)

          # Public access block configuration
          attribute :public_access_block_configuration, Resources::Types::Hash.schema(
            block_public_acls?: Resources::Types::Bool.optional,
            block_public_policy?: Resources::Types::Bool.optional,
            ignore_public_acls?: Resources::Types::Bool.optional,
            restrict_public_buckets?: Resources::Types::Bool.optional
          ).default({}.freeze)

          # Bucket policy (as JSON string)
          attribute? :policy, Resources::Types::String.optional

          # Tags
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)
            validate_kms_encryption(attrs)
            validate_lifecycle_rules(attrs)
            validate_object_lock(attrs)
            validate_website_config(attrs)
            attrs
          end

          def self.validate_kms_encryption(attrs)
            sse_config = attrs.server_side_encryption_configuration
            algorithm = sse_config[:rule][:apply_server_side_encryption_by_default][:sse_algorithm]
            key_id = sse_config[:rule][:apply_server_side_encryption_by_default][:kms_master_key_id]
            return unless algorithm == 'aws:kms' && key_id.nil?

            raise Dry::Struct::Error, 'kms_master_key_id is required when using aws:kms encryption'
          end

          def self.validate_lifecycle_rules(attrs)
            attrs.lifecycle_rule.each do |rule|
              has_action = rule[:transition] || rule[:expiration] ||
                           rule[:noncurrent_version_transition] || rule[:noncurrent_version_expiration]
              next if has_action

              raise Dry::Struct::Error,
                    "Lifecycle rule '#{rule[:id]}' must have at least one action (transition, expiration, etc.)"
            end
          end

          def self.validate_object_lock(attrs)
            return unless attrs.object_lock_configuration[:object_lock_enabled] && !attrs.versioning[:enabled]

            raise Dry::Struct::Error, 'Object lock requires versioning to be enabled'
          end

          def self.validate_website_config(attrs)
            return unless attrs.website.any?
            return unless attrs.website[:redirect_all_requests_to]
            return unless attrs.website[:index_document] || attrs.website[:error_document]

            raise Dry::Struct::Error, 'Cannot specify both redirect_all_requests_to and index/error documents'
          end

          # Helper methods
          def encryption_enabled?
            !server_side_encryption_configuration.dig(:rule, :apply_server_side_encryption_by_default,
                                                       :sse_algorithm).nil?
          end

          def kms_encrypted?
            server_side_encryption_configuration.dig(:rule, :apply_server_side_encryption_by_default,
                                                     :sse_algorithm) == 'aws:kms'
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
            pac[:block_public_acls] == true && pac[:block_public_policy] == true &&
              pac[:ignore_public_acls] == true && pac[:restrict_public_buckets] == true
          end
        end
      end
    end
  end
end
