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
require 'pangea/resources/cloudflare_workers_kv_namespace/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare Workers KV Namespace resource module that self-registers
    module CloudflareWorkersKvNamespace
      # Create a Cloudflare Workers KV Namespace
      #
      # Workers KV is a global, low-latency, key-value data store. Namespaces
      # are containers for KV pairs, providing isolation and organization.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Namespace attributes
      # @option attributes [String] :account_id Cloudflare account ID (required)
      # @option attributes [String] :title Human-readable namespace name (required)
      #
      # @return [ResourceReference] Reference object with outputs
      #
      # @example Create a production cache namespace
      #   kv_ns = cloudflare_workers_kv_namespace(:cache, {
      #     account_id: "a" * 32,
      #     title: "Production Cache"
      #   })
      #
      #   # Reference namespace ID in worker script
      #   cloudflare_worker_script(:api, {
      #     account_id: "a" * 32,
      #     name: "api-worker",
      #     content: "...",
      #     kv_namespace_bindings: [
      #       { name: "CACHE", namespace_id: kv_ns.id }
      #     ]
      #   })
      def cloudflare_workers_kv_namespace(name, attributes = {})
        # Validate attributes using dry-struct
        ns_attrs = Cloudflare::Types::WorkersKvNamespaceAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:cloudflare_workers_kv_namespace, name) do
          account_id ns_attrs.account_id
          title ns_attrs.title
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_workers_kv_namespace',
          name: name,
          resource_attributes: ns_attrs.to_h,
          outputs: {
            id: "${cloudflare_workers_kv_namespace.#{name}.id}",
            namespace_id: "${cloudflare_workers_kv_namespace.#{name}.id}"
          }
        )
      end
    end

    # Maintain backward compatibility by extending Cloudflare module
    module Cloudflare
      include CloudflareWorkersKvNamespace
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
