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
        # Ruleset kind enum
        CloudflareRulesetKind = Dry::Types['strict.string'].enum(
          'managed',
          'custom',
          'root',
          'zone'
        )

        # Ruleset phase enum
        CloudflareRulesetPhase = Dry::Types['strict.string'].enum(
          'ddos_l4',
          'ddos_l7',
          'http_config_settings',
          'http_custom_errors',
          'http_log_custom_fields',
          'http_ratelimit',
          'http_request_cache_settings',
          'http_request_dynamic_redirect',
          'http_request_firewall_custom',
          'http_request_firewall_managed',
          'http_request_late_transform',
          'http_request_main',
          'http_request_origin',
          'http_request_redirect',
          'http_request_sanitize',
          'http_request_sbfm',
          'http_request_transform',
          'http_response_compression',
          'http_response_firewall_managed',
          'http_response_headers_transform',
          'magic_transit'
        )

        # Ruleset rule configuration
        class RulesetRule < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute expression
          #   @return [String] Wireshark-like expression for matching
          attribute :expression, Dry::Types['strict.string'].constrained(min_size: 1)

          # @!attribute action
          #   @return [String] Action to perform (block, challenge, skip, etc.)
          attribute :action, Dry::Types['strict.string'].constrained(min_size: 1)

          # @!attribute description
          #   @return [String, nil] Rule description
          attribute :description, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute enabled
          #   @return [Boolean, nil] Whether rule is enabled
          attribute :enabled, ::Pangea::Resources::Types::Bool.optional.default(nil)

          # @!attribute ref
          #   @return [String, nil] Rule reference ID for stable ordering
          attribute :ref, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute action_parameters
          #   @return [Hash, nil] Flexible action parameters as hash
          attribute :action_parameters, Dry::Types['strict.hash'].optional.default(nil)

          # @!attribute logging
          #   @return [Hash, nil] Logging configuration
          attribute :logging, Dry::Types['strict.hash'].optional.default(nil)

          # @!attribute ratelimit
          #   @return [Hash, nil] Rate limiting configuration
          attribute :ratelimit, Dry::Types['strict.hash'].optional.default(nil)

          # @!attribute exposed_credential_check
          #   @return [Hash, nil] Exposed credential check configuration
          attribute :exposed_credential_check, Dry::Types['strict.hash'].optional.default(nil)

          # Check if rule has action parameters
          # @return [Boolean] true if action parameters configured
          def has_action_parameters?
            action_parameters && !action_parameters.empty?
          end

          # Check if rule has rate limiting
          # @return [Boolean] true if rate limiting configured
          def has_ratelimit?
            !ratelimit.nil?
          end

          # Check if rule is enabled
          # @return [Boolean] true if enabled (default true)
          def enabled?
            enabled.nil? ? true : enabled
          end
        end

        # Type-safe attributes for Cloudflare Ruleset
        #
        # Rulesets are the modern way to configure security, performance,
        # and transformation rules in Cloudflare. They replace legacy systems
        # like firewall rules and page rules.
        #
        # @example Zone-level WAF custom ruleset
        #   RulesetAttributes.new(
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
        #   )
        class RulesetAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute zone_id
          #   @return [String, nil] Zone ID (mutually exclusive with account_id)
          attribute :zone_id, ::Pangea::Resources::Types::CloudflareZoneId.optional.default(nil)

          # @!attribute account_id
          #   @return [String, nil] Account ID (mutually exclusive with zone_id)
          attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId.optional.default(nil)

          # @!attribute name
          #   @return [String] Ruleset name
          attribute :name, Dry::Types['strict.string'].constrained(min_size: 1)

          # @!attribute description
          #   @return [String, nil] Ruleset description
          attribute :description, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute kind
          #   @return [String] Ruleset kind
          attribute :kind, CloudflareRulesetKind

          # @!attribute phase
          #   @return [String] Ruleset phase
          attribute :phase, CloudflareRulesetPhase

          # @!attribute rules
          #   @return [Array<RulesetRule>] Rules in the ruleset
          attribute :rules, Dry::Types['strict.array']
            .of(RulesetRule)
            .constrained(min_size: 1)

          # Validate zone_id or account_id is specified
          def self.new(attributes)
            attrs = attributes.transform_keys(&:to_sym)
            super(attrs).tap do |instance|
              if instance.zone_id && instance.account_id
                raise Dry::Struct::Error, "zone_id and account_id are mutually exclusive"
              elsif !instance.zone_id && !instance.account_id
                raise Dry::Struct::Error, "Either zone_id or account_id must be provided"
              end
            end
          end

          # Check if ruleset is zone-scoped
          # @return [Boolean] true if zone-scoped
          def zone_scoped?
            !zone_id.nil?
          end

          # Check if ruleset is account-scoped
          # @return [Boolean] true if account-scoped
          def account_scoped?
            !account_id.nil?
          end

          # Check if ruleset is for WAF
          # @return [Boolean] true if WAF phase
          def waf_ruleset?
            phase.include?('firewall')
          end

          # Check if ruleset is for rate limiting
          # @return [Boolean] true if rate limiting phase
          def ratelimit_ruleset?
            phase == 'http_ratelimit'
          end

          # Check if ruleset is for caching
          # @return [Boolean] true if cache phase
          def cache_ruleset?
            phase == 'http_request_cache_settings'
          end
        end
      end
    end
  end
end
