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
        # Type-safe attributes for AWS IAM User resources
        class IamUserAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # User name (required)
          attribute :name, Resources::Types::String

          # Path for the user (default: "/")
          attribute :path, Resources::Types::String.default('/')

          # Permissions boundary ARN
          attribute :permissions_boundary, Resources::Types::String.optional

          # Force destroy user on deletion (removes dependencies)
          attribute :force_destroy, Resources::Types::Bool.default(false)

          # Tags to apply to the user
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)
        end
      end
    end
  end
end
