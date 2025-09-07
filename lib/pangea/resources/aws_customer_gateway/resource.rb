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
require 'pangea/resources/aws_customer_gateway/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Customer Gateway with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Customer Gateway attributes
      #   @option attributes [Integer] :bgp_asn (required) BGP ASN for the customer gateway
      #   @option attributes [String] :ip_address (required) Public IP address of the customer gateway
      #   @option attributes [String] :type (required) Gateway type (ipsec.1)
      #   @option attributes [String] :certificate_arn (optional) Certificate Manager certificate ARN
      #   @option attributes [String] :device_name (optional) Name of the customer gateway device
      #   @option attributes [Hash] :tags (optional) Resource tags
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_customer_gateway(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::CustomerGatewayAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_customer_gateway, name) do
          # Required attributes
          bgp_asn attrs.bgp_asn
          ip_address attrs.ip_address
          type attrs.type
          
          # Optional certificate for authentication
          certificate_arn attrs.certificate_arn if attrs.certificate_arn
          
          # Optional device name for identification
          device_name attrs.device_name if attrs.device_name
          
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
          type: 'aws_customer_gateway',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_customer_gateway.#{name}.id}",
            arn: "${aws_customer_gateway.#{name}.arn}",
            bgp_asn: "${aws_customer_gateway.#{name}.bgp_asn}",
            certificate_arn: "${aws_customer_gateway.#{name}.certificate_arn}",
            device_name: "${aws_customer_gateway.#{name}.device_name}",
            ip_address: "${aws_customer_gateway.#{name}.ip_address}",
            type: "${aws_customer_gateway.#{name}.type}",
            tags_all: "${aws_customer_gateway.#{name}.tags_all}"
          },
          computed_properties: {
            uses_certificate_authentication: attrs.uses_certificate_authentication?,
            has_device_name: attrs.has_device_name?,
            is_16bit_asn: attrs.is_16bit_asn?,
            is_32bit_asn: attrs.is_32bit_asn?,
            gateway_type: attrs.gateway_type
          }
        )
      end
    end
  end
end


# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)