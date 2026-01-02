# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS CloudFront Response Headers Policy resources
        class CloudFrontResponseHeadersPolicyAttributes < Dry::Struct
          attribute :name, Resources::Types::String
          attribute :comment, Resources::Types::String.optional

          attribute :cors_config, Resources::Types::Hash.schema(
            access_control_allow_credentials: Types::Bool.default(false),
            access_control_allow_headers?: Types::Hash.schema(items: Types::Array.of(Types::String)).optional,
            access_control_allow_methods: Types::Hash.schema(items: Types::Array.of(Types::String.enum('GET', 'POST', 'PUT', 'DELETE', 'HEAD', 'OPTIONS', 'PATCH'))),
            access_control_allow_origins: Types::Hash.schema(items: Types::Array.of(Types::String)),
            access_control_expose_headers?: Types::Hash.schema(items: Types::Array.of(Types::String)).optional,
            access_control_max_age_sec?: Types::Integer.optional,
            origin_override: Types::Bool.default(true)
          ).optional

          attribute :custom_headers_config, Resources::Types::Hash.schema(
            items?: Types::Array.of(Types::Hash.schema(header: Types::String, value: Types::String, override: Types::Bool.default(true))).optional
          ).optional

          attribute :remove_headers_config, Resources::Types::Hash.schema(
            items: Types::Array.of(Types::Hash.schema(header: Types::String))
          ).optional

          attribute :security_headers_config, Resources::Types::Hash.schema(
            content_type_options?: Types::Hash.schema(override: Types::Bool.default(true)).optional,
            frame_options?: Types::Hash.schema(frame_option: Types::String.enum('DENY', 'SAMEORIGIN'), override: Types::Bool.default(true)).optional,
            referrer_policy?: Types::Hash.schema(referrer_policy: Types::String.enum('no-referrer', 'no-referrer-when-downgrade', 'origin', 'origin-when-cross-origin', 'same-origin', 'strict-origin', 'strict-origin-when-cross-origin', 'unsafe-url'), override: Types::Bool.default(true)).optional,
            strict_transport_security?: Types::Hash.schema(access_control_max_age_sec: Types::Integer, include_subdomains?: Types::Bool.default(false).optional, override: Types::Bool.default(true), preload?: Types::Bool.default(false).optional).optional
          ).optional

          attribute :server_timing_headers_config, Resources::Types::Hash.schema(
            enabled: Types::Bool.default(false),
            sampling_rate?: Types::Coercible::Float.constrained(gteq: 0.0, lteq: 1.0).optional
          ).optional

          def self.new(attributes = {})
            attrs = super(attributes)
            validate_name!(attrs)
            raise Dry::Struct::Error, 'Response headers policy must have at least one header configuration' unless attrs.has_any_configuration?

            validate_cors_origins!(attrs)
            validate_custom_headers!(attrs)
            attrs = set_default_comment(attrs)
            attrs
          end

          def self.validate_name!(attrs)
            return if attrs.name.match?(/\A[a-zA-Z0-9\-_]{1,128}\z/)

            raise Dry::Struct::Error, 'Response headers policy name must be 1-128 characters and contain only alphanumeric, hyphens, and underscores'
          end

          def self.validate_cors_origins!(attrs)
            return unless attrs.cors_config&.dig(:access_control_allow_origins)

            attrs.cors_config[:access_control_allow_origins][:items].each do |origin|
              next if origin == '*' || origin.match?(/\Ahttps?:\/\/.+/) || origin.match?(/\A[a-zA-Z0-9\.\-]+\z/)

              raise Dry::Struct::Error, "Invalid CORS origin format: #{origin}"
            end
          end

          def self.validate_custom_headers!(attrs)
            return unless attrs.custom_headers_config&.dig(:items)

            attrs.custom_headers_config[:items].each do |header|
              raise Dry::Struct::Error, "Invalid custom header name: #{header[:header]}" unless header[:header].match?(/\A[a-zA-Z0-9\-_]+\z/)
            end
          end

          def self.set_default_comment(attrs)
            return attrs if attrs.comment

            config_types = []
            config_types << 'CORS' if attrs.cors_config
            config_types << 'Security' if attrs.security_headers_config
            config_types << 'Custom' if attrs.custom_headers_config
            attrs.copy_with(comment: "Response headers policy for #{config_types.join(', ')} headers")
          end

          def has_any_configuration?
            cors_config || custom_headers_config || remove_headers_config || security_headers_config || server_timing_headers_config
          end

          def has_cors? = !!cors_config
          def has_security_headers? = !!security_headers_config
          def has_custom_headers? = !!(custom_headers_config&.dig(:items)&.any?)
          def has_remove_headers? = !!(remove_headers_config&.dig(:items)&.any?)
          def cors_allows_credentials? = cors_config&.dig(:access_control_allow_credentials) == true
          def cors_allows_all_origins? = cors_config&.dig(:access_control_allow_origins, :items)&.include?('*')
          def hsts_enabled? = security_headers_config&.dig(:strict_transport_security).present?
          def frame_options_enabled? = security_headers_config&.dig(:frame_options).present?
          def estimated_monthly_cost = '$0.10 per 10,000 requests with response headers policy'

          def validate_configuration
            warnings = []
            warnings << 'CORS credentials with wildcard origins is not allowed by browsers' if cors_allows_credentials? && cors_allows_all_origins?
            warnings << 'CORS configuration should typically include OPTIONS method' if has_cors? && !cors_config[:access_control_allow_methods][:items].include?('OPTIONS')
            warnings << 'HSTS with wildcard CORS origins may cause unexpected behavior' if hsts_enabled? && cors_allows_all_origins?
            warnings << 'Server timing enabled without sampling rate - consider setting sampling rate' if server_timing_headers_config&.dig(:enabled) && server_timing_headers_config[:sampling_rate].nil?
            warnings << 'No security headers configured - consider adding security headers for protection' unless has_security_headers?
            warnings
          end

          def security_level
            score = 0
            score += 1 if hsts_enabled?
            score += 1 if frame_options_enabled?
            score += 1 if security_headers_config&.dig(:content_type_options)
            score += 1 if security_headers_config&.dig(:referrer_policy)

            case score
            when 3..4 then 'high'
            when 1..2 then 'medium'
            else 'basic'
            end
          end

          def complexity_level
            config_count = [has_cors?, has_security_headers?, has_custom_headers?, has_remove_headers?].count(true)

            case config_count
            when 1 then 'simple'
            when 2..3 then 'moderate'
            else 'complex'
            end
          end

          def production_ready? = has_security_headers? && security_level != 'basic'

          def primary_purpose
            return 'cors_policy' if has_cors? && !has_security_headers?
            return 'security_policy' if has_security_headers? && !has_cors?
            return 'comprehensive_policy' if has_cors? && has_security_headers?
            return 'custom_headers_policy' if has_custom_headers?

            'basic_policy'
          end
        end
      end
    end
  end
end
