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
require 'pangea/resources/cloudflare_list_item/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare List Item resource module that self-registers
    module CloudflareListItem
      # Create a Cloudflare List Item
      #
      # Items for lists used in firewall rules (IP, hostname, ASN, redirect).
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] List item attributes
      # @option attributes [String] :account_id Account ID (required)
      # @option attributes [String] :list_id List ID to add item to (required)
      # @option attributes [String] :ip IPv4/IPv6 address or CIDR (mutually exclusive)
      # @option attributes [Integer] :asn Autonomous System Number (mutually exclusive)
      # @option attributes [Hash] :hostname Hostname config (mutually exclusive)
      # @option attributes [Hash] :redirect Redirect config (mutually exclusive)
      # @option attributes [String] :comment Descriptive comment
      #
      # @return [ResourceReference] Reference object with outputs
      #
      # @example IP list item
      #   cloudflare_list_item(:blocked_ip, {
      #     account_id: "a" * 32,
      #     list_id: "2c0fc9fa937b11eaa1b71c4d701ab86e",
      #     ip: "192.0.2.0/24",
      #     comment: "Known attacker range"
      #   })
      #
      # @example ASN list item
      #   cloudflare_list_item(:blocked_asn, {
      #     account_id: "a" * 32,
      #     list_id: "2c0fc9fa937b11eaa1b71c4d701ab86e",
      #     asn: 13335,
      #     comment: "Block this ASN"
      #   })
      #
      # @example Hostname list item
      #   cloudflare_list_item(:blocked_host, {
      #     account_id: "a" * 32,
      #     list_id: "2c0fc9fa937b11eaa1b71c4d701ab86e",
      #     hostname: { url_hostname: "evil.example.com" }
      #   })
      #
      # @example Redirect list item
      #   cloudflare_list_item(:redirect, {
      #     account_id: "a" * 32,
      #     list_id: "2c0fc9fa937b11eaa1b71c4d701ab86e",
      #     redirect: {
      #       source_url: "example.com/old",
      #       target_url: "https://example.com/new",
      #       status_code: 301,
      #       preserve_query_string: "enabled"
      #     }
      #   })
      def cloudflare_list_item(name, attributes = {})
        # Validate attributes using dry-struct
        item_attrs = Cloudflare::Types::ListItemAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:cloudflare_list_item, name) do
          account_id item_attrs.account_id
          list_id item_attrs.list_id

          # Add the appropriate item type
          ip item_attrs.ip if item_attrs.ip
          asn item_attrs.asn if item_attrs.asn
          comment item_attrs.comment if item_attrs.comment

          if item_attrs.hostname
            hostname do
              url_hostname item_attrs.hostname.url_hostname
            end
          end

          if item_attrs.redirect
            redirect do
              source_url item_attrs.redirect.source_url
              target_url item_attrs.redirect.target_url
              status_code item_attrs.redirect.status_code if item_attrs.redirect.status_code
              include_subdomains item_attrs.redirect.include_subdomains if item_attrs.redirect.include_subdomains
              preserve_path_suffix item_attrs.redirect.preserve_path_suffix if item_attrs.redirect.preserve_path_suffix
              preserve_query_string item_attrs.redirect.preserve_query_string if item_attrs.redirect.preserve_query_string
              subpath_matching item_attrs.redirect.subpath_matching if item_attrs.redirect.subpath_matching
            end
          end
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_list_item',
          name: name,
          resource_attributes: item_attrs.to_h,
          outputs: {
            id: "${cloudflare_list_item.#{name}.id}",
            item_id: "${cloudflare_list_item.#{name}.id}"
          }
        )
      end
    end

    # Maintain backward compatibility by extending Cloudflare module
    module Cloudflare
      include CloudflareListItem
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
