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
require 'pangea/resources/aws_appsync_datasource/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS AppSync DataSource
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] DataSource attributes
      # @option attributes [String] :api_id The GraphQL API ID
      # @option attributes [String] :name The data source name
      # @option attributes [String] :type The data source type
      # @option attributes [String] :description Description of the data source
      # @option attributes [Hash] :dynamodb_config DynamoDB configuration
      # @option attributes [Hash] :elasticsearch_config Elasticsearch/OpenSearch configuration
      # @option attributes [Hash] :event_bridge_config EventBridge configuration
      # @option attributes [Hash] :http_config HTTP endpoint configuration
      # @option attributes [Hash] :lambda_config Lambda function configuration
      # @option attributes [Hash] :relational_database_config RDS configuration
      # @option attributes [String] :service_role_arn IAM role for data source access
      # @return [ResourceReference] Reference object with outputs
      def aws_appsync_datasource(name, attributes = {})
        # Validate attributes using dry-struct
        datasource_attrs = Types::Types::AppSyncDatasourceAttributes.new(attributes)
        
        # Generate terraform resource block
        resource(:aws_appsync_datasource, name) do
          api_id datasource_attrs.api_id
          name datasource_attrs.name
          type datasource_attrs.type
          
          description datasource_attrs.description if datasource_attrs.description
          
          # DynamoDB configuration
          if datasource_attrs.dynamodb_config
            dynamodb_config do
              table_name datasource_attrs.dynamodb_config[:table_name]
              region datasource_attrs.dynamodb_config[:region] if datasource_attrs.dynamodb_config[:region]
              use_caller_credentials datasource_attrs.dynamodb_config[:use_caller_credentials] if datasource_attrs.dynamodb_config.key?(:use_caller_credentials)
              versioned datasource_attrs.dynamodb_config[:versioned] if datasource_attrs.dynamodb_config.key?(:versioned)
              
              if datasource_attrs.dynamodb_config[:delta_sync_config]
                delta_sync_config do
                  base_table_ttl datasource_attrs.dynamodb_config[:delta_sync_config][:base_table_ttl] if datasource_attrs.dynamodb_config[:delta_sync_config][:base_table_ttl]
                  delta_sync_table_name datasource_attrs.dynamodb_config[:delta_sync_config][:delta_sync_table_name] if datasource_attrs.dynamodb_config[:delta_sync_config][:delta_sync_table_name]
                  delta_sync_table_ttl datasource_attrs.dynamodb_config[:delta_sync_config][:delta_sync_table_ttl] if datasource_attrs.dynamodb_config[:delta_sync_config][:delta_sync_table_ttl]
                end
              end
            end
          end
          
          # Elasticsearch/OpenSearch configuration
          if datasource_attrs.elasticsearch_config
            elasticsearch_config do
              endpoint datasource_attrs.elasticsearch_config[:endpoint]
              region datasource_attrs.elasticsearch_config[:region] if datasource_attrs.elasticsearch_config[:region]
            end
          end
          
          # EventBridge configuration
          if datasource_attrs.event_bridge_config
            event_bridge_config do
              event_bus_arn datasource_attrs.event_bridge_config[:event_bus_arn]
            end
          end
          
          # HTTP configuration
          if datasource_attrs.http_config
            http_config do
              endpoint datasource_attrs.http_config[:endpoint]
              
              if datasource_attrs.http_config[:authorization_config]
                authorization_config do
                  authorization_type datasource_attrs.http_config[:authorization_config][:authorization_type]
                  
                  if datasource_attrs.http_config[:authorization_config][:aws_iam_config]
                    aws_iam_config do
                      signing_region datasource_attrs.http_config[:authorization_config][:aws_iam_config][:signing_region] if datasource_attrs.http_config[:authorization_config][:aws_iam_config][:signing_region]
                      signing_service_name datasource_attrs.http_config[:authorization_config][:aws_iam_config][:signing_service_name] if datasource_attrs.http_config[:authorization_config][:aws_iam_config][:signing_service_name]
                    end
                  end
                end
              end
            end
          end
          
          # Lambda configuration
          if datasource_attrs.lambda_config
            lambda_config do
              function_arn datasource_attrs.lambda_config[:function_arn]
            end
          end
          
          # Relational database configuration
          if datasource_attrs.relational_database_config
            relational_database_config do
              database_name datasource_attrs.relational_database_config[:database_name] if datasource_attrs.relational_database_config[:database_name]
              source_type datasource_attrs.relational_database_config[:source_type] if datasource_attrs.relational_database_config[:source_type]
              
              if datasource_attrs.relational_database_config[:rds_http_endpoint_config]
                rds_http_endpoint_config do
                  aws_secret_store_arn datasource_attrs.relational_database_config[:rds_http_endpoint_config][:aws_secret_store_arn]
                  database_name datasource_attrs.relational_database_config[:rds_http_endpoint_config][:database_name] if datasource_attrs.relational_database_config[:rds_http_endpoint_config][:database_name]
                  db_cluster_identifier datasource_attrs.relational_database_config[:rds_http_endpoint_config][:db_cluster_identifier]
                  region datasource_attrs.relational_database_config[:rds_http_endpoint_config][:region] if datasource_attrs.relational_database_config[:rds_http_endpoint_config][:region]
                  schema datasource_attrs.relational_database_config[:rds_http_endpoint_config][:schema] if datasource_attrs.relational_database_config[:rds_http_endpoint_config][:schema]
                end
              end
            end
          end
          
          service_role_arn datasource_attrs.service_role_arn if datasource_attrs.service_role_arn
        end
        
        # Return resource reference with outputs
        ResourceReference.new(
          type: 'aws_appsync_datasource',
          name: name,
          resource_attributes: datasource_attrs.to_h,
          outputs: {
            id: "${aws_appsync_datasource.#{name}.id}",
            arn: "${aws_appsync_datasource.#{name}.arn}",
            name: "${aws_appsync_datasource.#{name}.name}",
            type: "${aws_appsync_datasource.#{name}.type}"
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)