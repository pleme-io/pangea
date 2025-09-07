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
require 'pangea/resources/aws_s3_access_point/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS S3 Access Point with type-safe attributes
      #
      # Access points simplify managing data access at scale for shared datasets in Amazon S3.
      # Each access point has distinct permissions and network controls that S3 applies for any
      # request made through that access point.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] S3 access point attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_s3_access_point(name, attributes = {})
        # Validate attributes using dry-struct
        access_point_attrs = S3AccessPoint::Types::S3AccessPointAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_s3_access_point, name) do
          # Required attributes
          account_id access_point_attrs.account_id
          bucket access_point_attrs.bucket
          name access_point_attrs.name
          
          # Optional attributes
          bucket_account_id access_point_attrs.bucket_account_id if access_point_attrs.bucket_account_id
          policy access_point_attrs.policy if access_point_attrs.policy
          
          # VPC Configuration for VPC-based access points
          if access_point_attrs.vpc_configuration
            vpc_configuration do
              vpc_id access_point_attrs.vpc_configuration[:vpc_id]
            end
          end
          
          # Public access block configuration
          if access_point_attrs.public_access_block_configuration.any?
            public_access_block_configuration do
              if access_point_attrs.public_access_block_configuration.key?(:block_public_acls)
                block_public_acls access_point_attrs.public_access_block_configuration[:block_public_acls]
              end
              if access_point_attrs.public_access_block_configuration.key?(:block_public_policy)
                block_public_policy access_point_attrs.public_access_block_configuration[:block_public_policy]
              end
              if access_point_attrs.public_access_block_configuration.key?(:ignore_public_acls)
                ignore_public_acls access_point_attrs.public_access_block_configuration[:ignore_public_acls]
              end
              if access_point_attrs.public_access_block_configuration.key?(:restrict_public_buckets)
                restrict_public_buckets access_point_attrs.public_access_block_configuration[:restrict_public_buckets]
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_s3_access_point',
          name: name,
          resource_attributes: access_point_attrs.to_h,
          outputs: {
            id: "${aws_s3_access_point.#{name}.id}",
            arn: "${aws_s3_access_point.#{name}.arn}",
            alias: "${aws_s3_access_point.#{name}.alias}",
            domain_name: "${aws_s3_access_point.#{name}.domain_name}",
            has_public_access_policy: "${aws_s3_access_point.#{name}.has_public_access_policy}",
            network_origin: "${aws_s3_access_point.#{name}.network_origin}",
            endpoints: "${aws_s3_access_point.#{name}.endpoints}"
          },
          computed: {
            vpc_access_point: access_point_attrs.vpc_access_point?,
            internet_access_point: access_point_attrs.internet_access_point?,
            has_public_access_block: access_point_attrs.has_public_access_block?,
            cross_account_access: access_point_attrs.cross_account_access?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)