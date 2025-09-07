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
require 'pangea/resources/aws_s3_access_point_policy/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS S3 Access Point Policy with type-safe attributes
      #
      # Provides resource-based permissions for S3 access points to control access from
      # applications and users. Access point policies work with bucket policies and IAM 
      # user policies to control access to the underlying S3 bucket.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] S3 access point policy attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_s3_access_point_policy(name, attributes = {})
        # Validate attributes using dry-struct
        policy_attrs = S3AccessPointPolicy::Types::S3AccessPointPolicyAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_s3_access_point_policy, name) do
          # Required attributes
          access_point_arn policy_attrs.access_point_arn
          policy policy_attrs.policy
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_s3_access_point_policy',
          name: name,
          resource_attributes: policy_attrs.to_h,
          outputs: {
            id: "${aws_s3_access_point_policy.#{name}.id}",
            access_point_arn: "${aws_s3_access_point_policy.#{name}.access_point_arn}",
            has_public_access_policy: "${aws_s3_access_point_policy.#{name}.has_public_access_policy}"
          },
          computed: {
            has_valid_json: policy_attrs.has_valid_json?,
            access_point_name: policy_attrs.access_point_name,
            account_id: policy_attrs.account_id,
            region: policy_attrs.region,
            policy_document: policy_attrs.policy_document
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)