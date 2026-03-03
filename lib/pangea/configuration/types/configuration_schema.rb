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
require 'fileutils'

module Pangea
  module ConfigurationTypes
    module Types
      # Main Configuration Schema
      class ConfigurationSchema < Dry::Struct
        transform_keys(&:to_sym)

        attribute? :default_namespace, Types::String.optional
        # Don't try to coerce to NamespaceConfig yet - we'll do it in the custom new method
        attribute :namespaces, Types::Hash.default({}.freeze)
        attribute? :terraform, TerraformConfig.optional
        attribute? :modules, ModulesConfig.optional
        attribute? :cache, CacheConfig.optional

        def self.new(attributes)
          attrs = attributes.is_a?(Hash) ? attributes.dup : {}

          # Create instance first with raw namespaces
          instance = super(attrs)

          # Now transform namespaces to NamespaceConfig instances using the stored raw namespaces
          raw_namespaces = instance.namespaces

          if raw_namespaces.is_a?(Array)
            raw_namespaces.each do |ns|
              ns_config = NamespaceConfig.new(ns)
              instance.namespace_configs[ns_config.name.to_sym] = ns_config
            end
          elsif raw_namespaces.is_a?(Hash)
            raw_namespaces.each do |name, config|
              ns_attrs = config.is_a?(Hash) ? config.merge(name: name.to_s) : { name: name.to_s }
              ns_config = NamespaceConfig.new(ns_attrs)
              instance.namespace_configs[name.to_sym] = ns_config
            end
          end

          instance
        end

        def namespace_configs
          @namespace_configs ||= {}
        end

        def get_namespace(name)
          namespace_configs[name.to_sym]
        end

        def validate!
          # Validate default namespace exists
          if default_namespace && !namespace_configs.key?(default_namespace.to_sym)
            available = namespace_configs.keys.map(&:to_s).join(', ')
            raise ConfigurationError, "Default namespace '#{default_namespace}' not found. Available: #{available}"
          end

          # Validate terraform binary if specified
          if terraform&.binary && !binary_exists?(terraform.binary)
            raise ConfigurationError, "Terraform binary not found: #{terraform.binary}"
          end

          # Validate paths exist
          if modules&.path && !Dir.exist?(File.expand_path(modules.path))
            raise ConfigurationError, "Modules path does not exist: #{modules.path}"
          end

          if cache&.directory
            cache_dir = File.expand_path(cache.directory)
            FileUtils.mkdir_p(cache_dir) unless Dir.exist?(cache_dir)
          end

          true
        end

        private

        def binary_exists?(binary)
          return true if File.exist?(binary) && File.executable?(binary)

          # Check in PATH
          ENV['PATH'].split(':').any? do |path|
            binary_path = File.join(path, binary)
            File.exist?(binary_path) && File.executable?(binary_path)
          end
        end
      end
    end
  end
end
