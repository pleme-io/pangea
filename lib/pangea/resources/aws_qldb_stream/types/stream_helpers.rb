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
  module Resources
    module AWS
      module Types
        # Helper methods for QLDB Stream analysis and metadata
        module QldbStreamHelpers
          def kinesis_stream_arn
            kinesis_configuration[:stream_arn]
          end

          def aggregation_enabled?
            kinesis_configuration[:aggregation_enabled]
          end

          def is_continuous_stream?
            exclusive_end_time.nil?
          end

          def is_bounded_stream?
            !exclusive_end_time.nil?
          end

          def stream_duration
            return nil if is_continuous_stream?

            start_time = Time.parse(inclusive_start_time)
            end_time = Time.parse(exclusive_end_time)
            end_time - start_time
          end

          def stream_type
            is_continuous_stream? ? :continuous : :bounded
          end

          def estimated_monthly_cost
            # Base streaming cost
            base_cost = 0.03 # $0.03 per GB of journal data streamed

            # Estimate based on typical QLDB usage
            estimated_gb_per_month = 10.0 # Conservative estimate

            streaming_cost = estimated_gb_per_month * base_cost

            # Add Kinesis costs (simplified)
            kinesis_cost = 0.015 * 730 # $0.015 per hour for Kinesis shard

            streaming_cost + kinesis_cost
          end

          def stream_features
            features = [:real_time_streaming, :journal_export]
            features << :record_aggregation if aggregation_enabled?
            features << :continuous_streaming if is_continuous_stream?
            features << :bounded_export if is_bounded_stream?
            features
          end

          def use_cases
            cases = []

            if is_continuous_stream?
              cases.concat([
                             :real_time_analytics,
                             :event_driven_processing,
                             :data_lake_ingestion,
                             :cross_region_replication
                           ])
            else
              cases.concat([
                             :point_in_time_export,
                             :audit_log_extraction,
                             :compliance_reporting,
                             :data_migration
                           ])
            end

            cases
          end

          def kinesis_region
            kinesis_stream_arn.split(':')[3]
          end

          def role_account_id
            role_arn.split(':')[4]
          end

          def required_iam_permissions
            %w[
              kinesis:PutRecords
              kinesis:PutRecord
              kinesis:DescribeStream
              kinesis:ListShards
            ]
          end

          def stream_record_format
            {
              qldbStreamArn: 'Stream ARN',
              recordType: 'BLOCK_SUMMARY or REVISION_DETAILS',
              payload: {
                blockAddress: 'Block location in journal',
                transactionId: 'Transaction identifier',
                blockTimestamp: 'Block creation time',
                blockHash: 'SHA-256 hash of block',
                entriesHash: 'Hash of block entries',
                previousBlockHash: 'Previous block hash',
                entriesHashList: 'List of entry hashes',
                transactionInfo: 'Transaction metadata',
                revisionSummaries: 'Document revision details'
              }
            }
          end
        end
      end
    end
  end
end
