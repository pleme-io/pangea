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
        # Type-safe attributes for AWS Route53 Health Check resources
        class Route53HealthCheckAttributes < Dry::Struct
          transform_keys(&:to_sym)
        # Health check type
        attribute :type, Pangea::Resources::Types::String.constrained(included_in: ["HTTP", "HTTPS", "HTTP_STR_MATCH", "HTTPS_STR_MATCH", "TCP", "CALCULATED", "CLOUDWATCH_METRIC"])

        # FQDN to check (required for HTTP/HTTPS/TCP types)
        attribute? :fqdn, Pangea::Resources::Types::String.optional

        # IP address to check (alternative to FQDN)
        attribute? :ip_address, Pangea::Resources::Types::String.optional

        # Port to check (default depends on type)
        attribute? :port, Pangea::Resources::Types::Integer.optional.constrained(gteq: 1, lteq: 65535)

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
        attribute? :insufficient_data_health_status, Pangea::Resources::Types::String.optional.constrained(included_in: ["Healthy", "Unhealthy", "LastKnownStatus"])

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

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Type-specific validations
          case attrs.type
          when "HTTP", "HTTPS", "HTTP_STR_MATCH", "HTTPS_STR_MATCH"
            # Must have either FQDN or IP address
            unless attrs.fqdn || attrs.ip_address
              raise Dry::Struct::Error, "HTTP/HTTPS health checks require either fqdn or ip_address"
            end

            # Cannot have both FQDN and IP address
            if attrs.fqdn && attrs.ip_address
              raise Dry::Struct::Error, "Cannot specify both fqdn and ip_address"
            end

            # String match types require search string
            if attrs.type.include?("STR_MATCH") && !attrs.search_string
              raise Dry::Struct::Error, "#{attrs.type} requires search_string parameter"
            end

            # Set default ports if not specified
            if !attrs.port
              default_port = attrs.type.start_with?("HTTPS") ? 443 : 80
              attrs = attrs.copy_with(port: default_port)
            end

            # Validate resource path format
            if attrs.resource_path && !attrs.resource_path.start_with?('/')
              attrs = attrs.copy_with(resource_path: "/#{attrs.resource_path}")
            end

          when "TCP"
            # Must have either FQDN or IP address
            unless attrs.fqdn || attrs.ip_address
              raise Dry::Struct::Error, "TCP health checks require either fqdn or ip_address"
            end

            # Cannot have both FQDN and IP address
            if attrs.fqdn && attrs.ip_address
              raise Dry::Struct::Error, "Cannot specify both fqdn and ip_address"
            end

            # Must have port
            unless attrs.port
              raise Dry::Struct::Error, "TCP health checks require port parameter"
            end

            # TCP checks cannot have resource_path or search_string
            if attrs.resource_path || attrs.search_string
              raise Dry::Struct::Error, "TCP health checks cannot have resource_path or search_string"
            end

          when "CALCULATED"
            # Must have child health checks
            if attrs.child_health_checks.empty?
              raise Dry::Struct::Error, "CALCULATED health checks require child_health_checks"
            end

            # Must have child threshold
            unless attrs.child_health_threshold
              raise Dry::Struct::Error, "CALCULATED health checks require child_health_threshold"
            end

            # Cannot have endpoint-specific parameters
            if attrs.fqdn || attrs.ip_address || attrs.port || attrs.resource_path
              raise Dry::Struct::Error, "CALCULATED health checks cannot have endpoint parameters"
            end

          when "CLOUDWATCH_METRIC"
            # Must have CloudWatch alarm details
            unless attrs.cloudwatch_alarm_region && attrs.cloudwatch_alarm_name
              raise Dry::Struct::Error, "CLOUDWATCH_METRIC requires cloudwatch_alarm_region and cloudwatch_alarm_name"
            end

            # Cannot have endpoint-specific parameters
            if attrs.fqdn || attrs.ip_address || attrs.port || attrs.resource_path
              raise Dry::Struct::Error, "CLOUDWATCH_METRIC health checks cannot have endpoint parameters"
            end
          end

          # Validate IP address format if provided
          if attrs.ip_address && !attrs.valid_ip_address?
            raise Dry::Struct::Error, "Invalid IP address format: #{attrs.ip_address}"
          end

          # Validate FQDN format if provided
          if attrs.fqdn && !attrs.valid_fqdn?
            raise Dry::Struct::Error, "Invalid FQDN format: #{attrs.fqdn}"
          end

          # Validate regions if provided
          attrs.regions.each do |region|
            unless attrs.valid_aws_region?(region)
              raise Dry::Struct::Error, "Invalid AWS region: #{region}"
            end
          end

          attrs
        end

        # Helper methods
        def valid_ip_address?
          # Simple IPv4 validation
          ip_address.match?(/\A(?:[0-9]{1,3}\.){3}[0-9]{1,3}\z/) &&
            ip_address.split('.').all? { |octet| (0..255).include?(octet.to_i) }
        end

        def valid_fqdn?
          return false if fqdn.nil? || fqdn.empty?
          return false if fqdn.length > 253

          labels = fqdn.split('.')
          labels.all? { |label| valid_dns_label?(label) }
        end

        def valid_dns_label?(label)
          return false if label.empty? || label.length > 63
          return false unless label.match?(/\A[a-zA-Z0-9\-]+\z/)
          return false if label.start_with?('-') || label.end_with?('-')
          true
        end

        def valid_aws_region?(region)
          # Common AWS regions (not exhaustive)
          aws_regions = %w[
            us-east-1 us-east-2 us-west-1 us-west-2
            eu-west-1 eu-west-2 eu-west-3 eu-central-1 eu-north-1
            ap-southeast-1 ap-southeast-2 ap-northeast-1 ap-northeast-2
            ap-south-1 ca-central-1 sa-east-1
          ]
          aws_regions.include?(region)
        end

        def is_endpoint_health_check?
          %w[HTTP HTTPS HTTP_STR_MATCH HTTPS_STR_MATCH TCP].include?(type)
        end

        def is_calculated_health_check?
          type == "CALCULATED"
        end

        def is_cloudwatch_health_check?
          type == "CLOUDWATCH_METRIC"
        end

        def requires_endpoint?
          is_endpoint_health_check?
        end

        def supports_string_matching?
          %w[HTTP_STR_MATCH HTTPS_STR_MATCH].include?(type)
        end

        def supports_ssl?
          %w[HTTPS HTTPS_STR_MATCH].include?(type)
        end

        def endpoint_identifier
          fqdn || ip_address
        end

        def default_port_for_type
          case type
          when "HTTPS", "HTTPS_STR_MATCH"
            443
          when "HTTP", "HTTP_STR_MATCH"
            80
          else
            nil
          end
        end

        # Estimate monthly cost
        def estimated_monthly_cost
          base_cost = 0.50  # $0.50 per health check per month

          # Additional costs for optional features
          if measure_latency
            base_cost += 1.00  # $1.00 additional for latency measurement
          end

          # Request interval affects cost (more frequent = higher cost)
          if request_interval == 10
            base_cost += 2.00  # Fast interval costs more
          end

          "$#{base_cost}/month"
        end

        # Configuration validation warnings
        def validate_configuration
          warnings = []

          if is_endpoint_health_check? && !fqdn && !ip_address
            warnings << "Endpoint health check missing target (fqdn or ip_address)"
          end

          if supports_string_matching? && !search_string
            warnings << "String matching health check missing search_string"
          end

          if request_interval == 10 && failure_threshold < 2
            warnings << "Fast interval (10s) with low failure threshold may cause false positives"
          end

          if disabled
            warnings << "Health check is disabled and will not perform checks"
          end

          if is_calculated_health_check? && child_health_threshold > child_health_checks.length
            warnings << "child_health_threshold exceeds number of child health checks"
          end

          warnings
        end
      end

      # Common Route53 health check configurations
      module Route53HealthCheckConfigs
        # HTTP health check
        def self.http_check(fqdn, port: 80, path: "/", search_string: nil)
          config = {
            type: search_string ? "HTTP_STR_MATCH" : "HTTP",
            fqdn: fqdn,
            port: port,
            resource_path: path,
            failure_threshold: 3,
            request_interval: 30
          }
          config[:search_string] = search_string if search_string
          config
        end

        # HTTPS health check
        def self.https_check(fqdn, port: 443, path: "/", search_string: nil)
          config = {
            type: search_string ? "HTTPS_STR_MATCH" : "HTTPS",
            fqdn: fqdn,
            port: port,
            resource_path: path,
            failure_threshold: 3,
            request_interval: 30,
            enable_sni: true
          }
          config[:search_string] = search_string if search_string
          config
        end

        # TCP health check
        def self.tcp_check(fqdn, port)
          {
            type: "TCP",
            fqdn: fqdn,
            port: port,
            failure_threshold: 3,
            request_interval: 30
          }
        end

        # Load balancer health check (alias-aware)
        def self.load_balancer_check(fqdn, port: 443, path: "/health", search_string: "OK")
          {
            type: "HTTPS_STR_MATCH",
            fqdn: fqdn,
            port: port,
            resource_path: path,
            search_string: search_string,
            failure_threshold: 3,
            request_interval: 30,
            enable_sni: true
          }
        end

        # Calculated health check for multi-endpoint monitoring
        def self.calculated_check(child_health_check_ids, min_healthy: nil)
          {
            type: "CALCULATED",
            child_health_checks: child_health_check_ids,
            child_health_threshold: min_healthy || (child_health_check_ids.length / 2).ceil,
            failure_threshold: 1,
            invert_healthcheck: false
          }
        end

        # CloudWatch alarm health check
        def self.cloudwatch_check(alarm_name, region, insufficient_data_status: "LastKnownStatus")
          {
            type: "CLOUDWATCH_METRIC",
            cloudwatch_alarm_name: alarm_name,
            cloudwatch_alarm_region: region,
            insufficient_data_health_status: insufficient_data_status,
            failure_threshold: 1
          }
        end
      end
      end
    end
  end
end