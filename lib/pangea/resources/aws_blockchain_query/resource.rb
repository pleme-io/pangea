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
require 'pangea/resources/aws_blockchain_query/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Blockchain Query for distributed ledger data analysis
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Blockchain query attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_blockchain_query(name, attributes = {})
        # Validate attributes using dry-struct
        query_attrs = Types::BlockchainQueryAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_blockchain_query, name) do
          # Set query name
          query_name query_attrs.query_name
          
          # Set blockchain network
          blockchain_network query_attrs.blockchain_network
          
          # Set query SQL
          query_string query_attrs.query_string
          
          # Set output configuration
          output_configuration do
            s3_configuration do
              bucket_name query_attrs.output_configuration[:s3_configuration][:bucket_name]
              key_prefix query_attrs.output_configuration[:s3_configuration][:key_prefix]
              
              if query_attrs.output_configuration[:s3_configuration][:encryption_configuration]
                encryption_configuration do
                  encryption_option query_attrs.output_configuration[:s3_configuration][:encryption_configuration][:encryption_option]
                  
                  if query_attrs.output_configuration[:s3_configuration][:encryption_configuration][:kms_key]
                    kms_key query_attrs.output_configuration[:s3_configuration][:encryption_configuration][:kms_key]
                  end
                end
              end
            end
          end
          
          # Set query parameters if provided
          if query_attrs.parameters && !query_attrs.parameters.empty?
            query_attrs.parameters.each do |key, value|
              parameter do
                name key
                value value
              end
            end
          end
          
          # Set schedule if provided
          if query_attrs.schedule_configuration
            schedule_configuration do
              schedule_expression query_attrs.schedule_configuration[:schedule_expression]
              
              if query_attrs.schedule_configuration[:timezone]
                timezone query_attrs.schedule_configuration[:timezone]
              end
            end
          end
          
          # Set tags
          if query_attrs.tags && !query_attrs.tags.empty?
            tags query_attrs.tags
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_blockchain_query',
          name: name,
          resource_attributes: query_attrs.to_h,
          outputs: {
            arn: "${aws_blockchain_query.#{name}.arn}",
            id: "${aws_blockchain_query.#{name}.id}",
            query_name: "${aws_blockchain_query.#{name}.query_name}",
            status: "${aws_blockchain_query.#{name}.status}",
            creation_date: "${aws_blockchain_query.#{name}.creation_date}",
            last_run_date: "${aws_blockchain_query.#{name}.last_run_date}",
            result_s3_location: "${aws_blockchain_query.#{name}.result_s3_location}"
          },
          computed: {
            is_scheduled_query: query_attrs.is_scheduled_query?,
            query_type: query_attrs.query_type,
            blockchain_protocol: query_attrs.blockchain_protocol,
            estimated_cost_per_execution: query_attrs.estimated_cost_per_execution,
            data_encryption_enabled: query_attrs.data_encryption_enabled?,
            has_parameters: query_attrs.has_parameters?,
            schedule_frequency: query_attrs.schedule_frequency,
            query_complexity_score: query_attrs.query_complexity_score,
            estimated_data_size_mb: query_attrs.estimated_data_size_mb
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)