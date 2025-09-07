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
        # AppSync authentication types
        AppSyncAuthenticationType = Pangea::Resources::Types::String.constrained(
          included_in: [
            'API_KEY',
            'AWS_IAM', 
            'AMAZON_COGNITO_USER_POOLS',
            'OPENID_CONNECT',
            'AWS_LAMBDA'
          ]
        )

        # AppSync field log level
        AppSyncFieldLogLevel = Pangea::Resources::Types::String.constrained(
          included_in: ['NONE', 'ERROR', 'ALL']
        )

        # AppSync resolver kind  
        AppSyncResolverKind = Pangea::Resources::Types::String.constrained(
          included_in: ['UNIT', 'PIPELINE']
        )

        # AppSync runtime
        AppSyncRuntime = Pangea::Resources::Types::Hash.schema(
          name: Pangea::Resources::Types::String.constrained(included_in: ['APPSYNC_JS']),
          runtime_version: Pangea::Resources::Types::String.constrained(format: /\A\d+\.\d+\.\d+\z/)
        )

        # AppSync log config
        AppSyncLogConfig = Pangea::Resources::Types::Hash.schema(
          cloudwatch_logs_role_arn: Pangea::Resources::Types::String.constrained(format: /\Aarn:aws:iam::\d{12}:role\//),
          field_log_level: AppSyncFieldLogLevel,
          exclude_verbose_content?: Pangea::Resources::Types::Bool.optional
        )

        # AppSync user pool config
        AppSyncUserPoolConfig = Pangea::Resources::Types::Hash.schema(
          app_id_client_regex?: Pangea::Resources::Types::String.optional,
          aws_region?: Pangea::Resources::Types::AwsRegion.optional,
          default_action?: Pangea::Resources::Types::String.constrained(included_in: ['ALLOW', 'DENY']).optional,
          user_pool_id: Pangea::Resources::Types::String.constrained(format: /\A[\w-]+_[a-zA-Z0-9]+\z/)
        )

        # AppSync OpenID Connect config
        AppSyncOpenIdConnectConfig = Pangea::Resources::Types::Hash.schema(
          auth_ttl?: Pangea::Resources::Types::Integer.constrained(gteq: 0).optional,
          client_id?: Pangea::Resources::Types::String.optional,
          iat_ttl?: Pangea::Resources::Types::Integer.constrained(gteq: 0).optional,
          issuer: Pangea::Resources::Types::String.constrained(format: /\Ahttps?:\/\//)
        )

        # AppSync Lambda authorizer config
        AppSyncLambdaAuthorizerConfig = Pangea::Resources::Types::Hash.schema(
          authorizer_result_ttl_in_seconds?: Pangea::Resources::Types::Integer.constrained(gteq: 0, lteq: 3600).optional,
          authorizer_uri: Pangea::Resources::Types::String.constrained(format: /\Aarn:aws:lambda:/),
          identity_validation_expression?: Pangea::Resources::Types::String.optional
        )

        # AppSync additional authentication provider
        AppSyncAdditionalAuthenticationProvider = Pangea::Resources::Types::Hash.schema(
          authentication_type: AppSyncAuthenticationType,
          user_pool_config?: AppSyncUserPoolConfig.optional,
          openid_connect_config?: AppSyncOpenIdConnectConfig.optional,
          lambda_authorizer_config?: AppSyncLambdaAuthorizerConfig.optional
        )

        # AppSync GraphQL API resource attributes
        class AppSyncGraphqlApiAttributes < Dry::Struct
          transform_keys(&:to_sym)

          attribute :name, Pangea::Resources::Types::String.constrained(
            format: /\A[a-zA-Z][a-zA-Z0-9_-]{0,63}\z/,
            size: 1..64
          )
          
          attribute :authentication_type, AppSyncAuthenticationType

          attribute? :additional_authentication_providers, Pangea::Resources::Types::Array.of(
            AppSyncAdditionalAuthenticationProvider
          ).optional

          attribute? :api_type, Pangea::Resources::Types::String.constrained(included_in: ['GRAPHQL', 'MERGED']).optional
          
          attribute? :introspection_config, Pangea::Resources::Types::String.constrained(included_in: ['ENABLED', 'DISABLED']).optional
          
          attribute? :lambda_authorizer_config, AppSyncLambdaAuthorizerConfig.optional
          
          attribute? :log_config, AppSyncLogConfig.optional
          
          attribute? :merged_api_execution_role_arn, Pangea::Resources::Types::String.constrained(
            format: /\Aarn:aws:iam::\d{12}:role\//
          ).optional
          
          attribute? :openid_connect_config, AppSyncOpenIdConnectConfig.optional
          
          attribute? :query_depth_limit, Pangea::Resources::Types::Integer.constrained(
            gteq: 1, lteq: 75
          ).optional
          
          attribute? :resolver_count_limit, Pangea::Resources::Types::Integer.constrained(
            gteq: 1, lteq: 10000
          ).optional
          
          attribute? :schema, Pangea::Resources::Types::String.optional
          
          attribute? :user_pool_config, AppSyncUserPoolConfig.optional
          
          attribute? :visibility, Pangea::Resources::Types::String.constrained(included_in: ['GLOBAL', 'PRIVATE']).optional
          
          attribute? :xray_enabled, Pangea::Resources::Types::Bool.optional

          attribute? :tags, Pangea::Resources::Types::AwsTags

          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            # Validate authentication provider configurations match authentication type
            if attrs[:authentication_type] == 'AMAZON_COGNITO_USER_POOLS' && !attrs[:user_pool_config]
              raise Dry::Struct::Error, "user_pool_config is required when authentication_type is AMAZON_COGNITO_USER_POOLS"
            end

            if attrs[:authentication_type] == 'OPENID_CONNECT' && !attrs[:openid_connect_config]
              raise Dry::Struct::Error, "openid_connect_config is required when authentication_type is OPENID_CONNECT"
            end

            if attrs[:authentication_type] == 'AWS_LAMBDA' && !attrs[:lambda_authorizer_config]
              raise Dry::Struct::Error, "lambda_authorizer_config is required when authentication_type is AWS_LAMBDA"
            end

            # Validate merged API configuration
            if attrs[:api_type] == 'MERGED' && !attrs[:merged_api_execution_role_arn]
              raise Dry::Struct::Error, "merged_api_execution_role_arn is required when api_type is MERGED"
            end

            super(attrs)
          end
        end
      end
    end
  end
end