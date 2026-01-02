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
      # Global Accelerator resources
      module Accelerator
        def create_global_accelerator_resources(name, attrs, resources, tags)
          return unless attrs.enable_global_accelerator

          resources[:global_accelerator] = create_global_accelerator(name, attrs, tags)
        end

        private

        def create_global_accelerator(name, attrs, tags)
          ga_resources = {}

          accelerator_ref = create_accelerator(name, attrs, tags)
          ga_resources[:accelerator] = accelerator_ref

          create_listeners_and_endpoint_groups(name, attrs, accelerator_ref, ga_resources)

          ga_resources
        end

        def create_accelerator(name, attrs, tags)
          aws_globalaccelerator_accelerator(
            component_resource_name(name, :accelerator),
            {
              name: "#{name}-global-accelerator",
              ip_address_type: 'IPV4',
              enabled: true,
              attributes: attrs.global_accelerator_attributes.merge({
                flow_logs_enabled: attrs.performance.flow_logs_enabled,
                flow_logs_s3_bucket: attrs.performance.flow_logs_s3_bucket,
                flow_logs_s3_prefix: "#{attrs.performance.flow_logs_s3_prefix}global-accelerator/"
              }).compact,
              tags: tags
            }
          )
        end

        def create_listeners_and_endpoint_groups(name, attrs, accelerator_ref, ga_resources)
          listener_configs = extract_listener_configs(attrs.endpoints)

          listener_configs.each do |config|
            listener_ref = create_listener(name, attrs, accelerator_ref, config)
            ga_resources["listener_#{config[:protocol].downcase}".to_sym] = listener_ref

            create_endpoint_groups_for_listener(name, attrs, listener_ref, config, ga_resources)
          end
        end

        def create_listener(name, attrs, accelerator_ref, config)
          aws_globalaccelerator_listener(
            component_resource_name(name, :ga_listener, config[:protocol].downcase.to_sym),
            {
              accelerator_arn: accelerator_ref.arn,
              client_affinity: attrs.advanced_routing.weighted_distribution.any? ? 'SOURCE_IP' : 'NONE',
              protocol: config[:protocol],
              port_ranges: config[:port_ranges]
            }
          )
        end

        def create_endpoint_groups_for_listener(name, attrs, listener_ref, config, ga_resources)
          attrs.endpoints.group_by(&:region).each do |region, region_endpoints|
            endpoint_group_ref = create_endpoint_group(name, attrs, listener_ref, config, region, region_endpoints)
            ga_resources["endpoint_group_#{config[:protocol].downcase}_#{region}".to_sym] = endpoint_group_ref
          end
        end

        def create_endpoint_group(name, attrs, listener_ref, config, region, region_endpoints)
          aws_globalaccelerator_endpoint_group(
            component_resource_name(name, :ga_endpoint_group, "#{config[:protocol].downcase}_#{region}".to_sym),
            {
              listener_arn: listener_ref.arn,
              endpoint_group_region: region,
              traffic_dial_percentage: attrs.advanced_routing.traffic_dials[region] || 100.0,
              health_check_interval_seconds: 30,
              health_check_path: attrs.traffic_policies.first&.health_check_path || '/health',
              health_check_port: config[:port_ranges].first[:from_port],
              health_check_protocol: config[:protocol],
              threshold_count: 3,
              endpoint_configuration: region_endpoints.map do |endpoint|
                {
                  endpoint_id: endpoint.endpoint_id,
                  weight: endpoint.weight,
                  client_ip_preservation_enabled: endpoint.client_ip_preservation
                }
              end
            }
          )
        end
      end
    end
  end
end
