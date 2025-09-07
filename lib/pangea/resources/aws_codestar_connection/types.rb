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
        # CodeStar Connection resource attributes with validation
        class CodeStarConnectionAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :name, Resources::Types::String
          attribute :provider_type, Resources::Types::String.enum(
            'Bitbucket', 
            'GitHub', 
            'GitHubEnterpriseServer',
            'GitLab'
          )
          
          # Optional attributes
          attribute :host_arn, Resources::Types::String.optional.default(nil)
          attribute :tags, Resources::Types::AwsTags
          
          # Validate attributes
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate connection name
            if attrs[:name]
              name = attrs[:name]
              unless name.match?(/^[a-zA-Z0-9][a-zA-Z0-9\-_]{0,31}$/)
                raise Dry::Struct::Error, "name must be 1-32 characters, start with alphanumeric, contain only letters, numbers, hyphens, underscores"
              end
              
              if name.length < 1 || name.length > 32
                raise Dry::Struct::Error, "name must be between 1 and 32 characters"
              end
            end
            
            # Validate host_arn requirement for GitHub Enterprise Server
            if attrs[:provider_type] == 'GitHubEnterpriseServer'
              unless attrs[:host_arn]
                raise Dry::Struct::Error, "host_arn is required when provider_type is GitHubEnterpriseServer"
              end
            end
            
            # Validate host_arn format if provided
            if attrs[:host_arn] && !attrs[:host_arn].empty?
              host_arn = attrs[:host_arn]
              unless host_arn.match?(/^arn:aws[a-z\-]*:codestar-connections:/) || host_arn.match?(/^\$\{/)
                raise Dry::Struct::Error, "host_arn must be a valid CodeStar Connections host ARN or terraform reference"
              end
            end
            
            # Validate host_arn not used with cloud providers
            if attrs[:host_arn] && %w[GitHub Bitbucket GitLab].include?(attrs[:provider_type])
              raise Dry::Struct::Error, "host_arn should not be specified for cloud-based providers (#{attrs[:provider_type]})"
            end
            
            super(attrs)
          end
          
          # Computed properties
          def is_github_cloud?
            provider_type == 'GitHub'
          end
          
          def is_github_enterprise?
            provider_type == 'GitHubEnterpriseServer'
          end
          
          def is_bitbucket_cloud?
            provider_type == 'Bitbucket'
          end
          
          def is_gitlab?
            provider_type == 'GitLab'
          end
          
          def is_cloud_provider?
            %w[GitHub Bitbucket GitLab].include?(provider_type)
          end
          
          def is_self_hosted_provider?
            %w[GitHubEnterpriseServer].include?(provider_type)
          end
          
          def requires_host_arn?
            is_self_hosted_provider?
          end
          
          def supports_webhooks?
            true  # All providers support webhooks
          end
          
          def supports_pull_requests?
            true  # All providers support pull requests
          end
          
          def webhook_filter_types
            case provider_type
            when 'GitHub', 'GitHubEnterpriseServer'
              %w[PUSH PULL_REQUEST_CREATED PULL_REQUEST_UPDATED PULL_REQUEST_MERGED]
            when 'Bitbucket'
              %w[PUSH PULL_REQUEST_CREATED PULL_REQUEST_UPDATED PULL_REQUEST_MERGED]
            when 'GitLab'
              %w[PUSH PULL_REQUEST_CREATED PULL_REQUEST_UPDATED PULL_REQUEST_MERGED]
            else
              []
            end
          end
          
          def default_branch_patterns
            case provider_type
            when 'GitHub', 'GitHubEnterpriseServer'
              ['main', 'master', 'develop']
            when 'Bitbucket'
              ['main', 'master', 'develop']
            when 'GitLab'
              ['main', 'master', 'develop']
            else
              ['main']
            end
          end
          
          def oauth_scopes
            case provider_type
            when 'GitHub', 'GitHubEnterpriseServer'
              ['repo', 'read:user', 'user:email']
            when 'Bitbucket'
              ['account', 'repositories']
            when 'GitLab'
              ['read_user', 'read_repository', 'read_api']
            else
              []
            end
          end
          
          def estimated_monthly_cost
            # CodeStar Connections are free, but consider pipeline usage
            0.0
          end
          
          def connection_url_template
            case provider_type
            when 'GitHub'
              'https://github.com'
            when 'GitHubEnterpriseServer'
              '${var.github_enterprise_url}'
            when 'Bitbucket'
              'https://bitbucket.org'
            when 'GitLab'
              'https://gitlab.com'
            else
              'unknown'
            end
          end
          
          def to_h
            hash = {
              name: name,
              provider_type: provider_type,
              tags: tags
            }
            
            hash[:host_arn] = host_arn if host_arn
            
            hash.compact
          end
        end
      end
    end
  end
end