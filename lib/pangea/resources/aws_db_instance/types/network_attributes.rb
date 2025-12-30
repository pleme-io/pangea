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
        # Network configuration attributes for AWS RDS Database Instance
        class NetworkAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # DB subnet group name
          attribute :db_subnet_group_name, Resources::Types::String.optional

          # VPC security group IDs
          attribute :vpc_security_group_ids, Resources::Types::Array.of(Resources::Types::String).default([].freeze)

          # Availability zone
          attribute :availability_zone, Resources::Types::String.optional

          # Multi-AZ deployment
          attribute :multi_az, Resources::Types::Bool.default(false)

          # Whether the instance is publicly accessible
          attribute :publicly_accessible, Resources::Types::Bool.default(false)
        end
      end
    end
  end
end
