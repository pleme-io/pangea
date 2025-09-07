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
require 'pangea/resources/aws_s3_bucket_encryption/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS S3 Bucket Encryption configuration with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] S3 bucket encryption attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_s3_bucket_encryption(name, attributes = {})
        # Validate attributes using dry-struct
        encryption_attrs = Types::S3BucketEncryptionAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_s3_bucket_server_side_encryption_configuration, name) do
          # Set bucket name
          bucket encryption_attrs.bucket
          
          # Set expected bucket owner if provided
          expected_bucket_owner encryption_attrs.expected_bucket_owner if encryption_attrs.expected_bucket_owner
          
          # Configure encryption rules
          encryption_attrs.server_side_encryption_configuration[:rule].each do |rule_config|
            rule do
              apply_server_side_encryption_by_default do
                sse_algorithm rule_config[:apply_server_side_encryption_by_default][:sse_algorithm]
                kms_master_key_id rule_config[:apply_server_side_encryption_by_default][:kms_master_key_id] if rule_config[:apply_server_side_encryption_by_default][:kms_master_key_id]
              end
              bucket_key_enabled rule_config[:bucket_key_enabled] if rule_config.key?(:bucket_key_enabled)
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_s3_bucket_server_side_encryption_configuration',
          name: name,
          resource_attributes: encryption_attrs.to_h,
          outputs: {
            id: "${aws_s3_bucket_server_side_encryption_configuration.#{name}.id}",
            bucket: "${aws_s3_bucket_server_side_encryption_configuration.#{name}.bucket}"
          },
          computed: {
            encryption_rules_count: encryption_attrs.encryption_rules_count,
            primary_encryption_algorithm: encryption_attrs.primary_encryption_algorithm,
            uses_kms_encryption: encryption_attrs.uses_kms_encryption?,
            uses_aes256_encryption: encryption_attrs.uses_aes256_encryption?,
            bucket_key_enabled: encryption_attrs.bucket_key_enabled?,
            kms_key_ids: encryption_attrs.kms_key_ids
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)