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
require 'pangea/resources/aws_subnet/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # AWS Subnet resource module that self-registers
    module AwsSubnet
      # Create an AWS Subnet with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Subnet attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_subnet(name, attributes = {})
        # Validate attributes using dry-struct
        subnet_attrs = AWS::Types::SubnetAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_subnet, name) do
          vpc_id subnet_attrs.vpc_id
          cidr_block subnet_attrs.cidr_block
          availability_zone subnet_attrs.availability_zone
          map_public_ip_on_launch subnet_attrs.map_public_ip_on_launch

          # Apply tags if present
          tags subnet_attrs.tags if subnet_attrs.tags.any?
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_subnet',
          name: name,
          resource_attributes: subnet_attrs.to_h,
          outputs: {
            id: "${aws_subnet.#{name}.id}",
            arn: "${aws_subnet.#{name}.arn}",
            availability_zone: "${aws_subnet.#{name}.availability_zone}",
            availability_zone_id: "${aws_subnet.#{name}.availability_zone_id}",
            cidr_block: "${aws_subnet.#{name}.cidr_block}",
            vpc_id: "${aws_subnet.#{name}.vpc_id}",
            owner_id: "${aws_subnet.#{name}.owner_id}"
          }
        )
      end
    end

    # Maintain backward compatibility by extending AWS module
    module AWS
      include AwsSubnet
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)
