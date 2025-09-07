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


require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # AppSync data source types
        AppSyncDataSourceType = String.enum(
          'AWS_LAMBDA',
          'AMAZON_DYNAMODB',
          'AMAZON_ELASTICSEARCH',
          'AMAZON_OPENSEARCH_SERVICE',
          'NONE',
          'HTTP',
          'RELATIONAL_DATABASE',
          'AMAZON_EVENTBRIDGE'
        )

        # DynamoDB config for AppSync data source
        AppSyncDynamodbConfig = Hash.schema(
          table_name: String,
          region?: Resources::Types::AwsRegion.optional,
          use_caller_credentials?: Resources::Types::Bool.optional,
          versioned?: Resources::Types::Bool.optional,
          delta_sync_config?: Hash.schema(
            base_table_ttl?: Resources::Types::Integer.constrained(gteq: 60, lteq: 31536000).optional,
            delta_sync_table_name?: String.optional,
            delta_sync_table_ttl?: Resources::Types::Integer.constrained(gteq: 60, lteq: 31536000).optional
          ).optional
        )

        # Lambda config for AppSync data source
        AppSyncLambdaConfig = Hash.schema(
          function_arn: String.constrained(format: /\Aarn:aws:lambda:/)
        )

        # Elasticsearch/OpenSearch config for AppSync data source
        AppSyncElasticsearchConfig = Hash.schema(
          endpoint: String.constrained(format: /\Ahttps?:\/\//),
          region?: Resources::Types::AwsRegion.optional
        )

        # HTTP config for AppSync data source  
        AppSyncHttpConfig = Hash.schema(
          endpoint: String.constrained(format: /\Ahttps?:\/\//),
          authorization_config?: Hash.schema(
            authorization_type: String.enum('AWS_IAM'),
            aws_iam_config?: Hash.schema(
              signing_region?: Resources::Types::AwsRegion.optional,
              signing_service_name?: String.optional
            ).optional
          ).optional
        )

        # Relational database config for AppSync data source
        AppSyncRelationalDatabaseConfig = Hash.schema(
          database_name?: String.optional,
          rds_http_endpoint_config?: Hash.schema(
            aws_secret_store_arn: String.constrained(format: /\Aarn:aws:secretsmanager:/),
            database_name?: String.optional,
            db_cluster_identifier: String,
            region?: Resources::Types::AwsRegion.optional,
            schema?: String.optional
          ).optional,
          source_type?: String.enum('RDS_HTTP_ENDPOINT').optional
        )

        # EventBridge config for AppSync data source
        AppSyncEventBridgeConfig = Hash.schema(
          event_bus_arn: String.constrained(format: /\Aarn:aws:events:/)
        )

        # AppSync DataSource resource attributes
        class AppSyncDatasourceAttributes < Dry::Struct
          transform_keys(&:to_sym)

          attribute :api_id, Resources::Types::String
          
          attribute :name, Resources::Types::String.constrained(
            format: /\A[a-zA-Z][a-zA-Z0-9_]{0,64}\z/,
            size: 1..65
          )
          
          attribute :type, AppSyncDataSourceType
          
          attribute? :description, Resources::Types::String.optional
          
          attribute? :dynamodb_config, AppSyncDynamodbConfig.optional
          
          attribute? :elasticsearch_config, AppSyncElasticsearchConfig.optional
          
          attribute? :event_bridge_config, AppSyncEventBridgeConfig.optional
          
          attribute? :http_config, AppSyncHttpConfig.optional
          
          attribute? :lambda_config, AppSyncLambdaConfig.optional
          
          attribute? :relational_database_config, AppSyncRelationalDatabaseConfig.optional
          
          attribute? :service_role_arn, Resources::Types::String.constrained(
            format: /\Aarn:aws:iam::\d{12}:role\//
          ).optional

          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            # Validate that the appropriate config is provided for the data source type
            case attrs[:type]
            when 'AMAZON_DYNAMODB'
              unless attrs[:dynamodb_config]
                raise Dry::Struct::Error, "dynamodb_config is required when type is AMAZON_DYNAMODB"
              end
              unless attrs[:service_role_arn]
                raise Dry::Struct::Error, "service_role_arn is required for DynamoDB data sources"
              end
            when 'AWS_LAMBDA'
              unless attrs[:lambda_config]
                raise Dry::Struct::Error, "lambda_config is required when type is AWS_LAMBDA"
              end
              unless attrs[:service_role_arn]
                raise Dry::Struct::Error, "service_role_arn is required for Lambda data sources"
              end
            when 'AMAZON_ELASTICSEARCH', 'AMAZON_OPENSEARCH_SERVICE'
              unless attrs[:elasticsearch_config]
                raise Dry::Struct::Error, "elasticsearch_config is required when type is #{attrs[:type]}"
              end
              unless attrs[:service_role_arn]
                raise Dry::Struct::Error, "service_role_arn is required for Elasticsearch/OpenSearch data sources"
              end
            when 'HTTP'
              unless attrs[:http_config]
                raise Dry::Struct::Error, "http_config is required when type is HTTP"
              end
            when 'RELATIONAL_DATABASE'
              unless attrs[:relational_database_config]
                raise Dry::Struct::Error, "relational_database_config is required when type is RELATIONAL_DATABASE"
              end
              unless attrs[:service_role_arn]
                raise Dry::Struct::Error, "service_role_arn is required for Relational Database data sources"
              end
            when 'AMAZON_EVENTBRIDGE'
              unless attrs[:event_bridge_config]
                raise Dry::Struct::Error, "event_bridge_config is required when type is AMAZON_EVENTBRIDGE"
              end
              unless attrs[:service_role_arn]
                raise Dry::Struct::Error, "service_role_arn is required for EventBridge data sources"
              end
            when 'NONE'
              # No config required for NONE type
            end

            super(attrs)
          end
        end
      end
    end
  end
end