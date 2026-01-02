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
        # Filter types for S3 replication rules
        module S3BucketReplicationFilter
          # Tag filter schema
          TagFilter = Resources::Types::Hash.schema(
            key: Resources::Types::String,
            value: Resources::Types::String
          )

          # And condition filter schema
          AndFilter = Resources::Types::Hash.schema(
            prefix?: Resources::Types::String.optional,
            tags?: Resources::Types::Hash.optional
          )

          # Complete filter schema
          Filter = Resources::Types::Hash.schema(
            prefix?: Resources::Types::String.optional,
            tag?: TagFilter.optional,
            and?: AndFilter.optional
          )
        end
      end
    end
  end
end
