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
require 'pangea/resources/aws_nat_gateway/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS NAT Gateway with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] NAT Gateway attributes
      # @option attributes [String] :subnet_id The subnet ID (required, must be public subnet)
      # @option attributes [String, nil] :allocation_id Elastic IP allocation ID for public NAT
      # @option attributes [String] :connectivity_type 'public' or 'private' (default: 'public')
      # @option attributes [Hash] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs and computed properties
      #
      # @example Create a public NAT Gateway with Elastic IP
      #   eip = aws_eip(:nat_eip, { domain: "vpc" })
      #   
      #   nat = aws_nat_gateway(:main, {
      #     subnet_id: public_subnet.id,
      #     allocation_id: eip.id,
      #     tags: { Name: "main-nat-gateway" }
      #   })
      #
      # @example Create a private NAT Gateway
      #   nat = aws_nat_gateway(:private, {
      #     subnet_id: private_subnet.id,
      #     connectivity_type: "private",
      #     tags: { Name: "private-nat-gateway" }
      #   })
      def aws_nat_gateway(name, attributes = {})
        # Validate attributes using dry-struct
        nat_attrs = Types::Types::NatGatewayAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_nat_gateway, name) do
          subnet_id nat_attrs.subnet_id
          allocation_id nat_attrs.allocation_id if nat_attrs.allocation_id
          connectivity_type nat_attrs.connectivity_type if nat_attrs.connectivity_type != 'public'
          
          # Apply tags if present
          if nat_attrs.tags.any?
            tags do
              nat_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs and computed properties
        ref = ResourceReference.new(
          type: 'aws_nat_gateway',
          name: name,
          resource_attributes: nat_attrs.to_h,
          outputs: {
            id: "${aws_nat_gateway.#{name}.id}",
            allocation_id: "${aws_nat_gateway.#{name}.allocation_id}",
            subnet_id: "${aws_nat_gateway.#{name}.subnet_id}",
            network_interface_id: "${aws_nat_gateway.#{name}.network_interface_id}",
            private_ip: "${aws_nat_gateway.#{name}.private_ip}",
            public_ip: "${aws_nat_gateway.#{name}.public_ip}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:public?) { nat_attrs.public? }
        ref.define_singleton_method(:private?) { nat_attrs.private? }
        ref.define_singleton_method(:requires_elastic_ip?) { nat_attrs.requires_elastic_ip? }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)