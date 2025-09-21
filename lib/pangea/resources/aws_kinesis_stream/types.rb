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
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Kinesis Stream resource attributes with validation
        class KinesisStreamAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :name, Pangea::Resources::Types::String
          attribute :shard_count, Pangea::Resources::Types::Integer.default(1).constrained(gteq: 1, lteq: 500000)
          attribute :retention_period, Pangea::Resources::Types::Integer.default(24).constrained(gteq: 24, lteq: 8760) # 24 hours to 1 year (365 days)
          attribute :shard_level_metrics, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String.constrained(included_in: [
            'IncomingRecords', 'IncomingBytes', 'OutgoingRecords', 'OutgoingBytes',
            'WriteProvisionedThroughputExceeded', 'ReadProvisionedThroughputExceeded',
            'IteratorAgeMilliseconds', 'ALL'
          ])).default([].freeze)
          attribute :encryption_type, Pangea::Resources::Types::String.default('NONE').constrained(included_in: ['NONE', 'KMS'])
          attribute? :kms_key_id, Pangea::Resources::Types::String.optional
          attribute? :stream_mode_details, Pangea::Resources::Types::Hash.schema(
            stream_mode: Pangea::Resources::Types::String.default('PROVISIONED').constrained(included_in: ['PROVISIONED', 'ON_DEMAND'])
          ).optional
          attribute :tags, Pangea::Resources::Types::AwsTags.default({}.freeze)
          
          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate encryption configuration
            if attrs[:encryption_type] == 'KMS' && (!attrs[:kms_key_id] || attrs[:kms_key_id].empty?)
              raise Dry::Struct::Error, "KMS key ID is required when encryption_type is 'KMS'"
            end
            
            # Validate KMS key ID format if provided
            if attrs[:kms_key_id] && !valid_kms_key_id?(attrs[:kms_key_id])
              raise Dry::Struct::Error, "Invalid KMS key ID format: #{attrs[:kms_key_id]}"
            end
            
            # Validate stream mode vs shard count
            if attrs[:stream_mode_details] && attrs[:stream_mode_details][:stream_mode] == 'ON_DEMAND'
              if attrs[:shard_count] && attrs[:shard_count] != 1
                raise Dry::Struct::Error, "Cannot specify shard_count with ON_DEMAND stream mode"
              end
            end
            
            # Set defaults for stream_mode_details if not provided
            unless attrs[:stream_mode_details]
              attrs[:stream_mode_details] = { stream_mode: 'PROVISIONED' }
            end
            
            super(attrs)
          end
          
          # Validation helpers
          def self.valid_kms_key_id?(key_id)
            # KMS key ID can be:
            # - Key ID: 12345678-1234-1234-1234-123456789012
            # - Key ARN: arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012
            # - Alias name: alias/my-key
            # - Alias ARN: arn:aws:kms:us-east-1:123456789012:alias/my-key
            
            # UUID format
            return true if key_id.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i)
            
            # Key ARN
            return true if key_id.match?(/\Aarn:aws:kms:[a-z0-9\-]+:\d{12}:key\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i)
            
            # Alias name
            return true if key_id.match?(/\Aalias\/[a-zA-Z0-9:\/_\-]+\z/)
            
            # Alias ARN
            return true if key_id.match?(/\Aarn:aws:kms:[a-z0-9\-]+:\d{12}:alias\/[a-zA-Z0-9:\/_\-]+\z/)
            
            false
          end
          
          # Computed properties
          def is_encrypted?
            encryption_type == 'KMS'
          end
          
          def is_on_demand_mode?
            stream_mode_details && stream_mode_details[:stream_mode] == 'ON_DEMAND'
          end
          
          def is_provisioned_mode?
            !is_on_demand_mode?
          end
          
          def has_enhanced_metrics?
            !shard_level_metrics.empty?
          end
          
          def max_throughput_per_shard_mbps
            # Each shard can ingest up to 1 MB/sec or 1000 records/sec
            1.0
          end
          
          def max_throughput_per_shard_records
            # Each shard can ingest up to 1000 records/sec
            1000
          end
          
          def total_max_throughput_mbps
            return nil if is_on_demand_mode? # On-demand scales automatically
            shard_count * max_throughput_per_shard_mbps
          end
          
          def total_max_throughput_records
            return nil if is_on_demand_mode? # On-demand scales automatically
            shard_count * max_throughput_per_shard_records
          end
          
          def retention_period_days
            retention_period / 24
          end
          
          def estimated_monthly_cost_usd
            if is_on_demand_mode?
              # On-demand pricing: $0.40 per million payload units (25KB each)
              # Difficult to estimate without usage patterns
              return "Variable - depends on usage"
            else
              # Provisioned mode: $0.015 per shard per hour
              shard_hours_per_month = shard_count * 24 * 30 # 30 days
              base_cost = shard_hours_per_month * 0.015
              
              # Extended retention cost: $0.023 per shard-month for each additional day beyond 24 hours
              if retention_period > 24
                extended_days = (retention_period - 24) / 24.0
                retention_cost = shard_count * extended_days * 0.023
                base_cost += retention_cost
              end
              
              base_cost.round(2)
            end
          end
        end
      end
    end
  end
end