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
require 'pangea/resources/aws_s3_bucket_inventory/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS S3 Bucket Inventory Configuration with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] S3 bucket inventory attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_s3_bucket_inventory(name, attributes = {})
        # Validate attributes using dry-struct
        inventory_attrs = Types::S3BucketInventoryAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_s3_bucket_inventory, name) do
          # Set the bucket
          bucket inventory_attrs.bucket
          
          # Set inventory configuration name
          name inventory_attrs.name
          
          # Set enabled status
          enabled inventory_attrs.enabled
          
          # Set object versions to include
          included_object_versions inventory_attrs.included_object_versions
          
          # Set prefix filter if provided
          prefix inventory_attrs.prefix if inventory_attrs.prefix
          
          # Configure destination
          destination do
            # Destination bucket
            bucket do
              bucket_arn inventory_attrs.destination[:bucket]
              prefix inventory_attrs.destination[:prefix] if inventory_attrs.destination[:prefix]
              account_id inventory_attrs.destination[:account_id] if inventory_attrs.destination[:account_id]
              format inventory_attrs.destination[:format] || inventory_attrs.format
              
              # Configure encryption if specified
              if inventory_attrs.destination[:encryption]
                encryption do
                  if inventory_attrs.destination[:encryption][:sse_s3]
                    sse_s3 do
                      # SSE-S3 encryption (no additional config needed)
                    end
                  end
                  
                  if inventory_attrs.destination[:encryption][:sse_kms]
                    sse_kms do
                      key_id inventory_attrs.destination[:encryption][:sse_kms][:key_id]
                    end
                  end
                end
              end
            end
          end
          
          # Configure schedule
          schedule do
            frequency inventory_attrs.schedule[:frequency]
            day_of_week inventory_attrs.schedule[:day_of_week] if inventory_attrs.schedule[:day_of_week]
          end
          
          # Add optional fields if specified
          if inventory_attrs.optional_fields.any?
            inventory_attrs.optional_fields.each do |field|
              optional_fields field
            end
          end
          
          # Set format (this might be redundant with destination format, but Terraform allows both)
          format inventory_attrs.format
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_s3_bucket_inventory',
          name: name,
          resource_attributes: inventory_attrs.to_h,
          outputs: {
            id: "${aws_s3_bucket_inventory.#{name}.id}",
            name: "${aws_s3_bucket_inventory.#{name}.name}",
            bucket: "${aws_s3_bucket_inventory.#{name}.bucket}"
          },
          computed: {
            daily_frequency: inventory_attrs.daily_frequency?,
            weekly_frequency: inventory_attrs.weekly_frequency?,
            includes_current_versions_only: inventory_attrs.includes_current_versions_only?,
            includes_all_versions: inventory_attrs.includes_all_versions?,
            has_prefix_filter: inventory_attrs.has_prefix_filter?,
            csv_format: inventory_attrs.csv_format?,
            orc_format: inventory_attrs.orc_format?,
            parquet_format: inventory_attrs.parquet_format?,
            encrypted_destination: inventory_attrs.encrypted_destination?,
            kms_encrypted_destination: inventory_attrs.kms_encrypted_destination?,
            s3_encrypted_destination: inventory_attrs.s3_encrypted_destination?,
            cross_account_destination: inventory_attrs.cross_account_destination?,
            has_optional_fields: inventory_attrs.has_optional_fields?,
            includes_size_field: inventory_attrs.includes_size_field?,
            includes_encryption_status: inventory_attrs.includes_encryption_status?,
            includes_object_lock_fields: inventory_attrs.includes_object_lock_fields?,
            includes_replication_status: inventory_attrs.includes_replication_status?,
            estimated_report_size_category: inventory_attrs.estimated_report_size_category,
            destination_bucket_name: inventory_attrs.destination_bucket_name,
            source_bucket_name: inventory_attrs.source_bucket_name
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)