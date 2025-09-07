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
require 'pangea/resources/aws_dynamodb_table/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS DynamoDB Table with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] DynamoDB table attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_dynamodb_table(name, attributes = {})
        # Validate attributes using dry-struct
        table_attrs = AWS::Types::Types::DynamoDbTableAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_dynamodb_table, name) do
          table_name table_attrs.name
          billing_mode table_attrs.billing_mode

          # Attribute definitions
          table_attrs.attribute.each do |attr_def|
            attribute do
              name attr_def[:name]
              type attr_def[:type]
            end
          end

          # Hash and range keys
          hash_key table_attrs.hash_key
          range_key table_attrs.range_key if table_attrs.range_key

          # Provisioned throughput (only for PROVISIONED billing mode)
          if table_attrs.is_provisioned?
            read_capacity table_attrs.read_capacity
            write_capacity table_attrs.write_capacity
          end

          # Global Secondary Indexes
          table_attrs.global_secondary_index.each do |gsi|
            global_secondary_index do
              name gsi[:name]
              hash_key gsi[:hash_key]
              range_key gsi[:range_key] if gsi[:range_key]
              
              if table_attrs.is_provisioned?
                read_capacity gsi[:read_capacity]
                write_capacity gsi[:write_capacity]
              end
              
              projection_type gsi[:projection_type]
              non_key_attributes gsi[:non_key_attributes] if gsi[:non_key_attributes]
            end
          end

          # Local Secondary Indexes
          table_attrs.local_secondary_index.each do |lsi|
            local_secondary_index do
              name lsi[:name]
              range_key lsi[:range_key]
              projection_type lsi[:projection_type]
              non_key_attributes lsi[:non_key_attributes] if lsi[:non_key_attributes]
            end
          end

          # TTL configuration
          if table_attrs.ttl
            ttl do
              attribute_name table_attrs.ttl[:attribute_name]
              enabled table_attrs.ttl[:enabled]
            end
          end

          # Stream configuration
          if table_attrs.stream_enabled
            stream_enabled table_attrs.stream_enabled
            stream_view_type table_attrs.stream_view_type
          end

          # Point-in-time recovery
          point_in_time_recovery do
            enabled table_attrs.point_in_time_recovery_enabled
          end

          # Server-side encryption
          if table_attrs.server_side_encryption
            server_side_encryption do
              enabled table_attrs.server_side_encryption[:enabled]
              kms_key_id table_attrs.server_side_encryption[:kms_key_id] if table_attrs.server_side_encryption[:kms_key_id]
            end
          end

          # Deletion protection
          deletion_protection_enabled table_attrs.deletion_protection_enabled

          # Table class
          table_class table_attrs.table_class

          # Restore configuration
          if table_attrs.restore_source_name
            restore_source_name table_attrs.restore_source_name
          elsif table_attrs.restore_source_table_arn
            restore_source_table_arn table_attrs.restore_source_table_arn
            restore_to_time table_attrs.restore_to_time if table_attrs.restore_to_time
            restore_date_time table_attrs.restore_date_time if table_attrs.restore_date_time
          end

          # Import configuration
          if table_attrs.import_table
            import_table do
              input_format table_attrs.import_table[:input_format]
              
              s3_bucket_source do
                bucket table_attrs.import_table[:s3_bucket_source][:bucket]
                bucket_owner table_attrs.import_table[:s3_bucket_source][:bucket_owner] if table_attrs.import_table[:s3_bucket_source][:bucket_owner]
                key_prefix table_attrs.import_table[:s3_bucket_source][:key_prefix] if table_attrs.import_table[:s3_bucket_source][:key_prefix]
              end
              
              if table_attrs.import_table[:input_format_options]
                input_format_options do
                  if table_attrs.import_table[:input_format_options][:csv]
                    csv do
                      delimiter table_attrs.import_table[:input_format_options][:csv][:delimiter] if table_attrs.import_table[:input_format_options][:csv][:delimiter]
                      header_list table_attrs.import_table[:input_format_options][:csv][:header_list] if table_attrs.import_table[:input_format_options][:csv][:header_list]
                    end
                  end
                end
              end
              
              input_compression_type table_attrs.import_table[:input_compression_type] if table_attrs.import_table[:input_compression_type]
            end
          end

          # Replica configuration (Global Tables)
          table_attrs.replica.each do |replica_config|
            replica do
              region_name replica_config[:region_name]
              kms_key_id replica_config[:kms_key_id] if replica_config[:kms_key_id]
              point_in_time_recovery replica_config[:point_in_time_recovery] if replica_config[:point_in_time_recovery]
              table_class replica_config[:table_class] if replica_config[:table_class]
              
              if replica_config[:global_secondary_index]
                replica_config[:global_secondary_index].each do |replica_gsi|
                  global_secondary_index do
                    name replica_gsi[:name]
                    read_capacity replica_gsi[:read_capacity] if replica_gsi[:read_capacity]
                    write_capacity replica_gsi[:write_capacity] if replica_gsi[:write_capacity]
                  end
                end
              end
            end
          end

          # Apply tags if present
          if table_attrs.tags.any?
            tags do
              table_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ref = ResourceReference.new(
          type: 'aws_dynamodb_table',
          name: name,
          resource_attributes: table_attrs.to_h,
          outputs: {
            id: "${aws_dynamodb_table.#{name}.id}",
            arn: "${aws_dynamodb_table.#{name}.arn}",
            name: "${aws_dynamodb_table.#{name}.name}",
            billing_mode: "${aws_dynamodb_table.#{name}.billing_mode}",
            hash_key: "${aws_dynamodb_table.#{name}.hash_key}",
            range_key: "${aws_dynamodb_table.#{name}.range_key}",
            read_capacity: "${aws_dynamodb_table.#{name}.read_capacity}",
            write_capacity: "${aws_dynamodb_table.#{name}.write_capacity}",
            stream_arn: "${aws_dynamodb_table.#{name}.stream_arn}",
            stream_label: "${aws_dynamodb_table.#{name}.stream_label}",
            table_class: "${aws_dynamodb_table.#{name}.table_class}",
            tags_all: "${aws_dynamodb_table.#{name}.tags_all}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:is_pay_per_request?) { table_attrs.is_pay_per_request? }
        ref.define_singleton_method(:is_provisioned?) { table_attrs.is_provisioned? }
        ref.define_singleton_method(:has_range_key?) { table_attrs.has_range_key? }
        ref.define_singleton_method(:has_gsi?) { table_attrs.has_gsi? }
        ref.define_singleton_method(:has_lsi?) { table_attrs.has_lsi? }
        ref.define_singleton_method(:has_stream?) { table_attrs.has_stream? }
        ref.define_singleton_method(:has_ttl?) { table_attrs.has_ttl? }
        ref.define_singleton_method(:has_encryption?) { table_attrs.has_encryption? }
        ref.define_singleton_method(:has_pitr?) { table_attrs.has_pitr? }
        ref.define_singleton_method(:is_global_table?) { table_attrs.is_global_table? }
        ref.define_singleton_method(:total_indexes) { table_attrs.total_indexes }
        ref.define_singleton_method(:estimated_monthly_cost) { table_attrs.estimated_monthly_cost }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)