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
require 'pangea/resources/aws_ec2_transit_gateway_vpc_attachment/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS EC2 Transit Gateway VPC Attachment with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Transit Gateway VPC Attachment attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_ec2_transit_gateway_vpc_attachment(name, attributes = {})
        # Validate attributes using dry-struct
        attachment_attrs = Types::TransitGatewayVpcAttachmentAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_ec2_transit_gateway_vpc_attachment, name) do
          # Required attributes
          transit_gateway_id attachment_attrs.transit_gateway_id
          vpc_id attachment_attrs.vpc_id
          subnet_ids attachment_attrs.subnet_ids
          
          # Optional appliance mode support
          if attachment_attrs.appliance_mode_support
            appliance_mode_support attachment_attrs.appliance_mode_support
          end
          
          # Optional DNS support
          if attachment_attrs.dns_support
            dns_support attachment_attrs.dns_support
          end
          
          # Optional IPv6 support
          if attachment_attrs.ipv6_support
            ipv6_support attachment_attrs.ipv6_support
          end
          
          # Optional default route table association
          if !attachment_attrs.transit_gateway_default_route_table_association.nil?
            transit_gateway_default_route_table_association attachment_attrs.transit_gateway_default_route_table_association
          end
          
          # Optional default route table propagation
          if !attachment_attrs.transit_gateway_default_route_table_propagation.nil?
            transit_gateway_default_route_table_propagation attachment_attrs.transit_gateway_default_route_table_propagation
          end
          
          # Apply tags if present
          if attachment_attrs.tags.any?
            tags do
              attachment_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_ec2_transit_gateway_vpc_attachment',
          name: name,
          resource_attributes: attachment_attrs.to_h,
          outputs: {
            id: "${aws_ec2_transit_gateway_vpc_attachment.#{name}.id}",
            vpc_owner_id: "${aws_ec2_transit_gateway_vpc_attachment.#{name}.vpc_owner_id}",
            tags_all: "${aws_ec2_transit_gateway_vpc_attachment.#{name}.tags_all}"
          },
          computed_attributes: {
            is_highly_available: attachment_attrs.is_highly_available?,
            supports_appliance_mode_inspection: attachment_attrs.supports_appliance_mode_inspection?,
            estimated_monthly_cost: attachment_attrs.estimated_monthly_cost,
            availability_zones_count: attachment_attrs.availability_zones_count,
            security_considerations: attachment_attrs.security_considerations,
            routing_behavior: attachment_attrs.routing_behavior
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)