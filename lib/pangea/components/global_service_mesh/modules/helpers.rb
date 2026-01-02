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
  module Components
    module GlobalServiceMesh
      # Utility methods for global service mesh component
      module Helpers
        def extract_connectivity_type(attrs)
          types = []

          types << "Transit Gateway" if attrs.cross_region.transit_gateway_enabled
          types << "VPC Peering" if attrs.cross_region.peering_enabled
          types << "PrivateLink" if attrs.cross_region.private_link_enabled
          types << "Inter-region TLS" if attrs.cross_region.inter_region_tls_enabled

          types.join(", ")
        end

        def extract_gateway_endpoints(gateway_resources)
          return {} unless gateway_resources

          endpoints = {}

          if gateway_resources[:nlb]
            endpoints[:load_balancer] = gateway_resources[:nlb].dns_name
          end

          if gateway_resources[:ingress]
            endpoints[:ingress_gateway] = "ingress-gateway.mesh"
          end

          if gateway_resources[:egress]
            endpoints[:egress_gateway] = "egress-gateway.mesh"
          end

          endpoints
        end

        def estimate_service_mesh_cost(attrs, resources)
          cost = 0.0

          # App Mesh costs - virtual nodes and services
          cost += attrs.services.length * 0.50  # $0.50 per virtual node per month
          cost += attrs.services.length * 0.25  # $0.25 per virtual service per month

          # Data processing (estimate 1TB/month across all services)
          cost += 0.005 * 1000  # $0.005 per GB

          # Cloud Map costs
          cost += 1.00  # Namespace
          cost += attrs.services.length * 0.50  # Service discovery registrations

          # Transit Gateway costs for multi-region
          cost += estimate_transit_gateway_cost(attrs)

          # VPC endpoints
          cost += attrs.regions.length * 2 * 7.20  # App Mesh and Cloud Map endpoints

          # Observability costs
          cost += estimate_observability_cost(attrs)

          # Gateway costs (if using NLB)
          if resources[:gateways] && resources[:gateways][:nlb]
            cost += 22.50  # NLB cost
          end

          # Certificate costs for mTLS
          cost += estimate_mtls_cost(attrs)

          cost.round(2)
        end

        private

        def estimate_transit_gateway_cost(attrs)
          return 0.0 unless attrs.cross_region.transit_gateway_enabled && attrs.regions.length > 1

          cost = attrs.regions.length * 36  # $0.05 per hour per TGW
          cost + attrs.regions.length * (attrs.regions.length - 1) * 20  # Attachments
        end

        def estimate_observability_cost(attrs)
          cost = 0.0

          if attrs.observability.xray_enabled
            cost += 5.00  # First million traces
          end

          if attrs.observability.cloudwatch_metrics_enabled
            cost += attrs.services.length * 5 * 0.30  # 5 metrics per service
          end

          if attrs.observability.access_logging_enabled
            cost += attrs.services.length * 10 * 0.50  # 10GB per service
          end

          cost
        end

        def estimate_mtls_cost(attrs)
          return 0.0 unless attrs.security.mtls_enabled

          400.00 + attrs.services.length * 0.75  # ACM Private CA + Certificates
        end

        def build_service_outputs(attrs)
          attrs.services.map do |s|
            {
              name: s.name,
              region: s.region,
              endpoint: "#{s.name}.#{attrs.service_discovery.namespace_name}",
              port: s.port,
              protocol: s.protocol
            }
          end
        end

        def build_security_features(attrs)
          [
            ("mTLS Enabled" if attrs.security.mtls_enabled),
            ("Service Authentication" if attrs.security.service_auth_enabled),
            ("RBAC Enabled" if attrs.security.rbac_enabled),
            ("Encryption in Transit" if attrs.security.encryption_in_transit),
            ("Secrets Manager Integration" if attrs.security.secrets_manager_integration)
          ].compact
        end

        def build_traffic_management_features(attrs)
          [
            ("Circuit Breaker" if attrs.traffic_management.circuit_breaker_enabled),
            ("Outlier Detection" if attrs.traffic_management.outlier_detection_enabled),
            ("Canary Deployments" if attrs.traffic_management.canary_deployments_enabled),
            ("Global Load Balancing" if attrs.enable_global_load_balancing),
            ("Multi-cluster Routing" if attrs.enable_multi_cluster_routing)
          ].compact
        end

        def build_observability_features(attrs)
          [
            ("X-Ray Distributed Tracing" if attrs.observability.xray_enabled),
            ("CloudWatch Metrics" if attrs.observability.cloudwatch_metrics_enabled),
            ("Access Logging" if attrs.observability.access_logging_enabled),
            ("Envoy Stats" if attrs.observability.envoy_stats_enabled),
            ("Custom Metrics" if attrs.observability.custom_metrics_enabled)
          ].compact
        end

        def build_resilience_features(attrs)
          [
            ("Retry Policy" if attrs.resilience.retry_policy_enabled),
            ("Bulkhead Pattern" if attrs.resilience.bulkhead_enabled),
            ("Request Timeout" if attrs.resilience.timeout_enabled),
            ("Chaos Testing" if attrs.resilience.chaos_testing_enabled)
          ].compact
        end
      end
    end
  end
end
