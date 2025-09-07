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
require 'pangea/resources/aws_athena_database/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Athena Database with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Athena Database attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_athena_database(name, attributes = {})
        # Validate attributes using dry-struct
        database_attrs = Types::AthenaDatabaseAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_athena_database, name) do
          # Required attributes
          database_name = database_attrs.name
          bucket database_attrs.bucket
          
          # Optional comment
          comment database_attrs.comment if database_attrs.comment
          
          # Properties
          if database_attrs.properties.any?
            properties do
              database_attrs.properties.each do |key, value|
                public_send(key.tr(".", "_"), value)
              end
            end
          end
          
          # Encryption configuration
          if database_attrs.encryption_configuration
            encryption_configuration do
              encryption_option database_attrs.encryption_configuration[:encryption_option]
              kms_key database_attrs.encryption_configuration[:kms_key] if database_attrs.encryption_configuration[:kms_key]
            end
          end
          
          # Expected bucket owner
          expected_bucket_owner database_attrs.expected_bucket_owner if database_attrs.expected_bucket_owner
          
          # Force destroy
          force_destroy database_attrs.force_destroy
          
          # ACL configuration
          if database_attrs.acl_configuration
            acl_configuration do
              s3_acl_option database_attrs.acl_configuration[:s3_acl_option]
            end
          end
          
          # Apply tags if present
          if database_attrs.tags.any?
            tags do
              database_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_athena_database',
          name: name,
          resource_attributes: database_attrs.to_h,
          outputs: {
            id: "${aws_athena_database.#{name}.id}",
            name: "${aws_athena_database.#{name}.name}"
          },
          computed_properties: {
            encrypted: database_attrs.encrypted?,
            encryption_type: database_attrs.encryption_type,
            uses_kms: database_attrs.uses_kms?,
            location_uri: database_attrs.location_uri,
            estimated_monthly_storage_gb: database_attrs.estimated_monthly_storage_gb
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)