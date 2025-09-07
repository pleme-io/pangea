# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module Code
        # AWS CodeStar Connection resource
        # Manages connections to external source repositories like GitHub,
        # Bitbucket, and GitLab for use with CodePipeline and CodeBuild.
        module CodestarConnection
          # Creates an AWS CodeStar Connection
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the connection
          # @option attributes [String] :name The name of the connection (required)
          # @option attributes [String] :provider_type The provider type (GitHub, Bitbucket, GitLab) (required)
          # @option attributes [String] :host_arn ARN of the host for GitLab connections
          # @option attributes [Hash] :tags Tags to apply to the connection
          #
          # @example GitHub connection
          #   github_connection = aws_codestar_connection(:github_main, {
          #     name: "GitHubMainConnection",
          #     provider_type: "GitHub",
          #     tags: {
          #       "Environment" => "Production",
          #       "Team" => "DevOps"
          #     }
          #   })
          #
          # @example GitLab self-hosted connection
          #   gitlab_connection = aws_codestar_connection(:gitlab_enterprise, {
          #     name: "GitLabEnterpriseConnection",
          #     provider_type: "GitLab",
          #     host_arn: ref(:aws_codestar_host, :gitlab_host, :arn),
          #     tags: {
          #       "Environment" => "Production"
          #     }
          #   })
          #
          # @return [ResourceReference] The CodeStar connection resource reference
          def aws_codestar_connection(name, attributes = {})
            resource(:aws_codestar_connection, name) do
              name attributes[:name] if attributes[:name]
              provider_type attributes[:provider_type] if attributes[:provider_type]
              host_arn attributes[:host_arn] if attributes[:host_arn]
              tags attributes[:tags] if attributes[:tags]
            end
            
            ResourceReference.new(
              type: 'aws_codestar_connection',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_codestar_connection.#{name}.id}",
                arn: "${aws_codestar_connection.#{name}.arn}",
                connection_status: "${aws_codestar_connection.#{name}.connection_status}"
              },
              computed_properties: {
                provider: attributes[:provider_type]&.downcase&.to_sym,
                requires_host: attributes[:provider_type] == 'GitLab'
              }
            )
          end
        end
      end
    end
  end
end