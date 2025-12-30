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
          T = Dry.Types()

          # Kinesis source configuration
          KinesisSourceConfiguration = T['hash'].schema(
            kinesis_stream_arn: T['string'],
            role_arn: T['string']
          )

          # Server-side encryption configuration
          ServerSideEncryption = T['hash'].schema(
            enabled?: T['bool'].default(false),
            key_type?: T['string'].enum('AWS_OWNED_CMK', 'CUSTOMER_MANAGED_CMK').optional,
            key_arn?: T['string'].optional
          )
        end
      end
    end
  end
end
