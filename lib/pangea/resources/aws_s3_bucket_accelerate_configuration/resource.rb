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
require 'pangea/resources/aws_s3_bucket_accelerate_configuration/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS S3 Bucket Accelerate Configuration with type-safe attributes
      #
      # S3 Transfer Acceleration enables fast, easy, and secure transfers of files
      # over long distances between your client and an S3 bucket. Transfer
      # Acceleration takes advantage of Amazon CloudFront's globally distributed edge locations.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] S3 bucket accelerate configuration attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_s3_bucket_accelerate_configuration(name, attributes = {})
        # Validate attributes using dry-struct
        accel_attrs = S3BucketAccelerateConfiguration::Types::S3BucketAccelerateConfigurationAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_s3_bucket_accelerate_configuration, name) do
          # Required attributes
          bucket accel_attrs.bucket
          status accel_attrs.status
          
          # Optional attributes
          expected_bucket_owner accel_attrs.expected_bucket_owner if accel_attrs.expected_bucket_owner
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_s3_bucket_accelerate_configuration',
          name: name,
          resource_attributes: accel_attrs.to_h,
          outputs: {
            id: "${aws_s3_bucket_accelerate_configuration.#{name}.id}",
            bucket: "${aws_s3_bucket_accelerate_configuration.#{name}.bucket}",
            status: "${aws_s3_bucket_accelerate_configuration.#{name}.status}"
          },
          computed: {
            acceleration_enabled: accel_attrs.acceleration_enabled?,
            acceleration_suspended: accel_attrs.acceleration_suspended?,
            cross_account_bucket: accel_attrs.cross_account_bucket?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)