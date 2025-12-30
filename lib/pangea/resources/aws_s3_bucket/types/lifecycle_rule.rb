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
        # Storage class enum for transitions
        STORAGE_CLASSES = %w[STANDARD_IA INTELLIGENT_TIERING ONEZONE_IA GLACIER DEEP_ARCHIVE].freeze

        # Lifecycle rule transition type
        LifecycleTransition = Resources::Types::Hash.schema(
          days: Resources::Types::Integer,
          storage_class: Resources::Types::String.enum(*STORAGE_CLASSES)
        )

        # Lifecycle rule expiration type
        LifecycleExpiration = Resources::Types::Hash.schema(
          days?: Resources::Types::Integer.optional,
          expired_object_delete_marker?: Resources::Types::Bool.optional
        )

        # Noncurrent version expiration type
        NoncurrentVersionExpiration = Resources::Types::Hash.schema(
          days: Resources::Types::Integer
        )

        # Complete lifecycle rule type
        LifecycleRule = Resources::Types::Hash.schema(
          id: Resources::Types::String,
          enabled: Resources::Types::Bool.default(true),
          prefix?: Resources::Types::String.optional,
          tags?: Resources::Types::Hash.optional,
          transition?: Resources::Types::Array.of(LifecycleTransition).optional,
          expiration?: LifecycleExpiration.optional,
          noncurrent_version_transition?: Resources::Types::Array.of(LifecycleTransition).optional,
          noncurrent_version_expiration?: NoncurrentVersionExpiration.optional
        )
      end
    end
  end
end
