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


require 'aws-sdk-s3'
require 'aws-sdk-dynamodb'
require 'pangea/backends/base'
require 'pangea/types'

module Pangea
  module Backends
    # S3 backend for Terraform state storage
    class S3 < Base
      REQUIRED_CONFIG = %i[bucket key region].freeze
      LOCK_TABLE_SCHEMA = {
        attribute_definitions: [
          { attribute_name: 'LockID', attribute_type: 'S' }
        ],
        key_schema: [
          { attribute_name: 'LockID', key_type: 'HASH' }
        ],
        billing_mode: 'PAY_PER_REQUEST'
      }.freeze
      
      def initialize(config = {})
        super
        @s3 = Aws::S3::Client.new(region: @config[:region])
        @dynamodb = Aws::DynamoDB::Client.new(region: @config[:region]) if @config[:dynamodb_table]
      end
      
      # Initialize the backend resources
      def initialize!
        ensure_bucket_exists!
        ensure_dynamodb_table_exists! if @config[:dynamodb_table]
        true
      end
      
      # Check if backend is properly configured
      def configured?
        bucket_exists? && (!@config[:dynamodb_table] || dynamodb_table_exists?)
      end
      
      # Lock state for exclusive access
      def lock(lock_id:, info: {})
        return true unless @config[:dynamodb_table]
        
        lock_item = {
          LockID: lock_id,
          Info: info.to_json,
          Created: Time.now.to_i
        }
        
        @dynamodb.put_item(
          table_name: @config[:dynamodb_table],
          item: lock_item,
          condition_expression: 'attribute_not_exists(LockID)'
        )
        true
      rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException
        false
      end
      
      # Unlock state
      def unlock(lock_id:)
        return true unless @config[:dynamodb_table]
        
        @dynamodb.delete_item(
          table_name: @config[:dynamodb_table],
          key: { LockID: lock_id }
        )
        true
      rescue Aws::DynamoDB::Errors::ServiceError
        false
      end
      
      # Check if state is locked
      def locked?
        return false unless @config[:dynamodb_table]
        
        !lock_info.nil?
      end
      
      # Get lock info
      def lock_info
        return nil unless @config[:dynamodb_table]
        
        response = @dynamodb.scan(
          table_name: @config[:dynamodb_table],
          limit: 1
        )
        
        return nil if response.items.empty?
        
        item = response.items.first
        {
          id: item['LockID'],
          info: JSON.parse(item['Info'] || '{}'),
          created: Time.at(item['Created'].to_i)
        }
      rescue Aws::DynamoDB::Errors::ServiceError
        nil
      end
      
      # Convert to Terraform backend configuration
      def to_terraform_config
        config = {
          bucket: @config[:bucket],
          key: @config[:key],
          region: @config[:region]
        }
        
        # Optional parameters
        config[:encrypt] = @config[:encrypt] if @config.key?(:encrypt)
        config[:dynamodb_table] = @config[:dynamodb_table] if @config[:dynamodb_table]
        config[:kms_key_id] = @config[:kms_key_id] if @config[:kms_key_id]
        config[:workspace_key_prefix] = @config[:workspace_key_prefix] if @config[:workspace_key_prefix]
        
        { s3: config }
      end
      
      protected
      
      def validate_config!
        missing = REQUIRED_CONFIG - @config.keys
        unless missing.empty?
          raise ArgumentError, "Missing required S3 backend config: #{missing.join(', ')}"
        end
        
        # Validate format
        unless @config[:bucket].match?(/^[a-z0-9][a-z0-9.-]*[a-z0-9]$/)
          raise ArgumentError, "Invalid S3 bucket name: #{@config[:bucket]}"
        end
        
        unless @config[:region].match?(/^[a-z]{2}-[a-z]+-\d+$/)
          raise ArgumentError, "Invalid AWS region: #{@config[:region]}"
        end
      end
      
      private
      
      def bucket_exists?
        @s3.head_bucket(bucket: @config[:bucket])
        true
      rescue Aws::S3::Errors::NotFound
        false
      end
      
      def ensure_bucket_exists!
        return if bucket_exists?
        
        @s3.create_bucket(
          bucket: @config[:bucket],
          create_bucket_configuration: {
            location_constraint: @config[:region]
          }
        )
        
        # Enable versioning for safety
        @s3.put_bucket_versioning(
          bucket: @config[:bucket],
          versioning_configuration: {
            status: 'Enabled'
          }
        )
        
        # Enable encryption if requested
        if @config[:encrypt]
          @s3.put_bucket_encryption(
            bucket: @config[:bucket],
            server_side_encryption_configuration: {
              rules: [{
                apply_server_side_encryption_by_default: {
                  sse_algorithm: 'AES256'
                }
              }]
            }
          )
        end
      end
      
      def dynamodb_table_exists?
        @dynamodb.describe_table(table_name: @config[:dynamodb_table])
        true
      rescue Aws::DynamoDB::Errors::ResourceNotFoundException
        false
      end
      
      def ensure_dynamodb_table_exists!
        return if dynamodb_table_exists?
        
        @dynamodb.create_table(
          table_name: @config[:dynamodb_table],
          **LOCK_TABLE_SCHEMA
        )
        
        # Wait for table to be active
        @dynamodb.wait_until(:table_exists, table_name: @config[:dynamodb_table])
      end
    end
  end
end