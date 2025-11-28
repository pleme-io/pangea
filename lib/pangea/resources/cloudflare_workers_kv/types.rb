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
require 'json'

module Pangea
  module Resources
    module Cloudflare
      module Types
        # Type-safe attributes for Cloudflare Workers KV key-value pairs
        #
        # Manages individual key-value pairs within a Workers KV namespace.
        # Keys are limited to 512 bytes and values to 25 MiB.
        #
        # @example Store a configuration value
        #   WorkersKvAttributes.new(
        #     account_id: "a" * 32,
        #     namespace_id: "0f2ac74b498b48028cb68387c421e279",
        #     key_name: "api-config",
        #     value: JSON.dump({ endpoint: "https://api.example.com" })
        #   )
        class WorkersKvAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute account_id
          #   @return [String] The Cloudflare account ID
          attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId

          # @!attribute namespace_id
          #   @return [String] The KV namespace identifier (or Terraform reference)
          attribute :namespace_id, Dry::Types['strict.string'].constrained(
            format: /\A([a-f0-9]{32}|\$\{.+\})\z/
          )

          # @!attribute key_name
          #   @return [String] The key name (max 512 bytes)
          attribute :key_name, Dry::Types['strict.string'].constrained(
            min_size: 1,
            max_size: 512
          )

          # @!attribute value
          #   @return [String] The value to store (max 25 MiB)
          attribute :value, Dry::Types['strict.string'].constrained(
            max_size: 25 * 1024 * 1024  # 25 MiB
          )

          # @!attribute metadata
          #   @return [Hash, nil] Optional metadata as a JSON-compatible hash
          attribute :metadata, Dry::Types['hash'].optional.default(nil)

          # Check if value appears to be JSON
          # @return [Boolean] true if value can be parsed as JSON
          def json_value?
            JSON.parse(value)
            true
          rescue JSON::ParserError
            false
          end

          # Get size of key in bytes
          # @return [Integer] Size of key name in bytes
          def key_size
            key_name.bytesize
          end

          # Get size of value in bytes
          # @return [Integer] Size of value in bytes
          def value_size
            value.bytesize
          end

          # Check if this is a large value (> 1 MiB)
          # @return [Boolean] true if value exceeds 1 MiB
          def large_value?
            value_size > 1024 * 1024
          end

          # Get metadata as JSON string if present
          # @return [String, nil] JSON-encoded metadata or nil
          def metadata_json
            metadata ? JSON.dump(metadata) : nil
          end
        end
      end
    end
  end
end
