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
    module MultiRegionActiveActive
      # Regional application resources (ECS, ALB, security groups)
      module Applications
        def create_regional_application(name, region_config, attrs, vpc_ref, subnets, tags)
          app, app_sg = attrs.application, create_app_security_group(name, region_config, vpc_ref, app, tags)
          alb_resources = create_alb_resources(name, region_config, attrs, app, app_sg, subnets, tags)
          ecs_resources = create_ecs_resources(name, region_config, attrs, app, app_sg, subnets, alb_resources, tags)
          { security_group: app_sg, load_balancer: alb_resources[:alb], target_group: alb_resources[:target_group],
            listener: alb_resources[:listener], ecs_cluster: ecs_resources[:cluster],
            task_definition: ecs_resources[:task_definition], ecs_service: ecs_resources[:service] }
        end

        private

        def create_app_security_group(name, region_config, vpc_ref, app, tags)
          sg = aws_security_group(component_resource_name(name, :app_sg, region_config.region.to_sym),
                                  { name: "#{name}-${region_config.region}-app-sg", vpc_id: vpc_ref.id,
                                    description: "Security group for application in #{region_config.region}",
                                    tags: tags.merge(Region: region_config.region) })
          aws_security_group_rule(component_resource_name(name, :app_sg_ingress, region_config.region.to_sym),
                                  { type: 'ingress', from_port: app.port, to_port: app.port, protocol: 'tcp',
                                    cidr_blocks: ['0.0.0.0/0'], security_group_id: sg.id })
          aws_security_group_rule(component_resource_name(name, :app_sg_egress, region_config.region.to_sym),
                                  { type: 'egress', from_port: 0, to_port: 0, protocol: '-1',
                                    cidr_blocks: ['0.0.0.0/0'], security_group_id: sg.id })
          sg
        end

        def create_alb_resources(name, region_config, attrs, app, app_sg, subnets, tags)
          public_subnets = subnets.select { |k, _| k.to_s.start_with?('public_') }.values.map(&:id)
          alb = aws_lb(component_resource_name(name, :alb, region_config.region.to_sym),
                       { name: "#{name}-#{region_config.region}-alb", internal: false, load_balancer_type: 'application',
                         security_groups: [app_sg.id], subnets: public_subnets, enable_deletion_protection: true,
                         enable_http2: true, enable_cross_zone_load_balancing: true, tags: tags.merge(Region: region_config.region) })
          tg = create_target_group(name, region_config, attrs, app, subnets, tags)
          listener_config = { load_balancer_arn: alb.arn, port: app.port, protocol: app.protocol,
                              default_action: [{ type: 'forward', target_group_arn: tg.arn }] }
          listener_config[:certificate_arn] = "arn:aws:acm:#{region_config.region}:ACCOUNT:certificate/CERT" if app.protocol == 'HTTPS'
          listener = aws_lb_listener(component_resource_name(name, :alb_listener, region_config.region.to_sym), listener_config.compact)
          { alb: alb, target_group: tg, listener: listener }
        end

        def create_target_group(name, region_config, attrs, app, subnets, tags)
          health_check = { enabled: true, healthy_threshold: 2, interval: 30, matcher: '200', path: app.health_check_path,
                           port: 'traffic-port', protocol: app.protocol == 'HTTPS' ? 'HTTP' : app.protocol,
                           timeout: 5, unhealthy_threshold: 2 }
          config = { name: "#{name}-#{region_config.region}-tg", port: app.port, vpc_id: subnets.values.first.vpc_id,
                     protocol: app.protocol == 'HTTPS' ? 'HTTP' : app.protocol, target_type: 'ip',
                     health_check: health_check, tags: tags.merge(Region: region_config.region) }
          config[:stickiness] = { enabled: true, type: 'lb_cookie', cookie_duration: attrs.traffic_routing.session_affinity_ttl } if attrs.traffic_routing.sticky_sessions
          aws_lb_target_group(component_resource_name(name, :target_group, region_config.region.to_sym), config.compact)
        end

        def create_ecs_resources(name, region_config, attrs, app, app_sg, subnets, alb_resources, tags)
          cluster = create_ecs_cluster(name, region_config, attrs, tags)
          task_def = create_task_definition(name, region_config, app, tags)
          private_subnets = subnets.select { |k, _| k.to_s.start_with?('private_') }.values.map(&:id)
          service = create_ecs_service(name, region_config, attrs, app, app_sg, private_subnets, cluster, task_def, alb_resources, tags)
          { cluster: cluster, task_definition: task_def, service: service }
        end

        def create_ecs_cluster(name, region_config, attrs, tags)
          capacity = [{ capacity_provider: 'FARGATE', weight: attrs.cost_optimization.spot_instances_enabled ? 20 : 100, base: 1 }]
          capacity << { capacity_provider: 'FARGATE_SPOT', weight: 80 } if attrs.cost_optimization.spot_instances_enabled
          aws_ecs_cluster(component_resource_name(name, :ecs_cluster, region_config.region.to_sym),
                          { name: "#{name}-#{region_config.region}-cluster", capacity_providers: %w[FARGATE FARGATE_SPOT],
                            default_capacity_provider_strategy: capacity.compact,
                            setting: [{ name: 'containerInsights', value: attrs.monitoring.enabled ? 'enabled' : 'disabled' }],
                            tags: tags.merge(Region: region_config.region) })
        end

        def create_task_definition(name, region_config, app, tags)
          container = { name: app.name, image: app.container_image || 'nginx:latest',
                        portMappings: [{ containerPort: app.port, protocol: 'tcp' }],
                        environment: [{ name: 'REGION', value: region_config.region }, { name: 'IS_PRIMARY', value: region_config.is_primary.to_s }],
                        logConfiguration: { logDriver: 'awslogs', options: { 'awslogs-group': "/ecs/#{name}-#{region_config.region}",
                                                                             'awslogs-region': region_config.region, 'awslogs-stream-prefix': 'ecs' } } }
          aws_ecs_task_definition(component_resource_name(name, :task_definition, region_config.region.to_sym),
                                  { family: "#{name}-#{region_config.region}-task", network_mode: 'awsvpc',
                                    requires_compatibilities: ['FARGATE'], cpu: app.task_cpu.to_s, memory: app.task_memory.to_s,
                                    container_definitions: JSON.generate([container]), tags: tags.merge(Region: region_config.region) })
        end

        def create_ecs_service(name, region_config, attrs, app, app_sg, subnet_ids, cluster, task_def, alb_resources, tags)
          deploy_config = { maximum_percent: 200, minimum_healthy_percent: 100 }
          deploy_config[:deployment_circuit_breaker] = { enable: true, rollback: true } if attrs.enable_circuit_breaker
          aws_ecs_service(component_resource_name(name, :ecs_service, region_config.region.to_sym),
                          { name: "#{name}-#{region_config.region}-service", cluster: cluster.id, task_definition: task_def.arn,
                            desired_count: app.desired_count, launch_type: 'FARGATE',
                            network_configuration: { awsvpc_configuration: { subnets: subnet_ids, security_groups: [app_sg.id], assign_public_ip: 'DISABLED' } },
                            load_balancer: [{ target_group_arn: alb_resources[:target_group].arn, container_name: app.name, container_port: app.port }],
                            health_check_grace_period_seconds: 60, deployment_configuration: deploy_config,
                            tags: tags.merge(Region: region_config.region) }.compact)
        end
      end
    end
  end
end
