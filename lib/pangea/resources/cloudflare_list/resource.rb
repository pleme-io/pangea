# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_list/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare List resource module
    module CloudflareList
      # Create a Cloudflare List
      #
      # Lists store IP addresses, hostnames, ASNs, or redirects for use in
      # firewall rules, rate limiting, and other security features.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] List attributes
      # @return [ResourceReference] Reference object with outputs
      #
      # @example Create IP list
      #   cloudflare_list(:blocked_ips, {
      #     account_id: "a" * 32,
      #     name: "blocked_ips",
      #     kind: "ip",
      #     description: "Blocked IP addresses"
      #   })
      def cloudflare_list(name, attributes = {})
        list_attrs = Cloudflare::Types::ListAttributes.new(attributes)

        resource(:cloudflare_list, name) do
          account_id list_attrs.account_id
          name list_attrs.name
          kind list_attrs.kind
          description list_attrs.description if list_attrs.description
        end

        ResourceReference.new(
          type: 'cloudflare_list',
          name: name,
          resource_attributes: list_attrs.to_h,
          outputs: {
            id: "${cloudflare_list.#{name}.id}",
            list_id: "${cloudflare_list.#{name}.id}"
          }
        )
      end
    end

    module Cloudflare
      include CloudflareList
    end
  end
end

Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
