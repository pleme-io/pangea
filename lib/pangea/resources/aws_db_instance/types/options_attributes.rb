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
        # Additional options and tags for AWS RDS Database Instance
        class OptionsAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Auto minor version upgrade
          attribute :auto_minor_version_upgrade, Resources::Types::Bool.default(true)

          # Deletion protection
          attribute :deletion_protection, Resources::Types::Bool.default(false)

          # Skip final snapshot on deletion
          attribute :skip_final_snapshot, Resources::Types::Bool.default(true)

          # Final snapshot identifier
          attribute :final_snapshot_identifier, Resources::Types::String.optional

          # Tags to apply to the database
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)
        end
      end
    end
  end
end
