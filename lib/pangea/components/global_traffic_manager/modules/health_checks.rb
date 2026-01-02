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
    module GlobalTrafficManager
      # Endpoint health check resources
      module HealthChecks
        def create_health_check_resources(name, attrs, resources, tags)
          health_checks = {}

          attrs.endpoints.each do |endpoint|
            next unless endpoint.health_check_enabled

            health_check_ref = create_endpoint_health_check(name, endpoint, attrs, tags)
            health_checks[endpoint.region.to_sym] = health_check_ref
          end

          resources[:health_checks] = health_checks
        end

        private

        def create_endpoint_health_check(name, endpoint, attrs, tags)
          policy = find_health_check_policy(attrs)

          aws_route53_health_check(
            component_resource_name(name, :health_check, endpoint.region.to_sym),
            build_health_check_config(endpoint, policy, tags)
          )
        end

        def find_health_check_policy(attrs)
          attrs.traffic_policies.find { |p| p.policy_name == attrs.default_policy } ||
            attrs.traffic_policies.first ||
            GlobalTrafficManagerAttributes::TrafficPolicyConfig.new({ policy_name: 'default' })
        end

        def build_health_check_config(endpoint, policy, tags)
          {
            fqdn: endpoint.endpoint_id,
            port: 443,
            type: determine_health_check_type(policy),
            resource_path: determine_resource_path(policy),
            failure_threshold: policy.unhealthy_threshold.to_s,
            request_interval: policy.health_check_interval.to_s,
            measure_latency: true,
            tags: tags.merge(
              Region: endpoint.region,
              EndpointType: endpoint.endpoint_type
            )
          }.compact
        end

        def determine_health_check_type(policy)
          policy.health_check_protocol == 'TCP' ? 'TCP' : policy.health_check_protocol
        end

        def determine_resource_path(policy)
          policy.health_check_protocol != 'TCP' ? policy.health_check_path : nil
        end
      end
    end
  end
end
