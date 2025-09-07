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
require 'pangea/resources/aws_docdb_event_subscription/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Provides a DocumentDB event subscription resource.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_docdb_event_subscription(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::DocdbEventSubscriptionAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_docdb_event_subscription, name) do
          name attrs.name if attrs.name
          sns_topic_arn attrs.sns_topic_arn if attrs.sns_topic_arn
          source_type attrs.source_type if attrs.source_type
          source_ids attrs.source_ids if attrs.source_ids
          event_categories attrs.event_categories if attrs.event_categories
          enabled attrs.enabled if attrs.enabled
          
          # Apply tags if present
          if attrs.tags.any?
            tags do
              attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_docdb_event_subscription',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_docdb_event_subscription.#{name}.id}",
            arn: "${aws_docdb_event_subscription.#{name}.arn}",
            customer_aws_id: "${aws_docdb_event_subscription.#{name}.customer_aws_id}"
          },
          computed_properties: {
            # Computed properties from type definitions
          }
        )
      end
    end
  end
end


# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)