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
    module DisasterRecoveryPilotLight
      # Cross-region VPC peering infrastructure
      module Networking
        def create_cross_region_peering(name, attrs, primary_resources, dr_resources, tags)
          peering_resources = {}

          peering_ref = create_peering_connection(
            name, attrs, primary_resources, dr_resources, tags
          )
          peering_resources[:connection] = peering_ref

          peering_resources[:accepter] = create_peering_accepter(name, peering_ref, tags)

          add_primary_routes(name, attrs, primary_resources, peering_ref, peering_resources)
          add_dr_routes(name, attrs, dr_resources, peering_ref, peering_resources)

          peering_resources
        end

        private

        def create_peering_connection(name, attrs, primary_resources, dr_resources, tags)
          aws_vpc_peering_connection(
            component_resource_name(name, :vpc_peering),
            {
              vpc_id: primary_resources[:vpc].id,
              peer_vpc_id: dr_resources[:vpc].id,
              peer_region: attrs.dr_region.region,
              tags: tags.merge(
                Name: "#{name}-primary-to-dr",
                Type: "Cross-Region-DR"
              )
            }
          )
        end

        def create_peering_accepter(name, peering_ref, tags)
          aws_vpc_peering_connection_accepter(
            component_resource_name(name, :vpc_peering_accepter),
            {
              vpc_peering_connection_id: peering_ref.id,
              tags: tags
            }
          )
        end

        def add_primary_routes(name, attrs, primary_resources, peering_ref, peering_resources)
          primary_resources[:subnets].each do |subnet_key, subnet|
            route_ref = aws_route(
              component_resource_name(name, :primary_to_dr_route, subnet_key),
              {
                route_table_id: subnet.route_table_id,
                destination_cidr_block: attrs.dr_region.vpc_cidr,
                vpc_peering_connection_id: peering_ref.id
              }
            )
            peering_resources["primary_route_#{subnet_key}".to_sym] = route_ref
          end
        end

        def add_dr_routes(name, attrs, dr_resources, peering_ref, peering_resources)
          dr_resources[:subnets].each do |subnet_key, subnet|
            route_ref = aws_route(
              component_resource_name(name, :dr_to_primary_route, subnet_key),
              {
                route_table_id: subnet.route_table_id,
                destination_cidr_block: attrs.primary_region.vpc_cidr,
                vpc_peering_connection_id: peering_ref.id
              }
            )
            peering_resources["dr_route_#{subnet_key}".to_sym] = route_ref
          end
        end
      end
    end
  end
end
