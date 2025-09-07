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


require 'pangea/components/base'
require 'pangea/components/reference'
require 'pangea/components/vpc_with_subnets/types'
require 'pangea/component_registry'

module Pangea
  module Components
    # VPC with Subnets component for creating a complete network setup
    #
    # Creates a VPC with public and/or private subnets across multiple
    # availability zones. This component demonstrates the auto-registration
    # pattern for components.
    #
    # @example Basic usage
    #   require 'pangea/components/vpc_with_subnets/component'
    #   
    #   template :infrastructure do
    #     network = vpc_with_subnets(:main, {
    #       vpc_cidr: "10.0.0.0/16",
    #       availability_zones: ["us-east-1a", "us-east-1b", "us-east-1c"]
    #     })
    #     
    #     # Access created resources
    #     app_server = aws_instance(:app, {
    #       subnet_id: network.private_subnets.first.id
    #     })
    #   end
    module VpcWithSubnets
      include Base
      
      # Create a VPC with public and private subnets
      #
      # @param name [Symbol] Component name
      # @param attributes [Hash] Component configuration
      # @option attributes [String] :vpc_cidr VPC CIDR block (required)
      # @option attributes [Array<String>] :availability_zones AZs to create subnets in (required)
      # @option attributes [Boolean] :create_private_subnets Create private subnets (default: true)
      # @option attributes [Boolean] :create_public_subnets Create public subnets (default: true)
      # @option attributes [Integer] :subnet_bits Additional bits for subnet mask (default: 8)
      # @option attributes [Hash] :vpc_tags Tags for VPC
      # @option attributes [Hash] :public_subnet_tags Tags for public subnets
      # @option attributes [Hash] :private_subnet_tags Tags for private subnets
      # @option attributes [Hash] :common_tags Tags applied to all resources
      # @option attributes [String] :name_prefix Prefix for resource names
      # @return [ComponentReference] Reference to created resources
      def vpc_with_subnets(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::VpcWithSubnetsAttributes.new(attributes)
        
        # Generate name prefix if not provided
        name_prefix = attrs.name_prefix || name.to_s
        
        # Create VPC
        vpc_name = component_resource_name(name, :vpc)
        vpc_tags = merge_tags(attrs.common_tags, attrs.vpc_tags).merge(
          Name: "#{name_prefix}-vpc"
        )
        
        resource(:aws_vpc, vpc_name) do
          cidr_block attrs.vpc_cidr
          enable_dns_hostnames attrs.enable_dns_hostnames
          enable_dns_support attrs.enable_dns_support
          
          tags vpc_tags
        end
        
        # Track created resources
        resources = { 
          vpc: { 
            type: :aws_vpc, 
            name: vpc_name,
            id: "${aws_vpc.#{vpc_name}.id}"
          } 
        }
        public_subnets = []
        private_subnets = []
        
        # Create subnets for each AZ
        attrs.availability_zones.each_with_index do |az, idx|
          az_suffix = az.split('-').last
          
          # Create public subnet
          if attrs.create_public_subnets
            public_subnet_name = component_resource_name(name, :public_subnet, az_suffix)
            public_cidr = calculate_subnet_cidr(attrs.vpc_cidr, idx * 2, attrs.subnet_bits)
            public_tags = merge_tags(attrs.common_tags, attrs.public_subnet_tags).merge(
              Name: "#{name_prefix}-public-#{az_suffix}",
              Type: "public"
            )
            
            resource(:aws_subnet, public_subnet_name) do
              vpc_id "${aws_vpc.#{vpc_name}.id}"
              cidr_block public_cidr
              availability_zone az
              map_public_ip_on_launch true
              
              tags public_tags
            end
            
            public_subnets << {
              type: :aws_subnet,
              name: public_subnet_name,
              id: "${aws_subnet.#{public_subnet_name}.id}"
            }
          end
          
          # Create private subnet
          if attrs.create_private_subnets
            private_subnet_name = component_resource_name(name, :private_subnet, az_suffix)
            private_cidr = calculate_subnet_cidr(attrs.vpc_cidr, idx * 2 + 1, attrs.subnet_bits)
            private_tags = merge_tags(attrs.common_tags, attrs.private_subnet_tags).merge(
              Name: "#{name_prefix}-private-#{az_suffix}",
              Type: "private"
            )
            
            resource(:aws_subnet, private_subnet_name) do
              vpc_id "${aws_vpc.#{vpc_name}.id}"
              cidr_block private_cidr
              availability_zone az
              map_public_ip_on_launch false
              
              tags private_tags
            end
            
            private_subnets << {
              type: :aws_subnet,
              name: private_subnet_name,
              id: "${aws_subnet.#{private_subnet_name}.id}"
            }
          end
        end
        
        # Add subnets to resources
        resources[:public_subnets] = public_subnets unless public_subnets.empty?
        resources[:private_subnets] = private_subnets unless private_subnets.empty?
        
        # Compute useful outputs
        outputs = {
          vpc_id: "${aws_vpc.#{vpc_name}.id}",
          vpc_cidr: attrs.vpc_cidr,
          availability_zones: attrs.availability_zones,
          public_subnet_ids: public_subnets.map { |s| s[:id] },
          private_subnet_ids: private_subnets.map { |s| s[:id] },
          subnet_count: public_subnets.length + private_subnets.length
        }
        
        # Return component reference
        ComponentReference.new(
          type: 'vpc_with_subnets',
          name: name,
          resources: resources,
          attributes: attrs.to_h,
          outputs: outputs
        )
      end
    end
  end
end

# Auto-register this component when loaded
Pangea::ComponentRegistry.register_component(Pangea::Components::VpcWithSubnets)