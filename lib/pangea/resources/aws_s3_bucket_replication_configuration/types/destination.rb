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
        # Destination types for S3 replication rules
        module S3BucketReplicationDestination
          # Status enum type (without default - applied in schemas)
          Status = Resources::Types::String.enum('Enabled', 'Disabled')

          # Status with disabled default
          StatusDefaultDisabled = Resources::Types::String.default('Disabled').enum('Enabled', 'Disabled')

          # Access control translation for cross-account replication
          AccessControlTranslation = Resources::Types::Hash.schema(
            owner: Resources::Types::String.default('Destination').enum('Destination')
          )

          # Encryption configuration for replicated objects
          EncryptionConfiguration = Resources::Types::Hash.schema(
            replica_kms_key_id: Resources::Types::String
          )

          # Event threshold configuration
          EventThreshold = Resources::Types::Hash.schema(
            minutes: Resources::Types::Integer.constrained(gteq: 15)
          )

          # Metrics configuration
          Metrics = Resources::Types::Hash.schema(
            status: StatusDefaultDisabled,
            event_threshold?: EventThreshold.optional
          )

          # Time configuration for replication time control
          TimeConfig = Resources::Types::Hash.schema(
            minutes: Resources::Types::Integer.constrained(gteq: 15)
          )

          # Replication time control
          ReplicationTime = Resources::Types::Hash.schema(
            status: StatusDefaultDisabled,
            time?: TimeConfig.optional
          )

          # Storage class enum
          StorageClass = Resources::Types::String.enum(
            'STANDARD', 'REDUCED_REDUNDANCY', 'STANDARD_IA', 'ONEZONE_IA',
            'INTELLIGENT_TIERING', 'GLACIER', 'DEEP_ARCHIVE', 'OUTPOSTS',
            'GLACIER_IR'
          )

          # Complete destination schema
          Destination = Resources::Types::Hash.schema(
            bucket: Resources::Types::String,
            storage_class?: StorageClass.optional,
            account_id?: Resources::Types::String.optional,
            access_control_translation?: AccessControlTranslation.optional,
            encryption_configuration?: EncryptionConfiguration.optional,
            metrics?: Metrics.optional,
            replication_time?: ReplicationTime.optional
          )
        end
      end
    end
  end
end
