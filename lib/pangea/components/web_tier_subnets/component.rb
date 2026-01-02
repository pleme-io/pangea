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
require 'pangea/components/web_tier_subnets/types'
require 'pangea/resources/aws_subnet/resource'
require 'pangea/resources/aws_internet_gateway/resource'
require 'pangea/resources/aws_route_table/resource'
require 'pangea/resources/aws_route/resource'
require 'pangea/resources/aws_route_table_association/resource'
require_relative 'component/outputs'

module Pangea
  module Components
    module WebTierSubnets
      include Base
      include Outputs
      
      # Create public subnets across multiple AZs optimized for web tier workloads
      #
      # @param name [Symbol] The component name
      # @param attributes [Hash] WebTierSubnets attributes
      # @return [ComponentReference] Reference object with web tier subnet resources and outputs
      def web_tier_subnets(name, attributes = {})
        # Validate attributes using dry-struct
        component_attrs = Types::WebTierSubnetsAttributes.new(attributes)
        
        # Extract VPC ID from reference (handle both ResourceReference and String)
        vpc_id = case component_attrs.vpc_ref
                 when String then component_attrs.vpc_ref
                 else component_attrs.vpc_ref.id
                 end
        
        resources = {}
        
        # 1. Create Internet Gateway for public internet access (if requested)
        igw_ref = nil
        if component_attrs.create_internet_gateway
          igw_ref = aws_internet_gateway(resource_name(name, :igw), {
            vpc_id: vpc_id,
            tags: merge_component_tags(
              component_attrs.tags,
              {
                Name: "#{name}-igw",
                Purpose: "Web tier internet access",
                Tier: "web"
              },
              :web_tier_subnets,
              :internet_gateway
            )
          })
          resources[:internet_gateway] = igw_ref
        end
        
        # 2. Create web tier subnets distributed across availability zones
        web_subnets = {}
        component_attrs.subnet_cidrs.each_with_index do |cidr, index|
          # Distribute subnets across AZs
          az = component_attrs.availability_zones[index % component_attrs.az_count]
          subnet_name = resource_name(name, "web_#{index + 1}")
          
          subnet_ref = aws_subnet(subnet_name, {
            vpc_id: vpc_id,
            cidr_block: cidr,
            availability_zone: az,
            map_public_ip_on_launch: component_attrs.enable_public_ips,
            # TODO: Add IPv6 support when aws_subnet resource supports it
            # assign_ipv6_address_on_creation: component_attrs.enable_ipv6,
            tags: merge_component_tags(
              component_attrs.tags.merge(component_attrs.subnet_tags),
              {
                Name: "#{name}-web-#{index + 1}",
                Type: "public",
                Tier: "web",
                AvailabilityZone: az,
                SubnetIndex: index + 1,
                Purpose: "Web tier workloads",
                LoadBalancerReady: component_attrs.load_balancer_ready?.to_s,
                PublicIPs: component_attrs.enable_public_ips.to_s
              },
              :web_tier_subnets,
              :web_subnet
            )
          })
          
          web_subnets[:"web_#{index + 1}"] = subnet_ref
        end
        resources[:web_subnets] = web_subnets
        
        # 3. Create route table for web tier routing
        web_rt_ref = aws_route_table(resource_name(name, :web_rt), {
          vpc_id: vpc_id,
          tags: merge_component_tags(
            component_attrs.tags,
            {
              Name: "#{name}-web-rt",
              Type: "public",
              Tier: "web",
              Purpose: "Web tier subnet routing"
            },
            :web_tier_subnets,
            :route_table
          )
        })
        resources[:web_route_table] = web_rt_ref
        
        # 4. Create route to Internet Gateway (if Internet Gateway was created)
        igw_route_ref = nil
        if igw_ref
          igw_route_ref = aws_route(resource_name(name, :igw_route), {
            route_table_id: web_rt_ref.id,
            destination_cidr_block: "0.0.0.0/0",
            gateway_id: igw_ref.id
          })
          resources[:internet_route] = igw_route_ref
        end
        
        # 5. Associate all web subnets with the web route table
        subnet_associations = {}
        web_subnets.each do |subnet_key, subnet_ref|
          assoc_name = resource_name(name, "#{subnet_key}_rt_assoc")
          assoc_ref = aws_route_table_association(assoc_name, {
            subnet_id: subnet_ref.id,
            route_table_id: web_rt_ref.id
          })
          subnet_associations[:"#{subnet_key}_association"] = assoc_ref
        end
        resources[:subnet_associations] = subnet_associations
        
        # 6. Generate AZ distribution and outputs
        az_distribution = generate_az_distribution(component_attrs, web_subnets)
        outputs = generate_outputs(component_attrs, vpc_id, igw_ref, web_subnets, web_rt_ref, az_distribution)

        # 7. Create and return component reference
        create_component_reference(
          type: :web_tier_subnets,
          name: name,
          component_attributes: component_attrs,
          resources: resources,
          outputs: outputs
        )
      end
    end
  end
end