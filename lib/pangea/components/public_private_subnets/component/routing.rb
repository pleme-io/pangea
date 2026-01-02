# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require_relative 'routing/nat_gateways'

module Pangea
  module Components
    module PublicPrivateSubnets
      # Routing methods for NAT gateways and route tables
      module Routing
        include NatGateways

        def create_internet_gateway(name, component_attrs, vpc_id)
          aws_internet_gateway(resource_name(name, :igw), {
            vpc_id: vpc_id,
            tags: merge_component_tags(
              component_attrs.tags,
              { Name: "#{name}-igw", Purpose: 'Public subnet internet access' },
              :public_private_subnets,
              :internet_gateway
            )
          })
        end

        def create_public_route_table(name, component_attrs, vpc_id, igw_ref)
          public_rt_ref = aws_route_table(resource_name(name, :public_rt), {
            vpc_id: vpc_id,
            tags: merge_component_tags(
              component_attrs.tags,
              { Name: "#{name}-public-rt", Type: 'public', Purpose: 'Public subnet routing' },
              :public_private_subnets,
              :route_table
            )
          })

          public_route_ref = aws_route(resource_name(name, :public_route), {
            route_table_id: public_rt_ref.id,
            destination_cidr_block: '0.0.0.0/0',
            gateway_id: igw_ref.id
          })

          { route_table: public_rt_ref, route: public_route_ref }
        end

        def create_public_route_associations(name, public_subnets, public_rt_ref)
          associations = {}
          public_subnets.each do |subnet_key, subnet_ref|
            assoc_name = resource_name(name, "#{subnet_key}_rt_assoc")
            assoc_ref = aws_route_table_association(assoc_name, {
              subnet_id: subnet_ref.id,
              route_table_id: public_rt_ref.id
            })
            associations[:"#{subnet_key}_association"] = assoc_ref
          end
          associations
        end

        def create_private_routing(name, component_attrs, vpc_id, private_subnets, nat_gateways, azs)
          return { route_tables: {}, routes: {}, associations: {} } unless component_attrs.create_nat_gateway

          case component_attrs.nat_gateway_type
          when 'single'
            create_single_private_routing(name, component_attrs, vpc_id, private_subnets, nat_gateways)
          when 'per_az'
            create_per_az_private_routing(name, component_attrs, vpc_id, private_subnets, nat_gateways, azs)
          else
            { route_tables: {}, routes: {}, associations: {} }
          end
        end

        def create_single_private_routing(name, component_attrs, vpc_id, private_subnets, nat_gateways)
          private_rt_ref = aws_route_table(resource_name(name, :private_rt), {
            vpc_id: vpc_id,
            tags: merge_component_tags(
              component_attrs.tags,
              { Name: "#{name}-private-rt", Type: 'private', Purpose: 'Private subnet routing' },
              :public_private_subnets,
              :route_table
            )
          })

          private_route_ref = aws_route(resource_name(name, :private_route), {
            route_table_id: private_rt_ref.id,
            destination_cidr_block: '0.0.0.0/0',
            nat_gateway_id: nat_gateways[:single].id
          })

          associations = {}
          private_subnets.each do |subnet_key, subnet_ref|
            assoc_name = resource_name(name, "#{subnet_key}_rt_assoc")
            assoc_ref = aws_route_table_association(assoc_name, {
              subnet_id: subnet_ref.id,
              route_table_id: private_rt_ref.id
            })
            associations[:"#{subnet_key}_association"] = assoc_ref
          end

          { route_tables: { single: private_rt_ref }, routes: { single: private_route_ref }, associations: associations }
        end

        def create_per_az_private_routing(name, component_attrs, vpc_id, private_subnets, nat_gateways, azs)
          route_tables = {}
          routes = {}
          associations = {}

          azs.each_with_index do |az, index|
            rt_ref = aws_route_table(resource_name(name, "private_rt_#{index + 1}"), {
              vpc_id: vpc_id,
              tags: merge_component_tags(
                component_attrs.tags,
                { Name: "#{name}-private-rt-#{index + 1}", Type: 'private', AvailabilityZone: az, Purpose: 'Private subnet AZ-specific routing' },
                :public_private_subnets,
                :route_table
              )
            })
            route_tables[:"az_#{index + 1}"] = rt_ref

            if nat_gateways[:"az_#{index + 1}"]
              route_ref = aws_route(resource_name(name, "private_route_#{index + 1}"), {
                route_table_id: rt_ref.id,
                destination_cidr_block: '0.0.0.0/0',
                nat_gateway_id: nat_gateways[:"az_#{index + 1}"].id
              })
              routes[:"az_#{index + 1}"] = route_ref
            end

            private_subnets.each_with_index do |(subnet_key, subnet_ref), subnet_index|
              next unless subnet_index % azs.length == index

              assoc_name = resource_name(name, "#{subnet_key}_rt_assoc")
              assoc_ref = aws_route_table_association(assoc_name, {
                subnet_id: subnet_ref.id,
                route_table_id: rt_ref.id
              })
              associations[:"#{subnet_key}_association"] = assoc_ref
            end
          end

          { route_tables: route_tables, routes: routes, associations: associations }
        end
      end
    end
  end
end
