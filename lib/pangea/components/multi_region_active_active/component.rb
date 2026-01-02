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
require 'pangea/components/multi_region_active_active/types'
require 'pangea/resources/aws'
require_relative 'modules/helpers'
require_relative 'modules/dynamodb'
require_relative 'modules/aurora'
require_relative 'modules/applications'
require_relative 'modules/networking'
require_relative 'modules/routing'
require_relative 'modules/monitoring'
require_relative 'modules/chaos'

module Pangea
  module Components
    module MultiRegionActiveActive
      include Helpers
      include DynamoDB
      include Aurora
      include Applications
      include Networking
      include Routing
      include Monitoring
      include Chaos

      # Multi-region active-active infrastructure with data consistency management
      def multi_region_active_active(name, attributes = {})
        include Base
        include Resources::AWS

        attrs = MultiRegionActiveActiveAttributes.new(attributes)
        attrs.validate!

        tags = component_tags('MultiRegionActiveActive', name, attrs.tags)
        resources = { regional: {} }

        resources[:hosted_zone] = create_hosted_zone(name, attrs, tags)
        resources[:global_database] = create_global_database(name, attrs, tags)
        resources.merge!(create_global_accelerator_resources(name, attrs, tags))

        regional_endpoints = process_regions(name, attrs, resources, tags)
        finalize_global_resources(name, attrs, resources, regional_endpoints, tags)

        create_component_reference('multi_region_active_active', name, attrs.to_h, resources,
                                   build_component_outputs(attrs, resources, regional_endpoints))
      end

      private

      def create_hosted_zone(name, attrs, tags)
        aws_route53_zone(component_resource_name(name, :hosted_zone),
                         { name: attrs.domain_name, comment: "Multi-region deployment for #{attrs.deployment_name}",
                           tags: tags.merge(GlobalDeployment: 'true') })
      end

      def create_global_database(name, attrs, tags)
        case attrs.global_database.engine
        when 'dynamodb' then create_dynamodb_global_table(name, attrs, tags)
        when 'aurora-mysql', 'aurora-postgresql' then create_aurora_global_cluster(name, attrs, tags)
        end
      end

      def create_global_accelerator_resources(name, attrs, tags)
        return {} unless attrs.enable_global_accelerator

        ga = create_global_accelerator(name, attrs, tags)
        { global_accelerator: ga[:accelerator], ga_listener: ga[:listener] }
      end

      def process_regions(name, attrs, resources, tags)
        attrs.regions.each_with_index.map do |region_config, index|
          region_resources = create_region_resources(name, region_config, attrs, resources, index, tags)
          resources[:regional][region_config.region.to_sym] = region_resources
          build_endpoint(attrs, region_config, region_resources)
        end.compact
      end

      def create_region_resources(name, region_config, attrs, resources, index, tags)
        r = { vpc: create_regional_vpc(name, region_config, tags) }
        r[:subnets] = create_regional_subnets(name, region_config, r[:vpc], tags)
        create_database_resources(name, region_config, attrs, resources, r, tags)
        create_app_resources(name, region_config, attrs, r, tags)
        create_network_resources(name, region_config, attrs, r, index, tags)
        r[:monitoring] = create_regional_monitoring(name, region_config, attrs, r, tags) if attrs.monitoring.enabled
        r
      end

      def create_database_resources(name, region_config, attrs, resources, r, tags)
        return unless attrs.global_database.engine.start_with?('aurora')

        r[:regional_cluster] = create_regional_aurora_cluster(name, region_config, attrs, resources[:global_database], r[:subnets], tags)
      end

      def create_app_resources(name, region_config, attrs, r, tags)
        return unless attrs.application

        r[:application] = create_regional_application(name, region_config, attrs, r[:vpc], r[:subnets], tags)
        r[:health_check] = aws_route53_health_check(
          component_resource_name(name, :health_check, region_config.region.to_sym),
          { fqdn: r[:application][:load_balancer].dns_name, port: attrs.application.port,
            type: attrs.application.protocol == 'HTTPS' ? 'HTTPS' : 'HTTP',
            resource_path: attrs.application.health_check_path,
            failure_threshold: attrs.failover.unhealthy_threshold.to_s,
            request_interval: attrs.failover.health_check_interval.to_s, tags: { Region: region_config.region } }
        )
      end

      def create_network_resources(name, region_config, attrs, r, index, tags)
        return unless attrs.regions.length > 1

        r[:transit_gateway] = create_transit_gateway(name, region_config, index, tags)
        r[:tgw_attachment] = create_transit_gateway_attachment(name, region_config, r[:transit_gateway], r[:vpc], r[:subnets], tags)
      end

      def build_endpoint(attrs, region_config, region_resources)
        return nil unless attrs.application && region_resources[:application]

        { region: region_config.region, endpoint: region_resources[:application][:load_balancer].dns_name,
          health_check_id: region_resources[:health_check].id, weight: region_config.write_weight }
      end

      def finalize_global_resources(name, attrs, resources, regional_endpoints, tags)
        resources[:peering] = create_transit_gateway_peering(name, attrs, resources[:regional], tags) if attrs.regions.length > 1
        resources[:traffic_routing] = create_global_traffic_routing(name, attrs, resources[:hosted_zone], regional_endpoints, resources[:ga_listener], tags) if regional_endpoints.any?
        resources[:global_dashboard] = create_global_dashboard(name, attrs, resources, tags) if attrs.monitoring.cross_region_dashboard
        resources[:chaos_engineering] = create_chaos_experiments(name, attrs, resources, tags) if attrs.enable_chaos_engineering
      end

      include Base
    end
  end
end
