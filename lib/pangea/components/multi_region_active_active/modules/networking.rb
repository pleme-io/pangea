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
  module Components
    module MultiRegionActiveActive
      # Networking resources: VPC, subnets, transit gateway, peering
      module Networking
        def create_regional_vpc(name, region_config, tags)
          return region_config.vpc_ref if region_config.vpc_ref

          aws_vpc(
            component_resource_name(name, :vpc, region_config.region.to_sym),
            {
              cidr_block: region_config.vpc_cidr,
              enable_dns_hostnames: true,
              enable_dns_support: true,
              tags: tags.merge(Region: region_config.region, IsPrimary: region_config.is_primary.to_s)
            }
          )
        end

        def create_regional_subnets(name, region_config, vpc_ref, tags)
          subnets = {}

          region_config.availability_zones.each_with_index do |az, az_index|
            base_ip = region_config.vpc_cidr.split('.')[0..1].join('.')

            subnets["public_#{az}".to_sym] = create_public_subnet(name, region_config, vpc_ref, az, az_index, base_ip, tags)
            subnets["private_#{az}".to_sym] = create_private_subnet(name, region_config, vpc_ref, az, az_index, base_ip, tags)
          end

          subnets
        end

        def create_transit_gateway(name, region_config, index, tags)
          aws_ec2_transit_gateway(
            component_resource_name(name, :transit_gateway, region_config.region.to_sym),
            {
              description: "Transit Gateway for #{name} in #{region_config.region}",
              amazon_side_asn: 64_512 + index,
              default_route_table_association: 'enable',
              default_route_table_propagation: 'enable',
              dns_support: 'enable',
              vpn_ecmp_support: 'enable',
              tags: tags.merge(Region: region_config.region)
            }
          )
        end

        def create_transit_gateway_attachment(name, region_config, tgw_ref, vpc_ref, subnets, tags)
          private_subnet_ids = subnets.select { |k, _| k.to_s.start_with?('private_') }.values.map(&:id)

          aws_ec2_transit_gateway_vpc_attachment(
            component_resource_name(name, :tgw_attachment, region_config.region.to_sym),
            {
              transit_gateway_id: tgw_ref.id,
              vpc_id: vpc_ref.id,
              subnet_ids: private_subnet_ids,
              dns_support: 'enable',
              ipv6_support: 'disable',
              tags: tags.merge(Region: region_config.region)
            }
          )
        end

        def create_transit_gateway_peering(name, attrs, regional_resources, tags)
          peering_connections = {}
          regions = attrs.regions.map(&:region)

          regions.combination(2).each do |region1, region2|
            peering_ref = create_peering_attachment(name, region1, region2, regional_resources, tags)
            peering_connections["#{region1}_#{region2}".to_sym] = peering_ref
          end

          peering_connections
        end

        private

        def create_public_subnet(name, region_config, vpc_ref, az, az_index, base_ip, tags)
          aws_subnet(
            component_resource_name(name, :subnet_public, "#{region_config.region}_#{az}".to_sym),
            {
              vpc_id: vpc_ref.id,
              cidr_block: "#{base_ip}.#{az_index * 2}.0/24",
              availability_zone: az,
              map_public_ip_on_launch: true,
              tags: tags.merge(Type: 'Public', Region: region_config.region, AvailabilityZone: az)
            }
          )
        end

        def create_private_subnet(name, region_config, vpc_ref, az, az_index, base_ip, tags)
          aws_subnet(
            component_resource_name(name, :subnet_private, "#{region_config.region}_#{az}".to_sym),
            {
              vpc_id: vpc_ref.id,
              cidr_block: "#{base_ip}.#{az_index * 2 + 1}.0/24",
              availability_zone: az,
              map_public_ip_on_launch: false,
              tags: tags.merge(Type: 'Private', Region: region_config.region, AvailabilityZone: az)
            }
          )
        end

        def create_peering_attachment(name, region1, region2, regional_resources, tags)
          aws_ec2_transit_gateway_peering_attachment(
            component_resource_name(name, :tgw_peering, "#{region1}_#{region2}".to_sym),
            {
              transit_gateway_id: regional_resources[region1.to_sym][:transit_gateway].id,
              peer_transit_gateway_id: regional_resources[region2.to_sym][:transit_gateway].id,
              peer_account_id: '${AWS::AccountId}',
              peer_region: region2,
              tags: tags.merge(PeeringType: 'InterRegion', Region1: region1, Region2: region2)
            }
          )
        end
      end
    end
  end
end
