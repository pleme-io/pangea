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
require 'pangea/resources/aws_s3_multi_region_access_point/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS S3 Multi-Region Access Point with type-safe attributes
      #
      # Multi-Region Access Points provide a global endpoint that applications use to
      # fulfill requests from S3 buckets located in multiple AWS Regions. You can use
      # Multi-Region Access Points to build multi-region applications with the same
      # simple architecture used in a single region.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] S3 multi-region access point attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_s3_multi_region_access_point(name, attributes = {})
        # Validate attributes using dry-struct
        mrap_attrs = S3MultiRegionAccessPoint::Types::S3MultiRegionAccessPointAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_s3_multi_region_access_point, name) do
          # Required attributes - details block
          details do
            # Access point name
            name mrap_attrs.details[:name]
            
            # Public access block configuration
            if mrap_attrs.details[:public_access_block_configuration].any?
              public_access_block_configuration do
                if mrap_attrs.details[:public_access_block_configuration].key?(:block_public_acls)
                  block_public_acls mrap_attrs.details[:public_access_block_configuration][:block_public_acls]
                end
                if mrap_attrs.details[:public_access_block_configuration].key?(:block_public_policy)
                  block_public_policy mrap_attrs.details[:public_access_block_configuration][:block_public_policy]
                end
                if mrap_attrs.details[:public_access_block_configuration].key?(:ignore_public_acls)
                  ignore_public_acls mrap_attrs.details[:public_access_block_configuration][:ignore_public_acls]
                end
                if mrap_attrs.details[:public_access_block_configuration].key?(:restrict_public_buckets)
                  restrict_public_buckets mrap_attrs.details[:public_access_block_configuration][:restrict_public_buckets]
                end
              end
            end
            
            # Region configurations
            mrap_attrs.details[:region].each do |region_config|
              region do
                bucket region_config[:bucket]
                bucket_account_id region_config[:bucket_account_id] if region_config[:bucket_account_id]
              end
            end
          end
          
          # Optional account ID
          account_id mrap_attrs.account_id if mrap_attrs.account_id
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_s3_multi_region_access_point',
          name: name,
          resource_attributes: mrap_attrs.to_h,
          outputs: {
            id: "${aws_s3_multi_region_access_point.#{name}.id}",
            arn: "${aws_s3_multi_region_access_point.#{name}.arn}",
            alias: "${aws_s3_multi_region_access_point.#{name}.alias}",
            domain_name: "${aws_s3_multi_region_access_point.#{name}.domain_name}",
            status: "${aws_s3_multi_region_access_point.#{name}.status}",
            endpoints: "${aws_s3_multi_region_access_point.#{name}.endpoints}"
          },
          computed: {
            access_point_name: mrap_attrs.access_point_name,
            region_count: mrap_attrs.region_count,
            has_public_access_block: mrap_attrs.has_public_access_block?,
            cross_account_buckets: mrap_attrs.cross_account_buckets?,
            bucket_names: mrap_attrs.bucket_names,
            region_names: mrap_attrs.region_names
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)