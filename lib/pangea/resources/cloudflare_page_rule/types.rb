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
        # Page Rule action configuration
        PageRuleAction = ::Pangea::Resources::Types::Hash

        # Cloudflare Page Rule resource attributes with validation
        class PageRuleAttributes < Dry::Struct
          transform_keys(&:to_sym)

          attribute :zone_id, ::Pangea::Resources::Types::CloudflareZoneId
          attribute :target, ::Pangea::Resources::Types::String  # URL pattern to match
          attribute :actions, PageRuleAction
          attribute :priority, ::Pangea::Resources::Types::Integer.default(1)
          attribute :status, ::Pangea::Resources::Types::String.default('active').enum('active', 'disabled')

          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            # Validate target is a valid URL pattern
            if attrs[:target] && !attrs[:target].include?('*')
              # Target should typically contain wildcards for page rules
              # But we allow non-wildcard patterns too
            end

            # Validate actions is not empty
            if attrs[:actions] && attrs[:actions].empty?
              raise Dry::Struct::Error, "Page rule must have at least one action"
            end

            super(attrs)
          end

          # Computed properties
          def is_active?
            status == 'active'
          end

          def is_wildcard_rule?
            target.include?('*')
          end

          def action_count
            actions.keys.length
          end
        end
      end
    end
  end
end
