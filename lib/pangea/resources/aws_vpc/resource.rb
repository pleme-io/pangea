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
require 'pangea/resources/aws_vpc/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # AWS VPC resource module that self-registers
    module AwsVpc
      # Create an AWS VPC with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] VPC attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_vpc(name, attributes = {})
        # Validate attributes using dry-struct
        vpc_attrs = AWS::Types::VpcAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_vpc, name) do
          cidr_block vpc_attrs.cidr_block
          enable_dns_hostnames vpc_attrs.enable_dns_hostnames
          enable_dns_support vpc_attrs.enable_dns_support
          instance_tenancy vpc_attrs.instance_tenancy
          
          # Apply tags if present
          if vpc_attrs.tags.any?
            tags do
              vpc_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_vpc',
          name: name,
          resource_attributes: vpc_attrs.to_h,
          outputs: {
            id: "${aws_vpc.#{name}.id}",
            arn: "${aws_vpc.#{name}.arn}",
            cidr_block: "${aws_vpc.#{name}.cidr_block}",
            default_security_group_id: "${aws_vpc.#{name}.default_security_group_id}",
            default_route_table_id: "${aws_vpc.#{name}.default_route_table_id}",
            default_network_acl_id: "${aws_vpc.#{name}.default_network_acl_id}",
            dhcp_options_id: "${aws_vpc.#{name}.dhcp_options_id}",
            main_route_table_id: "${aws_vpc.#{name}.main_route_table_id}",
            owner_id: "${aws_vpc.#{name}.owner_id}"
          }
        )
      end
    end
    
    # Maintain backward compatibility by extending AWS module
    module AWS
      include AwsVpc
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::AWS)