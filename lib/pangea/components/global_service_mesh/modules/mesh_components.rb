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
      # Mesh components: virtual nodes, virtual services, and virtual routers
      module MeshComponents
        def create_mesh_components(name, attrs, mesh_ref, _regional_resources, tags)
          components = {
            virtual_nodes: create_virtual_nodes(name, attrs, mesh_ref, tags),
            virtual_services: create_virtual_services(name, attrs, mesh_ref, tags)
          }
          create_virtual_routers(name, attrs, mesh_ref, tags, components) if attrs.traffic_management.canary_deployments_enabled || attrs.enable_multi_cluster_routing
          components
        end

        private

        def create_virtual_nodes(name, attrs, mesh_ref, tags)
          attrs.services.each_with_object({}) do |service, nodes|
            nodes[service.name.to_sym] = aws_appmesh_virtual_node(
              component_resource_name(name, :virtual_node, service.name.to_sym),
              { name: service.name, mesh_name: mesh_ref.name, spec: build_virtual_node_spec(attrs, service),
                tags: tags.merge(Service: service.name, Region: service.region) })
          end
        end

        def build_virtual_node_spec(attrs, service)
          { listener: [build_listener_spec(attrs, service)],
            service_discovery: { aws_cloud_map: { namespace_name: attrs.service_discovery.namespace_name, service_name: service.name } },
            backend: build_backends(attrs), backend_defaults: build_backend_defaults(attrs) }.compact
        end

        def build_listener_spec(attrs, service)
          { port_mapping: { port: service.port, protocol: service.protocol },
            health_check: { healthy_threshold: attrs.virtual_node_config.healthy_threshold,
              interval_millis: attrs.virtual_node_config.health_check_interval_millis, path: service.health_check_path,
              port: service.port, protocol: service.protocol == 'GRPC' ? 'grpc' : 'http',
              timeout_millis: attrs.virtual_node_config.health_check_timeout_millis,
              unhealthy_threshold: attrs.virtual_node_config.unhealthy_threshold },
            tls: build_tls_config(attrs, service), outlier_detection: build_outlier_detection(attrs),
            connection_pool: build_connection_pool(attrs), timeout: build_timeout(attrs) }.compact
        end

        def build_tls_config(attrs, service)
          return nil unless attrs.security.mtls_enabled
          { mode: attrs.security.tls_mode,
            certificate: { acm: { certificate_arn: "arn:aws:acm:#{service.region}:ACCOUNT:certificate/cert" } },
            validation: { trust: { acm: { certificate_authority_arns: [attrs.security.certificate_authority_arn] } } } }
        end

        def build_outlier_detection(attrs)
          return nil unless attrs.traffic_management.outlier_detection_enabled
          { base_ejection_duration: { unit: "s", value: attrs.traffic_management.outlier_ejection_duration_seconds },
            interval: { unit: "s", value: 10 }, max_ejection_percent: attrs.traffic_management.max_ejection_percent,
            max_server_errors: attrs.traffic_management.circuit_breaker_threshold }
        end

        def build_connection_pool(attrs)
          return nil unless attrs.resilience.bulkhead_enabled
          { http: { max_connections: attrs.resilience.max_connections, max_pending_requests: attrs.resilience.max_pending_requests } }
        end

        def build_timeout(attrs)
          return nil unless attrs.resilience.timeout_enabled
          { http: { idle: { unit: "s", value: 300 }, per_request: { unit: "s", value: attrs.resilience.request_timeout_seconds } } }
        end

        def build_backends(attrs)
          return nil unless attrs.virtual_node_config.backends.any?
          attrs.virtual_node_config.backends.map { |b| { virtual_service: { virtual_service_name: "#{b}.#{attrs.service_discovery.namespace_name}" } } }
        end

        def build_backend_defaults(attrs)
          return nil unless attrs.resilience.retry_policy_enabled
          { client_policy: { tls: attrs.security.mtls_enabled ? { enforce: true,
            validation: { trust: { acm: { certificate_authority_arns: [attrs.security.certificate_authority_arn] } } } } : nil } }
        end

        def create_virtual_services(name, attrs, mesh_ref, tags)
          attrs.services.each_with_object({}) do |service, services|
            services[service.name.to_sym] = aws_appmesh_virtual_service(
              component_resource_name(name, :virtual_service, service.name.to_sym),
              { name: "#{service.name}.#{attrs.service_discovery.namespace_name}", mesh_name: mesh_ref.name,
                spec: { provider: { virtual_node: { virtual_node_name: service.name } } }, tags: tags.merge(Service: service.name) })
          end
        end

        def create_virtual_routers(name, attrs, mesh_ref, tags, components)
          routers = {}
          attrs.services.group_by(&:name).select { |_, svcs| svcs.length > 1 }.each do |svc_name, versions|
            routers[svc_name.to_sym] = aws_appmesh_virtual_router(component_resource_name(name, :virtual_router, svc_name.to_sym),
              { name: "#{svc_name}-router", mesh_name: mesh_ref.name, tags: tags.merge(Service: svc_name),
                spec: { listener: [{ port_mapping: { port: versions.first.port, protocol: versions.first.protocol } }] } })
            components["route_#{svc_name}".to_sym] = create_route(name, attrs, mesh_ref, svc_name, versions, routers[svc_name.to_sym], tags)
          end
          components[:virtual_routers] = routers
        end

        def create_route(name, attrs, mesh_ref, svc_name, versions, router_ref, tags)
          aws_appmesh_route(component_resource_name(name, :route, svc_name.to_sym), {
            name: "#{svc_name}-route", mesh_name: mesh_ref.name, virtual_router_name: router_ref.name,
            spec: { http_route: { match: { prefix: "/" },
              action: { weighted_target: versions.map { |v| { virtual_node: v.name, weight: v.weight } } },
              retry_policy: attrs.resilience.retry_policy_enabled ? { http_retry_events: ["server-error", "gateway-error"],
                max_retries: attrs.resilience.max_retries, per_retry_timeout: { unit: "s", value: attrs.resilience.retry_timeout_seconds } } : nil,
              timeout: { per_request: { unit: "s", value: versions.first.timeout_seconds } } }.compact },
            tags: tags.merge(Service: svc_name) })
        end
      end
    end
  end
end
