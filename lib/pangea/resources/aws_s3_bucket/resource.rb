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
require 'pangea/resources/aws_s3_bucket/builders/configuration_builder'
require 'pangea/resources/aws_s3_bucket/builders/lifecycle_builder'
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
        bucket_attrs = Types::S3BucketAttributes.new(attributes)

        resource(:aws_s3_bucket, name) do
          bucket bucket_attrs.bucket if bucket_attrs.bucket
          acl bucket_attrs.acl

          S3Bucket::ConfigurationBuilder.build_versioning(self, bucket_attrs.versioning)
          S3Bucket::ConfigurationBuilder.build_encryption(self, bucket_attrs.server_side_encryption_configuration)
          S3Bucket::LifecycleBuilder.build_lifecycle_rules(self, bucket_attrs.lifecycle_rule)
          S3Bucket::LifecycleBuilder.build_cors_rules(self, bucket_attrs.cors_rule)
          S3Bucket::ConfigurationBuilder.build_website(self, bucket_attrs.website)
          S3Bucket::ConfigurationBuilder.build_logging(self, bucket_attrs.logging)
          S3Bucket::ConfigurationBuilder.build_object_lock(self, bucket_attrs.object_lock_configuration)
          S3Bucket::ConfigurationBuilder.build_tags(self, bucket_attrs.tags)

          policy bucket_attrs.policy if bucket_attrs.policy
        end

        build_public_access_block(name, bucket_attrs)
        build_resource_reference(name, bucket_attrs)
      end

      private

      def build_public_access_block(name, bucket_attrs)
        config = bucket_attrs.public_access_block_configuration
        return unless config.any?

        resource(:aws_s3_bucket_public_access_block, "#{name}_public_access_block") do
          bucket ref(:aws_s3_bucket, name, :id)
          block_public_acls config[:block_public_acls] if config.key?(:block_public_acls)
          block_public_policy config[:block_public_policy] if config.key?(:block_public_policy)
          ignore_public_acls config[:ignore_public_acls] if config.key?(:ignore_public_acls)
          restrict_public_buckets config[:restrict_public_buckets] if config.key?(:restrict_public_buckets)
        end
      end

      def build_resource_reference(name, bucket_attrs)
        ref = ResourceReference.new(
          type: 'aws_s3_bucket',
          name: name,
          resource_attributes: bucket_attrs.to_h,
          outputs: s3_bucket_outputs(name)
        )

        add_computed_properties(ref, bucket_attrs)
        ref
      end

      def s3_bucket_outputs(name)
        {
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
      end

      def add_computed_properties(ref, bucket_attrs)
        ref.define_singleton_method(:encryption_enabled?) { bucket_attrs.encryption_enabled? }
        ref.define_singleton_method(:kms_encrypted?) { bucket_attrs.kms_encrypted? }
        ref.define_singleton_method(:versioning_enabled?) { bucket_attrs.versioning_enabled? }
        ref.define_singleton_method(:website_enabled?) { bucket_attrs.website_enabled? }
        ref.define_singleton_method(:lifecycle_rules_count) { bucket_attrs.lifecycle_rules_count }
        ref.define_singleton_method(:public_access_blocked?) { bucket_attrs.public_access_blocked? }
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)
