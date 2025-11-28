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
require 'pangea/types'

module Pangea
  module Entities
    # Namespace represents a top-level organizational unit in Pangea
    # It contains state backend configuration and can have multiple projects
    class Namespace < Dry::Struct
      # Nested structure for state configuration
      class StateConfig < Dry::Struct
        attribute? :bucket, Types::String
        attribute? :key, Types::String
        attribute? :region, Types::AwsRegion
        attribute? :dynamodb_table, Types::String
        attribute? :lock, Types::String  # Alias for dynamodb_table
        attribute? :encrypt, Types::Bool
        attribute? :path, Types::String  # For local backend
        
        # Validate S3 backend has required fields
        def validate_s3!
          errors = []
          errors << "S3 bucket name is required" if bucket.nil?
          errors << "S3 key is required" if key.nil?
          lock_table = dynamodb_table || lock
          errors << "DynamoDB lock table is required" if lock_table.nil?
          raise ::Pangea::Entities::ValidationError, errors.join(", ") unless errors.empty?
        end
        
        def lock_table
          dynamodb_table || lock
        end
      end
      
      class State < Dry::Struct
        attribute :type, Types::StateBackendType
        attribute :config, StateConfig
        
        # Custom constructor with backend-specific validation
        def self.new(attributes)
          attrs = attributes.is_a?(Hash) ? attributes : {}
          state_type = attrs[:type]
          config_attrs = attrs[:config] || {}
          
          # Validate based on backend type
          if state_type == :s3
            required_fields = [:bucket, :key]
            missing_fields = required_fields.select { |field| config_attrs[field].nil? || config_attrs[field].empty? }
            unless missing_fields.empty?
              raise ::Pangea::Entities::ValidationError, "S3 backend requires: #{missing_fields.join(', ')}"
            end
          elsif state_type == :local
            # For local backends, ensure path is set (default if not provided)
            config_attrs[:path] ||= "./terraform.tfstate"
          end
          
          super(attrs)
        end
        
        # Check if this is an S3 backend
        def s3?
          type == :s3
        end
        
        # Check if this is a local backend
        def local?
          type == :local
        end
      end
      
      # Main attributes
      attribute :name, Types::NamespaceString
      attribute :state, State
      attribute :description, Types::OptionalString.default(nil)
      attribute :tags, Types::SymbolizedHash.default({}.freeze)
      
      # Check if namespace uses S3 backend
      def s3_backend?
        state.s3?
      end
      
      # Check if namespace uses local backend  
      def local_backend?
        state.local?
      end
      
      # Get the full state configuration as a hash
      def state_config
        config = {
          type: state.type,
          region: state.config.region
        }
        
        if s3_backend?
          config[:bucket] = state.config.bucket
          config[:lock] = state.config.lock
        end
        
        config.compact
      end
      
      # Get S3 backend configuration (raises if not S3)
      def s3_config
        raise "Namespace #{name} does not use S3 backend" unless s3_backend?
        state.config.validate_s3!
        {
          bucket: state.config.bucket,
          key: state.config.key,
          region: state.config.region,
          dynamodb_table: state.config.lock_table
        }
      end
      
      # Convert to Terraform backend configuration
      def to_terraform_backend
        if local_backend?
          return {
            local: {
              path: state.config.path || "terraform.tfstate"
            }
          }
        end

        # Validate S3 backend configuration before returning
        if state.config.bucket.nil? || state.config.bucket.empty?
          raise ValidationError, "S3 bucket is required but was nil or empty for namespace '#{name}'"
        end
        if state.config.key.nil? || state.config.key.empty?
          raise ValidationError, "S3 key is required but was nil or empty for namespace '#{name}'"
        end

        {
          s3: {
            bucket: state.config.bucket,
            key: state.config.key,
            region: state.config.region,
            dynamodb_table: state.config.lock_table,
            encrypt: state.config.encrypt
          }.compact
        }
      end
    end
    
    # Validation error for namespace operations
    class ValidationError < StandardError; end
  end
end