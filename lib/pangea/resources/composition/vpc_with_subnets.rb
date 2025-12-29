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

module Pangea
  module Resources
    module Composition
      # VPC with subnets composition pattern
      module VpcWithSubnets
        # Create a VPC with public and private subnets across multiple AZs
        #
        # @param name_prefix [Symbol] Prefix for resource names
        # @param vpc_cidr [String] CIDR block for VPC
        # @param availability_zones [Array<String>] AZs to create subnets in
        # @param attributes [Hash] Additional attributes and customization
        # @return [CompositeVpcReference] Composite reference with all created resources
        def vpc_with_subnets(name_prefix, vpc_cidr:, availability_zones:, public_subnet_cidrs: nil,
                            private_subnet_cidrs: nil, attributes: {})
          results = CompositeVpcReference.new(name_prefix)

          create_vpc_and_gateway(results, name_prefix, vpc_cidr, attributes)
          create_subnets(results, name_prefix, vpc_cidr, availability_zones,
                         public_subnet_cidrs, private_subnet_cidrs, attributes)
          create_nat_gateways(results, name_prefix, availability_zones, attributes)
          create_route_tables(results, name_prefix, availability_zones, attributes)

          results
        end

        private

        def create_vpc_and_gateway(results, name_prefix, vpc_cidr, attributes)
          results.vpc = aws_vpc(:"#{name_prefix}_vpc", {
                                  cidr_block: vpc_cidr,
                                  enable_dns_hostnames: true,
                                  enable_dns_support: true,
                                  tags: { Name: "#{name_prefix}-vpc" }.merge(attributes[:vpc_tags] || {})
                                })

          results.internet_gateway = aws_internet_gateway(:"#{name_prefix}_igw", {
                                                            vpc_id: results.vpc.id,
                                                            tags: { Name: "#{name_prefix}-igw" }.merge(attributes[:igw_tags] || {})
                                                          })
        end

        def create_subnets(results, name_prefix, vpc_cidr, availability_zones,
                           public_subnet_cidrs, private_subnet_cidrs, attributes)
          vpc_cidr_parts = vpc_cidr.split('/')
          base_ip = vpc_cidr_parts[0]
          vpc_size = vpc_cidr_parts[1].to_i

          public_cidrs = public_subnet_cidrs || []
          private_cidrs = private_subnet_cidrs || []

          raise ArgumentError, 'At least one availability zone must be specified' if availability_zones.empty?

          total_subnets = availability_zones.length * 2
          subnet_bits = Math.log2(total_subnets).ceil
          new_subnet_size = vpc_size + subnet_bits

          availability_zones.each_with_index do |az, index|
            create_public_subnet(results, name_prefix, base_ip, vpc_size, new_subnet_size,
                                 az, index, public_cidrs, attributes)
            create_private_subnet(results, name_prefix, base_ip, vpc_size, new_subnet_size,
                                  az, index, availability_zones.length, private_cidrs, attributes)
          end
        end

        def create_public_subnet(results, name_prefix, base_ip, vpc_size, new_subnet_size,
                                 az, index, public_cidrs, attributes)
          public_cidr = public_cidrs[index] || calculate_subnet_cidr_v2(base_ip, vpc_size, new_subnet_size, index)
          public_subnet = aws_subnet(:"#{name_prefix}_public_subnet_#{index}", {
                                       vpc_id: results.vpc.id,
                                       cidr_block: public_cidr,
                                       availability_zone: az,
                                       map_public_ip_on_launch: true,
                                       tags: {
                                         Name: "#{name_prefix}-public-#{index}",
                                         Type: 'public'
                                       }.merge(attributes[:public_subnet_tags] || {})
                                     })
          results.public_subnets << public_subnet
        end

        def create_private_subnet(results, name_prefix, base_ip, vpc_size, new_subnet_size,
                                  az, index, az_count, private_cidrs, attributes)
          private_cidr = private_cidrs[index] || calculate_subnet_cidr_v2(base_ip, vpc_size, new_subnet_size,
                                                                          index + az_count)
          private_subnet = aws_subnet(:"#{name_prefix}_private_subnet_#{index}", {
                                        vpc_id: results.vpc.id,
                                        cidr_block: private_cidr,
                                        availability_zone: az,
                                        map_public_ip_on_launch: false,
                                        tags: {
                                          Name: "#{name_prefix}-private-#{index}",
                                          Type: 'private'
                                        }.merge(attributes[:private_subnet_tags] || {})
                                      })
          results.private_subnets << private_subnet
        end

        def create_nat_gateways(results, name_prefix, availability_zones, attributes)
          availability_zones.each_with_index do |_az, index|
            nat_gateway = aws_nat_gateway(:"#{name_prefix}_nat_#{index}", {
                                            subnet_id: results.public_subnets[index].id,
                                            tags: { Name: "#{name_prefix}-nat-#{index}" }.merge(attributes[:nat_tags] || {})
                                          })
            results.nat_gateways << nat_gateway
          end
        end

        def create_route_tables(results, name_prefix, availability_zones, attributes)
          results.public_route_table = aws_route_table(:"#{name_prefix}_public_rt", {
                                                         vpc_id: results.vpc.id,
                                                         routes: [{ cidr_block: '0.0.0.0/0', gateway_id: results.internet_gateway.id }],
                                                         tags: { Name: "#{name_prefix}-public-rt" }.merge(attributes[:route_table_tags] || {})
                                                       })

          availability_zones.each_with_index do |_az, index|
            private_route_table = aws_route_table(:"#{name_prefix}_private_rt_#{index}", {
                                                    vpc_id: results.vpc.id,
                                                    routes: [{ cidr_block: '0.0.0.0/0', nat_gateway_id: results.nat_gateways[index].id }],
                                                    tags: { Name: "#{name_prefix}-private-rt-#{index}" }.merge(attributes[:route_table_tags] || {})
                                                  })
            results.private_route_tables << private_route_table
          end
        end
      end
    end
  end
end
