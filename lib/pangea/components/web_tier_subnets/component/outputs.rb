# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Components
    module WebTierSubnets
      # Output generation methods for the web tier subnets component
      module Outputs
        # Generate AZ distribution information
        def generate_az_distribution(component_attrs, web_subnets)
          az_distribution = {}
          component_attrs.availability_zones.each_with_index do |az, az_index|
            subnets_in_az = web_subnets.select.with_index do |(_subnet_key, _subnet_ref), subnet_index|
              subnet_index % component_attrs.az_count == az_index
            end
            az_distribution[az] = {
              subnet_count: subnets_in_az.count,
              subnets: subnets_in_az.keys,
              estimated_capacity: component_attrs.estimated_capacity_per_subnet
                                    .select.with_index { |_cap, idx| idx % component_attrs.az_count == az_index }
                                    .sum
            }
          end
          az_distribution
        end

        # Generate computed outputs for the component
        def generate_outputs(component_attrs, vpc_id, igw_ref, web_subnets, web_rt_ref, az_distribution)
          {
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
        end
      end
    end
  end
end
