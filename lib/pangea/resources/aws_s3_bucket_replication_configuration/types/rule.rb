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
require_relative 'filter'
require_relative 'destination'

module Pangea
  module Resources
    module AWS
      module Types
        # Rule types for S3 replication configuration
        module S3BucketReplicationRule
          # Status enum type (without default)
          Status = Resources::Types::String.enum('Enabled', 'Disabled')

          # Status with default values
          StatusDefaultEnabled = Resources::Types::String.default('Enabled').enum('Enabled', 'Disabled')
          StatusDefaultDisabled = Resources::Types::String.default('Disabled').enum('Enabled', 'Disabled')

          # Delete marker replication
          DeleteMarkerReplication = Resources::Types::Hash.schema(
            status: StatusDefaultDisabled
          )

          # Existing object replication
          ExistingObjectReplication = Resources::Types::Hash.schema(
            status: StatusDefaultDisabled
          )

          # Replica modifications in source selection
          ReplicaModifications = Resources::Types::Hash.schema(
            status: StatusDefaultDisabled
          )

          # SSE KMS encrypted objects in source selection
          SseKmsEncryptedObjects = Resources::Types::Hash.schema(
            status: StatusDefaultDisabled
          )

          # Source selection criteria
          SourceSelectionCriteria = Resources::Types::Hash.schema(
            replica_modifications?: ReplicaModifications.optional,
            sse_kms_encrypted_objects?: SseKmsEncryptedObjects.optional
          )

          # Complete rule schema
          Rule = Resources::Types::Hash.schema(
            id?: Resources::Types::String.optional,
            priority?: Resources::Types::Integer.constrained(gteq: 0).optional,
            status: StatusDefaultEnabled,
            filter?: S3BucketReplicationFilter::Filter.optional,
            destination: S3BucketReplicationDestination::Destination,
            delete_marker_replication?: DeleteMarkerReplication.optional,
            existing_object_replication?: ExistingObjectReplication.optional,
            source_selection_criteria?: SourceSelectionCriteria.optional
          )

          # Array of rules type
          Rules = Resources::Types::Array.of(Rule).constrained(min_size: 1)
        end
      end
    end
  end
end
