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

require 'pangea/components/base'
require 'pangea/components/global_traffic_manager/types'
require 'pangea/resources/aws'
require_relative 'modules/helpers'
require_relative 'modules/accelerator'
require_relative 'modules/cloudfront'
require_relative 'modules/health_checks'
require_relative 'modules/routing'
require_relative 'modules/advanced_routing'
require_relative 'modules/monitoring'
require_relative 'modules/security'
require_relative 'modules/synthetic'
require_relative 'modules/edge_functions'

module Pangea
  module Components
    module GlobalTrafficManager
      include Helpers
      include Accelerator
      include Cloudfront
      include HealthChecks
      include Routing
      include AdvancedRouting
      include Monitoring
      include Security
      include Synthetic
      include EdgeFunctions

      # Intelligent global traffic distribution with multiple routing strategies
      def global_traffic_manager(name, attributes = {})
        attrs = GlobalTrafficManagerAttributes.new(attributes)
        attrs.validate!

        tags = component_tags('GlobalTrafficManager', name, attrs.tags)
        resources = initialize_resources(name, attrs, tags)

        create_global_accelerator_resources(name, attrs, resources, tags)
        create_cloudfront_resources(name, attrs, resources, tags)
        create_health_check_resources(name, attrs, resources, tags)
        create_routing_resources(name, attrs, resources, tags)
        create_advanced_routing_resources(name, attrs, resources, tags)
        create_monitoring_resources(name, attrs, resources, tags)
        create_security_resources(name, attrs, resources, tags)
        create_synthetic_resources(name, attrs, resources, tags)

        create_component_reference('global_traffic_manager', name, attrs.to_h, resources, build_outputs(attrs, resources))
      end

      private

      def initialize_resources(name, attrs, tags)
        hosted_zone_ref = attrs.route53_hosted_zone_ref || aws_route53_zone(
          component_resource_name(name, :hosted_zone),
          { name: attrs.domain_name, comment: "Hosted zone for #{attrs.manager_name}", tags: tags }
        )
        { hosted_zone: hosted_zone_ref, global_accelerator: nil, cloudfront: nil, health_checks: {},
          traffic_policies: {}, geo_routing: {}, monitoring: {}, security: {}, synthetic_monitoring: {},
          advanced_routing: {} }
      end

      def build_outputs(attrs, resources)
        {
          manager_name: attrs.manager_name, domain_name: attrs.domain_name,
          hosted_zone_id: resources[:hosted_zone].zone_id, endpoints: format_endpoints(attrs),
          global_accelerator_dns: resources.dig(:global_accelerator, :accelerator)&.dns_name,
          global_accelerator_ips: extract_global_accelerator_ips(resources[:global_accelerator]),
          cloudfront_distribution_id: resources.dig(:cloudfront, :distribution)&.id,
          cloudfront_domain_name: resources.dig(:cloudfront, :distribution)&.domain_name,
          routing_strategies: extract_routing_strategies(attrs),
          health_check_status: resources[:health_checks].transform_values { |_hc| 'Configured' },
          security_features: extract_security_features(attrs),
          observability_features: extract_observability_features(attrs),
          performance_optimizations: extract_performance_optimizations(attrs),
          estimated_monthly_cost: estimate_traffic_manager_cost(attrs, resources)
        }
      end

      def format_endpoints(attrs)
        attrs.endpoints.map { |e| { region: e.region, endpoint_id: e.endpoint_id, weight: e.weight, enabled: e.enabled } }
      end

      def extract_security_features(attrs)
        [('DDoS Protection' if attrs.security.ddos_protection), ('WAF Enabled' if attrs.security.waf_enabled),
         ('Geo-blocking' if attrs.security.blocked_countries.any?), ('Rate Limiting' if attrs.security.rate_limiting.any?),
         ('IP Allowlist' if attrs.security.ip_allowlist.any?)].compact
      end

      def extract_observability_features(attrs)
        [('CloudWatch Metrics' if attrs.observability.cloudwatch_enabled), ('Flow Logs' if attrs.performance.flow_logs_enabled),
         ('Access Logs' if attrs.observability.access_logs_enabled), ('Distributed Tracing' if attrs.observability.distributed_tracing),
         ('Synthetic Monitoring' if attrs.observability.synthetic_checks.any?),
         ('Real User Monitoring' if attrs.observability.real_user_monitoring)].compact
      end

      def extract_performance_optimizations(attrs)
        [('TCP Optimization' if attrs.performance.tcp_optimization), ('Origin Shield' if attrs.cloudfront.origin_shield_enabled),
         ('Compression' if attrs.cloudfront.compress), ('Multi-CDN' if attrs.enable_multi_cdn)].compact
      end

      include Base
      include Resources::AWS
    end
  end
end
