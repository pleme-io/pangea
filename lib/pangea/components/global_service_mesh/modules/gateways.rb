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
      # Gateway resources: ingress gateway, egress gateway, and NLB
      module Gateways
        def create_gateways(name, attrs, mesh_ref, _regional_resources, tags)
          gateway_resources = {}

          if attrs.gateway.ingress_gateway_enabled
            create_ingress_gateway(name, attrs, mesh_ref, tags, gateway_resources)
          end

          if attrs.gateway.egress_gateway_enabled
            gateway_resources[:egress] = create_egress_gateway(name, attrs, mesh_ref, tags)
          end

          if attrs.gateway.custom_domain_enabled
            create_gateway_load_balancer(name, attrs, tags, gateway_resources)
          end

          gateway_resources
        end

        private

        def create_ingress_gateway(name, attrs, mesh_ref, tags, gateway_resources)
          gateway_resources[:ingress] = aws_appmesh_virtual_gateway(
            component_resource_name(name, :ingress_gateway),
            {
              name: "#{name}-ingress-gateway",
              mesh_name: mesh_ref.name,
              spec: build_ingress_gateway_spec(attrs),
              tags: tags.merge(Type: "Ingress")
            }
          )

          gateway_resources[:routes] = create_gateway_routes(name, attrs, mesh_ref, gateway_resources[:ingress], tags)
        end

        def build_ingress_gateway_spec(attrs)
          {
            listener: [{
              port_mapping: { port: attrs.gateway.gateway_port, protocol: attrs.gateway.gateway_protocol },
              tls: build_gateway_tls(attrs),
              health_check: build_gateway_health_check(attrs)
            }.compact],
            logging: build_gateway_logging(attrs)
          }.compact
        end

        def build_gateway_tls(attrs)
          return nil unless attrs.gateway.gateway_protocol == 'HTTPS'

          {
            mode: attrs.security.tls_mode,
            certificate: { acm: { certificate_arn: "arn:aws:acm:REGION:ACCOUNT:certificate/gateway-cert" } }
          }
        end

        def build_gateway_health_check(attrs)
          {
            healthy_threshold: 2,
            interval_millis: 30000,
            path: "/health",
            port: attrs.gateway.gateway_port,
            protocol: attrs.gateway.gateway_protocol == 'GRPC' ? 'grpc' : 'http',
            timeout_millis: 5000,
            unhealthy_threshold: 3
          }
        end

        def build_gateway_logging(attrs)
          return nil unless attrs.observability.access_logging_enabled

          { access_log: { file: { path: "/dev/stdout" } } }
        end

        def create_gateway_routes(name, attrs, mesh_ref, ingress_gateway_ref, tags)
          gateway_routes = {}

          attrs.services.each do |service|
            gateway_routes[service.name.to_sym] = aws_appmesh_gateway_route(
              component_resource_name(name, :gateway_route, service.name.to_sym),
              {
                name: "#{service.name}-route",
                mesh_name: mesh_ref.name,
                virtual_gateway_name: ingress_gateway_ref.name,
                spec: {
                  http_route: {
                    match: { prefix: "/#{service.name}" },
                    action: {
                      target: {
                        virtual_service: {
                          virtual_service_name: "#{service.name}.#{attrs.service_discovery.namespace_name}"
                        }
                      }
                    }
                  }
                },
                tags: tags.merge(Service: service.name)
              }
            )
          end

          gateway_routes
        end

        def create_egress_gateway(name, attrs, mesh_ref, tags)
          aws_appmesh_virtual_gateway(
            component_resource_name(name, :egress_gateway),
            {
              name: "#{name}-egress-gateway",
              mesh_name: mesh_ref.name,
              spec: {
                listener: [{ port_mapping: { port: 8080, protocol: "HTTP" } }],
                logging: build_gateway_logging(attrs)
              }.compact,
              tags: tags.merge(Type: "Egress")
            }
          )
        end

        def create_gateway_load_balancer(name, attrs, tags, gateway_resources)
          gateway_resources[:nlb] = create_nlb(name, tags)
          gateway_resources[:target_group] = create_target_group(name, attrs, tags)
          gateway_resources[:listener] = create_listener(name, attrs, gateway_resources)
        end

        def create_nlb(name, tags)
          aws_lb(
            component_resource_name(name, :gateway_nlb),
            {
              name: "#{name}-gateway-nlb",
              internal: false,
              load_balancer_type: "network",
              subnets: [],
              enable_cross_zone_load_balancing: true,
              enable_deletion_protection: true,
              tags: tags
            }
          )
        end

        def create_target_group(name, attrs, tags)
          aws_lb_target_group(
            component_resource_name(name, :gateway_target_group),
            {
              name: "#{name}-gateway-tg",
              port: attrs.gateway.gateway_port,
              protocol: attrs.gateway.gateway_protocol == 'HTTPS' ? 'TLS' : 'TCP',
              vpc_id: "vpc-placeholder",
              target_type: "ip",
              health_check: {
                enabled: true,
                healthy_threshold: 2,
                interval: 30,
                port: attrs.gateway.gateway_port,
                protocol: "TCP",
                unhealthy_threshold: 2
              },
              tags: tags
            }
          )
        end

        def create_listener(name, attrs, gateway_resources)
          aws_lb_listener(
            component_resource_name(name, :gateway_listener),
            {
              load_balancer_arn: gateway_resources[:nlb].arn,
              port: attrs.gateway.gateway_port,
              protocol: attrs.gateway.gateway_protocol == 'HTTPS' ? 'TLS' : 'TCP',
              certificate_arn: attrs.gateway.gateway_protocol == 'HTTPS' ?
                "arn:aws:acm:REGION:ACCOUNT:certificate/nlb-cert" : nil,
              default_action: [{ type: "forward", target_group_arn: gateway_resources[:target_group].arn }]
            }.compact
          )
        end
      end
    end
  end
end
