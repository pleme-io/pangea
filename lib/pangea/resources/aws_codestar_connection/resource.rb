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
require 'pangea/resources/aws_codestar_connection/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS CodeStar Connection with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] CodeStar Connection attributes
      # @option attributes [String] :name The name of the connection
      # @option attributes [String] :provider_type The provider type (GitHub, Bitbucket, GitHubEnterpriseServer, GitLab)
      # @option attributes [String] :host_arn The host ARN (required for GitHubEnterpriseServer)
      # @option attributes [Hash] :tags Tags to apply to the connection
      # @return [ResourceReference] Reference object with outputs and computed properties
      #
      # @example GitHub connection
      #   github_conn = aws_codestar_connection(:github, {
      #     name: "github-connection",
      #     provider_type: "GitHub",
      #     tags: {
      #       Provider: "GitHub",
      #       Usage: "ci-cd"
      #     }
      #   })
      #
      # @example Bitbucket connection
      #   bitbucket_conn = aws_codestar_connection(:bitbucket, {
      #     name: "bitbucket-connection",
      #     provider_type: "Bitbucket",
      #     tags: {
      #       Provider: "Bitbucket",
      #       Team: "development"
      #     }
      #   })
      #
      # @example GitHub Enterprise Server connection
      #   github_enterprise = aws_codestar_connection(:github_enterprise, {
      #     name: "github-enterprise-connection",
      #     provider_type: "GitHubEnterpriseServer",
      #     host_arn: github_host.arn,
      #     tags: {
      #       Provider: "GitHubEnterprise",
      #       Environment: "production"
      #     }
      #   })
      #
      # @example GitLab connection
      #   gitlab_conn = aws_codestar_connection(:gitlab, {
      #     name: "gitlab-connection",
      #     provider_type: "GitLab", 
      #     tags: {
      #       Provider: "GitLab",
      #       Usage: "source-control"
      #     }
      #   })
      def aws_codestar_connection(name, attributes = {})
        # Validate attributes using dry-struct
        conn_attrs = Types::Types::CodeStarConnectionAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_codestar_connections_connection, name) do
          # Connection name
          name conn_attrs.name
          
          # Provider type
          provider_type conn_attrs.provider_type
          
          # Host ARN for self-hosted providers
          host_arn conn_attrs.host_arn if conn_attrs.host_arn
          
          # Apply tags if present
          if conn_attrs.tags.any?
            tags do
              conn_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_codestar_connections_connection',
          name: name,
          resource_attributes: conn_attrs.to_h,
          outputs: {
            arn: "${aws_codestar_connections_connection.#{name}.arn}",
            connection_status: "${aws_codestar_connections_connection.#{name}.connection_status}",
            name: "${aws_codestar_connections_connection.#{name}.name}",
            provider_type: "${aws_codestar_connections_connection.#{name}.provider_type}",
            host_arn: "${aws_codestar_connections_connection.#{name}.host_arn}",
            tags_all: "${aws_codestar_connections_connection.#{name}.tags_all}"
          },
          computed_properties: {
            is_github_cloud: conn_attrs.is_github_cloud?,
            is_github_enterprise: conn_attrs.is_github_enterprise?,
            is_bitbucket_cloud: conn_attrs.is_bitbucket_cloud?,
            is_gitlab: conn_attrs.is_gitlab?,
            is_cloud_provider: conn_attrs.is_cloud_provider?,
            is_self_hosted_provider: conn_attrs.is_self_hosted_provider?,
            requires_host_arn: conn_attrs.requires_host_arn?,
            supports_webhooks: conn_attrs.supports_webhooks?,
            supports_pull_requests: conn_attrs.supports_pull_requests?,
            webhook_filter_types: conn_attrs.webhook_filter_types,
            default_branch_patterns: conn_attrs.default_branch_patterns,
            oauth_scopes: conn_attrs.oauth_scopes,
            estimated_monthly_cost: conn_attrs.estimated_monthly_cost,
            connection_url_template: conn_attrs.connection_url_template
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)