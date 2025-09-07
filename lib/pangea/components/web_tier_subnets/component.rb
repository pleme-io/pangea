# frozen_string_literal: true

require 'pangea/components/base'
require 'pangea/components/web_tier_subnets/types'
require 'pangea/resources/aws_subnet/resource'
require 'pangea/resources/aws_internet_gateway/resource'
require 'pangea/resources/aws_route_table/resource'
require 'pangea/resources/aws_route/resource'
require 'pangea/resources/aws_route_table_association/resource'

module Pangea
  module Components
    module WebTierSubnets
      include Base
      
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
        
        # 6. Generate AZ distribution information
        az_distribution = {}
        component_attrs.availability_zones.each_with_index do |az, az_index|
          subnets_in_az = web_subnets.select.with_index do |(subnet_key, subnet_ref), subnet_index|
            subnet_index % component_attrs.az_count == az_index
          end
          az_distribution[az] = {
            subnet_count: subnets_in_az.count,
            subnets: subnets_in_az.keys,
            estimated_capacity: component_attrs.estimated_capacity_per_subnet
                                  .select.with_index { |cap, idx| idx % component_attrs.az_count == az_index }
                                  .sum
          }
        end
        
        # 7. Generate computed outputs
        outputs = {
          # Subnet information
          subnet_ids: web_subnets.values.map(&:id),
          subnet_cidrs: component_attrs.subnet_cidrs,
          subnet_count: component_attrs.subnet_count,
          
          # Availability zone information
          availability_zones: component_attrs.availability_zones,
          az_count: component_attrs.az_count,
          az_distribution: az_distribution,
          subnets_per_az: component_attrs.subnets_per_az,
          
          # Network configuration
          vpc_id: vpc_id,
          internet_gateway_id: igw_ref&.id,
          route_table_id: web_rt_ref.id,
          
          # Feature flags
          public_ips_enabled: component_attrs.enable_public_ips,
          ipv6_enabled: component_attrs.enable_ipv6,
          internet_gateway_created: component_attrs.create_internet_gateway,
          
          # High availability information
          is_highly_available: component_attrs.is_highly_available?,
          distribution_pattern: component_attrs.distribution_pattern,
          load_balancer_ready: component_attrs.load_balancer_ready?,
          
          # Capacity planning
          estimated_capacity_per_subnet: component_attrs.estimated_capacity_per_subnet,
          total_estimated_capacity: component_attrs.total_estimated_capacity,
          
          # Configuration summary
          tier_configuration: component_attrs.tier_configuration,
          web_tier_profile: component_attrs.web_tier_profile,
          compliance_features: component_attrs.compliance_features
        }
        
        # 8. Create and return component reference
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