# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS API Gateway API Key resources
      class ApiGatewayApiKeyAttributes < Dry::Struct
        # Name for the API key
        attribute :name, Resources::Types::String

        # Description of the API key
        attribute :description, Resources::Types::String.optional

        # Whether the API key is enabled
        attribute :enabled, Resources::Types::Bool.default(true)

        # API key value (if provided, otherwise auto-generated)
        attribute :value, Resources::Types::String.optional

        # Tags to apply to the API key
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate name format
          unless attrs.name.match?(/\A[a-zA-Z0-9\-_]{1,128}\z/)
            raise Dry::Struct::Error, "API key name must be 1-128 characters and contain only alphanumeric, hyphens, and underscores"
          end

          # Validate API key value format if provided
          if attrs.value
            unless attrs.value.match?(/\A[a-zA-Z0-9]{20,128}\z/)
              raise Dry::Struct::Error, "API key value must be 20-128 characters and contain only alphanumeric characters"
            end
          end

          # Set default description if not provided
          unless attrs.description
            status = attrs.enabled ? "Active" : "Disabled"
            attrs = attrs.copy_with(description: "#{status} API key for #{attrs.name}")
          end

          attrs
        end

        # Helper methods
        def active?
          enabled
        end

        def disabled?
          !enabled
        end

        def custom_value?
          !value.nil?
        end

        def auto_generated_value?
          value.nil?
        end

        def estimated_monthly_cost
          "$0.00 (no additional charge for API keys)"
        end

        def validate_configuration
          warnings = []
          
          if disabled?
            warnings << "API key is disabled - remember to enable for production use"
          end
          
          if name.length < 3
            warnings << "Very short API key name - consider more descriptive naming"
          end
          
          if custom_value? && value.length < 32
            warnings << "Short custom API key value - consider longer keys for better security"
          end
          
          unless description&.include?(name) || description&.include?('purpose')
            warnings << "API key description should include purpose or context"
          end
          
          warnings
        end

        # Get security assessment
        def security_level
          return 'low' if disabled?
          
          if custom_value?
            case value.length
            when 20..31
              'medium'
            when 32..63
              'high'
            else
              'very_high'
            end
          else
            'high' # AWS-generated keys are secure
          end
        end

        # Check if suitable for production
        def production_ready?
          enabled && name.length >= 5
        end

        # Get key status
        def status
          enabled ? 'active' : 'disabled'
        end

        # Get key type
        def key_type
          custom_value? ? 'custom' : 'auto_generated'
        end
      end

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
end