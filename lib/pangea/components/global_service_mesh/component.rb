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

require 'pangea/components/base'
require 'pangea/components/global_service_mesh/types'
require 'pangea/resources/aws'
require_relative 'modules/helpers'
require_relative 'modules/regional_mesh'
require_relative 'modules/connectivity'
require_relative 'modules/mesh_components'
require_relative 'modules/gateways'
require_relative 'modules/observability'
require_relative 'modules/security'
require_relative 'modules/resilience'

module Pangea
  module Components
    module GlobalServiceMesh
      include Helpers
      include RegionalMesh
      include Connectivity
      include MeshComponents
      include Gateways
      include Observability
      include Security
      include Resilience

      # Multi-region service mesh infrastructure for microservices communication
      def global_service_mesh(name, attributes = {})
        include Base
        include Resources::AWS

        attrs = GlobalServiceMesh::GlobalServiceMeshAttributes.new(attributes)
        attrs.validate!

        tags = component_tags('GlobalServiceMesh', name, attrs.tags)
        resources = create_core_resources(name, attrs, tags)

        create_component_reference('global_service_mesh', name, attrs.to_h, resources,
                                   build_outputs(attrs, resources))
      end

      private

      def create_core_resources(name, attrs, tags)
        resources = {}
        resources[:mesh] = create_app_mesh(name, attrs, tags)
        resources[:namespace] = create_namespace(name, attrs, tags)
        resources[:regional] = create_regional_resources(name, attrs, resources, tags)

        if attrs.regions.length > 1 && attrs.cross_region.peering_enabled
          resources[:connectivity] = create_cross_region_connectivity(name, attrs, resources[:regional], tags)
        end

        resources[:mesh_components] = create_mesh_components(name, attrs, resources[:mesh], resources[:regional], tags)
        create_optional_infrastructure(name, attrs, resources, tags)
        resources
      end

      def create_app_mesh(name, attrs, tags)
        aws_appmesh_mesh(component_resource_name(name, :mesh), {
          name: attrs.mesh_name,
          spec: {
            egress_filter: { type: attrs.gateway.egress_gateway_enabled ? "ALLOW_ALL" : "DROP_ALL" },
            service_discovery: { ip_preference: "IPv4_PREFERRED" }
          },
          tags: tags
        })
      end

      def create_namespace(name, attrs, tags)
        aws_service_discovery_private_dns_namespace(component_resource_name(name, :namespace), {
          name: attrs.service_discovery.namespace_name,
          description: attrs.service_discovery.namespace_description,
          vpc: "vpc-placeholder",
          tags: tags
        })
      end

      def create_regional_resources(name, attrs, resources, tags)
        attrs.regions.each_with_object({}) do |region, regional|
          regional[region.to_sym] = setup_regional_mesh(name, region, attrs, resources[:mesh], resources[:namespace], tags)
        end
      end

      def create_optional_infrastructure(name, attrs, resources, tags)
        if attrs.gateway.ingress_gateway_enabled || attrs.gateway.egress_gateway_enabled
          resources[:gateways] = create_gateways(name, attrs, resources[:mesh], resources[:regional], tags)
        end
        if attrs.observability.xray_enabled || attrs.observability.cloudwatch_metrics_enabled
          resources[:observability] = create_observability_infrastructure(name, attrs, resources, tags)
        end
        resources[:security] = create_security_infrastructure(name, attrs, resources[:mesh], tags) if attrs.security.mtls_enabled
        resources[:resilience] = create_resilience_infrastructure(name, attrs, resources, tags) if attrs.resilience.chaos_testing_enabled
      end

      def build_outputs(attrs, resources)
        {
          mesh_name: attrs.mesh_name, mesh_arn: resources[:mesh].arn,
          service_discovery_namespace: attrs.service_discovery.namespace_name,
          regions: attrs.regions, services: build_service_outputs(attrs),
          connectivity_type: extract_connectivity_type(attrs),
          security_features: build_security_features(attrs),
          traffic_management_features: build_traffic_management_features(attrs),
          observability_features: build_observability_features(attrs),
          resilience_features: build_resilience_features(attrs),
          gateway_endpoints: extract_gateway_endpoints(resources[:gateways]),
          virtual_nodes: resources[:mesh_components][:virtual_nodes]&.keys || [],
          virtual_services: resources[:mesh_components][:virtual_services]&.keys || [],
          virtual_routers: resources[:mesh_components][:virtual_routers]&.keys || [],
          estimated_monthly_cost: estimate_service_mesh_cost(attrs, resources)
        }
      end

      include Base
    end
  end
end
