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
    module MultiRegionActiveActive
      # Global traffic routing: Global Accelerator, Route 53 records
      module Routing
        def create_global_accelerator(name, attrs, tags)
          accelerator = aws_globalaccelerator_accelerator(
            component_resource_name(name, :global_accelerator),
            build_accelerator_config(name, attrs, tags)
          )

          listener = create_accelerator_listener(name, attrs, accelerator)

          { accelerator: accelerator, listener: listener }
        end

        def create_global_traffic_routing(name, attrs, hosted_zone, endpoints, ga_listener, tags)
          routing_resources = {}

          create_global_accelerator_endpoints(name, attrs, endpoints, ga_listener, routing_resources) if attrs.enable_global_accelerator && ga_listener
          create_route53_routing(name, attrs, hosted_zone, endpoints, routing_resources)

          routing_resources
        end

        private

        def build_accelerator_config(name, attrs, tags)
          {
            name: "#{name}-accelerator",
            ip_address_type: 'IPV4',
            enabled: true,
            attributes: {
              flow_logs_enabled: attrs.monitoring.enabled,
              flow_logs_s3_bucket: attrs.monitoring.enabled ? "#{name}-flow-logs" : nil,
              flow_logs_s3_prefix: 'global-accelerator/'
            },
            tags: tags
          }
        end

        def create_accelerator_listener(name, attrs, accelerator)
          aws_globalaccelerator_listener(
            component_resource_name(name, :ga_listener),
            {
              accelerator_arn: accelerator.arn,
              client_affinity: attrs.traffic_routing.sticky_sessions ? 'SOURCE_IP' : 'NONE',
              protocol: attrs.application ? attrs.application.protocol : 'TCP',
              port_ranges: [{
                from_port: attrs.application ? attrs.application.port : 443,
                to_port: attrs.application ? attrs.application.port : 443
              }]
            }
          )
        end

        def create_global_accelerator_endpoints(name, attrs, endpoints, ga_listener, routing_resources)
          endpoints.each do |endpoint|
            endpoint_group_ref = aws_globalaccelerator_endpoint_group(
              component_resource_name(name, :ga_endpoint_group, endpoint[:region].to_sym),
              build_endpoint_group_config(attrs, ga_listener, endpoint)
            )
            routing_resources["ga_endpoint_#{endpoint[:region]}".to_sym] = endpoint_group_ref
          end
        end

        def build_endpoint_group_config(attrs, ga_listener, endpoint)
          {
            listener_arn: ga_listener.arn,
            endpoint_group_region: endpoint[:region],
            endpoint_configuration: [{
              endpoint_id: endpoint[:endpoint],
              weight: endpoint[:weight],
              client_ip_preservation_enabled: false
            }],
            health_check_interval_seconds: attrs.failover.health_check_interval,
            health_check_path: attrs.application.health_check_path,
            health_check_port: attrs.application.port,
            health_check_protocol: attrs.application.protocol,
            threshold_count: attrs.failover.unhealthy_threshold
          }
        end

        def create_route53_routing(name, attrs, hosted_zone, endpoints, routing_resources)
          case attrs.traffic_routing.routing_policy
          when 'latency'
            create_latency_routing(name, attrs, hosted_zone, endpoints, routing_resources)
          when 'weighted'
            create_weighted_routing(name, attrs, hosted_zone, endpoints, routing_resources)
          when 'failover'
            create_failover_routing(name, attrs, hosted_zone, endpoints, routing_resources)
          end
        end

        def create_latency_routing(name, attrs, hosted_zone, endpoints, routing_resources)
          endpoints.each do |endpoint|
            record_ref = aws_route53_record(
              component_resource_name(name, :route53_record, endpoint[:region].to_sym),
              build_route53_record_config(attrs, hosted_zone, endpoint).merge(
                latency_routing_policy: { region: endpoint[:region] }
              )
            )
            routing_resources["route53_#{endpoint[:region]}".to_sym] = record_ref
          end
        end

        def create_weighted_routing(name, attrs, hosted_zone, endpoints, routing_resources)
          endpoints.each do |endpoint|
            record_ref = aws_route53_record(
              component_resource_name(name, :route53_record, endpoint[:region].to_sym),
              build_route53_record_config(attrs, hosted_zone, endpoint).merge(
                weighted_routing_policy: { weight: endpoint[:weight] }
              )
            )
            routing_resources["route53_#{endpoint[:region]}".to_sym] = record_ref
          end
        end

        def create_failover_routing(name, attrs, hosted_zone, endpoints, routing_resources)
          primary_endpoint = endpoints.find { |e| attrs.regions.find { |r| r.region == e[:region] }&.is_primary }
          secondary_endpoints = endpoints.reject { |e| e == primary_endpoint }

          create_primary_record(name, attrs, hosted_zone, primary_endpoint, routing_resources) if primary_endpoint
          create_secondary_record(name, attrs, hosted_zone, secondary_endpoints.first, routing_resources) if secondary_endpoints.any?
        end

        def build_route53_record_config(attrs, hosted_zone, endpoint)
          {
            zone_id: hosted_zone.zone_id,
            name: attrs.domain_name,
            type: 'A',
            set_identifier: endpoint[:region],
            alias: { name: endpoint[:endpoint], zone_id: 'Z35SXDOTRQ7X7K', evaluate_target_health: true },
            health_check_id: endpoint[:health_check_id]
          }
        end

        def create_primary_record(name, attrs, hosted_zone, endpoint, routing_resources)
          routing_resources[:route53_primary] = aws_route53_record(
            component_resource_name(name, :route53_record_primary),
            {
              zone_id: hosted_zone.zone_id,
              name: attrs.domain_name,
              type: 'A',
              set_identifier: 'Primary',
              alias: { name: endpoint[:endpoint], zone_id: 'Z35SXDOTRQ7X7K', evaluate_target_health: true },
              failover_routing_policy: { type: 'PRIMARY' },
              health_check_id: endpoint[:health_check_id]
            }
          )
        end

        def create_secondary_record(name, attrs, hosted_zone, endpoint, routing_resources)
          routing_resources[:route53_secondary] = aws_route53_record(
            component_resource_name(name, :route53_record_secondary),
            {
              zone_id: hosted_zone.zone_id,
              name: attrs.domain_name,
              type: 'A',
              set_identifier: 'Secondary',
              alias: { name: endpoint[:endpoint], zone_id: 'Z35SXDOTRQ7X7K', evaluate_target_health: true },
              failover_routing_policy: { type: 'SECONDARY' },
              health_check_id: endpoint[:health_check_id]
            }
          )
        end
      end
    end
  end
end
