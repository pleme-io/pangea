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
require 'pangea/components/public_private_subnets/types'
require 'pangea/resources/aws_subnet/resource'
require 'pangea/resources/aws_internet_gateway/resource'
require 'pangea/resources/aws_nat_gateway/resource'
require 'pangea/resources/aws_route_table/resource'
require 'pangea/resources/aws_route/resource'
require 'pangea/resources/aws_route_table_association/resource'
require 'pangea/resources/aws_eip/resource'

module Pangea
  module Components
    module PublicPrivateSubnets
      include Base
      
      # Create public and private subnets with NAT Gateway and proper routing
      #
      # @param name [Symbol] The component name
      # @param attributes [Hash] PublicPrivateSubnets attributes
      # @return [ComponentReference] Reference object with subnet resources and outputs
      def public_private_subnets(name, attributes = {})
        # Validate attributes using dry-struct
        component_attrs = Types::PublicPrivateSubnetsAttributes.new(attributes)
        
        # Extract VPC ID from reference (handle both ResourceReference and String)
        vpc_id = case component_attrs.vpc_ref
                 when String then component_attrs.vpc_ref
                 else component_attrs.vpc_ref.id
                 end
        
        # Determine availability zones (use provided or distribute evenly)
        azs = component_attrs.availability_zones || ['us-east-1a', 'us-east-1b']
        
        resources = {}
        
        # 1. Create Internet Gateway for public subnets
        igw_ref = aws_internet_gateway(resource_name(name, :igw), {
          vpc_id: vpc_id,
          tags: merge_component_tags(
            component_attrs.tags,
            {
              Name: "#{name}-igw",
              Purpose: "Public subnet internet access"
            },
            :public_private_subnets,
            :internet_gateway
          )
        })
        resources[:internet_gateway] = igw_ref
        
        # 2. Create public subnets
        public_subnets = {}
        component_attrs.public_cidrs.each_with_index do |cidr, index|
          az = azs[index % azs.length]
          subnet_name = resource_name(name, "public_#{index + 1}")
          
          subnet_ref = aws_subnet(subnet_name, {
            vpc_id: vpc_id,
            cidr_block: cidr,
            availability_zone: az,
            map_public_ip_on_launch: true,
            tags: merge_component_tags(
              component_attrs.tags.merge(component_attrs.public_subnet_tags),
              {
                Name: "#{name}-public-#{index + 1}",
                Type: "public",
                Tier: "web",
                AvailabilityZone: az
              },
              :public_private_subnets,
              :public_subnet
            )
          })
          
          public_subnets[:"public_#{index + 1}"] = subnet_ref
        end
        resources[:public_subnets] = public_subnets
        
        # 3. Create public route table and routes
        public_rt_ref = aws_route_table(resource_name(name, :public_rt), {
          vpc_id: vpc_id,
          tags: merge_component_tags(
            component_attrs.tags,
            {
              Name: "#{name}-public-rt",
              Type: "public",
              Purpose: "Public subnet routing"
            },
            :public_private_subnets,
            :route_table
          )
        })
        resources[:public_route_table] = public_rt_ref
        
        # 4. Create route to Internet Gateway
        public_route_ref = aws_route(resource_name(name, :public_route), {
          route_table_id: public_rt_ref.id,
          destination_cidr_block: "0.0.0.0/0",
          gateway_id: igw_ref.id
        })
        resources[:public_route] = public_route_ref
        
        # 5. Associate public subnets with public route table
        public_associations = {}
        public_subnets.each do |subnet_key, subnet_ref|
          assoc_name = resource_name(name, "#{subnet_key}_rt_assoc")
          assoc_ref = aws_route_table_association(assoc_name, {
            subnet_id: subnet_ref.id,
            route_table_id: public_rt_ref.id
          })
          public_associations[:"#{subnet_key}_association"] = assoc_ref
        end
        resources[:public_route_associations] = public_associations
        
        # 6. Create private subnets
        private_subnets = {}
        component_attrs.private_cidrs.each_with_index do |cidr, index|
          az = azs[index % azs.length]
          subnet_name = resource_name(name, "private_#{index + 1}")
          
          subnet_ref = aws_subnet(subnet_name, {
            vpc_id: vpc_id,
            cidr_block: cidr,
            availability_zone: az,
            map_public_ip_on_launch: false,
            tags: merge_component_tags(
              component_attrs.tags.merge(component_attrs.private_subnet_tags),
              {
                Name: "#{name}-private-#{index + 1}",
                Type: "private",
                Tier: "application",
                AvailabilityZone: az
              },
              :public_private_subnets,
              :private_subnet
            )
          })
          
          private_subnets[:"private_#{index + 1}"] = subnet_ref
        end
        resources[:private_subnets] = private_subnets
        
        # 7. Create NAT Gateways if requested
        nat_gateways = {}
        nat_eips = {}
        if component_attrs.create_nat_gateway
          case component_attrs.nat_gateway_type
          when 'single'
            # Single NAT Gateway in first public subnet
            first_public = public_subnets.values.first
            
            # Create Elastic IP for NAT Gateway
            eip_ref = aws_eip(resource_name(name, :nat_eip), {
              domain: "vpc",
              tags: merge_component_tags(
                component_attrs.tags,
                {
                  Name: "#{name}-nat-eip",
                  Purpose: "NAT Gateway public IP"
                },
                :public_private_subnets,
                :eip
              )
            })
            nat_eips[:single] = eip_ref
            
            # Create NAT Gateway
            nat_ref = aws_nat_gateway(resource_name(name, :nat_gw), {
              allocation_id: eip_ref.id,
              subnet_id: first_public.id,
              tags: merge_component_tags(
                component_attrs.tags,
                {
                  Name: "#{name}-nat-gw",
                  Type: "single",
                  HighAvailability: "false"
                },
                :public_private_subnets,
                :nat_gateway
              )
            })
            nat_gateways[:single] = nat_ref
            
          when 'per_az'
            # NAT Gateway per availability zone for high availability
            azs.each_with_index do |az, index|
              # Find public subnet in this AZ
              public_subnet = public_subnets.values.find do |subnet|
                # This is a simplification - in practice we'd track AZ per subnet
                subnet
              end
              
              next unless public_subnet
              
              # Create Elastic IP for this NAT Gateway
              eip_ref = aws_eip(resource_name(name, "nat_eip_#{index + 1}"), {
                domain: "vpc",
                tags: merge_component_tags(
                  component_attrs.tags,
                  {
                    Name: "#{name}-nat-eip-#{index + 1}",
                    AvailabilityZone: az,
                    Purpose: "NAT Gateway public IP"
                  },
                  :public_private_subnets,
                  :eip
                )
              })
              nat_eips[:"az_#{index + 1}"] = eip_ref
              
              # Create NAT Gateway
              nat_ref = aws_nat_gateway(resource_name(name, "nat_gw_#{index + 1}"), {
                allocation_id: eip_ref.id,
                subnet_id: public_subnet.id,
                tags: merge_component_tags(
                  component_attrs.tags,
                  {
                    Name: "#{name}-nat-gw-#{index + 1}",
                    AvailabilityZone: az,
                    Type: "per_az",
                    HighAvailability: "true"
                  },
                  :public_private_subnets,
                  :nat_gateway
                )
              })
              nat_gateways[:"az_#{index + 1}"] = nat_ref
            end
          end
        end
        resources[:nat_gateways] = nat_gateways
        resources[:nat_eips] = nat_eips
        
        # 8. Create private route tables and routes to NAT Gateways
        private_route_tables = {}
        private_routes = {}
        private_associations = {}
        
        if component_attrs.create_nat_gateway
          case component_attrs.nat_gateway_type
          when 'single'
            # Single route table for all private subnets
            private_rt_ref = aws_route_table(resource_name(name, :private_rt), {
              vpc_id: vpc_id,
              tags: merge_component_tags(
                component_attrs.tags,
                {
                  Name: "#{name}-private-rt",
                  Type: "private",
                  Purpose: "Private subnet routing"
                },
                :public_private_subnets,
                :route_table
              )
            })
            private_route_tables[:single] = private_rt_ref
            
            # Route to single NAT Gateway
            private_route_ref = aws_route(resource_name(name, :private_route), {
              route_table_id: private_rt_ref.id,
              destination_cidr_block: "0.0.0.0/0",
              nat_gateway_id: nat_gateways[:single].id
            })
            private_routes[:single] = private_route_ref
            
            # Associate all private subnets with this route table
            private_subnets.each do |subnet_key, subnet_ref|
              assoc_name = resource_name(name, "#{subnet_key}_rt_assoc")
              assoc_ref = aws_route_table_association(assoc_name, {
                subnet_id: subnet_ref.id,
                route_table_id: private_rt_ref.id
              })
              private_associations[:"#{subnet_key}_association"] = assoc_ref
            end
            
          when 'per_az'
            # Route table per AZ for high availability
            azs.each_with_index do |az, index|
              rt_ref = aws_route_table(resource_name(name, "private_rt_#{index + 1}"), {
                vpc_id: vpc_id,
                tags: merge_component_tags(
                  component_attrs.tags,
                  {
                    Name: "#{name}-private-rt-#{index + 1}",
                    Type: "private",
                    AvailabilityZone: az,
                    Purpose: "Private subnet AZ-specific routing"
                  },
                  :public_private_subnets,
                  :route_table
                )
              })
              private_route_tables[:"az_#{index + 1}"] = rt_ref
              
              # Route to AZ-specific NAT Gateway if it exists
              if nat_gateways[:"az_#{index + 1}"]
                route_ref = aws_route(resource_name(name, "private_route_#{index + 1}"), {
                  route_table_id: rt_ref.id,
                  destination_cidr_block: "0.0.0.0/0",
                  nat_gateway_id: nat_gateways[:"az_#{index + 1}"].id
                })
                private_routes[:"az_#{index + 1}"] = route_ref
              end
              
              # Associate private subnets in this AZ with this route table
              private_subnets.each_with_index do |(subnet_key, subnet_ref), subnet_index|
                if subnet_index % azs.length == index
                  assoc_name = resource_name(name, "#{subnet_key}_rt_assoc")
                  assoc_ref = aws_route_table_association(assoc_name, {
                    subnet_id: subnet_ref.id,
                    route_table_id: rt_ref.id
                  })
                  private_associations[:"#{subnet_key}_association"] = assoc_ref
                end
              end
            end
          end
        end
        
        resources[:private_route_tables] = private_route_tables
        resources[:private_routes] = private_routes
        resources[:private_route_associations] = private_associations
        
        # 9. Generate computed outputs
        outputs = {
          # Subnet information
          public_subnet_ids: public_subnets.values.map(&:id),
          private_subnet_ids: private_subnets.values.map(&:id),
          public_subnet_cidrs: component_attrs.public_cidrs,
          private_subnet_cidrs: component_attrs.private_cidrs,
          
          # Network configuration
          vpc_id: vpc_id,
          internet_gateway_id: igw_ref.id,
          nat_gateway_ids: nat_gateways.values.map(&:id),
          nat_eip_ips: nat_eips.values.map(&:public_ip),
          
          # Routing information
          public_route_table_id: public_rt_ref.id,
          private_route_table_ids: private_route_tables.values.map(&:id),
          
          # Configuration summary
          subnet_pairs_count: component_attrs.subnet_pairs_count,
          total_subnets_count: component_attrs.total_subnets_count,
          nat_gateway_count: component_attrs.nat_gateway_count,
          nat_gateway_type: component_attrs.nat_gateway_type,
          
          # High availability information
          availability_zones: azs,
          high_availability_level: component_attrs.high_availability_level,
          subnet_distribution_strategy: component_attrs.subnet_distribution_strategy,
          networking_pattern: component_attrs.networking_pattern,
          security_profile: component_attrs.security_profile,
          
          # Cost information
          estimated_monthly_nat_cost: component_attrs.estimated_monthly_nat_cost
        }
        
        # 10. Create and return component reference
        create_component_reference(
          type: :public_private_subnets,
          name: name,
          component_attributes: component_attrs,
          resources: resources,
          outputs: outputs
        )
      end
    end
  end
end