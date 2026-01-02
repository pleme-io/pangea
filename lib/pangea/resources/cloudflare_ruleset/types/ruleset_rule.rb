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
      end
    end
  end
end
