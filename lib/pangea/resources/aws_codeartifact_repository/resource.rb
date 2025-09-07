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
require 'pangea/resources/aws_codeartifact_repository/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS CodeArtifact Repository with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] CodeArtifact Repository attributes
      # @option attributes [String] :repository The name of the repository
      # @option attributes [String] :domain The domain containing the repository
      # @option attributes [String] :format The package format (npm, pypi, maven, nuget)
      # @option attributes [String] :domain_owner The domain owner (AWS account ID)
      # @option attributes [String] :description Description of the repository
      # @option attributes [Array<Hash>] :upstream Upstream repository configurations
      # @option attributes [Hash] :external_connections External connection configuration
      # @option attributes [Hash] :tags Tags to apply to the repository
      # @return [ResourceReference] Reference object with outputs and computed properties
      #
      # @example Basic npm repository
      #   npm_repo = aws_codeartifact_repository(:npm_packages, {
      #     repository: "npm-packages",
      #     domain: codeartifact_domain.domain,
      #     format: "npm",
      #     description: "Internal npm packages",
      #     tags: {
      #       Format: "npm",
      #       Team: "frontend"
      #     }
      #   })
      #
      # @example Python repository with external connection
      #   pypi_repo = aws_codeartifact_repository(:python_packages, {
      #     repository: "python-packages",
      #     domain: codeartifact_domain.domain,
      #     format: "pypi",
      #     description: "Python packages with PyPI proxy",
      #     external_connections: {
      #       external_connection_name: "public:pypi"
      #     },
      #     tags: {
      #       Format: "pypi",
      #       Team: "backend"
      #     }
      #   })
      #
      # @example Maven repository with upstream
      #   maven_repo = aws_codeartifact_repository(:maven_packages, {
      #     repository: "maven-packages", 
      #     domain: codeartifact_domain.domain,
      #     format: "maven",
      #     description: "Maven packages with upstream",
      #     upstream: [
      #       {
      #         repository_name: maven_central_proxy.repository
      #       }
      #     ],
      #     tags: {
      #       Format: "maven",
      #       Team: "platform"
      #     }
      #   })
      #
      # @example Cross-account repository
      #   cross_account_repo = aws_codeartifact_repository(:shared_packages, {
      #     repository: "shared-packages",
      #     domain: "shared-domain",
      #     domain_owner: "123456789012",
      #     format: "npm",
      #     description: "Shared packages from central account",
      #     tags: {
      #       Usage: "shared",
      #       Source: "central-account"
      #     }
      #   })
      def aws_codeartifact_repository(name, attributes = {})
        # Validate attributes using dry-struct
        repo_attrs = Types::Types::CodeArtifactRepositoryAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_codeartifact_repository, name) do
          # Repository name
          repository repo_attrs.repository
          
          # Domain reference
          domain repo_attrs.domain
          
          # Package format
          format repo_attrs.format
          
          # Optional domain owner
          domain_owner repo_attrs.domain_owner if repo_attrs.domain_owner
          
          # Optional description
          description repo_attrs.description if repo_attrs.description
          
          # Upstream repositories
          if repo_attrs.upstream.any?
            repo_attrs.upstream.each do |upstream_config|
              upstream do
                repository_name upstream_config[:repository_name]
              end
            end
          end
          
          # External connections
          if repo_attrs.external_connections && repo_attrs.external_connections[:external_connection_name]
            external_connections do
              external_connection_name repo_attrs.external_connections[:external_connection_name]
            end
          end
          
          # Apply tags if present
          if repo_attrs.tags.any?
            tags do
              repo_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_codeartifact_repository',
          name: name,
          resource_attributes: repo_attrs.to_h,
          outputs: {
            arn: "${aws_codeartifact_repository.#{name}.arn}",
            repository: "${aws_codeartifact_repository.#{name}.repository}",
            domain: "${aws_codeartifact_repository.#{name}.domain}",
            domain_owner: "${aws_codeartifact_repository.#{name}.domain_owner}",
            format: "${aws_codeartifact_repository.#{name}.format}",
            description: "${aws_codeartifact_repository.#{name}.description}",
            administrator_account: "${aws_codeartifact_repository.#{name}.administrator_account}",
            tags_all: "${aws_codeartifact_repository.#{name}.tags_all}"
          },
          computed_properties: {
            has_upstream_repositories: repo_attrs.has_upstream_repositories?,
            upstream_count: repo_attrs.upstream_count,
            has_external_connection: repo_attrs.has_external_connection?,
            external_connection_type: repo_attrs.external_connection_type,
            supports_external_connection: repo_attrs.supports_external_connection?,
            is_private_repository: repo_attrs.is_private_repository?,
            is_public_proxy_repository: repo_attrs.is_public_proxy_repository?,
            package_manager_config_command: repo_attrs.package_manager_config_command,
            estimated_monthly_cost_per_gb: repo_attrs.estimated_monthly_cost_per_gb,
            repository_endpoint_template: repo_attrs.repository_endpoint_template
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)