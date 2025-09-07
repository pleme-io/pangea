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
  module Resources
    module AWS
      module DynamoDBKinesisStreamingDestination
        # Common types for DynamoDB Kinesis Streaming Destination configurations
        class Types < Dry::Types::Module
          include Dry.Types()

          # Kinesis Stream ARN constraint
          StreamArn = String.constrained(
            format: /\Aarn:aws:kinesis:[a-z0-9\-]*:[0-9]{12}:stream\/[a-zA-Z0-9_.-]+\z/
          )
          
          # DynamoDB Table name constraint
          TableName = String.constrained(
            min_size: 3,
            max_size: 255,
            format: /\A[a-zA-Z0-9_.-]+\z/
          )
        end

        # DynamoDB Kinesis Streaming Destination attributes with comprehensive validation
        class DynamoDBKinesisStreamingDestinationAttributes < Dry::Struct
          include Types[self]
          
          # Required attributes
          attribute :stream_arn, StreamArn
          attribute :table_name, TableName
          
          # Computed properties
          def stream_name
            stream_arn.split('/')[-1]
          end
          
          def stream_region
            stream_arn.split(':')[3]
          end
          
          def stream_account_id
            stream_arn.split(':')[4]
          end
          
          def cross_region_streaming?
            # This would need to be compared with the DynamoDB table region
            # For now, return false as we don't have access to table details
            false
          end
          
          def cross_account_streaming?
            # This would need to be compared with the DynamoDB table account
            # For now, return false as we don't have access to table details
            false
          end
        end
      end
    end
  end
end