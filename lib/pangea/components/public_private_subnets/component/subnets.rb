# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Components
    module PublicPrivateSubnets
      # Subnet creation methods for public and private subnets
      module Subnets
        def create_public_subnets(name, component_attrs, vpc_id, azs)
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
                  Type: 'public',
                  Tier: 'web',
                  AvailabilityZone: az
                },
                :public_private_subnets,
                :public_subnet
              )
            })

            public_subnets[:"public_#{index + 1}"] = subnet_ref
          end
          public_subnets
        end

        def create_private_subnets(name, component_attrs, vpc_id, azs)
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
                  Type: 'private',
                  Tier: 'application',
                  AvailabilityZone: az
                },
                :public_private_subnets,
                :private_subnet
              )
            })

            private_subnets[:"private_#{index + 1}"] = subnet_ref
          end
          private_subnets
        end
      end
    end
  end
end
