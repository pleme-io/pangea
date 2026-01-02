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

require 'aws-sdk-dynamodb'

module Pangea
  module Backends
    class S3
      # DynamoDB-based locking mechanism for S3 backend
      module DynamoDBLock
        LOCK_TABLE_SCHEMA = {
          attribute_definitions: [
            { attribute_name: 'LockID', attribute_type: 'S' }
          ],
          key_schema: [
            { attribute_name: 'LockID', key_type: 'HASH' }
          ],
          billing_mode: 'PAY_PER_REQUEST'
        }.freeze

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

        # Check if DynamoDB table exists
        def dynamodb_table_exists?
          @dynamodb.describe_table(table_name: @config[:dynamodb_table])
          true
        rescue Aws::DynamoDB::Errors::ResourceNotFoundException
          false
        end

        # Create DynamoDB table if it doesn't exist
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
end
