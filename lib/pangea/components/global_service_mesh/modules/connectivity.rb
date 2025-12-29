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
    module GlobalServiceMesh
      # Cross-region connectivity including Transit Gateway peering and PrivateLink
      module Connectivity
        def create_cross_region_connectivity(name, attrs, regional_resources, tags)
          connectivity_resources = {}

          # Create Transit Gateway peering attachments
          if attrs.cross_region.transit_gateway_enabled
            connectivity_resources[:tgw_peering] = create_tgw_peering(
              name, attrs, regional_resources, tags
            )
          end

          # Create PrivateLink connections if enabled
          if attrs.cross_region.private_link_enabled
            connectivity_resources[:privatelink] = create_privatelink_connections(
              name, attrs, tags
            )
          end

          connectivity_resources
        end

        private

        def create_tgw_peering(name, attrs, regional_resources, tags)
          peering_attachments = {}

          attrs.regions.combination(2).each do |region1, region2|
            tgw1 = regional_resources[region1.to_sym][:transit_gateway]
            tgw2 = regional_resources[region2.to_sym][:transit_gateway]

            next unless tgw1 && tgw2

            peering_attachments["#{region1}_#{region2}".to_sym] = create_peering_attachment(
              name, region1, region2, tgw1, tgw2, tags
            )
          end

          peering_attachments
        end

        def create_peering_attachment(name, region1, region2, tgw1, tgw2, tags)
          aws_ec2_transit_gateway_peering_attachment(
            component_resource_name(name, :tgw_peering, "#{region1}_#{region2}".to_sym),
            {
              transit_gateway_id: tgw1.id,
              peer_transit_gateway_id: tgw2.id,
              peer_account_id: "${AWS::AccountId}",
              peer_region: region2,
              tags: tags.merge(
                ConnectionType: "ServiceMesh",
                Region1: region1,
                Region2: region2
              )
            }
          )
        end

        def create_privatelink_connections(name, attrs, tags)
          privatelink_connections = {}

          attrs.services.group_by(&:region).each do |provider_region, services|
            services.each do |service|
              create_service_privatelink(
                name, attrs, service, provider_region, tags, privatelink_connections
              )
            end
          end

          privatelink_connections
        end

        def create_service_privatelink(name, attrs, service, provider_region, tags, connections)
          # Create VPC endpoint service
          endpoint_service_ref = aws_vpc_endpoint_service(
            component_resource_name(name, :endpoint_service, service.name.to_sym),
            {
              acceptance_required: false,
              network_load_balancer_arns: [],
              tags: tags.merge(Service: service.name, Region: provider_region)
            }
          )

          connections["service_#{service.name}".to_sym] = endpoint_service_ref

          # Create VPC endpoints in consumer regions
          create_consumer_endpoints(name, attrs, service, provider_region, endpoint_service_ref, tags, connections)
        end

        def create_consumer_endpoints(name, attrs, service, provider_region, endpoint_service_ref, tags, connections)
          consumer_regions = attrs.regions - [provider_region]

          consumer_regions.each do |consumer_region|
            endpoint_ref = aws_vpc_endpoint(
              component_resource_name(name, :service_endpoint, "#{service.name}_#{consumer_region}".to_sym),
              {
                vpc_id: "vpc-placeholder",
                service_name: endpoint_service_ref.service_name,
                vpc_endpoint_type: "Interface",
                subnet_ids: [],
                security_group_ids: [],
                tags: tags.merge(
                  Service: service.name,
                  ProviderRegion: provider_region,
                  ConsumerRegion: consumer_region
                )
              }
            )
            connections["endpoint_#{service.name}_#{consumer_region}".to_sym] = endpoint_ref
          end
        end
      end
    end
  end
end
