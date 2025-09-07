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
require 'json'

module Pangea
  module Components
    # Multi-region service mesh infrastructure for microservices communication
    # Creates App Mesh, service discovery, cross-region connectivity, and observability
    def global_service_mesh(name, attributes = {})
      include Base
      include Resources::AWS
      
      # Validate and set defaults
      component_attrs = GlobalServiceMesh::GlobalServiceMeshAttributes.new(attributes)
      component_attrs.validate!
      
      # Generate component-specific tags
      component_tag_set = component_tags('GlobalServiceMesh', name, component_attrs.tags)
      
      resources = {}
      
      # Create the App Mesh
      mesh_ref = aws_appmesh_mesh(
        component_resource_name(name, :mesh),
        {
          name: component_attrs.mesh_name,
          
          spec: {
            egress_filter: {
              type: component_attrs.gateway.egress_gateway_enabled ? "ALLOW_ALL" : "DROP_ALL"
            },
            service_discovery: {
              ip_preference: "IPv4_PREFERRED"
            }
          },
          
          tags: component_tag_set
        }
      )
      resources[:mesh] = mesh_ref
      
      # Create Cloud Map namespace for service discovery
      namespace_ref = aws_service_discovery_private_dns_namespace(
        component_resource_name(name, :namespace),
        {
          name: component_attrs.service_discovery.namespace_name,
          description: component_attrs.service_discovery.namespace_description,
          vpc: "vpc-placeholder", # Would be dynamic based on region
          tags: component_tag_set
        }
      )
      resources[:namespace] = namespace_ref
      
      # Process each region
      regional_resources = {}
      
      component_attrs.regions.each do |region|
        region_resources = setup_regional_mesh(
          name, region, component_attrs, mesh_ref, namespace_ref, component_tag_set
        )
        regional_resources[region.to_sym] = region_resources
      end
      
      resources[:regional] = regional_resources
      
      # Create cross-region connectivity
      if component_attrs.regions.length > 1 && component_attrs.cross_region.peering_enabled
        connectivity_resources = create_cross_region_connectivity(
          name, component_attrs, regional_resources, component_tag_set
        )
        resources[:connectivity] = connectivity_resources
      end
      
      # Create service mesh components
      mesh_components = create_mesh_components(
        name, component_attrs, mesh_ref, regional_resources, component_tag_set
      )
      resources[:mesh_components] = mesh_components
      
      # Create gateways if enabled
      if component_attrs.gateway.ingress_gateway_enabled || component_attrs.gateway.egress_gateway_enabled
        gateway_resources = create_gateways(
          name, component_attrs, mesh_ref, regional_resources, component_tag_set
        )
        resources[:gateways] = gateway_resources
      end
      
      # Create observability infrastructure
      if component_attrs.observability.xray_enabled || component_attrs.observability.cloudwatch_metrics_enabled
        observability_resources = create_observability_infrastructure(
          name, component_attrs, resources, component_tag_set
        )
        resources[:observability] = observability_resources
      end
      
      # Create security resources
      if component_attrs.security.mtls_enabled
        security_resources = create_security_infrastructure(
          name, component_attrs, mesh_ref, component_tag_set
        )
        resources[:security] = security_resources
      end
      
      # Create resilience patterns
      if component_attrs.resilience.chaos_testing_enabled
        resilience_resources = create_resilience_infrastructure(
          name, component_attrs, resources, component_tag_set
        )
        resources[:resilience] = resilience_resources
      end
      
      # Calculate outputs
      outputs = {
        mesh_name: component_attrs.mesh_name,
        mesh_arn: mesh_ref.arn,
        
        service_discovery_namespace: component_attrs.service_discovery.namespace_name,
        
        regions: component_attrs.regions,
        services: component_attrs.services.map { |s| 
          {
            name: s.name,
            region: s.region,
            endpoint: "#{s.name}.#{component_attrs.service_discovery.namespace_name}",
            port: s.port,
            protocol: s.protocol
          }
        },
        
        connectivity_type: extract_connectivity_type(component_attrs),
        
        security_features: [
          ("mTLS Enabled" if component_attrs.security.mtls_enabled),
          ("Service Authentication" if component_attrs.security.service_auth_enabled),
          ("RBAC Enabled" if component_attrs.security.rbac_enabled),
          ("Encryption in Transit" if component_attrs.security.encryption_in_transit),
          ("Secrets Manager Integration" if component_attrs.security.secrets_manager_integration)
        ].compact,
        
        traffic_management_features: [
          ("Circuit Breaker" if component_attrs.traffic_management.circuit_breaker_enabled),
          ("Outlier Detection" if component_attrs.traffic_management.outlier_detection_enabled),
          ("Canary Deployments" if component_attrs.traffic_management.canary_deployments_enabled),
          ("Global Load Balancing" if component_attrs.enable_global_load_balancing),
          ("Multi-cluster Routing" if component_attrs.enable_multi_cluster_routing)
        ].compact,
        
        observability_features: [
          ("X-Ray Distributed Tracing" if component_attrs.observability.xray_enabled),
          ("CloudWatch Metrics" if component_attrs.observability.cloudwatch_metrics_enabled),
          ("Access Logging" if component_attrs.observability.access_logging_enabled),
          ("Envoy Stats" if component_attrs.observability.envoy_stats_enabled),
          ("Custom Metrics" if component_attrs.observability.custom_metrics_enabled)
        ].compact,
        
        resilience_features: [
          ("Retry Policy" if component_attrs.resilience.retry_policy_enabled),
          ("Bulkhead Pattern" if component_attrs.resilience.bulkhead_enabled),
          ("Request Timeout" if component_attrs.resilience.timeout_enabled),
          ("Chaos Testing" if component_attrs.resilience.chaos_testing_enabled)
        ].compact,
        
        gateway_endpoints: extract_gateway_endpoints(resources[:gateways]),
        
        virtual_nodes: mesh_components[:virtual_nodes]&.keys || [],
        virtual_services: mesh_components[:virtual_services]&.keys || [],
        virtual_routers: mesh_components[:virtual_routers]&.keys || [],
        
        estimated_monthly_cost: estimate_service_mesh_cost(component_attrs, resources)
      }
      
      create_component_reference(
        'global_service_mesh',
        name,
        component_attrs.to_h,
        resources,
        outputs
      )
    end
    
    private
    
    def setup_regional_mesh(name, region, attrs, mesh_ref, namespace_ref, tags)
      region_resources = {}
      
      # Get services for this region
      region_services = attrs.services.select { |s| s.region == region }
      
      # Create VPC endpoints for App Mesh and Cloud Map
      vpc_endpoints = {}
      
      # App Mesh VPC endpoint
      appmesh_endpoint_ref = aws_vpc_endpoint(
        component_resource_name(name, :appmesh_endpoint, region.to_sym),
        {
          vpc_id: "vpc-placeholder", # Would reference actual VPC
          service_name: "com.amazonaws.#{region}.appmesh-envoy-management",
          vpc_endpoint_type: "Interface",
          subnet_ids: [], # Would reference private subnets
          security_group_ids: [], # Would reference security groups
          private_dns_enabled: true,
          tags: tags.merge(Region: region)
        }
      )
      vpc_endpoints[:appmesh] = appmesh_endpoint_ref
      
      # Cloud Map VPC endpoint
      servicediscovery_endpoint_ref = aws_vpc_endpoint(
        component_resource_name(name, :servicediscovery_endpoint, region.to_sym),
        {
          vpc_id: "vpc-placeholder",
          service_name: "com.amazonaws.#{region}.servicediscovery",
          vpc_endpoint_type: "Interface",
          subnet_ids: [],
          security_group_ids: [],
          private_dns_enabled: true,
          tags: tags.merge(Region: region)
        }
      )
      vpc_endpoints[:servicediscovery] = servicediscovery_endpoint_ref
      
      region_resources[:vpc_endpoints] = vpc_endpoints
      
      # Create service-specific resources
      services_resources = {}
      
      region_services.each do |service|
        service_resources = {}
        
        # Create Cloud Map service
        service_discovery_ref = aws_service_discovery_service(
          component_resource_name(name, :service_discovery, service.name.to_sym),
          {
            name: service.name,
            namespace_id: namespace_ref.id,
            
            dns_config: {
              namespace_id: namespace_ref.id,
              routing_policy: attrs.service_discovery.routing_policy,
              
              dns_records: [{
                ttl: attrs.service_discovery.dns_ttl,
                type: "A"
              }]
            },
            
            health_check_custom_config: attrs.service_discovery.health_check_custom_config_enabled ? {
              failure_threshold: attrs.virtual_node_config.unhealthy_threshold
            } : nil,
            
            tags: tags.merge(Service: service.name, Region: region)
          }.compact
        )
        service_resources[:discovery] = service_discovery_ref
        
        # Create ECS task definition if not provided
        if !service.task_definition_ref && service.cluster_ref
          task_def_ref = aws_ecs_task_definition(
            component_resource_name(name, :task_definition, service.name.to_sym),
            {
              family: "#{service.name}-task",
              network_mode: "awsvpc",
              requires_compatibilities: ["FARGATE"],
              cpu: "256",
              memory: "512",
              
              proxy_configuration: {
                type: "APPMESH",
                container_name: "envoy",
                properties: {
                  AppPorts: service.port.to_s,
                  EgressIgnoredIPs: "169.254.170.2,169.254.169.254",
                  IgnoredUID: "1337",
                  ProxyEgressPort: 15001,
                  ProxyIngressPort: 15000
                }
              },
              
              container_definitions: JSON.generate([
                {
                  name: service.name,
                  image: "service-image:latest",
                  portMappings: [{
                    containerPort: service.port,
                    protocol: "tcp"
                  }],
                  environment: [
                    { name: "SERVICE_NAME", value: service.name },
                    { name: "SERVICE_PORT", value: service.port.to_s }
                  ],
                  dependsOn: [{
                    containerName: "envoy",
                    condition: "HEALTHY"
                  }]
                },
                {
                  name: "envoy",
                  image: "public.ecr.aws/appmesh/aws-appmesh-envoy:latest",
                  memory: 128,
                  user: "1337",
                  essential: true,
                  environment: [
                    { name: "APPMESH_RESOURCE_ARN", value: "mesh/#{attrs.mesh_name}/virtualNode/#{service.name}" },
                    { name: "ENABLE_ENVOY_XRAY_TRACING", value: attrs.observability.xray_enabled ? "1" : "0" }
                  ],
                  healthCheck: {
                    command: ["CMD-SHELL", "curl -s http://localhost:9901/server_info | grep state | grep -q LIVE"],
                    interval: 5,
                    timeout: 2,
                    retries: 3,
                    startPeriod: 10
                  }
                }
              ]),
              
              task_role_arn: "arn:aws:iam::ACCOUNT:role/ecsTaskRole",
              execution_role_arn: "arn:aws:iam::ACCOUNT:role/ecsTaskExecutionRole",
              
              tags: tags.merge(Service: service.name)
            }
          )
          service_resources[:task_definition] = task_def_ref
        else
          service_resources[:task_definition] = service.task_definition_ref
        end
        
        services_resources[service.name.to_sym] = service_resources
      end
      
      region_resources[:services] = services_resources
      
      # Create Transit Gateway if enabled for cross-region
      if attrs.cross_region.transit_gateway_enabled && attrs.regions.length > 1
        tgw_ref = aws_ec2_transit_gateway(
          component_resource_name(name, :transit_gateway, region.to_sym),
          {
            description: "Transit Gateway for service mesh in #{region}",
            amazon_side_asn: 64512,
            default_route_table_association: "enable",
            default_route_table_propagation: "enable",
            dns_support: "enable",
            vpn_ecmp_support: "enable",
            tags: tags.merge(Region: region)
          }
        )
        region_resources[:transit_gateway] = tgw_ref
      end
      
      region_resources
    end
    
    def create_cross_region_connectivity(name, attrs, regional_resources, tags)
      connectivity_resources = {}
      
      # Create Transit Gateway peering attachments
      if attrs.cross_region.transit_gateway_enabled
        peering_attachments = {}
        
        attrs.regions.combination(2).each do |region1, region2|
          tgw1 = regional_resources[region1.to_sym][:transit_gateway]
          tgw2 = regional_resources[region2.to_sym][:transit_gateway]
          
          next unless tgw1 && tgw2
          
          peering_ref = aws_ec2_transit_gateway_peering_attachment(
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
          peering_attachments["#{region1}_#{region2}".to_sym] = peering_ref
        end
        
        connectivity_resources[:tgw_peering] = peering_attachments
      end
      
      # Create PrivateLink connections if enabled
      if attrs.cross_region.private_link_enabled
        privatelink_connections = {}
        
        attrs.services.group_by(&:region).each do |provider_region, services|
          services.each do |service|
            # Create VPC endpoint service
            endpoint_service_ref = aws_vpc_endpoint_service(
              component_resource_name(name, :endpoint_service, service.name.to_sym),
              {
                acceptance_required: false,
                network_load_balancer_arns: [], # Would reference NLBs
                tags: tags.merge(Service: service.name, Region: provider_region)
              }
            )
            
            privatelink_connections["service_#{service.name}".to_sym] = endpoint_service_ref
            
            # Create VPC endpoints in consumer regions
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
              privatelink_connections["endpoint_#{service.name}_#{consumer_region}".to_sym] = endpoint_ref
            end
          end
        end
        
        connectivity_resources[:privatelink] = privatelink_connections
      end
      
      connectivity_resources
    end
    
    def create_mesh_components(name, attrs, mesh_ref, regional_resources, tags)
      mesh_components = {}
      
      # Create virtual nodes for each service
      virtual_nodes = {}
      attrs.services.each do |service|
        virtual_node_ref = aws_appmesh_virtual_node(
          component_resource_name(name, :virtual_node, service.name.to_sym),
          {
            name: service.name,
            mesh_name: mesh_ref.name,
            
            spec: {
              listener: [{
                port_mapping: {
                  port: service.port,
                  protocol: service.protocol
                },
                
                health_check: {
                  healthy_threshold: attrs.virtual_node_config.healthy_threshold,
                  interval_millis: attrs.virtual_node_config.health_check_interval_millis,
                  path: service.health_check_path,
                  port: service.port,
                  protocol: service.protocol == 'GRPC' ? 'grpc' : 'http',
                  timeout_millis: attrs.virtual_node_config.health_check_timeout_millis,
                  unhealthy_threshold: attrs.virtual_node_config.unhealthy_threshold
                },
                
                tls: attrs.security.mtls_enabled ? {
                  mode: attrs.security.tls_mode,
                  certificate: {
                    acm: {
                      certificate_arn: "arn:aws:acm:#{service.region}:ACCOUNT:certificate/cert"
                    }
                  },
                  validation: {
                    trust: {
                      acm: {
                        certificate_authority_arns: [attrs.security.certificate_authority_arn]
                      }
                    }
                  }
                } : nil,
                
                outlier_detection: attrs.traffic_management.outlier_detection_enabled ? {
                  base_ejection_duration: {
                    unit: "s",
                    value: attrs.traffic_management.outlier_ejection_duration_seconds
                  },
                  interval: {
                    unit: "s",
                    value: 10
                  },
                  max_ejection_percent: attrs.traffic_management.max_ejection_percent,
                  max_server_errors: attrs.traffic_management.circuit_breaker_threshold
                } : nil,
                
                connection_pool: attrs.resilience.bulkhead_enabled ? {
                  http: {
                    max_connections: attrs.resilience.max_connections,
                    max_pending_requests: attrs.resilience.max_pending_requests
                  }
                } : nil,
                
                timeout: attrs.resilience.timeout_enabled ? {
                  http: {
                    idle: {
                      unit: "s",
                      value: 300
                    },
                    per_request: {
                      unit: "s",
                      value: attrs.resilience.request_timeout_seconds
                    }
                  }
                } : nil
              }.compact],
              
              service_discovery: {
                aws_cloud_map: {
                  namespace_name: attrs.service_discovery.namespace_name,
                  service_name: service.name
                }
              },
              
              backend: attrs.virtual_node_config.backends.any? ? 
                attrs.virtual_node_config.backends.map do |backend|
                  {
                    virtual_service: {
                      virtual_service_name: "#{backend}.#{attrs.service_discovery.namespace_name}"
                    }
                  }
                end : nil,
              
              backend_defaults: attrs.resilience.retry_policy_enabled ? {
                client_policy: {
                  tls: attrs.security.mtls_enabled ? {
                    enforce: true,
                    validation: {
                      trust: {
                        acm: {
                          certificate_authority_arns: [attrs.security.certificate_authority_arn]
                        }
                      }
                    }
                  } : nil
                }
              } : nil
            }.compact,
            
            tags: tags.merge(Service: service.name, Region: service.region)
          }
        )
        virtual_nodes[service.name.to_sym] = virtual_node_ref
      end
      mesh_components[:virtual_nodes] = virtual_nodes
      
      # Create virtual services
      virtual_services = {}
      attrs.services.each do |service|
        virtual_service_ref = aws_appmesh_virtual_service(
          component_resource_name(name, :virtual_service, service.name.to_sym),
          {
            name: "#{service.name}.#{attrs.service_discovery.namespace_name}",
            mesh_name: mesh_ref.name,
            
            spec: {
              provider: {
                virtual_node: {
                  virtual_node_name: service.name
                }
              }
            },
            
            tags: tags.merge(Service: service.name)
          }
        )
        virtual_services[service.name.to_sym] = virtual_service_ref
      end
      mesh_components[:virtual_services] = virtual_services
      
      # Create virtual routers for advanced routing
      if attrs.traffic_management.canary_deployments_enabled || attrs.enable_multi_cluster_routing
        virtual_routers = {}
        
        attrs.services.group_by(&:name).select { |_, svcs| svcs.length > 1 }.each do |service_name, service_versions|
          virtual_router_ref = aws_appmesh_virtual_router(
            component_resource_name(name, :virtual_router, service_name.to_sym),
            {
              name: "#{service_name}-router",
              mesh_name: mesh_ref.name,
              
              spec: {
                listener: [{
                  port_mapping: {
                    port: service_versions.first.port,
                    protocol: service_versions.first.protocol
                  }
                }]
              },
              
              tags: tags.merge(Service: service_name)
            }
          )
          virtual_routers[service_name.to_sym] = virtual_router_ref
          
          # Create routes
          route_ref = aws_appmesh_route(
            component_resource_name(name, :route, service_name.to_sym),
            {
              name: "#{service_name}-route",
              mesh_name: mesh_ref.name,
              virtual_router_name: virtual_router_ref.name,
              
              spec: {
                http_route: {
                  match: {
                    prefix: "/"
                  },
                  
                  action: {
                    weighted_target: service_versions.map do |version|
                      {
                        virtual_node: version.name,
                        weight: version.weight
                      }
                    end
                  },
                  
                  retry_policy: attrs.resilience.retry_policy_enabled ? {
                    http_retry_events: ["server-error", "gateway-error"],
                    max_retries: attrs.resilience.max_retries,
                    per_retry_timeout: {
                      unit: "s",
                      value: attrs.resilience.retry_timeout_seconds
                    }
                  } : nil,
                  
                  timeout: {
                    per_request: {
                      unit: "s",
                      value: service_versions.first.timeout_seconds
                    }
                  }
                }.compact
              },
              
              tags: tags.merge(Service: service_name)
            }
          )
          mesh_components["route_#{service_name}".to_sym] = route_ref
        end
        
        mesh_components[:virtual_routers] = virtual_routers
      end
      
      mesh_components
    end
    
    def create_gateways(name, attrs, mesh_ref, regional_resources, tags)
      gateway_resources = {}
      
      # Create virtual gateway for ingress
      if attrs.gateway.ingress_gateway_enabled
        ingress_gateway_ref = aws_appmesh_virtual_gateway(
          component_resource_name(name, :ingress_gateway),
          {
            name: "#{name}-ingress-gateway",
            mesh_name: mesh_ref.name,
            
            spec: {
              listener: [{
                port_mapping: {
                  port: attrs.gateway.gateway_port,
                  protocol: attrs.gateway.gateway_protocol
                },
                
                tls: attrs.gateway.gateway_protocol == 'HTTPS' ? {
                  mode: attrs.security.tls_mode,
                  certificate: {
                    acm: {
                      certificate_arn: "arn:aws:acm:REGION:ACCOUNT:certificate/gateway-cert"
                    }
                  }
                } : nil,
                
                health_check: {
                  healthy_threshold: 2,
                  interval_millis: 30000,
                  path: "/health",
                  port: attrs.gateway.gateway_port,
                  protocol: attrs.gateway.gateway_protocol == 'GRPC' ? 'grpc' : 'http',
                  timeout_millis: 5000,
                  unhealthy_threshold: 3
                }
              }.compact],
              
              logging: attrs.observability.access_logging_enabled ? {
                access_log: {
                  file: {
                    path: "/dev/stdout"
                  }
                }
              } : nil
            }.compact,
            
            tags: tags.merge(Type: "Ingress")
          }
        )
        gateway_resources[:ingress] = ingress_gateway_ref
        
        # Create gateway routes
        gateway_routes = {}
        attrs.services.each do |service|
          gateway_route_ref = aws_appmesh_gateway_route(
            component_resource_name(name, :gateway_route, service.name.to_sym),
            {
              name: "#{service.name}-route",
              mesh_name: mesh_ref.name,
              virtual_gateway_name: ingress_gateway_ref.name,
              
              spec: {
                http_route: {
                  match: {
                    prefix: "/#{service.name}"
                  },
                  
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
          gateway_routes[service.name.to_sym] = gateway_route_ref
        end
        gateway_resources[:routes] = gateway_routes
      end
      
      # Create egress gateway if enabled
      if attrs.gateway.egress_gateway_enabled
        egress_gateway_ref = aws_appmesh_virtual_gateway(
          component_resource_name(name, :egress_gateway),
          {
            name: "#{name}-egress-gateway",
            mesh_name: mesh_ref.name,
            
            spec: {
              listener: [{
                port_mapping: {
                  port: 8080,
                  protocol: "HTTP"
                }
              }],
              
              logging: attrs.observability.access_logging_enabled ? {
                access_log: {
                  file: {
                    path: "/dev/stdout"
                  }
                }
              } : nil
            }.compact,
            
            tags: tags.merge(Type: "Egress")
          }
        )
        gateway_resources[:egress] = egress_gateway_ref
      end
      
      # Create NLB for gateway if custom domain enabled
      if attrs.gateway.custom_domain_enabled
        nlb_ref = aws_lb(
          component_resource_name(name, :gateway_nlb),
          {
            name: "#{name}-gateway-nlb",
            internal: false,
            load_balancer_type: "network",
            subnets: [], # Would reference public subnets
            
            enable_cross_zone_load_balancing: true,
            enable_deletion_protection: true,
            
            tags: tags
          }
        )
        gateway_resources[:nlb] = nlb_ref
        
        # Create target group
        target_group_ref = aws_lb_target_group(
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
        gateway_resources[:target_group] = target_group_ref
        
        # Create listener
        listener_ref = aws_lb_listener(
          component_resource_name(name, :gateway_listener),
          {
            load_balancer_arn: nlb_ref.arn,
            port: attrs.gateway.gateway_port,
            protocol: attrs.gateway.gateway_protocol == 'HTTPS' ? 'TLS' : 'TCP',
            
            certificate_arn: attrs.gateway.gateway_protocol == 'HTTPS' ? 
              "arn:aws:acm:REGION:ACCOUNT:certificate/nlb-cert" : nil,
            
            default_action: [{
              type: "forward",
              target_group_arn: target_group_ref.arn
            }]
          }.compact
        )
        gateway_resources[:listener] = listener_ref
      end
      
      gateway_resources
    end
    
    def create_observability_infrastructure(name, attrs, resources, tags)
      observability_resources = {}
      
      # Create X-Ray service map if enabled
      if attrs.observability.xray_enabled
        # Create X-Ray sampling rule
        sampling_rule_ref = aws_xray_sampling_rule(
          component_resource_name(name, :xray_sampling_rule),
          {
            rule_name: "#{name}-service-mesh-sampling",
            priority: 9000,
            version: 1,
            reservoir_size: 1,
            fixed_rate: attrs.observability.distributed_tracing_sampling_rate,
            url_path: "*",
            host: "*",
            http_method: "*",
            service_type: "*",
            service_name: "*",
            resource_arn: "*",
            tags: tags
          }
        )
        observability_resources[:sampling_rule] = sampling_rule_ref
        
        # Create X-Ray group
        xray_group_ref = aws_xray_group(
          component_resource_name(name, :xray_group),
          {
            group_name: attrs.mesh_name,
            filter_expression: "service(\"*#{attrs.mesh_name}*\")",
            tags: tags
          }
        )
        observability_resources[:xray_group] = xray_group_ref
      end
      
      # Create CloudWatch Log Groups
      if attrs.observability.access_logging_enabled
        log_groups = {}
        
        attrs.services.each do |service|
          log_group_ref = aws_cloudwatch_log_group(
            component_resource_name(name, :log_group, service.name.to_sym),
            {
              name: "/aws/appmesh/#{attrs.mesh_name}/#{service.name}",
              retention_in_days: attrs.observability.log_retention_days,
              tags: tags.merge(Service: service.name)
            }
          )
          log_groups[service.name.to_sym] = log_group_ref
        end
        
        observability_resources[:log_groups] = log_groups
      end
      
      # Create CloudWatch Dashboard
      dashboard_widgets = []
      
      # Service mesh overview widget
      dashboard_widgets << {
        type: "metric",
        x: 0,
        y: 0,
        width: 24,
        height: 6,
        properties: {
          title: "Service Mesh Overview",
          metrics: attrs.services.map do |service|
            ["AWS/AppMesh", "TargetResponseTime", { 
              MeshName: attrs.mesh_name,
              VirtualNodeName: service.name 
            }]
          end,
          period: 300,
          stat: "Average",
          region: attrs.regions.first,
          yAxis: { left: { label: "Response Time (ms)" } }
        }
      }
      
      # Request rate by service
      dashboard_widgets << {
        type: "metric",
        x: 0,
        y: 6,
        width: 12,
        height: 6,
        properties: {
          title: "Request Rate by Service",
          metrics: attrs.services.map do |service|
            ["AWS/AppMesh", "RequestCount", {
              MeshName: attrs.mesh_name,
              VirtualNodeName: service.name
            }]
          end,
          period: 300,
          stat: "Sum",
          region: attrs.regions.first
        }
      }
      
      # Error rate by service
      dashboard_widgets << {
        type: "metric",
        x: 12,
        y: 6,
        width: 12,
        height: 6,
        properties: {
          title: "Error Rate by Service",
          metrics: attrs.services.map do |service|
            ["AWS/AppMesh", "TargetConnectionErrorCount", {
              MeshName: attrs.mesh_name,
              VirtualNodeName: service.name
            }]
          end,
          period: 300,
          stat: "Sum",
          region: attrs.regions.first
        }
      }
      
      # Circuit breaker status
      if attrs.traffic_management.circuit_breaker_enabled
        dashboard_widgets << {
          type: "metric",
          x: 0,
          y: 12,
          width: 24,
          height: 6,
          properties: {
            title: "Circuit Breaker Status",
            metrics: attrs.services.map do |service|
              ["AWS/AppMesh", "CircuitBreakerOpen", {
                MeshName: attrs.mesh_name,
                VirtualNodeName: service.name
              }]
            end,
            period: 60,
            stat: "Maximum",
            region: attrs.regions.first,
            yAxis: { left: { min: 0, max: 1 } }
          }
        }
      end
      
      dashboard_ref = aws_cloudwatch_dashboard(
        component_resource_name(name, :dashboard),
        {
          dashboard_name: "#{name}-service-mesh",
          dashboard_body: JSON.generate({
            widgets: dashboard_widgets,
            periodOverride: "auto",
            start: "-PT6H"
          })
        }
      )
      observability_resources[:dashboard] = dashboard_ref
      
      # Create alarms
      alarms = {}
      attrs.services.each do |service|
        # High latency alarm
        latency_alarm_ref = aws_cloudwatch_metric_alarm(
          component_resource_name(name, :alarm_latency, service.name.to_sym),
          {
            alarm_name: "#{name}-#{service.name}-high-latency",
            comparison_operator: "GreaterThanThreshold",
            evaluation_periods: "2",
            metric_name: "TargetResponseTime",
            namespace: "AWS/AppMesh",
            period: "300",
            statistic: "Average",
            threshold: (service.timeout_seconds * 1000 * 0.8).to_s,
            alarm_description: "Service #{service.name} latency is high",
            dimensions: {
              MeshName: attrs.mesh_name,
              VirtualNodeName: service.name
            },
            tags: tags
          }
        )
        alarms["latency_#{service.name}".to_sym] = latency_alarm_ref
        
        # Connection error alarm
        error_alarm_ref = aws_cloudwatch_metric_alarm(
          component_resource_name(name, :alarm_errors, service.name.to_sym),
          {
            alarm_name: "#{name}-#{service.name}-connection-errors",
            comparison_operator: "GreaterThanThreshold",
            evaluation_periods: "2",
            metric_name: "TargetConnectionErrorCount",
            namespace: "AWS/AppMesh",
            period: "300",
            statistic: "Sum",
            threshold: "10",
            alarm_description: "Service #{service.name} connection errors",
            dimensions: {
              MeshName: attrs.mesh_name,
              VirtualNodeName: service.name
            },
            tags: tags
          }
        )
        alarms["errors_#{service.name}".to_sym] = error_alarm_ref
      end
      observability_resources[:alarms] = alarms
      
      observability_resources
    end
    
    def create_security_infrastructure(name, attrs, mesh_ref, tags)
      security_resources = {}
      
      # Create ACM Private CA if not provided
      if attrs.security.mtls_enabled && !attrs.security.certificate_authority_arn
        ca_ref = aws_acmpca_certificate_authority(
          component_resource_name(name, :private_ca),
          {
            certificate_authority_configuration: {
              key_algorithm: "RSA_4096",
              signing_algorithm: "SHA512WITHRSA",
              subject: {
                common_name: "#{attrs.mesh_name}.ca"
              }
            },
            type: "ROOT",
            tags: tags
          }
        )
        security_resources[:ca] = ca_ref
      end
      
      # Create IAM roles for service authentication
      if attrs.security.service_auth_enabled
        service_roles = {}
        
        attrs.services.each do |service|
          role_ref = aws_iam_role(
            component_resource_name(name, :service_role, service.name.to_sym),
            {
              name: "#{name}-${service.name}-role",
              assume_role_policy: JSON.generate({
                Version: "2012-10-17",
                Statement: [{
                  Effect: "Allow",
                  Principal: {
                    Service: "ecs-tasks.amazonaws.com"
                  },
                  Action: "sts:AssumeRole",
                  Condition: {
                    StringEquals: {
                      "sts:ExternalId": service.name
                    }
                  }
                }]
              }),
              tags: tags.merge(Service: service.name)
            }
          )
          service_roles[service.name.to_sym] = role_ref
          
          # Attach App Mesh policy
          policy_attachment_ref = aws_iam_role_policy_attachment(
            component_resource_name(name, :service_policy, service.name.to_sym),
            {
              role: role_ref.name,
              policy_arn: "arn:aws:iam::aws:policy/AWSAppMeshEnvoyAccess"
            }
          )
          security_resources["policy_#{service.name}".to_sym] = policy_attachment_ref
        end
        
        security_resources[:service_roles] = service_roles
      end
      
      # Create Secrets Manager secrets for sensitive data
      if attrs.security.secrets_manager_integration
        secrets = {}
        
        attrs.services.each do |service|
          secret_ref = aws_secretsmanager_secret(
            component_resource_name(name, :service_secret, service.name.to_sym),
            {
              name: "#{name}/#{service.name}/config",
              description: "Configuration secrets for #{service.name}",
              tags: tags.merge(Service: service.name)
            }
          )
          secrets[service.name.to_sym] = secret_ref
        end
        
        security_resources[:secrets] = secrets
      end
      
      security_resources
    end
    
    def create_resilience_infrastructure(name, attrs, resources, tags)
      resilience_resources = {}
      
      # Create FIS experiment templates for chaos testing
      if attrs.resilience.chaos_testing_enabled
        # Create IAM role for FIS
        fis_role_ref = aws_iam_role(
          component_resource_name(name, :fis_role),
          {
            name: "#{name}-fis-role",
            assume_role_policy: JSON.generate({
              Version: "2012-10-17",
              Statement: [{
                Effect: "Allow",
                Principal: { Service: "fis.amazonaws.com" },
                Action: "sts:AssumeRole"
              }]
            }),
            tags: tags
          }
        )
        resilience_resources[:fis_role] = fis_role_ref
        
        # Create experiment template
        experiment_ref = aws_fis_experiment_template(
          component_resource_name(name, :chaos_experiment),
          {
            description: "Service mesh chaos testing",
            role_arn: fis_role_ref.arn,
            
            stop_condition: [{
              source: "aws:cloudwatch:alarm",
              value: "arn:aws:cloudwatch:*:*:alarm:#{name}-*"
            }],
            
            action: {
              inject_latency: {
                action_id: "aws:network:disrupt-connectivity",
                description: "Inject network latency",
                parameters: {
                  duration: "PT5M",
                  scope: "SOME",
                  percentage: "50"
                },
                target: {
                  key: "Targets",
                  value: "service-instances"
                }
              }
            },
            
            target: {
              "service-instances": {
                resource_type: "aws:ecs:task",
                selection_mode: "PERCENT(25)",
                resource_tag: {
                  ServiceMesh: attrs.mesh_name
                }
              }
            },
            
            tags: tags
          }
        )
        resilience_resources[:experiment] = experiment_ref
      end
      
      resilience_resources
    end
    
    def extract_connectivity_type(attrs)
      types = []
      
      types << "Transit Gateway" if attrs.cross_region.transit_gateway_enabled
      types << "VPC Peering" if attrs.cross_region.peering_enabled
      types << "PrivateLink" if attrs.cross_region.private_link_enabled
      types << "Inter-region TLS" if attrs.cross_region.inter_region_tls_enabled
      
      types.join(", ")
    end
    
    def extract_gateway_endpoints(gateway_resources)
      return {} unless gateway_resources
      
      endpoints = {}
      
      if gateway_resources[:nlb]
        endpoints[:load_balancer] = gateway_resources[:nlb].dns_name
      end
      
      if gateway_resources[:ingress]
        endpoints[:ingress_gateway] = "ingress-gateway.mesh"
      end
      
      if gateway_resources[:egress]
        endpoints[:egress_gateway] = "egress-gateway.mesh"
      end
      
      endpoints
    end
    
    def estimate_service_mesh_cost(attrs, resources)
      cost = 0.0
      
      # App Mesh costs
      # Virtual nodes
      cost += attrs.services.length * 0.50  # $0.50 per virtual node per month
      
      # Virtual services
      cost += attrs.services.length * 0.25  # $0.25 per virtual service per month
      
      # Data processing (estimate 1TB/month across all services)
      cost += 0.005 * 1000  # $0.005 per GB
      
      # Cloud Map costs
      cost += 1.00  # Namespace
      cost += attrs.services.length * 0.50  # Service discovery registrations
      
      # Transit Gateway costs for multi-region
      if attrs.cross_region.transit_gateway_enabled && attrs.regions.length > 1
        cost += attrs.regions.length * 36  # $0.05 per hour per TGW
        cost += attrs.regions.length * (attrs.regions.length - 1) * 20  # Attachments
      end
      
      # VPC endpoints
      cost += attrs.regions.length * 2 * 7.20  # App Mesh and Cloud Map endpoints
      
      # Observability costs
      if attrs.observability.xray_enabled
        # X-Ray traces (estimate 1M traces/month)
        cost += 5.00  # First million traces
      end
      
      if attrs.observability.cloudwatch_metrics_enabled
        # Custom metrics
        cost += attrs.services.length * 5 * 0.30  # 5 metrics per service
      end
      
      if attrs.observability.access_logging_enabled
        # Log ingestion and storage
        cost += attrs.services.length * 10 * 0.50  # 10GB per service
      end
      
      # Gateway costs (if using NLB)
      if resources[:gateways] && resources[:gateways][:nlb]
        cost += 22.50  # NLB cost
      end
      
      # Certificate costs for mTLS
      if attrs.security.mtls_enabled
        cost += 400.00  # ACM Private CA
        cost += attrs.services.length * 0.75  # Certificates
      end
      
      cost.round(2)
    end
  end
end