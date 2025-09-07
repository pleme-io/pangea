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
        # NAT Gateway resource attributes with validation
        class NatGatewayAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required: Must be in a public subnet
          attribute :subnet_id, Resources::Types::String
          
          # Optional: Elastic IP allocation ID for public NAT gateway
          # If not provided, AWS will create a private NAT gateway
          attribute :allocation_id, Resources::Types::String.optional.default(nil)
          
          # Optional: Connectivity type (public or private)
          attribute :connectivity_type, Resources::Types::String.default('public').enum('public', 'private')
          
          attribute :tags, Resources::Types::AwsTags
          
          # Validate consistency between allocation_id and connectivity_type
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # If allocation_id is provided, connectivity_type must be public
            if attrs[:allocation_id] && attrs[:connectivity_type] == 'private'
              raise Dry::Struct::Error, "allocation_id can only be used with public NAT gateways"
            end
            
            # If connectivity_type is public but no allocation_id, that's ok (AWS will allocate)
            # But we should warn in computed properties
            
            super(attrs)
          end
          
          # Computed properties
          def public?
            connectivity_type == 'public'
          end
          
          def private?
            connectivity_type == 'private'
          end
          
          def requires_elastic_ip?
            public? && allocation_id.nil?
          end
          
          def to_h
            {
              subnet_id: subnet_id,
              allocation_id: allocation_id,
              connectivity_type: connectivity_type,
              tags: tags
            }.compact
          end
        end
      end
    end
  end
end