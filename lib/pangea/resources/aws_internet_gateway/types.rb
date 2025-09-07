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
  module Resources
    module AWS
      module Types
        # Internet Gateway resource attributes with validation
        class InternetGatewayAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # VPC ID is optional as it can be attached separately
          attribute :vpc_id, Resources::Types::String.optional.default(nil)
          attribute :tags, Resources::Types::AwsTags
          
          # Computed properties
          def attached?
            !vpc_id.nil?
          end
          
          def to_h
            {
              vpc_id: vpc_id,
              tags: tags
            }.compact
          end
        end
      end
    end
  end
end