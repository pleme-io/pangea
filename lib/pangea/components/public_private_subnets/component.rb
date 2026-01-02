# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'pangea/components/base'
require 'pangea/components/public_private_subnets/types'
require 'pangea/resources/aws_subnet/resource'
require 'pangea/resources/aws_internet_gateway/resource'
require 'pangea/resources/aws_nat_gateway/resource'
require 'pangea/resources/aws_route_table/resource'
require 'pangea/resources/aws_route/resource'
require 'pangea/resources/aws_route_table_association/resource'
require 'pangea/resources/aws_eip/resource'
require_relative 'component/subnets'
require_relative 'component/routing'
require_relative 'component/outputs'

module Pangea
  module Components
    module PublicPrivateSubnets
      include Base
      include Subnets
      include Routing
      include Outputs

      # Create public and private subnets with NAT Gateway and proper routing
      #
      # @param name [Symbol] The component name
      # @param attributes [Hash] PublicPrivateSubnets attributes
      # @return [ComponentReference] Reference object with subnet resources and outputs
      def public_private_subnets(name, attributes = {})
        component_attrs = Types::PublicPrivateSubnetsAttributes.new(attributes)

        vpc_id = case component_attrs.vpc_ref
                 when String then component_attrs.vpc_ref
                 else component_attrs.vpc_ref.id
                 end

        azs = component_attrs.availability_zones || %w[us-east-1a us-east-1b]
        resources = {}

        # 1. Create Internet Gateway
        igw_ref = create_internet_gateway(name, component_attrs, vpc_id)
        resources[:internet_gateway] = igw_ref

        # 2. Create public subnets
        public_subnets = create_public_subnets(name, component_attrs, vpc_id, azs)
        resources[:public_subnets] = public_subnets

        # 3. Create public route table and routes
        public_routing = create_public_route_table(name, component_attrs, vpc_id, igw_ref)
        resources[:public_route_table] = public_routing[:route_table]
        resources[:public_route] = public_routing[:route]

        # 4. Associate public subnets with public route table
        public_associations = create_public_route_associations(name, public_subnets, public_routing[:route_table])
        resources[:public_route_associations] = public_associations

        # 5. Create private subnets
        private_subnets = create_private_subnets(name, component_attrs, vpc_id, azs)
        resources[:private_subnets] = private_subnets

        # 6. Create NAT Gateways if requested
        nat_result = create_nat_gateways(name, component_attrs, public_subnets, azs)
        resources[:nat_gateways] = nat_result[:nat_gateways]
        resources[:nat_eips] = nat_result[:nat_eips]

        # 7. Create private route tables and routes
        private_routing = create_private_routing(name, component_attrs, vpc_id, private_subnets, nat_result[:nat_gateways], azs)
        resources[:private_route_tables] = private_routing[:route_tables]
        resources[:private_routes] = private_routing[:routes]
        resources[:private_route_associations] = private_routing[:associations]

        # 8. Generate outputs
        outputs = generate_outputs(
          component_attrs, vpc_id, igw_ref, public_subnets, private_subnets,
          public_routing[:route_table], nat_result[:nat_gateways], nat_result[:nat_eips],
          private_routing[:route_tables], azs
        )

        # 9. Create and return component reference
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
