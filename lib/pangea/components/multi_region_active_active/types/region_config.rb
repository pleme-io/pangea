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
    module MultiRegionActiveActive
      # Region configuration for active-active deployment
      class RegionConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :region, Types::String
        attribute :vpc_cidr, Types::String
        attribute :availability_zones, Types::Array.of(Types::String).constrained(min_size: 2, max_size: 6)
        attribute :vpc_ref, Types::ResourceReference.optional
        attribute :is_primary, Types::Bool.default(false)
        attribute :database_priority, Types::Integer.default(100)
        attribute :write_weight, Types::Integer.default(100)
      end
    end
  end
end
