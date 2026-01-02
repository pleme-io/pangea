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
        # Excluded cluster member configuration for Aurora endpoints
        class ExcludedMember < Dry::Struct
          # The DB instance identifier for the cluster member to exclude
          attribute :db_instance_identifier, Resources::Types::String
        end

        # Static cluster member configuration for Aurora endpoints
        class StaticMember < Dry::Struct
          # The DB instance identifier for the static cluster member
          attribute :db_instance_identifier, Resources::Types::String
        end
      end
    end
  end
end
