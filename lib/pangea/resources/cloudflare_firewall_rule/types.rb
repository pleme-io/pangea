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
        # Cloudflare Firewall Rule resource attributes with validation
        class FirewallRuleAttributes < Dry::Struct
          transform_keys(&:to_sym)

          attribute :zone_id, ::Pangea::Resources::Types::CloudflareZoneId
          attribute :filter_id, ::Pangea::Resources::Types::String
          attribute :action, ::Pangea::Resources::Types::CloudflareFirewallAction
          attribute :description, ::Pangea::Resources::Types::String.optional.default(nil)
          attribute :priority, ::Pangea::Resources::Types::Integer.optional.default(nil)
          attribute :paused, ::Pangea::Resources::Types::Bool.default(false)
          attribute :products, ::Pangea::Resources::Types::Array.of(::Pangea::Resources::Types::String).default([].freeze)

          # Computed properties
          def is_active?
            !paused
          end

          def is_blocking?
            action == 'block'
          end

          def is_allowing?
            action == 'allow'
          end

          def is_challenging?
            %w[challenge js_challenge managed_challenge].include?(action)
          end

          def is_logging_only?
            action == 'log'
          end

          def bypasses_products?
            action == 'bypass' && products.any?
          end
        end
      end
    end
  end
end
