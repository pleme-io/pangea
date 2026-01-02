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
      # Shared helper methods for GlobalTrafficManager components
      module Helpers
        def extract_listener_configs(endpoints)
          configs = []

          endpoints.group_by { |e| [e.endpoint_type, e.metadata[:port] || 443] }.each do |(_, port), _|
            protocol = 'TCP'
            configs << {
              protocol: protocol,
              port_ranges: [{
                from_port: port,
                to_port: port
              }]
            }
          end

          configs.uniq
        end

        def get_endpoint_zone_id(endpoint)
          case endpoint.endpoint_type
          when 'ALB'
            alb_zone_ids = {
              'us-east-1' => 'Z35SXDOTRQ7X7K',
              'us-west-2' => 'Z1H1FL5HABSF5',
              'eu-west-1' => 'Z32O12XQLNTSW2',
              'ap-southeast-1' => 'Z1LMS91P8CMLE5'
            }
            alb_zone_ids[endpoint.region] || 'Z35SXDOTRQ7X7K'
          when 'NLB'
            'Z26RNL4JYFTOTI'
          else
            'Z35SXDOTRQ7X7K'
          end
        end

        def parse_geolocation(location)
          if location.length == 2
            { country_code: location }
          elsif location.start_with?('US-')
            { country_code: 'US', subdivision_code: location.split('-')[1] }
          else
            { continent_code: location }
          end
        end

        def generate_canary_router_code(_config)
          <<~JS
            exports.handler = async (event) => {
              const request = event.Records[0].cf.request;
              const canaryPercentage = parseInt(process.env.CANARY_PERCENTAGE);
              const random = Math.random() * 100;

              if (random < canaryPercentage) {
                request.origin = {
                  custom: {
                    domainName: process.env.CANARY_ENDPOINT,
                    port: 443,
                    protocol: 'https'
                  }
                };
                request.headers['x-deployment-version'] = [{ key: 'X-Deployment-Version', value: 'canary' }];
              } else {
                request.headers['x-deployment-version'] = [{ key: 'X-Deployment-Version', value: 'stable' }];
              }

              return request;
            };
          JS
        end

        def extract_global_accelerator_ips(ga_resources)
          return [] unless ga_resources&.dig(:accelerator)

          ['192.0.2.1', '192.0.2.2']
        end

        def extract_routing_strategies(attrs)
          strategies = []

          strategies << attrs.default_policy.capitalize
          strategies << 'Geo-routing' if attrs.geo_routing.enabled
          strategies << 'Canary Deployment' if attrs.advanced_routing.canary_deployment.any?
          strategies << 'Blue-Green' if attrs.advanced_routing.blue_green_deployment.any?
          strategies << 'Weighted Distribution' if attrs.advanced_routing.weighted_distribution.any?

          strategies
        end

        def estimate_traffic_manager_cost(attrs, _resources)
          cost = 0.0

          cost += calculate_global_accelerator_cost(attrs)
          cost += calculate_cloudfront_cost(attrs)
          cost += calculate_route53_cost(attrs)
          cost += calculate_security_cost(attrs)
          cost += calculate_monitoring_cost(attrs)

          cost.round(2)
        end

        private

        def calculate_global_accelerator_cost(attrs)
          return 0.0 unless attrs.enable_global_accelerator

          hourly_cost = 0.025 * 24 * 30
          data_cost = 0.015 * 1000
          hourly_cost + data_cost
        end

        def calculate_cloudfront_cost(attrs)
          return 0.0 unless attrs.cloudfront.enabled

          data_cost = case attrs.cloudfront.price_class
                      when 'PriceClass_All' then 0.085 * 5000
                      when 'PriceClass_200' then 0.080 * 5000
                      when 'PriceClass_100' then 0.075 * 5000
                      else 0.0
                      end
          request_cost = 0.0075 * 10
          data_cost + request_cost
        end

        def calculate_route53_cost(attrs)
          hosted_zone_cost = 0.50
          health_check_cost = attrs.endpoints.count { |e| e.health_check_enabled } * 0.50
          policy_cost = attrs.enable_route53_policies ? attrs.traffic_policies.length * 50.0 : 0.0
          hosted_zone_cost + health_check_cost + policy_cost
        end

        def calculate_security_cost(attrs)
          waf_cost = attrs.security.waf_enabled ? (5.00 + 1.00 + 0.60 * 10) : 0.0
          shield_cost = attrs.security.ddos_protection ? 3000.0 : 0.0
          waf_cost + shield_cost
        end

        def calculate_monitoring_cost(attrs)
          cw_cost = attrs.observability.cloudwatch_enabled ? 10.0 : 0.0
          synthetic_cost = attrs.observability.synthetic_checks.any? ? attrs.observability.synthetic_checks.length * 8.64 : 0.0
          cw_cost + synthetic_cost
        end
      end
    end
  end
end
