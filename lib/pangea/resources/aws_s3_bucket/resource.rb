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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_s3_bucket/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS S3 Bucket with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] S3 bucket attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_s3_bucket(name, attributes = {})
        # Validate attributes using dry-struct
        bucket_attrs = Types::S3BucketAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_s3_bucket, name) do
          # Set bucket name if provided
          bucket bucket_attrs.bucket if bucket_attrs.bucket
          
          # Set ACL
          acl bucket_attrs.acl
          
          # Configure versioning
          if bucket_attrs.versioning[:enabled] || bucket_attrs.versioning[:mfa_delete]
            versioning do
              enabled bucket_attrs.versioning[:enabled]
              mfa_delete bucket_attrs.versioning[:mfa_delete] if bucket_attrs.versioning[:mfa_delete]
            end
          end
          
          # Configure server-side encryption
          if bucket_attrs.server_side_encryption_configuration[:rule]
            server_side_encryption_configuration do
              rule do
                apply_server_side_encryption_by_default do
                  sse_algorithm bucket_attrs.server_side_encryption_configuration[:rule][:apply_server_side_encryption_by_default][:sse_algorithm]
                  if bucket_attrs.server_side_encryption_configuration[:rule][:apply_server_side_encryption_by_default][:kms_master_key_id]
                    kms_master_key_id bucket_attrs.server_side_encryption_configuration[:rule][:apply_server_side_encryption_by_default][:kms_master_key_id]
                  end
                end
                if bucket_attrs.server_side_encryption_configuration[:rule][:bucket_key_enabled]
                  bucket_key_enabled bucket_attrs.server_side_encryption_configuration[:rule][:bucket_key_enabled]
                end
              end
            end
          end
          
          # Configure lifecycle rules
          bucket_attrs.lifecycle_rule.each do |rule_config|
            lifecycle_rule do
              id rule_config[:id]
              enabled rule_config[:enabled]
              prefix rule_config[:prefix] if rule_config[:prefix]
              
              # Tags for lifecycle rule
              if rule_config[:tags]
                tags do
                  rule_config[:tags].each do |key, value|
                    public_send(key, value)
                  end
                end
              end
              
              # Transitions
              if rule_config[:transition]
                rule_config[:transition].each do |transition_config|
                  transition do
                    days transition_config[:days]
                    storage_class transition_config[:storage_class]
                  end
                end
              end
              
              # Expiration
              if rule_config[:expiration]
                expiration do
                  days rule_config[:expiration][:days] if rule_config[:expiration][:days]
                  expired_object_delete_marker rule_config[:expiration][:expired_object_delete_marker] if rule_config[:expiration].key?(:expired_object_delete_marker)
                end
              end
              
              # Noncurrent version transitions
              if rule_config[:noncurrent_version_transition]
                rule_config[:noncurrent_version_transition].each do |nv_transition|
                  noncurrent_version_transition do
                    days nv_transition[:days]
                    storage_class nv_transition[:storage_class]
                  end
                end
              end
              
              # Noncurrent version expiration
              if rule_config[:noncurrent_version_expiration]
                noncurrent_version_expiration do
                  days rule_config[:noncurrent_version_expiration][:days]
                end
              end
            end
          end
          
          # Configure CORS rules
          bucket_attrs.cors_rule.each do |cors_config|
            cors_rule do
              allowed_headers cors_config[:allowed_headers] if cors_config[:allowed_headers]
              allowed_methods cors_config[:allowed_methods]
              allowed_origins cors_config[:allowed_origins]
              expose_headers cors_config[:expose_headers] if cors_config[:expose_headers]
              max_age_seconds cors_config[:max_age_seconds] if cors_config[:max_age_seconds]
            end
          end
          
          # Configure website
          if bucket_attrs.website.any?
            website do
              if bucket_attrs.website[:redirect_all_requests_to]
                redirect_all_requests_to do
                  host_name bucket_attrs.website[:redirect_all_requests_to][:host_name]
                  protocol bucket_attrs.website[:redirect_all_requests_to][:protocol] if bucket_attrs.website[:redirect_all_requests_to][:protocol]
                end
              else
                index_document bucket_attrs.website[:index_document] if bucket_attrs.website[:index_document]
                error_document bucket_attrs.website[:error_document] if bucket_attrs.website[:error_document]
                routing_rules bucket_attrs.website[:routing_rules] if bucket_attrs.website[:routing_rules]
              end
            end
          end
          
          # Configure logging
          if bucket_attrs.logging[:target_bucket]
            logging do
              target_bucket bucket_attrs.logging[:target_bucket]
              target_prefix bucket_attrs.logging[:target_prefix] if bucket_attrs.logging[:target_prefix]
            end
          end
          
          # Configure object lock
          if bucket_attrs.object_lock_configuration[:object_lock_enabled]
            object_lock_configuration do
              object_lock_enabled bucket_attrs.object_lock_configuration[:object_lock_enabled]
              if bucket_attrs.object_lock_configuration[:rule]
                rule do
                  default_retention do
                    mode bucket_attrs.object_lock_configuration[:rule][:default_retention][:mode]
                    days bucket_attrs.object_lock_configuration[:rule][:default_retention][:days] if bucket_attrs.object_lock_configuration[:rule][:default_retention][:days]
                    years bucket_attrs.object_lock_configuration[:rule][:default_retention][:years] if bucket_attrs.object_lock_configuration[:rule][:default_retention][:years]
                  end
                end
              end
            end
          end
          
          # Apply tags
          if bucket_attrs.tags.any?
            tags do
              bucket_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
          
          # Apply bucket policy if provided
          policy bucket_attrs.policy if bucket_attrs.policy
        end
        
        # Create public access block if configured
        if bucket_attrs.public_access_block_configuration.any?
          resource(:aws_s3_bucket_public_access_block, "#{name}_public_access_block") do
            bucket ref(:aws_s3_bucket, name, :id)
            block_public_acls bucket_attrs.public_access_block_configuration[:block_public_acls] if bucket_attrs.public_access_block_configuration.key?(:block_public_acls)
            block_public_policy bucket_attrs.public_access_block_configuration[:block_public_policy] if bucket_attrs.public_access_block_configuration.key?(:block_public_policy)
            ignore_public_acls bucket_attrs.public_access_block_configuration[:ignore_public_acls] if bucket_attrs.public_access_block_configuration.key?(:ignore_public_acls)
            restrict_public_buckets bucket_attrs.public_access_block_configuration[:restrict_public_buckets] if bucket_attrs.public_access_block_configuration.key?(:restrict_public_buckets)
          end
        end
        
        # Return resource reference with available outputs
        ref = ResourceReference.new(
          type: 'aws_s3_bucket',
          name: name,
          resource_attributes: bucket_attrs.to_h,
          outputs: {
            id: "${aws_s3_bucket.#{name}.id}",
            arn: "${aws_s3_bucket.#{name}.arn}",
            bucket: "${aws_s3_bucket.#{name}.bucket}",
            bucket_domain_name: "${aws_s3_bucket.#{name}.bucket_domain_name}",
            bucket_regional_domain_name: "${aws_s3_bucket.#{name}.bucket_regional_domain_name}",
            hosted_zone_id: "${aws_s3_bucket.#{name}.hosted_zone_id}",
            region: "${aws_s3_bucket.#{name}.region}",
            website_endpoint: "${aws_s3_bucket.#{name}.website_endpoint}",
            website_domain: "${aws_s3_bucket.#{name}.website_domain}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:encryption_enabled?) { bucket_attrs.encryption_enabled? }
        ref.define_singleton_method(:kms_encrypted?) { bucket_attrs.kms_encrypted? }
        ref.define_singleton_method(:versioning_enabled?) { bucket_attrs.versioning_enabled? }
        ref.define_singleton_method(:website_enabled?) { bucket_attrs.website_enabled? }
        ref.define_singleton_method(:lifecycle_rules_count) { bucket_attrs.lifecycle_rules_count }
        ref.define_singleton_method(:public_access_blocked?) { bucket_attrs.public_access_blocked? }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)