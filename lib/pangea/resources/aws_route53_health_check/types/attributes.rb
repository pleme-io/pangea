# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS Route53 Health Check resources
        class Route53HealthCheckAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Health check type
          attribute :type, Pangea::Resources::Types::String.constrained(included_in: %w[HTTP HTTPS HTTP_STR_MATCH HTTPS_STR_MATCH TCP CALCULATED CLOUDWATCH_METRIC])

          # FQDN to check (required for HTTP/HTTPS/TCP types)
          attribute? :fqdn, Pangea::Resources::Types::String.optional

          # IP address to check (alternative to FQDN)
          attribute? :ip_address, Pangea::Resources::Types::String.optional

          # Port to check (default depends on type)
          attribute? :port, Pangea::Resources::Types::Integer.optional.constrained(gteq: 1, lteq: 65_535)

          # Resource path for HTTP/HTTPS checks
          attribute? :resource_path, Pangea::Resources::Types::String.optional

          # Failure threshold (number of consecutive failures)
          attribute :failure_threshold, Pangea::Resources::Types::Integer.default(3).constrained(gteq: 1, lteq: 10)

          # Request interval in seconds
          attribute :request_interval, Pangea::Resources::Types::Integer.default(30).constrained(included_in: [10, 30])

          # String to search for in HTTP/HTTPS_STR_MATCH
          attribute? :search_string, Pangea::Resources::Types::String.optional

          # Measure latency
          attribute :measure_latency, Pangea::Resources::Types::Bool.default(false)

          # Invert health check status
          attribute :invert_healthcheck, Pangea::Resources::Types::Bool.default(false)

          # Disabled health check
          attribute :disabled, Pangea::Resources::Types::Bool.default(false)

          # Enable SNI for HTTPS checks
          attribute :enable_sni, Pangea::Resources::Types::Bool.default(true)

          # CloudWatch alarm region (for CLOUDWATCH_METRIC type)
          attribute? :cloudwatch_alarm_region, Pangea::Resources::Types::String.optional

          # CloudWatch alarm name (for CLOUDWATCH_METRIC type)
          attribute? :cloudwatch_alarm_name, Pangea::Resources::Types::String.optional

          # Insufficient data health status for CloudWatch
          attribute? :insufficient_data_health_status, Pangea::Resources::Types::String.optional.constrained(included_in: %w[Healthy Unhealthy LastKnownStatus])

          # Child health checks (for CALCULATED type)
          attribute :child_health_checks, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default([].freeze)

          # Minimum healthy children (for CALCULATED type)
          attribute? :child_health_threshold, Pangea::Resources::Types::Integer.optional.constrained(gteq: 0, lteq: 256)

          # Regions for health checking
          attribute :regions, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default([].freeze)

          # Reference name for the health check
          attribute? :reference_name, Pangea::Resources::Types::String.optional

          # Tags to apply to the health check
          attribute :tags, Pangea::Resources::Types::AwsTags.default({}.freeze)

          def self.new(attributes = {})
            attrs = super(attributes)
            validate_type_specific!(attrs)
            validate_formats!(attrs)
            attrs
          end

          def self.validate_type_specific!(attrs)
            case attrs.type
            when 'HTTP', 'HTTPS', 'HTTP_STR_MATCH', 'HTTPS_STR_MATCH'
              validate_http_type!(attrs)
            when 'TCP'
              validate_tcp_type!(attrs)
            when 'CALCULATED'
              validate_calculated_type!(attrs)
            when 'CLOUDWATCH_METRIC'
              validate_cloudwatch_type!(attrs)
            end
          end

          def self.validate_http_type!(attrs)
            raise Dry::Struct::Error, 'HTTP/HTTPS health checks require either fqdn or ip_address' unless attrs.fqdn || attrs.ip_address
            raise Dry::Struct::Error, 'Cannot specify both fqdn and ip_address' if attrs.fqdn && attrs.ip_address
            raise Dry::Struct::Error, "#{attrs.type} requires search_string parameter" if attrs.type.include?('STR_MATCH') && !attrs.search_string
          end

          def self.validate_tcp_type!(attrs)
            raise Dry::Struct::Error, 'TCP health checks require either fqdn or ip_address' unless attrs.fqdn || attrs.ip_address
            raise Dry::Struct::Error, 'Cannot specify both fqdn and ip_address' if attrs.fqdn && attrs.ip_address
            raise Dry::Struct::Error, 'TCP health checks require port parameter' unless attrs.port
            raise Dry::Struct::Error, 'TCP health checks cannot have resource_path or search_string' if attrs.resource_path || attrs.search_string
          end

          def self.validate_calculated_type!(attrs)
            raise Dry::Struct::Error, 'CALCULATED health checks require child_health_checks' if attrs.child_health_checks.empty?
            raise Dry::Struct::Error, 'CALCULATED health checks require child_health_threshold' unless attrs.child_health_threshold
            raise Dry::Struct::Error, 'CALCULATED health checks cannot have endpoint parameters' if attrs.fqdn || attrs.ip_address || attrs.port || attrs.resource_path
          end

          def self.validate_cloudwatch_type!(attrs)
            raise Dry::Struct::Error, 'CLOUDWATCH_METRIC requires cloudwatch_alarm_region and cloudwatch_alarm_name' unless attrs.cloudwatch_alarm_region && attrs.cloudwatch_alarm_name
            raise Dry::Struct::Error, 'CLOUDWATCH_METRIC health checks cannot have endpoint parameters' if attrs.fqdn || attrs.ip_address || attrs.port || attrs.resource_path
          end

          def self.validate_formats!(attrs)
            raise Dry::Struct::Error, "Invalid IP address format: #{attrs.ip_address}" if attrs.ip_address && !attrs.valid_ip_address?
            raise Dry::Struct::Error, "Invalid FQDN format: #{attrs.fqdn}" if attrs.fqdn && !attrs.valid_fqdn?

            attrs.regions.each do |region|
              raise Dry::Struct::Error, "Invalid AWS region: #{region}" unless attrs.valid_aws_region?(region)
            end
          end

          def valid_ip_address?
            ip_address.match?(/\A(?:[0-9]{1,3}\.){3}[0-9]{1,3}\z/) &&
              ip_address.split('.').all? { |octet| (0..255).include?(octet.to_i) }
          end

          def valid_fqdn?
            return false if fqdn.nil? || fqdn.empty?
            return false if fqdn.length > 253

            fqdn.split('.').all? { |label| valid_dns_label?(label) }
          end

          def valid_dns_label?(label)
            return false if label.empty? || label.length > 63
            return false unless label.match?(/\A[a-zA-Z0-9\-]+\z/)
            return false if label.start_with?('-') || label.end_with?('-')

            true
          end

          def valid_aws_region?(region)
            %w[
              us-east-1 us-east-2 us-west-1 us-west-2
              eu-west-1 eu-west-2 eu-west-3 eu-central-1 eu-north-1
              ap-southeast-1 ap-southeast-2 ap-northeast-1 ap-northeast-2
              ap-south-1 ca-central-1 sa-east-1
            ].include?(region)
          end

          def is_endpoint_health_check? = %w[HTTP HTTPS HTTP_STR_MATCH HTTPS_STR_MATCH TCP].include?(type)
          def is_calculated_health_check? = type == 'CALCULATED'
          def is_cloudwatch_health_check? = type == 'CLOUDWATCH_METRIC'
          def requires_endpoint? = is_endpoint_health_check?
          def supports_string_matching? = %w[HTTP_STR_MATCH HTTPS_STR_MATCH].include?(type)
          def supports_ssl? = %w[HTTPS HTTPS_STR_MATCH].include?(type)
          def endpoint_identifier = fqdn || ip_address

          def default_port_for_type
            case type
            when 'HTTPS', 'HTTPS_STR_MATCH' then 443
            when 'HTTP', 'HTTP_STR_MATCH' then 80
            end
          end

          def estimated_monthly_cost
            base_cost = 0.50
            base_cost += 1.00 if measure_latency
            base_cost += 2.00 if request_interval == 10
            "$#{base_cost}/month"
          end

          def validate_configuration
            warnings = []
            warnings << 'Endpoint health check missing target (fqdn or ip_address)' if is_endpoint_health_check? && !fqdn && !ip_address
            warnings << 'String matching health check missing search_string' if supports_string_matching? && !search_string
            warnings << 'Fast interval (10s) with low failure threshold may cause false positives' if request_interval == 10 && failure_threshold < 2
            warnings << 'Health check is disabled and will not perform checks' if disabled
            warnings << 'child_health_threshold exceeds number of child health checks' if is_calculated_health_check? && child_health_threshold > child_health_checks.length
            warnings
          end
        end
      end
    end
  end
end
