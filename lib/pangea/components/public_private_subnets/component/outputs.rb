# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Components
    module PublicPrivateSubnets
      # Output generation methods for the component
      module Outputs
        def generate_outputs(component_attrs, vpc_id, igw_ref, public_subnets, private_subnets,
                             public_rt_ref, nat_gateways, nat_eips, private_route_tables, azs)
          {
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
        end
      end
    end
  end
end
