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
require 'pangea/resources/aws_vpc_endpoint_connection_notification/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Manages VPC endpoint connection notifications for monitoring endpoint state changes.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_vpc_endpoint_connection_notification(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::VpcEndpointConnectionNotificationAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_vpc_endpoint_connection_notification, name) do
          vpc_endpoint_service_id attrs.vpc_endpoint_service_id if attrs.vpc_endpoint_service_id
          connection_notification_arn attrs.connection_notification_arn if attrs.connection_notification_arn
          connection_events attrs.connection_events if attrs.connection_events
          
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
          type: 'aws_vpc_endpoint_connection_notification',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_vpc_endpoint_connection_notification.#{name}.id}",
            vpc_endpoint_service_id: "${aws_vpc_endpoint_connection_notification.#{name}.vpc_endpoint_service_id}",
            connection_notification_arn: "${aws_vpc_endpoint_connection_notification.#{name}.connection_notification_arn}",
            connection_events: "${aws_vpc_endpoint_connection_notification.#{name}.connection_events}",
            notification_type: "${aws_vpc_endpoint_connection_notification.#{name}.notification_type}",
            state: "${aws_vpc_endpoint_connection_notification.#{name}.state}"
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