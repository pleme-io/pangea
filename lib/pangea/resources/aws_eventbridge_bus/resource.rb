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
require 'pangea/resources/aws_eventbridge_bus/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS EventBridge Bus with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] EventBridge bus attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_eventbridge_bus(name, attributes = {})
        # Validate attributes using dry-struct
        bus_attrs = Types::EventBridgeBusAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_cloudwatch_event_bus, name) do
          event_bus_name bus_attrs.name
          event_source_name bus_attrs.event_source_name if bus_attrs.event_source_name
          kms_key_id bus_attrs.kms_key_id if bus_attrs.kms_key_id

          # Apply tags if present
          if bus_attrs.tags.any?
            tags do
              bus_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_cloudwatch_event_bus',
          name: name,
          resource_attributes: bus_attrs.to_h,
          outputs: {
            id: "${aws_cloudwatch_event_bus.#{name}.id}",
            arn: "${aws_cloudwatch_event_bus.#{name}.arn}",
            event_bus_name: "${aws_cloudwatch_event_bus.#{name}.event_bus_name}",
            tags_all: "${aws_cloudwatch_event_bus.#{name}.tags_all}"
          },
          computed_properties: {
            is_default: bus_attrs.is_default?,
            is_custom: bus_attrs.is_custom?,
            is_aws_service: bus_attrs.is_aws_service?,
            is_partner: bus_attrs.is_partner?,
            has_encryption: bus_attrs.has_encryption?,
            bus_type: bus_attrs.bus_type,
            estimated_monthly_cost: bus_attrs.estimated_monthly_cost,
            max_rules_per_bus: bus_attrs.max_rules_per_bus
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)