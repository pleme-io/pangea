# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module Cloudflare
      module Types
        # Access rule mode enum
        CloudflareAccessRuleMode = Dry::Types['strict.string'].enum(
          'block',
          'challenge',
          'whitelist',
          'js_challenge',
          'managed_challenge'
        )

        # Access rule target enum
        CloudflareAccessRuleTarget = Dry::Types['strict.string'].enum(
          'ip',
          'ip6',
          'ip_range',
          'asn',
          'country'
        )

        # Type-safe attributes for Cloudflare Access Rule
        class AccessRuleAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute zone_id
          #   @return [String, nil] Zone ID (mutually exclusive with account_id)
          attribute :zone_id, ::Pangea::Resources::Types::CloudflareZoneId.optional.default(nil)

          # @!attribute account_id
          #   @return [String, nil] Account ID (mutually exclusive with zone_id)
          attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId.optional.default(nil)

          # @!attribute mode
          #   @return [String] Action to apply
          attribute :mode, CloudflareAccessRuleMode

          # @!attribute target
          #   @return [String] Configuration target
          attribute :target, CloudflareAccessRuleTarget

          # @!attribute value
          #   @return [String] Target value (IP, ASN, country code)
          attribute :value, Dry::Types['strict.string'].constrained(min_size: 1)

          # @!attribute notes
          #   @return [String, nil] Rule notes
          attribute :notes, Dry::Types['strict.string'].optional.default(nil)

          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            # Validate mutually exclusive zone_id and account_id
            if attrs[:zone_id] && attrs[:account_id]
              raise Dry::Struct::Error, "zone_id and account_id are mutually exclusive"
            end

            unless attrs[:zone_id] || attrs[:account_id]
              raise Dry::Struct::Error, "Either zone_id or account_id must be provided"
            end

            super(attrs)
          end

          # Check if this is an account-level rule
          # @return [Boolean] true if account-level
          def account_level?
            !account_id.nil?
          end

          # Check if this blocks traffic
          # @return [Boolean] true if mode is block
          def blocking?
            mode == 'block'
          end

          # Check if this is a whitelist rule
          # @return [Boolean] true if mode is whitelist
          def whitelist?
            mode == 'whitelist'
          end
        end
      end
    end
  end
end
