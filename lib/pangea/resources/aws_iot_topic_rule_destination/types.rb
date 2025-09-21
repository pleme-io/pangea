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
      class IotTopicRuleDestinationAttributes < Dry::Struct
        attribute :enabled, Resources::Types::Bool.default(true)
        attribute :vpc_configuration, Resources::Types::Hash.schema(
          subnet_ids: Types::Array.of(Types::String),
          security_group_ids: Types::Array.of(Types::String),
          vpc_id: Types::String,
          role_arn: Types::String
        )
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)
        
        def vpc_subnet_count
          vpc_configuration[:subnet_ids].length
        end
        
        def security_group_count
          vpc_configuration[:security_group_ids].length
        end
        
        def is_multi_az?
          vpc_subnet_count > 1
        end
      end
    end
  end
end