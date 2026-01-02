# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Components
    module PublicPrivateSubnets
      module Routing
        # NAT Gateway creation methods
        module NatGateways
          def create_nat_gateways(name, component_attrs, public_subnets, azs)
            return { nat_gateways: {}, nat_eips: {} } unless component_attrs.create_nat_gateway

            case component_attrs.nat_gateway_type
            when 'single'
              create_single_nat_gateway(name, component_attrs, public_subnets)
            when 'per_az'
              create_per_az_nat_gateways(name, component_attrs, public_subnets, azs)
            else
              { nat_gateways: {}, nat_eips: {} }
            end
          end

          def create_single_nat_gateway(name, component_attrs, public_subnets)
            first_public = public_subnets.values.first

            eip_ref = aws_eip(resource_name(name, :nat_eip), {
              domain: 'vpc',
              tags: merge_component_tags(
                component_attrs.tags,
                { Name: "#{name}-nat-eip", Purpose: 'NAT Gateway public IP' },
                :public_private_subnets,
                :eip
              )
            })

            nat_ref = aws_nat_gateway(resource_name(name, :nat_gw), {
              allocation_id: eip_ref.id,
              subnet_id: first_public.id,
              tags: merge_component_tags(
                component_attrs.tags,
                { Name: "#{name}-nat-gw", Type: 'single', HighAvailability: 'false' },
                :public_private_subnets,
                :nat_gateway
              )
            })

            { nat_gateways: { single: nat_ref }, nat_eips: { single: eip_ref } }
          end

          def create_per_az_nat_gateways(name, component_attrs, public_subnets, azs)
            nat_gateways = {}
            nat_eips = {}

            azs.each_with_index do |az, index|
              public_subnet = public_subnets.values[index % public_subnets.size]
              next unless public_subnet

              eip_ref = aws_eip(resource_name(name, "nat_eip_#{index + 1}"), {
                domain: 'vpc',
                tags: merge_component_tags(
                  component_attrs.tags,
                  { Name: "#{name}-nat-eip-#{index + 1}", AvailabilityZone: az, Purpose: 'NAT Gateway public IP' },
                  :public_private_subnets,
                  :eip
                )
              })
              nat_eips[:"az_#{index + 1}"] = eip_ref

              nat_ref = aws_nat_gateway(resource_name(name, "nat_gw_#{index + 1}"), {
                allocation_id: eip_ref.id,
                subnet_id: public_subnet.id,
                tags: merge_component_tags(
                  component_attrs.tags,
                  { Name: "#{name}-nat-gw-#{index + 1}", AvailabilityZone: az, Type: 'per_az', HighAvailability: 'true' },
                  :public_private_subnets,
                  :nat_gateway
                )
              })
              nat_gateways[:"az_#{index + 1}"] = nat_ref
            end

            { nat_gateways: nat_gateways, nat_eips: nat_eips }
          end
        end
      end
    end
  end
end
