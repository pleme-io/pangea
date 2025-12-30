# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # Common CloudFront response headers policy configurations
        module CloudFrontResponseHeadersPolicyConfigs
          def self.secure_web_app_policy(app_name, allowed_origins = ['*'])
            {
              name: "#{app_name.downcase.gsub(/[^a-z0-9]/, '-')}-secure-headers",
              comment: "Secure response headers policy for #{app_name}",
              cors_config: {
                access_control_allow_credentials: false,
                access_control_allow_methods: { items: %w[GET POST PUT DELETE OPTIONS] },
                access_control_allow_origins: { items: allowed_origins },
                access_control_max_age_sec: 600,
                origin_override: true
              },
              security_headers_config: {
                content_type_options: { override: true },
                frame_options: { frame_option: 'DENY', override: true },
                referrer_policy: { referrer_policy: 'strict-origin-when-cross-origin', override: true },
                strict_transport_security: { access_control_max_age_sec: 31_536_000, include_subdomains: true, override: true, preload: true }
              }
            }
          end

          def self.api_cors_policy(api_name, allowed_origins, allowed_headers = %w[Content-Type Authorization])
            {
              name: "#{api_name.downcase.gsub(/[^a-z0-9]/, '-')}-cors-policy",
              comment: "CORS policy for #{api_name} API",
              cors_config: {
                access_control_allow_credentials: true,
                access_control_allow_headers: { items: allowed_headers },
                access_control_allow_methods: { items: %w[GET POST PUT DELETE OPTIONS PATCH] },
                access_control_allow_origins: { items: allowed_origins },
                access_control_expose_headers: { items: %w[X-Custom-Header X-Request-Id] },
                access_control_max_age_sec: 3600,
                origin_override: true
              }
            }
          end

          def self.security_headers_policy(service_name)
            {
              name: "#{service_name.downcase.gsub(/[^a-z0-9]/, '-')}-security-headers",
              comment: "Security headers policy for #{service_name}",
              security_headers_config: {
                content_type_options: { override: true },
                frame_options: { frame_option: 'SAMEORIGIN', override: true },
                referrer_policy: { referrer_policy: 'strict-origin-when-cross-origin', override: true },
                strict_transport_security: { access_control_max_age_sec: 63_072_000, include_subdomains: true, override: true }
              }
            }
          end

          def self.development_policy(project_name)
            {
              name: "#{project_name.downcase.gsub(/[^a-z0-9]/, '-')}-dev-headers",
              comment: "Development headers policy for #{project_name}",
              cors_config: {
                access_control_allow_credentials: true,
                access_control_allow_headers: { items: ['*'] },
                access_control_allow_methods: { items: %w[GET POST PUT DELETE OPTIONS PATCH HEAD] },
                access_control_allow_origins: { items: ['*'] },
                access_control_max_age_sec: 86_400,
                origin_override: true
              },
              custom_headers_config: {
                items: [{ header: 'X-Environment', value: 'development', override: true }]
              }
            }
          end
        end
      end
    end
  end
end
