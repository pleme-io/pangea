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
        # Type-safe attributes for Cloudflare Workers KV Namespace
        #
        # Workers KV is a global, low-latency, key-value data store.
        # Namespaces are containers for KV pairs.
        #
        # @example Create a KV namespace
        #   WorkersKvNamespaceAttributes.new(
        #     account_id: "a" * 32,
        #     title: "Production Cache"
        #   )
        class WorkersKvNamespaceAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute account_id
          #   @return [String] The Cloudflare account ID
          attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId

          # @!attribute title
          #   @return [String] Human-readable name for the KV namespace
          attribute :title, Dry::Types['strict.string'].constrained(
            min_size: 1,
            max_size: 256
          )

          # Check if this namespace follows naming conventions
          # @return [Boolean] true if title follows standard naming pattern
          def follows_naming_convention?
            title.match?(/\A[a-z0-9][a-z0-9_-]*\z/i)
          end

          # Extract environment from title if present
          # @return [String, nil] Environment name if detected (production, staging, dev, etc.)
          def environment
            case title.downcase
            when /production|prod/
              'production'
            when /staging|stage/
              'staging'
            when /development|dev/
              'development'
            when /test/
              'test'
            else
              nil
            end
          end
        end
      end
    end
  end
end
