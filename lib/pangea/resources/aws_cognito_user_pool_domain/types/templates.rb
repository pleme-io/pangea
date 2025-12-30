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

module Pangea
  module Resources
    module AWS
      module Types
        # Pre-configured domain templates for common scenarios
        module UserPoolDomainTemplates
          # Cognito-hosted domain with prefix
          def self.cognito_domain(domain_prefix, user_pool_id)
            {
              domain: domain_prefix,
              user_pool_id: user_pool_id
            }
          end

          # Custom domain with SSL certificate
          def self.custom_domain(custom_domain_name, user_pool_id, certificate_arn)
            {
              domain: custom_domain_name,
              user_pool_id: user_pool_id,
              certificate_arn: certificate_arn
            }
          end

          # Development domain with predictable naming
          def self.development_domain(app_name, user_pool_id, stage = 'dev')
            domain_prefix = "#{app_name}-#{stage}-auth"
            cognito_domain(domain_prefix, user_pool_id)
          end

          # Production custom domain
          def self.production_custom_domain(base_domain, user_pool_id, certificate_arn)
            auth_domain = "auth.#{base_domain}"
            custom_domain(auth_domain, user_pool_id, certificate_arn)
          end

          # Staging environment domain
          def self.staging_domain(base_domain, user_pool_id, certificate_arn = nil)
            if certificate_arn
              staging_domain = "auth-staging.#{base_domain}"
              custom_domain(staging_domain, user_pool_id, certificate_arn)
            else
              staging_prefix = "#{base_domain.gsub('.', '-')}-staging-auth"
              cognito_domain(staging_prefix, user_pool_id)
            end
          end

          # Multi-environment domain strategy
          def self.environment_domain(base_domain, environment, user_pool_id, certificate_arn = nil)
            case environment.to_sym
            when :production
              raise ArgumentError, 'Certificate ARN required for production custom domain' unless certificate_arn

              production_custom_domain(base_domain, user_pool_id, certificate_arn)
            when :staging
              staging_domain(base_domain, user_pool_id, certificate_arn)
            when :development
              app_name = base_domain.split('.').first
              development_domain(app_name, user_pool_id, environment)
            else
              domain_prefix = "#{base_domain.gsub('.', '-')}-#{environment}-auth"
              cognito_domain(domain_prefix, user_pool_id)
            end
          end
        end
      end
    end
  end
end
