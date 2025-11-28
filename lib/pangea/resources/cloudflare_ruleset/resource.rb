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
require 'pangea/resources/cloudflare_ruleset/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare Ruleset resource module that self-registers
    module CloudflareRuleset
      # Create a Cloudflare Ruleset
      #
      # Rulesets are the modern way to configure security, performance,
      # and transformation rules in Cloudflare. They replace legacy systems
      # like firewall rules and page rules.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Ruleset attributes
      # @option attributes [String] :zone_id Zone ID (mutually exclusive with account_id)
      # @option attributes [String] :account_id Account ID (mutually exclusive with zone_id)
      # @option attributes [String] :name Ruleset name (required)
      # @option attributes [String] :description Ruleset description
      # @option attributes [String] :kind Ruleset kind (required)
      # @option attributes [String] :phase Ruleset phase (required)
      # @option attributes [Array<Hash>] :rules Rules configuration (required)
      #
      # @return [ResourceReference] Reference object with outputs
      #
      # @example Custom WAF ruleset
      #   cloudflare_ruleset(:waf_custom, {
      #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
      #     name: "Custom WAF Rules",
      #     description: "Block malicious traffic",
      #     kind: "zone",
      #     phase: "http_request_firewall_custom",
      #     rules: [{
      #       expression: '(ip.src eq 192.0.2.1)',
      #       action: "block",
      #       description: "Block specific IP"
      #     }]
      #   })
      #
      # @example Rate limiting ruleset
      #   cloudflare_ruleset(:rate_limit, {
      #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
      #     name: "API Rate Limiting",
      #     kind: "zone",
      #     phase: "http_ratelimit",
      #     rules: [{
      #       expression: '(http.request.uri.path matches "^/api/")',
      #       action: "block",
      #       ratelimit: {
      #         characteristics: ["cf.colo.id", "ip.src"],
      #         period: 10,
      #         requests_per_period: 100
      #       }
      #     }]
      #   })
      def cloudflare_ruleset(name, attributes = {})
        # Validate attributes using dry-struct
        ruleset_attrs = Cloudflare::Types::RulesetAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:cloudflare_ruleset, name) do
          zone_id ruleset_attrs.zone_id if ruleset_attrs.zone_id
          account_id ruleset_attrs.account_id if ruleset_attrs.account_id
          name ruleset_attrs.name
          description ruleset_attrs.description if ruleset_attrs.description
          kind ruleset_attrs.kind
          phase ruleset_attrs.phase

          # Generate rules as array (terraform-synthesizer handles array → blocks conversion)
          if ruleset_attrs.rules.any?
            rules ruleset_attrs.rules.map { |r| r.to_h }
          end
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_ruleset',
          name: name,
          resource_attributes: ruleset_attrs.to_h,
          outputs: {
            id: "${cloudflare_ruleset.#{name}.id}"
          }
        )
      end
    end

    # Maintain backward compatibility by extending Cloudflare module
    module Cloudflare
      include CloudflareRuleset
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
