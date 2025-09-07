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
        class CloudTrailEventDataStoreAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :name, Resources::Types::String
          attribute :multi_region_enabled, Resources::Types::Bool.default(true)
          attribute :organization_enabled, Resources::Types::Bool.default(false)
          attribute :retention_period, Resources::Types::Integer.default(2555) # 7 years
          attribute :termination_protection_enabled, Resources::Types::Bool.default(true)
          
          attribute :tags, Resources::Types::AwsTags
          
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            if attrs[:retention_period]
              period = attrs[:retention_period]
              if period < 7 || period > 2555
                raise Dry::Struct::Error, "retention_period must be between 7 and 2555 days"
              end
            end
            
            super(attrs)
          end
          
          def estimated_monthly_cost_usd
            # CloudTrail Lake pricing: $2.50 per million events
            estimated_events = organization_enabled ? 10_000_000 : 1_000_000
            event_cost = (estimated_events / 1_000_000.0) * 2.50
            
            # Storage cost based on retention
            storage_cost = (retention_period / 365.0) * 10.0 # $10 per year of retention
            
            (event_cost + storage_cost).round(2)
          end
          
          def to_h
            {
              name: name,
              multi_region_enabled: multi_region_enabled,
              organization_enabled: organization_enabled,
              retention_period: retention_period,
              termination_protection_enabled: termination_protection_enabled,
              tags: tags
            }
          end
        end
      end
    end
  end
end