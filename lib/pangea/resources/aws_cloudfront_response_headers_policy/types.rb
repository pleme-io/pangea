# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS CloudFront Response Headers Policy resources
      class CloudFrontResponseHeadersPolicyAttributes < Dry::Struct
        # Name for the response headers policy
        attribute :name, Resources::Types::String

        # Comment/description for the policy
        attribute :comment, Resources::Types::String.optional

        # CORS configuration
        attribute :cors_config, Resources::Types::Hash.schema(
          access_control_allow_credentials: Types::Bool.default(false),
          access_control_allow_headers?: Types::Hash.schema(
            items: Types::Array.of(Types::String)
          ).optional,
          access_control_allow_methods: Types::Hash.schema(
            items: Types::Array.of(Types::String.enum('GET', 'POST', 'PUT', 'DELETE', 'HEAD', 'OPTIONS', 'PATCH'))
          ),
          access_control_allow_origins: Types::Hash.schema(
            items: Types::Array.of(Types::String)
          ),
          access_control_expose_headers?: Types::Hash.schema(
            items: Types::Array.of(Types::String)
          ).optional,
          access_control_max_age_sec?: Types::Integer.optional,
          origin_override: Types::Bool.default(true)
        ).optional

        # Custom headers configuration
        attribute :custom_headers_config, Resources::Types::Hash.schema(
          items?: Types::Array.of(
            Types::Hash.schema(
              header: Types::String,
              value: Types::String,
              override: Types::Bool.default(true)
            )
          ).optional
        ).optional

        # Remove headers configuration
        attribute :remove_headers_config, Resources::Types::Hash.schema(
          items: Types::Array.of(
            Types::Hash.schema(
              header: Types::String
            )
          )
        ).optional

        # Security headers configuration
        attribute :security_headers_config, Resources::Types::Hash.schema(
          content_type_options?: Types::Hash.schema(
            override: Types::Bool.default(true)
          ).optional,
          frame_options?: Types::Hash.schema(
            frame_option: Types::String.enum('DENY', 'SAMEORIGIN'),
            override: Types::Bool.default(true)
          ).optional,
          referrer_policy?: Types::Hash.schema(
            referrer_policy: Types::String.enum('no-referrer', 'no-referrer-when-downgrade', 'origin', 'origin-when-cross-origin', 'same-origin', 'strict-origin', 'strict-origin-when-cross-origin', 'unsafe-url'),
            override: Types::Bool.default(true)
          ).optional,
          strict_transport_security?: Types::Hash.schema(
            access_control_max_age_sec: Types::Integer,
            include_subdomains?: Types::Bool.default(false).optional,
            override: Types::Bool.default(true),
            preload?: Types::Bool.default(false).optional
          ).optional
        ).optional

        # Server timing headers configuration
        attribute :server_timing_headers_config, Resources::Types::Hash.schema(
          enabled: Types::Bool.default(false),
          sampling_rate?: Types::Coercible::Float.constrained(gteq: 0.0, lteq: 1.0).optional
        ).optional

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate name format
          unless attrs.name.match?(/\A[a-zA-Z0-9\-_]{1,128}\z/)
            raise Dry::Struct::Error, "Response headers policy name must be 1-128 characters and contain only alphanumeric, hyphens, and underscores"
          end

          # Validate that at least one header configuration is provided
          unless attrs.has_any_configuration?
            raise Dry::Struct::Error, "Response headers policy must have at least one header configuration"
          end

          # Validate CORS origins if provided
          if attrs.cors_config && attrs.cors_config[:access_control_allow_origins]
            attrs.cors_config[:access_control_allow_origins][:items].each do |origin|
              unless origin == '*' || origin.match?(/\Ahttps?:\/\/.+/) || origin.match?(/\A[a-zA-Z0-9\.\-]+\z/)
                raise Dry::Struct::Error, "Invalid CORS origin format: #{origin}"
              end
            end
          end

          # Validate custom header names
          if attrs.custom_headers_config&.dig(:items)
            attrs.custom_headers_config[:items].each do |header|
              unless header[:header].match?(/\A[a-zA-Z0-9\-_]+\z/)
                raise Dry::Struct::Error, "Invalid custom header name: #{header[:header]}"
              end
            end
          end

          # Set default comment if not provided
          unless attrs.comment
            config_types = []
            config_types << "CORS" if attrs.cors_config
            config_types << "Security" if attrs.security_headers_config
            config_types << "Custom" if attrs.custom_headers_config
            attrs = attrs.copy_with(comment: "Response headers policy for #{config_types.join(', ')} headers")
          end

          attrs
        end

        # Helper methods
        def has_any_configuration?
          cors_config || custom_headers_config || remove_headers_config || security_headers_config || server_timing_headers_config
        end

        def has_cors?
          !!cors_config
        end

        def has_security_headers?
          !!security_headers_config
        end

        def has_custom_headers?
          !!(custom_headers_config&.dig(:items)&.any?)
        end

        def has_remove_headers?
          !!(remove_headers_config&.dig(:items)&.any?)
        end

        def cors_allows_credentials?
          cors_config&.dig(:access_control_allow_credentials) == true
        end

        def cors_allows_all_origins?
          cors_config&.dig(:access_control_allow_origins, :items)&.include?('*')
        end

        def hsts_enabled?
          security_headers_config&.dig(:strict_transport_security).present?
        end

        def frame_options_enabled?
          security_headers_config&.dig(:frame_options).present?
        end

        def estimated_monthly_cost
          "$0.10 per 10,000 requests with response headers policy"
        end

        def validate_configuration
          warnings = []
          
          if cors_allows_credentials? && cors_allows_all_origins?
            warnings << "CORS credentials with wildcard origins is not allowed by browsers"
          end
          
          if has_cors? && !cors_config[:access_control_allow_methods][:items].include?('OPTIONS')
            warnings << "CORS configuration should typically include OPTIONS method"
          end
          
          if hsts_enabled? && cors_allows_all_origins?
            warnings << "HSTS with wildcard CORS origins may cause unexpected behavior"
          end
          
          if server_timing_headers_config&.dig(:enabled) && server_timing_headers_config[:sampling_rate].nil?
            warnings << "Server timing enabled without sampling rate - consider setting sampling rate"
          end
          
          unless has_security_headers?
            warnings << "No security headers configured - consider adding security headers for protection"
          end
          
          warnings
        end

        # Get security level assessment
        def security_level
          score = 0
          score += 1 if hsts_enabled?
          score += 1 if frame_options_enabled?
          score += 1 if security_headers_config&.dig(:content_type_options)
          score += 1 if security_headers_config&.dig(:referrer_policy)
          
          case score
          when 3..4
            'high'
          when 1..2
            'medium'
          else
            'basic'
          end
        end

        # Get policy complexity
        def complexity_level
          config_count = 0
          config_count += 1 if has_cors?
          config_count += 1 if has_security_headers?
          config_count += 1 if has_custom_headers?
          config_count += 1 if has_remove_headers?
          
          case config_count
          when 1
            'simple'
          when 2..3
            'moderate'
          else
            'complex'
          end
        end

        # Check if suitable for production
        def production_ready?
          has_security_headers? && security_level != 'basic'
        end

        # Get primary purpose
        def primary_purpose
          return 'cors_policy' if has_cors? && !has_security_headers?
          return 'security_policy' if has_security_headers? && !has_cors?
          return 'comprehensive_policy' if has_cors? && has_security_headers?
          return 'custom_headers_policy' if has_custom_headers?
          'basic_policy'
        end
      end

      # Common CloudFront response headers policy configurations
      module CloudFrontResponseHeadersPolicyConfigs
        # Secure web application policy
        def self.secure_web_app_policy(app_name, allowed_origins = ['*'])
          {
            name: "#{app_name.downcase.gsub(/[^a-z0-9]/, '-')}-secure-headers",
            comment: "Secure response headers policy for #{app_name}",
            cors_config: {
              access_control_allow_credentials: false,
              access_control_allow_methods: {
                items: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']
              },
              access_control_allow_origins: {
                items: allowed_origins
              },
              access_control_max_age_sec: 600,
              origin_override: true
            },
            security_headers_config: {
              content_type_options: {
                override: true
              },
              frame_options: {
                frame_option: 'DENY',
                override: true
              },
              referrer_policy: {
                referrer_policy: 'strict-origin-when-cross-origin',
                override: true
              },
              strict_transport_security: {
                access_control_max_age_sec: 31536000,
                include_subdomains: true,
                override: true,
                preload: true
              }
            }
          }
        end

        # API CORS policy
        def self.api_cors_policy(api_name, allowed_origins, allowed_headers = ['Content-Type', 'Authorization'])
          {
            name: "#{api_name.downcase.gsub(/[^a-z0-9]/, '-')}-cors-policy",
            comment: "CORS policy for #{api_name} API",
            cors_config: {
              access_control_allow_credentials: true,
              access_control_allow_headers: {
                items: allowed_headers
              },
              access_control_allow_methods: {
                items: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH']
              },
              access_control_allow_origins: {
                items: allowed_origins
              },
              access_control_expose_headers: {
                items: ['X-Custom-Header', 'X-Request-Id']
              },
              access_control_max_age_sec: 3600,
              origin_override: true
            }
          }
        end

        # Security-only policy
        def self.security_headers_policy(service_name)
          {
            name: "#{service_name.downcase.gsub(/[^a-z0-9]/, '-')}-security-headers",
            comment: "Security headers policy for #{service_name}",
            security_headers_config: {
              content_type_options: {
                override: true
              },
              frame_options: {
                frame_option: 'SAMEORIGIN',
                override: true
              },
              referrer_policy: {
                referrer_policy: 'strict-origin-when-cross-origin',
                override: true
              },
              strict_transport_security: {
                access_control_max_age_sec: 63072000,
                include_subdomains: true,
                override: true
              }
            }
          }
        end

        # Development policy with permissive CORS
        def self.development_policy(project_name)
          {
            name: "#{project_name.downcase.gsub(/[^a-z0-9]/, '-')}-dev-headers",
            comment: "Development headers policy for #{project_name}",
            cors_config: {
              access_control_allow_credentials: true,
              access_control_allow_headers: {
                items: ['*']
              },
              access_control_allow_methods: {
                items: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH', 'HEAD']
              },
              access_control_allow_origins: {
                items: ['*']
              },
              access_control_max_age_sec: 86400,
              origin_override: true
            },
            custom_headers_config: {
              items: [
                {
                  header: 'X-Environment',
                  value: 'development',
                  override: true
                }
              ]
            }
          }
        end
      end
    end
      end
    end
  end
end