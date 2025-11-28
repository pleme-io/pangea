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


require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module Cloudflare
      module Types
        # Enabled/disabled enum for redirect options
        CloudflareRedirectOption = Dry::Types['strict.string'].enum(
          'disabled',
          'enabled'
        )

        # Hostname configuration for list items
        class ListItemHostname < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute url_hostname
          #   @return [String] The hostname (e.g., "example.com")
          attribute :url_hostname, Dry::Types['strict.string'].constrained(
            format: /\A[a-z0-9*\-\.]+\z/i
          )
        end

        # Redirect configuration for list items
        class ListItemRedirect < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute source_url
          #   @return [String] The source URL to redirect from
          attribute :source_url, Dry::Types['strict.string'].constrained(min_size: 1)

          # @!attribute target_url
          #   @return [String] The target URL to redirect to
          attribute :target_url, Dry::Types['strict.string'].constrained(min_size: 1)

          # @!attribute status_code
          #   @return [Integer, nil] HTTP status code (301, 302, 307, 308)
          attribute :status_code, Dry::Types['coercible.integer']
            .constrained(included_in: [301, 302, 307, 308])
            .optional
            .default(nil)

          # @!attribute include_subdomains
          #   @return [String, nil] Match subdomains of source URL
          attribute :include_subdomains, CloudflareRedirectOption.optional.default(nil)

          # @!attribute preserve_path_suffix
          #   @return [String, nil] Preserve path suffix in subpath matching
          attribute :preserve_path_suffix, CloudflareRedirectOption.optional.default(nil)

          # @!attribute preserve_query_string
          #   @return [String, nil] Keep query string from request
          attribute :preserve_query_string, CloudflareRedirectOption.optional.default(nil)

          # @!attribute subpath_matching
          #   @return [String, nil] Match subpaths of source URL
          attribute :subpath_matching, CloudflareRedirectOption.optional.default(nil)
        end

        # Type-safe attributes for Cloudflare List Item
        #
        # Items in lists (IP, hostname, ASN, redirect) for use in firewall rules.
        #
        # @example Create IP list item
        #   ListItemAttributes.new(
        #     account_id: "a" * 32,
        #     list_id: "2c0fc9fa937b11eaa1b71c4d701ab86e",
        #     ip: "192.0.2.0/24"
        #   )
        #
        # @example Create redirect list item
        #   ListItemAttributes.new(
        #     account_id: "a" * 32,
        #     list_id: "2c0fc9fa937b11eaa1b71c4d701ab86e",
        #     redirect: {
        #       source_url: "example.com/old",
        #       target_url: "https://example.com/new",
        #       status_code: 301
        #     }
        #   )
        class ListItemAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute account_id
          #   @return [String] The account ID
          attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId

          # @!attribute list_id
          #   @return [String] The list ID this item belongs to
          attribute :list_id, Dry::Types['strict.string'].constrained(
            format: /\A[a-f0-9]{32}\z/
          )

          # @!attribute ip
          #   @return [String, nil] IPv4/IPv6 address or CIDR
          attribute :ip, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute asn
          #   @return [Integer, nil] Autonomous System Number
          attribute :asn, Dry::Types['coercible.integer']
            .constrained(gteq: 0, lteq: 4_294_967_295)
            .optional
            .default(nil)

          # @!attribute hostname
          #   @return [ListItemHostname, nil] Hostname configuration
          attribute :hostname, ListItemHostname.optional.default(nil)

          # @!attribute redirect
          #   @return [ListItemRedirect, nil] Redirect configuration
          attribute :redirect, ListItemRedirect.optional.default(nil)

          # @!attribute comment
          #   @return [String, nil] Informative summary of the item
          attribute :comment, Dry::Types['strict.string'].optional.default(nil)

          # Validate that exactly one item type is specified
          def self.new(attributes)
            attrs = attributes.transform_keys(&:to_sym)
            super(attrs).tap do |instance|
              item_types = [instance.ip, instance.asn, instance.hostname, instance.redirect].compact
              if item_types.empty?
                raise Dry::Struct::Error, "Must specify exactly one of: ip, asn, hostname, redirect"
              elsif item_types.size > 1
                raise Dry::Struct::Error, "Can only specify one of: ip, asn, hostname, redirect"
              end
            end
          end

          # Check if this is an IP item
          # @return [Boolean] true if IP item
          def ip_item?
            !ip.nil?
          end

          # Check if this is an ASN item
          # @return [Boolean] true if ASN item
          def asn_item?
            !asn.nil?
          end

          # Check if this is a hostname item
          # @return [Boolean] true if hostname item
          def hostname_item?
            !hostname.nil?
          end

          # Check if this is a redirect item
          # @return [Boolean] true if redirect item
          def redirect_item?
            !redirect.nil?
          end

          # Get the item type
          # @return [String] The item type: 'ip', 'asn', 'hostname', or 'redirect'
          def item_type
            return 'ip' if ip_item?
            return 'asn' if asn_item?
            return 'hostname' if hostname_item?
            return 'redirect' if redirect_item?
          end
        end
      end
    end
  end
end
