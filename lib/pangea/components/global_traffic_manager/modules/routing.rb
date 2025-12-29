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
      # Route53 traffic policies and geo routing resources
      module Routing
        def create_routing_resources(name, attrs, resources, tags)
          create_traffic_policies(name, attrs, resources, tags)
          create_geo_routing(name, attrs, resources, tags)
        end

        private

        def create_traffic_policies(name, attrs, resources, _tags)
          return unless attrs.enable_route53_policies

          policy_resources = {}
          hosted_zone = resources[:hosted_zone]
          health_checks = resources[:health_checks]

          case attrs.default_policy
          when 'latency'
            create_latency_records(name, attrs, hosted_zone, health_checks, policy_resources)
          when 'weighted'
            create_weighted_records(name, attrs, hosted_zone, health_checks, policy_resources)
          when 'geoproximity'
            create_geoproximity_records(name, attrs, hosted_zone, health_checks, policy_resources)
          end

          resources[:traffic_policies] = policy_resources
        end

        def create_latency_records(name, attrs, hosted_zone, health_checks, policy_resources)
          attrs.endpoints.select(&:enabled).each do |endpoint|
            record_ref = create_route53_record(name, attrs, hosted_zone, endpoint, health_checks, :latency)
            policy_resources["latency_#{endpoint.region}".to_sym] = record_ref
          end
        end

        def create_weighted_records(name, attrs, hosted_zone, health_checks, policy_resources)
          attrs.endpoints.select(&:enabled).each do |endpoint|
            record_ref = create_route53_record(name, attrs, hosted_zone, endpoint, health_checks, :weighted)
            policy_resources["weighted_#{endpoint.region}".to_sym] = record_ref
          end
        end

        def create_geoproximity_records(name, attrs, hosted_zone, health_checks, policy_resources)
          attrs.endpoints.select(&:enabled).each do |endpoint|
            record_ref = create_route53_record(name, attrs, hosted_zone, endpoint, health_checks, :geoproximity)
            policy_resources["geoprox_#{endpoint.region}".to_sym] = record_ref
          end
        end

        def create_route53_record(name, attrs, hosted_zone, endpoint, health_checks, policy_type)
          config = build_record_config(attrs, hosted_zone, endpoint, health_checks, policy_type)
          aws_route53_record(
            component_resource_name(name, "route53_#{policy_type}".to_sym, endpoint.region.to_sym),
            config
          )
        end

        def build_record_config(attrs, hosted_zone, endpoint, health_checks, policy_type)
          {
            zone_id: hosted_zone.zone_id,
            name: attrs.domain_name,
            type: 'A',
            set_identifier: "#{endpoint.region}-#{policy_type}",
            alias: {
              name: endpoint.endpoint_id,
              zone_id: get_endpoint_zone_id(endpoint),
              evaluate_target_health: false
            },
            health_check_id: health_checks[endpoint.region.to_sym]&.id
          }.merge(routing_policy_for(attrs, endpoint, policy_type)).compact
        end

        def routing_policy_for(attrs, endpoint, policy_type)
          case policy_type
          when :latency
            { latency_routing_policy: { region: endpoint.region } }
          when :weighted
            { weighted_routing_policy: { weight: endpoint.weight } }
          when :geoproximity
            bias = attrs.geo_routing.bias_adjustments[endpoint.region] || 0
            { geoproximity_routing_policy: { aws_region: endpoint.region, bias: bias } }
          else
            {}
          end
        end

        def create_geo_routing(name, attrs, resources, _tags)
          return unless attrs.geo_routing.enabled

          geo_resources = {}
          create_geo_location_records(name, attrs, resources, geo_resources)
          create_geo_default_record(name, attrs, resources, geo_resources)
          resources[:geo_routing] = geo_resources
        end

        def create_geo_location_records(name, attrs, resources, geo_resources)
          attrs.geo_routing.location_rules.each_with_index do |rule, index|
            endpoint = attrs.endpoints.find { |e| e.region == rule[:endpoint_region] }
            next unless endpoint

            record_ref = aws_route53_record(
              component_resource_name(name, :route53_geo, "rule#{index}".to_sym),
              build_geo_record_config(attrs, resources, rule, endpoint, index)
            )
            geo_resources["geo_rule_#{index}".to_sym] = record_ref
          end
        end

        def build_geo_record_config(attrs, resources, rule, endpoint, index)
          {
            zone_id: resources[:hosted_zone].zone_id,
            name: attrs.domain_name,
            type: 'A',
            set_identifier: "geo-#{rule[:location]}-#{index}",
            alias: {
              name: endpoint.endpoint_id,
              zone_id: get_endpoint_zone_id(endpoint),
              evaluate_target_health: false
            },
            geolocation_routing_policy: parse_geolocation(rule[:location]),
            health_check_id: resources[:health_checks][endpoint.region.to_sym]&.id
          }.compact
        end

        def create_geo_default_record(name, attrs, resources, geo_resources)
          default_endpoint = attrs.endpoints.max_by(&:priority)
          return unless default_endpoint

          default_record_ref = aws_route53_record(
            component_resource_name(name, :route53_geo_default),
            {
              zone_id: resources[:hosted_zone].zone_id,
              name: attrs.domain_name,
              type: 'A',
              set_identifier: 'geo-default',
              alias: {
                name: default_endpoint.endpoint_id,
                zone_id: get_endpoint_zone_id(default_endpoint),
                evaluate_target_health: false
              },
              geolocation_routing_policy: { country_code: '*' },
              health_check_id: resources[:health_checks][default_endpoint.region.to_sym]&.id
            }.compact
          )
          geo_resources[:geo_default] = default_record_ref
        end
      end
    end
  end
end
