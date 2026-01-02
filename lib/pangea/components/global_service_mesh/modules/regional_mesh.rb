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

require 'json'

module Pangea
  module Components
    module GlobalServiceMesh
      # Regional mesh setup including VPC endpoints, service discovery, and transit gateway
      module RegionalMesh
        def setup_regional_mesh(name, region, attrs, mesh_ref, namespace_ref, tags)
          region_resources = { vpc_endpoints: create_vpc_endpoints(name, region, tags) }
          region_services = attrs.services.select { |s| s.region == region }
          region_resources[:services] = create_service_resources(name, attrs, region_services, namespace_ref, region, tags)
          if attrs.cross_region.transit_gateway_enabled && attrs.regions.length > 1
            region_resources[:transit_gateway] = create_transit_gateway(name, region, tags)
          end
          region_resources
        end

        private

        def create_vpc_endpoints(name, region, tags)
          {
            appmesh: aws_vpc_endpoint(component_resource_name(name, :appmesh_endpoint, region.to_sym), {
              vpc_id: "vpc-placeholder", service_name: "com.amazonaws.#{region}.appmesh-envoy-management",
              vpc_endpoint_type: "Interface", subnet_ids: [], security_group_ids: [],
              private_dns_enabled: true, tags: tags.merge(Region: region)
            }),
            servicediscovery: aws_vpc_endpoint(component_resource_name(name, :servicediscovery_endpoint, region.to_sym), {
              vpc_id: "vpc-placeholder", service_name: "com.amazonaws.#{region}.servicediscovery",
              vpc_endpoint_type: "Interface", subnet_ids: [], security_group_ids: [],
              private_dns_enabled: true, tags: tags.merge(Region: region)
            })
          }
        end

        def create_service_resources(name, attrs, region_services, namespace_ref, region, tags)
          region_services.each_with_object({}) do |service, resources|
            resources[service.name.to_sym] = {
              discovery: create_service_discovery(name, attrs, service, namespace_ref, region, tags),
              task_definition: create_or_reference_task_definition(name, attrs, service, tags)
            }
          end
        end

        def create_service_discovery(name, attrs, service, namespace_ref, region, tags)
          aws_service_discovery_service(component_resource_name(name, :service_discovery, service.name.to_sym), {
            name: service.name, namespace_id: namespace_ref.id,
            dns_config: { namespace_id: namespace_ref.id, routing_policy: attrs.service_discovery.routing_policy,
                          dns_records: [{ ttl: attrs.service_discovery.dns_ttl, type: "A" }] },
            health_check_custom_config: attrs.service_discovery.health_check_custom_config_enabled ?
              { failure_threshold: attrs.virtual_node_config.unhealthy_threshold } : nil,
            tags: tags.merge(Service: service.name, Region: region)
          }.compact)
        end

        def create_or_reference_task_definition(name, attrs, service, tags)
          return service.task_definition_ref if service.task_definition_ref || !service.cluster_ref
          aws_ecs_task_definition(component_resource_name(name, :task_definition, service.name.to_sym), {
            family: "#{service.name}-task", network_mode: "awsvpc", requires_compatibilities: ["FARGATE"],
            cpu: "256", memory: "512",
            proxy_configuration: { type: "APPMESH", container_name: "envoy",
              properties: { AppPorts: service.port.to_s, EgressIgnoredIPs: "169.254.170.2,169.254.169.254",
                            IgnoredUID: "1337", ProxyEgressPort: 15001, ProxyIngressPort: 15000 } },
            container_definitions: build_container_definitions(attrs, service),
            task_role_arn: "arn:aws:iam::ACCOUNT:role/ecsTaskRole",
            execution_role_arn: "arn:aws:iam::ACCOUNT:role/ecsTaskExecutionRole",
            tags: tags.merge(Service: service.name)
          })
        end

        def build_container_definitions(attrs, service)
          JSON.generate([
            { name: service.name, image: "service-image:latest",
              portMappings: [{ containerPort: service.port, protocol: "tcp" }],
              environment: [{ name: "SERVICE_NAME", value: service.name }, { name: "SERVICE_PORT", value: service.port.to_s }],
              dependsOn: [{ containerName: "envoy", condition: "HEALTHY" }] },
            { name: "envoy", image: "public.ecr.aws/appmesh/aws-appmesh-envoy:latest", memory: 128, user: "1337", essential: true,
              environment: [{ name: "APPMESH_RESOURCE_ARN", value: "mesh/#{attrs.mesh_name}/virtualNode/#{service.name}" },
                            { name: "ENABLE_ENVOY_XRAY_TRACING", value: attrs.observability.xray_enabled ? "1" : "0" }],
              healthCheck: { command: ["CMD-SHELL", "curl -s http://localhost:9901/server_info | grep state | grep -q LIVE"],
                             interval: 5, timeout: 2, retries: 3, startPeriod: 10 } }
          ])
        end

        def create_transit_gateway(name, region, tags)
          aws_ec2_transit_gateway(component_resource_name(name, :transit_gateway, region.to_sym), {
            description: "Transit Gateway for service mesh in #{region}", amazon_side_asn: 64512,
            default_route_table_association: "enable", default_route_table_propagation: "enable",
            dns_support: "enable", vpn_ecmp_support: "enable", tags: tags.merge(Region: region)
          })
        end
      end
    end
  end
end
