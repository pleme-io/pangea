# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module Cloudflare
      module Types
        # List kind enum
        CloudflareListKind = Dry::Types['strict.string'].enum('ip', 'redirect', 'hostname', 'asn')

        # Type-safe attributes for Cloudflare List
        class ListAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute account_id
          #   @return [String] Account ID
          attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId

          # @!attribute name
          #   @return [String] List name
          attribute :name, Dry::Types['strict.string'].constrained(min_size: 1, max_size: 50)

          # @!attribute kind
          #   @return [String] List type (ip, redirect, hostname, asn)
          attribute :kind, CloudflareListKind

          # @!attribute description
          #   @return [String, nil] List description
          attribute :description, Dry::Types['strict.string'].optional.default(nil)

          # Check if this is an IP list
          # @return [Boolean] true if kind is ip
          def ip_list?
            kind == 'ip'
          end

          # Check if this is a redirect list
          # @return [Boolean] true if kind is redirect
          def redirect_list?
            kind == 'redirect'
          end
        end
      end
    end
  end
end
