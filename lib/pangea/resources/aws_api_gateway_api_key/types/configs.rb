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
        # Common API Gateway API key configurations
        module ApiGatewayApiKeyConfigs
          # Standard API key for application
          def self.application_api_key(app_name, environment = 'production')
            {
              name: "#{app_name.downcase.gsub(/[^a-z0-9]/, '-')}-#{environment}-api-key",
              description: "#{environment.capitalize} API key for #{app_name}",
              enabled: true,
              tags: {
                Application: app_name,
                Environment: environment,
                Purpose: 'API Access Control'
              }
            }
          end

          # Development API key with descriptive naming
          def self.development_api_key(project_name, developer_name = nil)
            key_name = developer_name ?
              "#{project_name.downcase.gsub(/[^a-z0-9]/, '-')}-#{developer_name.downcase.gsub(/[^a-z0-9]/, '-')}-dev" :
              "#{project_name.downcase.gsub(/[^a-z0-9]/, '-')}-dev-api-key"

            {
              name: key_name,
              description: "Development API key for #{project_name}#{developer_name ? " (#{developer_name})" : ''}",
              enabled: true,
              tags: {
                Environment: 'development',
                Project: project_name,
                Developer: developer_name,
                Purpose: 'Development and Testing'
              }.compact
            }
          end

          # Corporate partner API key
          def self.partner_api_key(partner_name, access_level = 'standard')
            {
              name: "#{partner_name.downcase.gsub(/[^a-z0-9]/, '-')}-partner-api-key",
              description: "#{access_level.capitalize} access API key for partner #{partner_name}",
              enabled: true,
              tags: {
                Partner: partner_name,
                AccessLevel: access_level,
                Purpose: 'Partner API Access',
                KeyType: 'external_partner'
              }
            }
          end

          # Service-to-service API key
          def self.service_api_key(service_name, target_service, environment = 'production')
            {
              name: "#{service_name.downcase.gsub(/[^a-z0-9]/, '-')}-to-#{target_service.downcase.gsub(/[^a-z0-9]/, '-')}-key",
              description: "#{environment.capitalize} service key for #{service_name} to access #{target_service}",
              enabled: true,
              tags: {
                SourceService: service_name,
                TargetService: target_service,
                Environment: environment,
                Purpose: 'Service-to-Service Communication',
                KeyType: 'internal_service'
              }
            }
          end

          # Mobile application API key
          def self.mobile_app_api_key(app_name, platform, version = nil)
            key_name = version ?
              "#{app_name.downcase.gsub(/[^a-z0-9]/, '-')}-#{platform.downcase}-v#{version.gsub('.', '-')}" :
              "#{app_name.downcase.gsub(/[^a-z0-9]/, '-')}-#{platform.downcase}-mobile"

            {
              name: key_name,
              description: "#{platform} mobile API key for #{app_name}#{version ? " v#{version}" : ''}",
              enabled: true,
              tags: {
                Application: app_name,
                Platform: platform,
                Version: version,
                Purpose: 'Mobile Application Access',
                KeyType: 'mobile_client'
              }.compact
            }
          end

          # Temporary/limited API key
          def self.temporary_api_key(purpose, expiry_context, enabled = false)
            {
              name: "temp-#{purpose.downcase.gsub(/[^a-z0-9]/, '-')}-api-key",
              description: "Temporary API key for #{purpose} (#{expiry_context})",
              enabled: enabled,
              tags: {
                Purpose: purpose,
                KeyType: 'temporary',
                ExpiryContext: expiry_context,
                AutoManaged: 'true'
              }
            }
          end
        end
      end
    end
  end
end
