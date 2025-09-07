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
require 'pangea/resources/aws_dynamodb_table_export/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS DynamoDB Table Export with type-safe attributes
      #
      # DynamoDB table export allows you to export DynamoDB table data to Amazon S3
      # for analytics, backup, or archival purposes. You can export data in DynamoDB JSON
      # or Amazon Ion format, and optionally encrypt the export using AWS KMS.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] DynamoDB table export attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_dynamodb_table_export(name, attributes = {})
        # Validate attributes using dry-struct
        export_attrs = DynamoDBTableExport::Types::DynamoDBTableExportAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_dynamodb_table_export, name) do
          # Required attributes
          s3_bucket export_attrs.s3_bucket
          table_arn export_attrs.table_arn
          
          # Optional attributes
          export_format export_attrs.export_format if export_attrs.export_format
          export_type export_attrs.export_type if export_attrs.export_type
          export_time export_attrs.export_time.iso8601 if export_attrs.export_time
          s3_bucket_owner export_attrs.s3_bucket_owner if export_attrs.s3_bucket_owner
          s3_prefix export_attrs.s3_prefix if export_attrs.s3_prefix
          s3_sse_algorithm export_attrs.s3_sse_algorithm if export_attrs.s3_sse_algorithm
          s3_sse_kms_key_id export_attrs.s3_sse_kms_key_id if export_attrs.s3_sse_kms_key_id
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_dynamodb_table_export',
          name: name,
          resource_attributes: export_attrs.to_h,
          outputs: {
            id: "${aws_dynamodb_table_export.#{name}.id}",
            arn: "${aws_dynamodb_table_export.#{name}.arn}",
            export_status: "${aws_dynamodb_table_export.#{name}.export_status}",
            start_time: "${aws_dynamodb_table_export.#{name}.start_time}",
            end_time: "${aws_dynamodb_table_export.#{name}.end_time}",
            exported_record_count: "${aws_dynamodb_table_export.#{name}.exported_record_count}",
            item_count: "${aws_dynamodb_table_export.#{name}.item_count}",
            manifest_files_s3_key: "${aws_dynamodb_table_export.#{name}.manifest_files_s3_key}"
          },
          computed: {
            table_name: export_attrs.table_name,
            bucket_name: export_attrs.bucket_name,
            uses_kms_encryption: export_attrs.uses_kms_encryption?,
            uses_aes_encryption: export_attrs.uses_aes_encryption?,
            cross_account_bucket: export_attrs.cross_account_bucket?,
            incremental_export: export_attrs.incremental_export?,
            full_export: export_attrs.full_export?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)