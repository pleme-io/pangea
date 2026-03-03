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

module Pangea
  class Configuration
    # Handles namespace loading, building, and querying
    module NamespaceManager
      # Get all namespaces as entities
      def namespaces
        @namespaces ||= @schema ? load_schema_namespaces : load_fallback_namespaces
      end

      # Get a specific namespace
      def namespace(name)
        namespaces.find { |ns| ns.name == name.to_s }
      end

      # Check if a namespace exists
      def namespace?(name)
        !namespace(name).nil?
      end

      # Get the default namespace (from env or config)
      def default_namespace
        ENV['PANGEA_NAMESPACE'] || fetch(:default_namespace)
      end

      private

      def load_schema_namespaces
        @schema.namespace_configs.values.map do |ns_config|
          build_namespace_from_schema(ns_config)
        end
      end

      def load_fallback_namespaces
        fetch(:namespaces, default: {}).map do |name, config|
          build_namespace_from_config(name, config)
        end
      end

      def build_namespace_from_schema(ns_config)
        Entities::Namespace.new(
          name: ns_config.name,
          description: ns_config.description,
          state: {
            type: ns_config.state.type,
            config: ns_config.state.config.transform_keys(&:to_sym)
          },
          tags: {} # Schema doesn't have tags yet
        )
      end

      def build_namespace_from_config(name, config)
        state_config = extract_state_config(config)

        Entities::Namespace.new(
          name: name.to_s,
          state: prepare_state(state_config),
          description: config[:description],
          tags: config[:tags] || {}
        )
      rescue Dry::Struct::Error => e
        raise ConfigurationError, "Invalid namespace '#{name}': #{e.message}"
      end

      def extract_state_config(config)
        config[:state] || config['state'] || {}
      end

      def prepare_state(state_config)
        state_type = state_config[:type] || state_config['type']
        config_fields = state_config.reject { |k, _| k.to_s == 'type' }

        {
          type: state_type&.to_sym,
          config: config_fields.transform_keys(&:to_sym)
        }
      end
    end
  end
end
