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
require 'pangea/resources/aws_s3_bucket_policy/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS S3 Bucket Policy with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] S3 bucket policy attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_s3_bucket_policy(name, attributes = {})
        # Validate attributes using dry-struct
        policy_attrs = Types::S3BucketPolicyAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_s3_bucket_policy, name) do
          # Set bucket name
          bucket policy_attrs.bucket
          
          # Set policy document
          policy policy_attrs.policy
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_s3_bucket_policy',
          name: name,
          resource_attributes: policy_attrs.to_h,
          outputs: {
            id: "${aws_s3_bucket_policy.#{name}.id}",
            bucket: "${aws_s3_bucket_policy.#{name}.bucket}",
            policy: "${aws_s3_bucket_policy.#{name}.policy}"
          },
          computed: {
            statement_count: policy_attrs.statement_count,
            allows_public_read: policy_attrs.allows_public_read?,
            allows_public_write: policy_attrs.allows_public_write?,
            has_condition_restrictions: policy_attrs.has_condition_restrictions?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)