# frozen_string_literal: true

require 'ipaddr'
require 'socket'
require 'ostruct'

module Pangea
  module Architectures
    module Base
      # VPC networking helpers
      module VpcNetworking
        def vpc_with_subnets(name, vpc_cidr:, availability_zones:, attributes: {})
          vpc_tags = attributes[:vpc_tags] || {}
          public_subnet_tags = attributes[:public_subnet_tags] || {}
          private_subnet_tags = attributes[:private_subnet_tags] || {}

          vpc_ref = create_vpc(name, vpc_cidr, vpc_tags)
          igw_ref = create_internet_gateway(name, vpc_ref, vpc_tags)
          public_subnets = create_public_subnets(name, vpc_ref, vpc_cidr, availability_zones, public_subnet_tags)
          private_subnets = create_private_subnets(name, vpc_ref, vpc_cidr, availability_zones, private_subnet_tags)

          public_rt = setup_public_routing(name, vpc_ref, igw_ref, public_subnets, vpc_tags)
          nat_gateways = create_nat_gateways(name, public_subnets, vpc_tags)
          setup_private_routing(name, vpc_ref, private_subnets, nat_gateways, vpc_tags)

          build_network_reference(name, vpc_ref, igw_ref, public_subnets, private_subnets, nat_gateways, public_rt)
        end

        def calculate_subnet_cidr(vpc_cidr, subnet_index)
          base_ip = IPAddr.new(vpc_cidr)
          subnet_size = 24
          new_prefix = base_ip.prefix + (subnet_size - base_ip.prefix)
          subnet_increment = 2**(32 - subnet_size) * subnet_index
          IPAddr.new(base_ip.to_i + subnet_increment, Socket::AF_INET).mask(subnet_size).to_s
        end

        private

        def create_vpc(name, vpc_cidr, tags)
          aws_vpc(name, {
            cidr_block: vpc_cidr,
            enable_dns_hostnames: true,
            enable_dns_support: true,
            tags: tags.merge(Name: "#{name}-vpc")
          })
        end

        def create_internet_gateway(name, vpc_ref, tags)
          aws_internet_gateway("#{name}_igw".to_sym, {
            vpc_id: vpc_ref.id,
            tags: tags.merge(Name: "#{name}-igw")
          })
        end

        def create_public_subnets(name, vpc_ref, vpc_cidr, availability_zones, tags)
          availability_zones.each_with_index.map do |az, index|
            subnet_cidr = calculate_subnet_cidr(vpc_cidr, index * 2)
            aws_subnet("#{name}_public_#{('a'.ord + index).chr}".to_sym, {
              vpc_id: vpc_ref.id,
              cidr_block: subnet_cidr,
              availability_zone: az,
              map_public_ip_on_launch: true,
              tags: tags.merge(Name: "#{name}-public-#{('a'.ord + index).chr}", Type: 'Public')
            })
          end
        end

        def create_private_subnets(name, vpc_ref, vpc_cidr, availability_zones, tags)
          availability_zones.each_with_index.map do |az, index|
            subnet_cidr = calculate_subnet_cidr(vpc_cidr, (index * 2) + 1)
            aws_subnet("#{name}_private_#{('a'.ord + index).chr}".to_sym, {
              vpc_id: vpc_ref.id,
              cidr_block: subnet_cidr,
              availability_zone: az,
              map_public_ip_on_launch: false,
              tags: tags.merge(Name: "#{name}-private-#{('a'.ord + index).chr}", Type: 'Private')
            })
          end
        end

        def setup_public_routing(name, vpc_ref, igw_ref, public_subnets, tags)
          public_rt = aws_route_table("#{name}_public_rt".to_sym, {
            vpc_id: vpc_ref.id,
            tags: tags.merge(Name: "#{name}-public-rt", Type: 'Public')
          })

          aws_route("#{name}_public_route".to_sym, {
            route_table_id: public_rt.id,
            destination_cidr_block: '0.0.0.0/0',
            gateway_id: igw_ref.id
          })

          public_subnets.each_with_index do |subnet, index|
            aws_route_table_association("#{name}_public_rta_#{('a'.ord + index).chr}".to_sym, {
              subnet_id: subnet.id,
              route_table_id: public_rt.id
            })
          end

          public_rt
        end

        def create_nat_gateways(name, public_subnets, tags)
          public_subnets.each_with_index.map do |public_subnet, index|
            eip = aws_eip("#{name}_nat_eip_#{('a'.ord + index).chr}".to_sym, {
              domain: 'vpc',
              tags: tags.merge(Name: "#{name}-nat-eip-#{('a'.ord + index).chr}")
            })

            aws_nat_gateway("#{name}_nat_gw_#{('a'.ord + index).chr}".to_sym, {
              allocation_id: eip.id,
              subnet_id: public_subnet.id,
              tags: tags.merge(Name: "#{name}-nat-gw-#{('a'.ord + index).chr}")
            })
          end
        end

        def setup_private_routing(name, vpc_ref, private_subnets, nat_gateways, tags)
          private_subnets.each_with_index do |private_subnet, index|
            private_rt = aws_route_table("#{name}_private_rt_#{('a'.ord + index).chr}".to_sym, {
              vpc_id: vpc_ref.id,
              tags: tags.merge(Name: "#{name}-private-rt-#{('a'.ord + index).chr}", Type: 'Private')
            })

            aws_route("#{name}_private_route_#{('a'.ord + index).chr}".to_sym, {
              route_table_id: private_rt.id,
              destination_cidr_block: '0.0.0.0/0',
              nat_gateway_id: nat_gateways[index].id
            })

            aws_route_table_association("#{name}_private_rta_#{('a'.ord + index).chr}".to_sym, {
              subnet_id: private_subnet.id,
              route_table_id: private_rt.id
            })
          end
        end

        def build_network_reference(name, vpc_ref, igw_ref, public_subnets, private_subnets, nat_gateways, public_rt)
          OpenStruct.new(
            vpc: vpc_ref,
            internet_gateway: igw_ref,
            public_subnets: public_subnets,
            private_subnets: private_subnets,
            public_subnet_ids: public_subnets.map(&:id),
            private_subnet_ids: private_subnets.map(&:id),
            all_subnet_ids: public_subnets.map(&:id) + private_subnets.map(&:id),
            nat_gateways: nat_gateways,
            public_route_table: public_rt,
            private_route_tables: private_subnets.each_with_index.map { |_, i| "#{name}_private_rt_#{('a'.ord + i).chr}".to_sym }
          )
        end
      end
    end
  end
end
