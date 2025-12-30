# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # Common Route53 health check configurations
        module Route53HealthCheckConfigs
          def self.http_check(fqdn, port: 80, path: '/', search_string: nil)
            config = {
              type: search_string ? 'HTTP_STR_MATCH' : 'HTTP',
              fqdn: fqdn,
              port: port,
              resource_path: path,
              failure_threshold: 3,
              request_interval: 30
            }
            config[:search_string] = search_string if search_string
            config
          end

          def self.https_check(fqdn, port: 443, path: '/', search_string: nil)
            config = {
              type: search_string ? 'HTTPS_STR_MATCH' : 'HTTPS',
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

          def self.tcp_check(fqdn, port)
            {
              type: 'TCP',
              fqdn: fqdn,
              port: port,
              failure_threshold: 3,
              request_interval: 30
            }
          end

          def self.load_balancer_check(fqdn, port: 443, path: '/health', search_string: 'OK')
            {
              type: 'HTTPS_STR_MATCH',
              fqdn: fqdn,
              port: port,
              resource_path: path,
              search_string: search_string,
              failure_threshold: 3,
              request_interval: 30,
              enable_sni: true
            }
          end

          def self.calculated_check(child_health_check_ids, min_healthy: nil)
            {
              type: 'CALCULATED',
              child_health_checks: child_health_check_ids,
              child_health_threshold: min_healthy || (child_health_check_ids.length / 2).ceil,
              failure_threshold: 1,
              invert_healthcheck: false
            }
          end

          def self.cloudwatch_check(alarm_name, region, insufficient_data_status: 'LastKnownStatus')
            {
              type: 'CLOUDWATCH_METRIC',
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
