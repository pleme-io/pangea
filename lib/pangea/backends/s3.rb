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
require_relative 's3/dynamodb_lock'

module Pangea
  module Backends
    # S3 backend for Terraform state storage
    class S3 < Base
      include DynamoDBLock

      REQUIRED_CONFIG = %i[bucket key region].freeze

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
        raise ArgumentError, "Missing required S3 backend config: #{missing.join(', ')}" unless missing.empty?

        # Validate format
        raise ArgumentError, "Invalid S3 bucket name: #{@config[:bucket]}" unless valid_bucket_name?
        raise ArgumentError, "Invalid AWS region: #{@config[:region]}" unless valid_region?
      end

      private

      def valid_bucket_name?
        @config[:bucket].match?(/^[a-z0-9][a-z0-9.-]*[a-z0-9]$/)
      end

      def valid_region?
        @config[:region].match?(/^[a-z]{2}-[a-z]+-\d+$/)
      end

      def bucket_exists?
        @s3.head_bucket(bucket: @config[:bucket])
        true
      rescue Aws::S3::Errors::NotFound
        false
      end

      def ensure_bucket_exists!
        return if bucket_exists?

        create_bucket!
        enable_versioning!
        enable_encryption! if @config[:encrypt]
      end

      def create_bucket!
        @s3.create_bucket(
          bucket: @config[:bucket],
          create_bucket_configuration: {
            location_constraint: @config[:region]
          }
        )
      end

      def enable_versioning!
        @s3.put_bucket_versioning(
          bucket: @config[:bucket],
          versioning_configuration: { status: 'Enabled' }
        )
      end

      def enable_encryption!
        @s3.put_bucket_encryption(
          bucket: @config[:bucket],
          server_side_encryption_configuration: {
            rules: [{
              apply_server_side_encryption_by_default: { sse_algorithm: 'AES256' }
            }]
          }
        )
      end
    end
  end
end
