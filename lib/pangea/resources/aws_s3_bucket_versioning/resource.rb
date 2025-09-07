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
require 'pangea/resources/aws_s3_bucket_versioning/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS S3 Bucket Versioning configuration with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] S3 bucket versioning attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_s3_bucket_versioning(name, attributes = {})
        # Validate attributes using dry-struct
        versioning_attrs = Types::S3BucketVersioningAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_s3_bucket_versioning, name) do
          # Set bucket name
          bucket versioning_attrs.bucket
          
          # Set expected bucket owner if provided
          expected_bucket_owner versioning_attrs.expected_bucket_owner if versioning_attrs.expected_bucket_owner
          
          # Configure versioning
          versioning_configuration do
            status versioning_attrs.versioning_configuration[:status]
            mfa_delete versioning_attrs.versioning_configuration[:mfa_delete] if versioning_attrs.versioning_configuration[:mfa_delete]
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_s3_bucket_versioning',
          name: name,
          resource_attributes: versioning_attrs.to_h,
          outputs: {
            id: "${aws_s3_bucket_versioning.#{name}.id}",
            bucket: "${aws_s3_bucket_versioning.#{name}.bucket}"
          },
          computed: {
            versioning_enabled: versioning_attrs.versioning_enabled?,
            versioning_suspended: versioning_attrs.versioning_suspended?,
            mfa_delete_enabled: versioning_attrs.mfa_delete_enabled?,
            mfa_delete_configured: versioning_attrs.mfa_delete_configured?,
            status: versioning_attrs.status
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)