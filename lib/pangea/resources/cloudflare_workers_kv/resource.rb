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
require 'pangea/resources/cloudflare_workers_kv/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare Workers KV key-value pair resource module that self-registers
    module CloudflareWorkersKv
      # Create a Cloudflare Workers KV key-value pair
      #
      # Manages individual key-value pairs within a Workers KV namespace.
      # Use this for static configuration or data that needs to be accessible
      # to Workers at runtime.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] KV attributes
      # @option attributes [String] :account_id Cloudflare account ID (required)
      # @option attributes [String] :namespace_id KV namespace ID (required)
      # @option attributes [String] :key_name Key name, max 512 bytes (required)
      # @option attributes [String] :value Value to store, max 25 MiB (required)
      # @option attributes [Hash] :metadata Optional metadata hash
      #
      # @return [ResourceReference] Reference object with outputs
      #
      # @example Store API configuration
      #   ns = cloudflare_workers_kv_namespace(:config, {
      #     account_id: "a" * 32,
      #     title: "Configuration"
      #   })
      #
      #   cloudflare_workers_kv(:api_endpoint, {
      #     account_id: "a" * 32,
      #     namespace_id: ns.id,
      #     key_name: "api-url",
      #     value: "https://api.example.com"
      #   })
      #
      # @example Store JSON data with metadata
      #   cloudflare_workers_kv(:user_preferences, {
      #     account_id: "a" * 32,
      #     namespace_id: ns.id,
      #     key_name: "user:123:prefs",
      #     value: JSON.dump({ theme: "dark", lang: "en" }),
      #     metadata: { user_id: "123", updated_at: Time.now.iso8601 }
      #   })
      def cloudflare_workers_kv(name, attributes = {})
        # Validate attributes using dry-struct
        kv_attrs = Cloudflare::Types::WorkersKvAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:cloudflare_workers_kv, name) do
          account_id kv_attrs.account_id
          namespace_id kv_attrs.namespace_id
          key kv_attrs.key_name
          value kv_attrs.value
          metadata kv_attrs.metadata if kv_attrs.metadata
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_workers_kv',
          name: name,
          resource_attributes: kv_attrs.to_h,
          outputs: {
            id: "${cloudflare_workers_kv.#{name}.id}",
            key: "${cloudflare_workers_kv.#{name}.key}",
            value: "${cloudflare_workers_kv.#{name}.value}"
          }
        )
      end
    end

    # Maintain backward compatibility by extending Cloudflare module
    module Cloudflare
      include CloudflareWorkersKv
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
