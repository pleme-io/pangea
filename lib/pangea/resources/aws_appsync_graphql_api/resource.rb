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
require 'pangea/resources/aws_appsync_graphql_api/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS AppSync GraphQL API
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] GraphQL API attributes
      # @option attributes [String] :name The API name
      # @option attributes [String] :authentication_type Primary authentication type
      # @option attributes [Array<Hash>] :additional_authentication_providers Additional auth providers
      # @option attributes [String] :api_type GRAPHQL or MERGED
      # @option attributes [String] :introspection_config Enable/disable introspection
      # @option attributes [Hash] :lambda_authorizer_config Lambda authorizer configuration
      # @option attributes [Hash] :log_config CloudWatch logging configuration
      # @option attributes [String] :merged_api_execution_role_arn IAM role for merged APIs
      # @option attributes [Hash] :openid_connect_config OpenID Connect configuration
      # @option attributes [Integer] :query_depth_limit Max query depth (1-75)
      # @option attributes [Integer] :resolver_count_limit Max resolver count (1-10000)
      # @option attributes [String] :schema GraphQL schema definition
      # @option attributes [Hash] :user_pool_config Cognito user pool configuration
      # @option attributes [String] :visibility GLOBAL or PRIVATE
      # @option attributes [Boolean] :xray_enabled Enable X-Ray tracing
      # @option attributes [Hash] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs
      def aws_appsync_graphql_api(name, attributes = {})
        # Validate attributes using dry-struct
        api_attrs = Types::Types::AppSyncGraphqlApiAttributes.new(attributes)
        
        # Generate terraform resource block
        resource(:aws_appsync_graphql_api, name) do
          name api_attrs.name
          authentication_type api_attrs.authentication_type
          
          # Optional additional authentication providers
          if api_attrs.additional_authentication_providers&.any?
            api_attrs.additional_authentication_providers.each do |provider|
              additional_authentication_provider do
                authentication_type provider[:authentication_type]
                
                if provider[:user_pool_config]
                  user_pool_config do
                    user_pool_id provider[:user_pool_config][:user_pool_id]
                    app_id_client_regex provider[:user_pool_config][:app_id_client_regex] if provider[:user_pool_config][:app_id_client_regex]
                    aws_region provider[:user_pool_config][:aws_region] if provider[:user_pool_config][:aws_region]
                    default_action provider[:user_pool_config][:default_action] if provider[:user_pool_config][:default_action]
                  end
                end
                
                if provider[:openid_connect_config]
                  openid_connect_config do
                    issuer provider[:openid_connect_config][:issuer]
                    auth_ttl provider[:openid_connect_config][:auth_ttl] if provider[:openid_connect_config][:auth_ttl]
                    client_id provider[:openid_connect_config][:client_id] if provider[:openid_connect_config][:client_id]
                    iat_ttl provider[:openid_connect_config][:iat_ttl] if provider[:openid_connect_config][:iat_ttl]
                  end
                end
                
                if provider[:lambda_authorizer_config]
                  lambda_authorizer_config do
                    authorizer_uri provider[:lambda_authorizer_config][:authorizer_uri]
                    authorizer_result_ttl_in_seconds provider[:lambda_authorizer_config][:authorizer_result_ttl_in_seconds] if provider[:lambda_authorizer_config][:authorizer_result_ttl_in_seconds]
                    identity_validation_expression provider[:lambda_authorizer_config][:identity_validation_expression] if provider[:lambda_authorizer_config][:identity_validation_expression]
                  end
                end
              end
            end
          end
          
          api_type api_attrs.api_type if api_attrs.api_type
          introspection_config api_attrs.introspection_config if api_attrs.introspection_config
          
          # Lambda authorizer config
          if api_attrs.lambda_authorizer_config
            lambda_authorizer_config do
              authorizer_uri api_attrs.lambda_authorizer_config[:authorizer_uri]
              authorizer_result_ttl_in_seconds api_attrs.lambda_authorizer_config[:authorizer_result_ttl_in_seconds] if api_attrs.lambda_authorizer_config[:authorizer_result_ttl_in_seconds]
              identity_validation_expression api_attrs.lambda_authorizer_config[:identity_validation_expression] if api_attrs.lambda_authorizer_config[:identity_validation_expression]
            end
          end
          
          # Log config
          if api_attrs.log_config
            log_config do
              cloudwatch_logs_role_arn api_attrs.log_config[:cloudwatch_logs_role_arn]
              field_log_level api_attrs.log_config[:field_log_level]
              exclude_verbose_content api_attrs.log_config[:exclude_verbose_content] if api_attrs.log_config.key?(:exclude_verbose_content)
            end
          end
          
          merged_api_execution_role_arn api_attrs.merged_api_execution_role_arn if api_attrs.merged_api_execution_role_arn
          
          # OpenID Connect config
          if api_attrs.openid_connect_config
            openid_connect_config do
              issuer api_attrs.openid_connect_config[:issuer]
              auth_ttl api_attrs.openid_connect_config[:auth_ttl] if api_attrs.openid_connect_config[:auth_ttl]
              client_id api_attrs.openid_connect_config[:client_id] if api_attrs.openid_connect_config[:client_id]
              iat_ttl api_attrs.openid_connect_config[:iat_ttl] if api_attrs.openid_connect_config[:iat_ttl]
            end
          end
          
          query_depth_limit api_attrs.query_depth_limit if api_attrs.query_depth_limit
          resolver_count_limit api_attrs.resolver_count_limit if api_attrs.resolver_count_limit
          schema api_attrs.schema if api_attrs.schema
          
          # User pool config
          if api_attrs.user_pool_config
            user_pool_config do
              user_pool_id api_attrs.user_pool_config[:user_pool_id]
              app_id_client_regex api_attrs.user_pool_config[:app_id_client_regex] if api_attrs.user_pool_config[:app_id_client_regex]
              aws_region api_attrs.user_pool_config[:aws_region] if api_attrs.user_pool_config[:aws_region]
              default_action api_attrs.user_pool_config[:default_action] if api_attrs.user_pool_config[:default_action]
            end
          end
          
          visibility api_attrs.visibility if api_attrs.visibility
          xray_enabled api_attrs.xray_enabled if api_attrs.xray_enabled
          
          # Tags
          if api_attrs.tags&.any?
            tags api_attrs.tags
          end
        end
        
        # Return resource reference with outputs
        ResourceReference.new(
          type: 'aws_appsync_graphql_api',
          name: name,
          resource_attributes: api_attrs.to_h,
          outputs: {
            id: "${aws_appsync_graphql_api.#{name}.id}",
            arn: "${aws_appsync_graphql_api.#{name}.arn}",
            name: "${aws_appsync_graphql_api.#{name}.name}",
            uris: "${aws_appsync_graphql_api.#{name}.uris}",
            api_id: "${aws_appsync_graphql_api.#{name}.id}",
            authentication_type: "${aws_appsync_graphql_api.#{name}.authentication_type}"
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)