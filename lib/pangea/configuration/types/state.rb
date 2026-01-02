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
      # State Configuration
      class StateConfig < Dry::Struct
        attribute :type, StateType
        attribute :config, Types::Hash.default({}.freeze)

        def backend_config
          case type
          when :s3
            S3BackendConfig.new(config)
          when :local
            LocalBackendConfig.new(config)
          when :azurerm
            AzureRMBackendConfig.new(config)
          when :gcs
            GCSBackendConfig.new(config)
          else
            config # For other backends, pass through as-is
          end
        end

        def to_terraform_backend
          backend_hash = backend_config.respond_to?(:to_h) ? backend_config.to_h : backend_config
          { type => backend_hash }
        end
      end

      # Namespace Configuration
      class NamespaceConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :name, Types::String.constrained(min_size: 1)
        attribute? :description, Types::String.optional
        attribute :state, StateConfig

        def self.new(attributes)
          # Handle both nested and flat state configurations
          attrs = attributes.is_a?(Hash) ? attributes.dup : {}

          # Clean up attributes - remove string keys if symbol keys exist
          attrs.delete('state') if attrs[:state]
          attrs.delete('name') if attrs[:name]
          attrs.delete('description') if attrs[:description]

          # Transform state configuration if needed
          state_attrs = attrs[:state] || attrs['state']
          if state_attrs
            # Always transform to the structure StateConfig expects
            state_type = state_attrs[:type] || state_attrs['type']

            if state_type
              # Extract config fields (everything except type)
              config_fields = state_attrs.reject { |k, _| k.to_s == 'type' }

              attrs[:state] = {
                type: state_type.to_sym,
                config: config_fields
              }
            else
              raise ArgumentError, "State configuration missing 'type' field"
            end

            # Remove string key if we have symbol key
            attrs.delete('state')
          end

          super(attrs)
        end
      end
    end
  end
end
