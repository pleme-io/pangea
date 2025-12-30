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

require 'dry-types'

module Pangea
  module Resources
    module AWS
      module Types
        # Source and encryption schemas for Kinesis Firehose Delivery Stream
        module FirehoseSourceAndEncryption
          include Dry.Types()

          # Kinesis source configuration
          KinesisSourceConfiguration = Hash.schema(
            kinesis_stream_arn: String,
            role_arn: String
          )

          # Server-side encryption configuration
          ServerSideEncryption = Hash.schema(
            enabled?: Bool.default(false),
            key_type?: String.enum('AWS_OWNED_CMK', 'CUSTOMER_MANAGED_CMK').optional,
            key_arn?: String.optional
          )
        end
      end
    end
  end
end
