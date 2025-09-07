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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_cloudtrail_event_data_store/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      def aws_cloudtrail_event_data_store(name, attributes = {})
        store_attrs = Types::Types::CloudTrailEventDataStoreAttributes.new(attributes)
        
        resource(:aws_cloudtrail_event_data_store, name) do
          name store_attrs.name
          multi_region_enabled store_attrs.multi_region_enabled
          organization_enabled store_attrs.organization_enabled
          retention_period store_attrs.retention_period
          termination_protection_enabled store_attrs.termination_protection_enabled
          
          if store_attrs.tags.any?
            tags do
              store_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        ResourceReference.new(
          type: 'aws_cloudtrail_event_data_store',
          name: name,
          resource_attributes: store_attrs.to_h,
          outputs: {
            id: "${aws_cloudtrail_event_data_store.#{name}.id}",
            arn: "${aws_cloudtrail_event_data_store.#{name}.arn}",
            name: "${aws_cloudtrail_event_data_store.#{name}.name}",
            tags_all: "${aws_cloudtrail_event_data_store.#{name}.tags_all}"
          },
          computed_properties: {
            estimated_monthly_cost_usd: store_attrs.estimated_monthly_cost_usd
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)