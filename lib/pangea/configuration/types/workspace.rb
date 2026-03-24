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

module Pangea
  module ConfigurationTypes
    module Types
      # Provider configuration for a workspace
      class ProviderConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :region, Types::String.optional.default(nil)
        attribute? :version, Types::String.optional
        attribute? :profile, Types::String.optional

        def to_h
          super.compact
        end
      end

      # Workspace definition — architecture-based infrastructure unit
      class WorkspaceConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :name, Types::String.constrained(min_size: 1)
        attribute :architecture, Types::String.constrained(min_size: 1)
        attribute? :namespace, Types::String.optional
        attribute? :aws_profile, Types::String.optional
        attribute :backend, StateConfig
        attribute? :remote_backend, Types::Hash.optional
        attribute? :config, Types::Hash.default({}.freeze)
        attribute? :providers, Types::Hash.default({}.freeze)

        def self.new(attributes)
          attrs = attributes.is_a?(Hash) ? attributes.dup : {}

          # Transform backend from flat to StateConfig format
          if attrs[:backend].is_a?(Hash) && !attrs[:backend].is_a?(StateConfig)
            backend = attrs[:backend].dup
            backend_type = backend.delete(:type) || backend.delete('type') || 'local'
            attrs[:backend] = { type: backend_type.to_sym, config: backend }
          end

          super(attrs)
        end

        # Resolve the remote backend as a StateConfig
        def remote_backend_config
          return nil unless remote_backend

          rb = remote_backend.transform_keys(&:to_sym)
          rb_type = rb.delete(:type) || 's3'
          StateConfig.new(type: rb_type.to_sym, config: rb)
        end
      end
    end
  end
end
