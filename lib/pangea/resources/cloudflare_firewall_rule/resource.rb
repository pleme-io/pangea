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
require 'pangea/resources/cloudflare_firewall_rule/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare Firewall Rule resource module
    module CloudflareFirewallRule
      # Create a Cloudflare Firewall Rule with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Firewall rule attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def cloudflare_firewall_rule(name, attributes = {})
        # Validate attributes using dry-struct
        rule_attrs = Cloudflare::Types::FirewallRuleAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:cloudflare_firewall_rule, name) do
          zone_id rule_attrs.zone_id
          filter_id rule_attrs.filter_id
          action rule_attrs.action
          description rule_attrs.description if rule_attrs.description
          priority rule_attrs.priority if rule_attrs.priority
          paused rule_attrs.paused

          # Add products for bypass action
          if rule_attrs.products.any?
            products rule_attrs.products
          end
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_firewall_rule',
          name: name,
          resource_attributes: rule_attrs.to_h,
          outputs: {
            id: "${cloudflare_firewall_rule.#{name}.id}"
          }
        )
      end
    end

    # Extend Cloudflare module
    module Cloudflare
      include CloudflareFirewallRule
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
