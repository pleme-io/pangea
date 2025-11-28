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
        include Dry.Types()

        # Worker KV namespace binding
        WorkerKvNamespaceBinding = ::Pangea::Resources::Types::Hash.schema(
          name: ::Pangea::Resources::Types::String,
          namespace_id: ::Pangea::Resources::Types::String
        )

        # Worker plain text binding
        WorkerPlainTextBinding = ::Pangea::Resources::Types::Hash.schema(
          name: ::Pangea::Resources::Types::String,
          text: ::Pangea::Resources::Types::String
        )

        # Worker secret text binding
        WorkerSecretTextBinding = ::Pangea::Resources::Types::Hash.schema(
          name: ::Pangea::Resources::Types::String,
          text: ::Pangea::Resources::Types::String
        )

        # Worker D1 database binding
        WorkerD1DatabaseBinding = ::Pangea::Resources::Types::Hash.schema(
          name: ::Pangea::Resources::Types::String,
          database_id: ::Pangea::Resources::Types::String
        )

        # Worker queue binding
        WorkerQueueBinding = ::Pangea::Resources::Types::Hash.schema(
          name: ::Pangea::Resources::Types::String,
          queue_name: ::Pangea::Resources::Types::String
        )

        # Cloudflare Worker Script resource attributes with validation
        class WorkerScriptAttributes < Dry::Struct
          transform_keys(&:to_sym)

          attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId
          attribute :name, ::Pangea::Resources::Types::String
          attribute :content, ::Pangea::Resources::Types::String
          attribute :module, ::Pangea::Resources::Types::Bool.default(false)
          attribute :compatibility_date, ::Pangea::Resources::Types::String.optional.default(nil)
          attribute :compatibility_flags, ::Pangea::Resources::Types::Array.of(::Pangea::Resources::Types::String).default([].freeze)
          attribute :kv_namespace_bindings, ::Pangea::Resources::Types::Array.of(WorkerKvNamespaceBinding).default([].freeze)
          attribute :plain_text_bindings, ::Pangea::Resources::Types::Array.of(WorkerPlainTextBinding).default([].freeze)
          attribute :secret_text_bindings, ::Pangea::Resources::Types::Array.of(WorkerSecretTextBinding).default([].freeze)
          attribute :d1_database_bindings, ::Pangea::Resources::Types::Array.of(WorkerD1DatabaseBinding).default([].freeze)
          attribute :queue_bindings, ::Pangea::Resources::Types::Array.of(WorkerQueueBinding).default([].freeze)

          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            # Validate script content is not empty
            if attrs[:content] && attrs[:content].strip.empty?
              raise Dry::Struct::Error, "Worker script content cannot be empty"
            end

            # Validate worker name format
            if attrs[:name] && !attrs[:name].match?(/\A[a-z0-9_-]+\z/i)
              raise Dry::Struct::Error, "Worker script name must contain only alphanumeric characters, hyphens, and underscores"
            end

            super(attrs)
          end

          # Computed properties
          def is_module_worker?
            self.module
          end

          def is_service_worker?
            !self.module
          end

          def has_kv_bindings?
            kv_namespace_bindings.any?
          end

          def has_secrets?
            secret_text_bindings.any?
          end
        end
      end
    end
  end
end
