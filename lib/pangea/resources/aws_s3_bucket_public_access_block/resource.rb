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
require 'pangea/resources/aws_s3_bucket_public_access_block/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS S3 Bucket Public Access Block configuration with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] S3 bucket public access block attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_s3_bucket_public_access_block(name, attributes = {})
        # Validate attributes using dry-struct
        pab_attrs = Types::S3BucketPublicAccessBlockAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_s3_bucket_public_access_block, name) do
          # Set bucket name
          bucket pab_attrs.bucket
          
          # Set expected bucket owner if provided
          expected_bucket_owner pab_attrs.expected_bucket_owner if pab_attrs.expected_bucket_owner
          
          # Configure public access block settings
          block_public_acls pab_attrs.block_public_acls if pab_attrs.block_public_acls
          block_public_policy pab_attrs.block_public_policy if pab_attrs.block_public_policy
          ignore_public_acls pab_attrs.ignore_public_acls if pab_attrs.ignore_public_acls
          restrict_public_buckets pab_attrs.restrict_public_buckets if pab_attrs.restrict_public_buckets
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_s3_bucket_public_access_block',
          name: name,
          resource_attributes: pab_attrs.to_h,
          outputs: {
            id: "${aws_s3_bucket_public_access_block.#{name}.id}",
            bucket: "${aws_s3_bucket_public_access_block.#{name}.bucket}",
            block_public_acls: "${aws_s3_bucket_public_access_block.#{name}.block_public_acls}",
            block_public_policy: "${aws_s3_bucket_public_access_block.#{name}.block_public_policy}",
            ignore_public_acls: "${aws_s3_bucket_public_access_block.#{name}.ignore_public_acls}",
            restrict_public_buckets: "${aws_s3_bucket_public_access_block.#{name}.restrict_public_buckets}"
          },
          computed: {
            fully_blocked: pab_attrs.fully_blocked?,
            partially_blocked: pab_attrs.partially_blocked?,
            allows_public_access: pab_attrs.allows_public_access?,
            blocked_settings_count: pab_attrs.blocked_settings_count,
            security_level: pab_attrs.security_level,
            configuration_summary: pab_attrs.configuration_summary
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)