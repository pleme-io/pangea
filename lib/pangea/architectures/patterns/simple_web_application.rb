# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'
require 'pangea/architectures/base'

module Pangea
  module Architectures
    module Patterns
      # Simplified Web Application Architecture - Basic VPC with routing
      module SimpleWebApplication
        include Base
        
        # Simple web application architecture attributes
        class SimpleWebAppAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :domain, Types::String
          attribute :environment, Types::String.default('development')
          attribute :vpc_cidr, Types::String.default('10.0.0.0/16')
          attribute :availability_zones, Types::Array.of(Types::String).default(['us-east-1a', 'us-east-1b'].freeze)
          attribute :tags, Types::Hash.default({}.freeze)
        end
        
        # Create a simplified web application architecture
        def simple_web_application_architecture(name, attributes = {})
          # Validate and set defaults
          arch_attrs = SimpleWebAppAttributes.new(attributes)
          arch_ref = create_architecture_reference('simple_web_application', name, architecture_attributes: arch_attrs.to_h)
          
          # Generate base tags
          base_tags = architecture_tags(arch_ref, {
            Domain: arch_attrs.domain,
            Environment: arch_attrs.environment
          }.merge(arch_attrs.tags))
          
          # Create network tier using only working resources
          network = create_basic_network(name, arch_attrs, base_tags)
          
          # Store network in components
          arch_ref.instance_variable_set(:@components, { network: network })
          arch_ref.instance_variable_set(:@resources, {})
          arch_ref.instance_variable_set(:@outputs, {})
          
          arch_ref
        end
        
        private
        
        # Create basic VPC with subnets and routing using only available resources
        def create_basic_network(name, arch_attrs, base_tags)
          # Create VPC
          vpc_ref = aws_vpc(architecture_resource_name(name, :vpc), {
            cidr_block: arch_attrs.vpc_cidr,
            enable_dns_hostnames: true,
            enable_dns_support: true,
            tags: base_tags.merge(Name: "#{name}-vpc", Tier: 'network')
          })
          
          # Create internet gateway
          igw_ref = aws_internet_gateway(architecture_resource_name(name, :igw), {
            vpc_id: vpc_ref.id,
            tags: base_tags.merge(Name: "#{name}-igw", Tier: 'network')
          })
          
          # Create public subnet
          public_subnet = aws_subnet(architecture_resource_name(name, :public_subnet), {
            vpc_id: vpc_ref.id,
            cidr_block: "10.0.1.0/24",
            availability_zone: arch_attrs.availability_zones[0],
            map_public_ip_on_launch: true,
            tags: base_tags.merge(Name: "#{name}-public-subnet", Type: 'public')
          })
          
          # Create route table for public subnet with internet gateway route
          public_rt = aws_route_table(architecture_resource_name(name, :public_rt), {
            vpc_id: vpc_ref.id,
            routes: [{
              cidr_block: "0.0.0.0/0",
              gateway_id: igw_ref.id
            }],
            tags: base_tags.merge(Name: "#{name}-public-rt", Type: 'public')
          })
          
          # Associate public subnet with route table
          aws_route_table_association(architecture_resource_name(name, :public_rta), {
            subnet_id: public_subnet.id,
            route_table_id: public_rt.id
          })
          
          # Return network reference
          {
            vpc: vpc_ref,
            internet_gateway: igw_ref,
            public_subnet: public_subnet,
            public_route_table: public_rt
          }
        end
      end
    end
  end
end

# Auto-register when loaded
require 'pangea/architecture_registry'
Pangea::ArchitectureRegistry.register_architecture(Pangea::Architectures::Patterns::SimpleWebApplication)