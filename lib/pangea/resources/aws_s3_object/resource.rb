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
require 'pangea/resources/aws_s3_object/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS S3 Object with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] S3 object attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_s3_object(name, attributes = {})
        # Validate attributes using dry-struct
        object_attrs = Types::S3ObjectAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_s3_object, name) do
          # Set bucket and key
          bucket object_attrs.bucket
          key object_attrs.key
          
          # Set content source
          source object_attrs.source if object_attrs.source
          content object_attrs.content if object_attrs.content
          
          # Set content properties
          content_type object_attrs.inferred_content_type if object_attrs.inferred_content_type
          content_encoding object_attrs.content_encoding if object_attrs.content_encoding
          content_language object_attrs.content_language if object_attrs.content_language
          content_disposition object_attrs.content_disposition if object_attrs.content_disposition
          cache_control object_attrs.cache_control if object_attrs.cache_control
          expires object_attrs.expires if object_attrs.expires
          
          # Set storage class
          storage_class object_attrs.storage_class if object_attrs.storage_class
          
          # Set ACL
          acl object_attrs.acl if object_attrs.acl
          
          # Set encryption
          server_side_encryption object_attrs.server_side_encryption if object_attrs.server_side_encryption
          kms_key_id object_attrs.kms_key_id if object_attrs.kms_key_id
          
          # Set website redirect
          website_redirect object_attrs.website_redirect if object_attrs.website_redirect
          
          # Set object lock configuration
          object_lock_mode object_attrs.object_lock_mode if object_attrs.object_lock_mode
          object_lock_retain_until_date object_attrs.object_lock_retain_until_date if object_attrs.object_lock_retain_until_date
          object_lock_legal_hold_status object_attrs.object_lock_legal_hold_status if object_attrs.object_lock_legal_hold_status
          
          # Set expected bucket owner
          expected_bucket_owner object_attrs.expected_bucket_owner if object_attrs.expected_bucket_owner
          
          # Set metadata
          if object_attrs.metadata.any?
            metadata do
              object_attrs.metadata.each do |key, value|
                public_send(key, value)
              end
            end
          end
          
          # Set tags
          if object_attrs.tags.any?
            tags do
              object_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_s3_object',
          name: name,
          resource_attributes: object_attrs.to_h,
          outputs: {
            id: "${aws_s3_object.#{name}.id}",
            bucket: "${aws_s3_object.#{name}.bucket}",
            key: "${aws_s3_object.#{name}.key}",
            etag: "${aws_s3_object.#{name}.etag}",
            version_id: "${aws_s3_object.#{name}.version_id}",
            source: "${aws_s3_object.#{name}.source}",
            content_type: "${aws_s3_object.#{name}.content_type}",
            storage_class: "${aws_s3_object.#{name}.storage_class}",
            server_side_encryption: "${aws_s3_object.#{name}.server_side_encryption}",
            kms_key_id: "${aws_s3_object.#{name}.kms_key_id}"
          },
          computed: {
            has_source_file: object_attrs.has_source_file?,
            has_inline_content: object_attrs.has_inline_content?,
            encrypted: object_attrs.encrypted?,
            kms_encrypted: object_attrs.kms_encrypted?,
            has_metadata: object_attrs.has_metadata?,
            has_tags: object_attrs.has_tags?,
            object_lock_enabled: object_attrs.object_lock_enabled?,
            legal_hold_enabled: object_attrs.legal_hold_enabled?,
            is_website_redirect: object_attrs.is_website_redirect?,
            source_file_extension: object_attrs.source_file_extension,
            inferred_content_type: object_attrs.inferred_content_type,
            estimated_size: object_attrs.estimated_size,
            content_source_type: object_attrs.content_source_type
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)