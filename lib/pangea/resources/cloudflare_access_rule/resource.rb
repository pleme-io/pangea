# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_access_rule/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare Access Rule resource module
    module CloudflareAccessRule
      # Create a Cloudflare IP Access Rule
      #
      # Control access based on IP, ASN, or country at zone or account level.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Access rule attributes
      # @return [ResourceReference] Reference object with outputs
      #
      # @example Block IP at zone level
      #   cloudflare_access_rule(:block_bad_ip, {
      #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
      #     mode: "block",
      #     target: "ip",
      #     value: "198.51.100.4"
      #   })
      #
      # @example Whitelist IP range at account level
      #   cloudflare_access_rule(:allow_office, {
      #     account_id: "a" * 32,
      #     mode: "whitelist",
      #     target: "ip_range",
      #     value: "192.0.2.0/24",
      #     notes: "Office IP range"
      #   })
      def cloudflare_access_rule(name, attributes = {})
        rule_attrs = Cloudflare::Types::AccessRuleAttributes.new(attributes)

        resource(:cloudflare_access_rule, name) do
          zone_id rule_attrs.zone_id if rule_attrs.zone_id
          account_id rule_attrs.account_id if rule_attrs.account_id
          mode rule_attrs.mode

          configuration do
            target rule_attrs.target
            value rule_attrs.value
          end

          notes rule_attrs.notes if rule_attrs.notes
        end

        ResourceReference.new(
          type: 'cloudflare_access_rule',
          name: name,
          resource_attributes: rule_attrs.to_h,
          outputs: {
            id: "${cloudflare_access_rule.#{name}.id}",
            rule_id: "${cloudflare_access_rule.#{name}.id}"
          }
        )
      end
    end

    module Cloudflare
      include CloudflareAccessRule
    end
  end
end

Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
