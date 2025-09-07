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
require 'pangea/resources/aws_dynamodb_global_table/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS DynamoDB Global Table with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] DynamoDB global table attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_dynamodb_global_table(name, attributes = {})
        # Validate attributes using dry-struct
        global_table_attrs = Types::DynamoDbGlobalTableAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_dynamodb_global_table, name) do
          global_table_name global_table_attrs.name
          billing_mode global_table_attrs.billing_mode

          # Replica configurations
          global_table_attrs.replica.each do |replica_config|
            replica do
              region_name replica_config[:region_name]
              kms_key_id replica_config[:kms_key_id] if replica_config[:kms_key_id]
              point_in_time_recovery replica_config[:point_in_time_recovery] if replica_config[:point_in_time_recovery]
              table_class replica_config[:table_class] if replica_config[:table_class]
              
              # Global Secondary Index configurations per replica
              if replica_config[:global_secondary_index]
                replica_config[:global_secondary_index].each do |gsi|
                  global_secondary_index do
                    name gsi[:name]
                    read_capacity gsi[:read_capacity] if gsi[:read_capacity]
                    write_capacity gsi[:write_capacity] if gsi[:write_capacity]
                  end
                end
              end

              # Replica-specific tags
              if replica_config[:tags] && replica_config[:tags].any?
                tags do
                  replica_config[:tags].each do |key, value|
                    public_send(key, value)
                  end
                end
              end
            end
          end

          # Stream configuration
          if global_table_attrs.stream_enabled
            stream_enabled global_table_attrs.stream_enabled
            stream_view_type global_table_attrs.stream_view_type
          end

          # Server-side encryption
          if global_table_attrs.server_side_encryption
            server_side_encryption do
              enabled global_table_attrs.server_side_encryption[:enabled]
              kms_key_id global_table_attrs.server_side_encryption[:kms_key_id] if global_table_attrs.server_side_encryption[:kms_key_id]
            end
          end

          # Point-in-time recovery
          if global_table_attrs.point_in_time_recovery
            point_in_time_recovery do
              enabled global_table_attrs.point_in_time_recovery[:enabled]
            end
          end

          # Apply global tags if present
          if global_table_attrs.tags.any?
            tags do
              global_table_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_dynamodb_global_table',
          name: name,
          resource_attributes: global_table_attrs.to_h,
          outputs: {
            id: "${aws_dynamodb_global_table.#{name}.id}",
            arn: "${aws_dynamodb_global_table.#{name}.arn}",
            global_table_name: "${aws_dynamodb_global_table.#{name}.global_table_name}",
            billing_mode: "${aws_dynamodb_global_table.#{name}.billing_mode}",
            stream_arn: "${aws_dynamodb_global_table.#{name}.stream_arn}",
            stream_label: "${aws_dynamodb_global_table.#{name}.stream_label}",
            tags_all: "${aws_dynamodb_global_table.#{name}.tags_all}"
          },
          computed_properties: {
            is_pay_per_request: global_table_attrs.is_pay_per_request?,
            is_provisioned: global_table_attrs.is_provisioned?,
            has_stream: global_table_attrs.has_stream?,
            has_encryption: global_table_attrs.has_encryption?,
            has_pitr: global_table_attrs.has_pitr?,
            region_count: global_table_attrs.region_count,
            regions: global_table_attrs.regions,
            has_gsi: global_table_attrs.has_gsi?,
            total_gsi_count: global_table_attrs.total_gsi_count,
            estimated_monthly_cost: global_table_attrs.estimated_monthly_cost,
            multi_region_strategy: global_table_attrs.multi_region_strategy
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)