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
require 'pangea/resources/cloudflare_worker_script/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare Worker Script resource module
    module CloudflareWorkerScript
      # Create a Cloudflare Worker Script with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Worker script attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def cloudflare_worker_script(name, attributes = {})
        # Validate attributes using dry-struct
        script_attrs = Cloudflare::Types::WorkerScriptAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:cloudflare_worker_script, name) do
          account_id script_attrs.account_id
          name script_attrs.name
          content script_attrs.content
          self.module script_attrs.module if script_attrs.module

          compatibility_date script_attrs.compatibility_date if script_attrs.compatibility_date

          if script_attrs.compatibility_flags.any?
            compatibility_flags script_attrs.compatibility_flags
          end

          # Add bindings as arrays (terraform-synthesizer handles array → blocks conversion)
          if script_attrs.kv_namespace_bindings.any?
            kv_namespace_binding script_attrs.kv_namespace_bindings.map { |b| b.to_h }
          end

          if script_attrs.plain_text_bindings.any?
            plain_text_binding script_attrs.plain_text_bindings.map { |b| b.to_h }
          end

          if script_attrs.secret_text_bindings.any?
            secret_text_binding script_attrs.secret_text_bindings.map { |b| b.to_h }
          end

          if script_attrs.d1_database_bindings.any?
            d1_database_binding script_attrs.d1_database_bindings.map { |b| b.to_h }
          end

          if script_attrs.queue_bindings.any?
            queue_binding script_attrs.queue_bindings.map { |b| b.to_h }
          end
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_worker_script',
          name: name,
          resource_attributes: script_attrs.to_h,
          outputs: {
            id: "${cloudflare_worker_script.#{name}.id}"
          }
        )
      end
    end

    # Extend Cloudflare module
    module Cloudflare
      include CloudflareWorkerScript
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
