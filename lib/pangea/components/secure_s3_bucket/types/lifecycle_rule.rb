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
  module Components
    module SecureS3Bucket
      # Lifecycle rule configuration
      class LifecycleRule < Dry::Struct
        transform_keys(&:to_sym)

        attribute :id, Types::String
        attribute :status, Types::String.default("Enabled").enum('Enabled', 'Disabled')
        attribute :filter, Types::Hash.optional

        # Transition rules
        attribute :transitions, Types::Array.default([].freeze).constructor { |value|
          # Validate transition storage classes and days
          valid_storage_classes = [
            'STANDARD_IA', 'ONEZONE_IA', 'INTELLIGENT_TIERING', 'GLACIER_IR',
            'GLACIER', 'DEEP_ARCHIVE'
          ]

          value.each do |transition|
            unless valid_storage_classes.include?(transition[:storage_class])
              raise Dry::Types::ConstraintError, "Invalid storage class: #{transition[:storage_class]}"
            end

            unless transition[:days] && transition[:days] >= 0
              raise Dry::Types::ConstraintError, "Transition days must be non-negative"
            end
          end

          value
        }

        # Expiration rules
        attribute :expiration, Types::Hash.optional
        attribute :noncurrent_version_expiration, Types::Hash.optional
        attribute :noncurrent_version_transitions, Types::Array.default([].freeze)
        attribute :abort_incomplete_multipart_upload, Types::Hash.optional
      end
    end
  end
end
