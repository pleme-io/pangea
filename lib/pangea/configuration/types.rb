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
require 'dry-types'
require 'fileutils'

module Pangea
  module ConfigurationTypes
    module Types
      include Dry.Types()
      
      # Base types
      PathString = Types::String.constrained(min_size: 1)
      BinaryPath = Types::String.constrained(format: /\A[\w\-\.\/]+\z/)
      BucketName = Types::String.constrained(format: /\A[a-z0-9][a-z0-9\-\.]*[a-z0-9]\z/)
      AwsRegion = Types::String.constrained(format: /\A[a-z]{2}-[a-z]+-\d+\z/)
      
      # State backend types
      StateType = Types::Symbol.enum(:local, :s3, :azurerm, :gcs, :consul, :etcd)
      
      # S3 Backend Configuration
      class S3BackendConfig < Dry::Struct
        attribute :bucket, BucketName
        attribute :key, PathString
        attribute :region, AwsRegion
        attribute? :dynamodb_table, Types::String.optional
        attribute? :encrypt, Types::Bool.default(true)
        attribute? :kms_key_id, Types::String.optional
        attribute? :workspace_key_prefix, Types::String.optional
        attribute? :role_arn, Types::String.optional
        attribute? :session_name, Types::String.optional
        attribute? :external_id, Types::String.optional
        attribute? :assume_role_duration_seconds, Types::Integer.optional
        attribute? :assume_role_policy, Types::String.optional
        attribute? :shared_credentials_file, Types::String.optional
        attribute? :profile, Types::String.optional
        attribute? :skip_credentials_validation, Types::Bool.default(false)
        attribute? :skip_metadata_api_check, Types::Bool.default(false)
        attribute? :force_path_style, Types::Bool.default(false)
        attribute? :max_retries, Types::Integer.optional
        
        def to_h
          super.compact
        end
      end
      
      # Local Backend Configuration
      class LocalBackendConfig < Dry::Struct
        attribute :path, PathString.default('terraform.tfstate')
        attribute? :workspace_dir, Types::String.optional
        
        def to_h
          super.compact
        end
      end
      
      # Azure Backend Configuration
      class AzureRMBackendConfig < Dry::Struct
        attribute :storage_account_name, Types::String
        attribute :container_name, Types::String
        attribute :key, PathString
        attribute? :environment, Types::String.optional
        attribute? :endpoint, Types::String.optional
        attribute? :snapshot, Types::Bool.default(false)
        attribute? :subscription_id, Types::String.optional
        attribute? :tenant_id, Types::String.optional
        attribute? :client_id, Types::String.optional
        attribute? :client_secret, Types::String.optional
        attribute? :resource_group_name, Types::String.optional
        attribute? :msi_endpoint, Types::String.optional
        attribute? :use_msi, Types::Bool.default(false)
        attribute? :sas_token, Types::String.optional
        attribute? :access_key, Types::String.optional
        
        def to_h
          super.compact
        end
      end
      
      # GCS Backend Configuration
      class GCSBackendConfig < Dry::Struct
        attribute :bucket, Types::String
        attribute? :prefix, PathString.optional
        attribute? :credentials, Types::String.optional
        attribute? :access_token, Types::String.optional
        attribute? :impersonate_service_account, Types::String.optional
        attribute? :impersonate_service_account_delegates, Types::Array.of(Types::String).optional
        
        def to_h
          super.compact
        end
      end
      
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
      
      # Terraform Configuration
      class TerraformConfig < Dry::Struct
        attribute? :binary, BinaryPath.default('terraform')
        attribute? :version, Types::String.optional
        attribute? :workspace_prefix, Types::String.optional
        attribute? :plugin_cache_dir, Types::String.optional
        
        def to_h
          super.compact
        end
      end
      
      # Modules Configuration
      class ModulesConfig < Dry::Struct
        attribute? :path, PathString.optional
        attribute? :auto_install, Types::Bool.default(true)
        attribute? :registry_url, Types::String.optional
        
        def to_h
          super.compact
        end
      end
      
      # Cache Configuration
      class CacheConfig < Dry::Struct
        attribute? :directory, PathString.default('~/.pangea/cache')
        attribute? :ttl, Types::Integer.default(3600)
        attribute? :enabled, Types::Bool.default(true)
        
        def to_h
          super.compact
        end
      end
      
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