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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_load_balancer_monitor/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare Load Balancer Monitor resource module
    module CloudflareLoadBalancerMonitor
      # Create a Cloudflare Load Balancer Monitor with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Monitor attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def cloudflare_load_balancer_monitor(name, attributes = {})
        # Validate attributes using dry-struct
        monitor_attrs = Cloudflare::Types::LoadBalancerMonitorAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:cloudflare_load_balancer_monitor, name) do
          account_id monitor_attrs.account_id
          type monitor_attrs.type
          expected_codes monitor_attrs.expected_codes
          __send__(:method_missing, :method, monitor_attrs[:method])  # Use method_missing directly to avoid Object#method
          timeout monitor_attrs.timeout
          path monitor_attrs.path
          interval monitor_attrs.interval
          retries monitor_attrs.retries
          description monitor_attrs.description if monitor_attrs.description
          allow_insecure monitor_attrs.allow_insecure
          follow_redirects monitor_attrs.follow_redirects
          probe_zone monitor_attrs.probe_zone if monitor_attrs.probe_zone

          # Add custom headers as array (terraform-synthesizer handles conversion)
          if monitor_attrs.header.any?
            header monitor_attrs.header.map { |name, values| { name: name, values: values } }
          end
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_load_balancer_monitor',
          name: name,
          resource_attributes: monitor_attrs.to_h,
          outputs: {
            id: "${cloudflare_load_balancer_monitor.#{name}.id}",
            created_on: "${cloudflare_load_balancer_monitor.#{name}.created_on}",
            modified_on: "${cloudflare_load_balancer_monitor.#{name}.modified_on}"
          }
        )
      end
    end

    # Extend Cloudflare module
    module Cloudflare
      include CloudflareLoadBalancerMonitor
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
