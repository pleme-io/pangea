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

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Shared S3 event types for bucket notifications
        module S3Events
          # All valid S3 notification event types
          S3_EVENT_TYPES = [
            's3:ObjectCreated:*',
            's3:ObjectCreated:Put',
            's3:ObjectCreated:Post',
            's3:ObjectCreated:Copy',
            's3:ObjectCreated:CompleteMultipartUpload',
            's3:ObjectRemoved:*',
            's3:ObjectRemoved:Delete',
            's3:ObjectRemoved:DeleteMarkerCreated',
            's3:ObjectRestore:*',
            's3:ObjectRestore:Post',
            's3:ObjectRestore:Completed',
            's3:Replication:*',
            's3:Replication:OperationFailedReplication',
            's3:Replication:OperationNotTracked',
            's3:Replication:OperationMissedThreshold',
            's3:Replication:OperationReplicatedAfterThreshold'
          ].freeze

          # Reusable event type enum
          EventType = Resources::Types::String.enum(*S3_EVENT_TYPES)

          # Array of events type
          EventsArray = Resources::Types::Array.of(EventType)
        end
      end
    end
  end
end
