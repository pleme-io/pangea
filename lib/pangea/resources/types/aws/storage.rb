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

require_relative 'core'

module Pangea
  module Resources
    module Types
      # S3 bucket versioning
      S3Versioning = String.enum('Enabled', 'Suspended', 'Disabled')

      # EFS-specific types
      EfsPerformanceMode = String.constrained(included_in: ['generalPurpose', 'maxIO'])
      EfsThroughputMode = String.constrained(included_in: ['bursting', 'provisioned', 'elastic'])

      # EFS Lifecycle Policy configuration
      EfsLifecyclePolicy = Hash.schema(
        transition_to_ia?: String.constrained(included_in: ['AFTER_7_DAYS', 'AFTER_14_DAYS', 'AFTER_30_DAYS', 'AFTER_60_DAYS', 'AFTER_90_DAYS']).optional,
        transition_to_primary_storage_class?: String.constrained(included_in: ['AFTER_1_ACCESS']).optional
      ).constructor { |value|
        if value.empty? || (!value[:transition_to_ia] && !value[:transition_to_primary_storage_class])
          raise Dry::Types::ConstraintError, "EFS lifecycle policy must specify at least one transition"
        end
        value
      }

      # EFS Access Point POSIX user
      EfsPosixUser = Hash.schema(
        uid: Integer.constrained(gteq: 0, lteq: 4294967295),
        gid: Integer.constrained(gteq: 0, lteq: 4294967295),
        secondary_gids?: Array.of(Integer.constrained(gteq: 0, lteq: 4294967295)).optional
      )

      # EFS Access Point root directory creation info
      EfsCreationInfo = Hash.schema(
        owner_uid: Integer.constrained(gteq: 0, lteq: 4294967295),
        owner_gid: Integer.constrained(gteq: 0, lteq: 4294967295),
        permissions: String.constrained(format: /\A[0-7]{3,4}\z/)
      )

      # EFS Access Point root directory
      EfsRootDirectory = Hash.schema(
        path?: String.constrained(format: /\A\/.*/).default("/"),
        creation_info?: EfsCreationInfo.optional
      )
    end
  end
end
