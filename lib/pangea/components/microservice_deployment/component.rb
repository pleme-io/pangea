# frozen_string_literal: true

require 'pangea/components/base'
require 'pangea/components/microservice_deployment/types'
require 'pangea/resources/aws'

module Pangea
  module Components
    # Production-ready ECS microservice deployment with service discovery, circuit breakers, and distributed tracing
    # Creates a complete microservice deployment with health checks, auto-scaling, and resilience patterns
    def microservice_deployment(name, attributes = {})
      include Base
      include Resources::AWS
      
      # Validate and set defaults
      component_attrs = MicroserviceDeployment::MicroserviceDeploymentAttributes.new(attributes)
      component_attrs.validate!
      
      # Generate component-specific tags
      component_tag_set = component_tags('MicroserviceDeployment', name, component_attrs.tags)
      
      resources = {}
      
      # Create CloudWatch Log Group for the service
      log_group_name = component_attrs.log_group_name || "/ecs/#{component_attrs.task_definition_family}"
      log_group_ref = aws_cloudwatch_log_group(component_resource_name(name, :log_group), {
        name: log_group_name,
        retention_in_days: component_attrs.log_retention_days,
        tags: component_tag_set
      })
      resources[:log_group] = log_group_ref
      
      # Create log streams for each container
      log_streams = {}
      component_attrs.container_definitions.each do |container|
        log_stream_ref = aws_cloudwatch_log_stream(
          component_resource_name(name, :log_stream, container.name.to_sym),
          {
            name: "#{component_attrs.log_stream_prefix}/#{container.name}",
            log_group_name: log_group_ref.name
          }
        )
        log_streams[container.name.to_sym] = log_stream_ref
      end
      resources[:log_streams] = log_streams
      
      # Build container definitions with proper logging and tracing
      container_defs = component_attrs.container_definitions.map do |container|
        definition = {
          name: container.name,
          image: container.image,
          cpu: container.cpu,
          memory: container.memory,
          essential: container.essential,
          portMappings: container.port_mappings,
          environment: container.environment,
          secrets: container.secrets,
          healthCheck: container.health_check.empty? ? nil : container.health_check,
          dependsOn: container.depends_on.empty? ? nil : container.depends_on,
          ulimits: container.ulimits.empty? ? nil : container.ulimits,
          mountPoints: container.mount_points.empty? ? nil : container.mount_points,
          volumesFrom: container.volume_from.empty? ? nil : container.volume_from,
          logConfiguration: container.log_configuration.empty? ? {
            logDriver: "awslogs",
            options: {
              "awslogs-group" => log_group_ref.name,
              "awslogs-region" => "${AWS::Region}",
              "awslogs-stream-prefix" => "#{component_attrs.log_stream_prefix}/#{container.name}"
            }
          } : container.log_configuration
        }.compact
        
        # Add X-Ray sidecar if tracing is enabled
        if component_attrs.tracing.enabled && component_attrs.tracing.x_ray && container.essential
          definition[:environment] ||= []
          definition[:environment] << {
            name: "AWS_XRAY_DAEMON_ADDRESS",
            value: "localhost:2000"
          }
        end
        
        definition
      end
      
      # Add X-Ray sidecar container if enabled
      if component_attrs.tracing.enabled && component_attrs.tracing.x_ray
        container_defs << {
          name: "xray-daemon",
          image: "public.ecr.aws/xray/aws-xray-daemon:latest",
          cpu: 32,
          memory: 256,
          essential: false,
          portMappings: [{
            containerPort: 2000,
            protocol: "udp"
          }],
          logConfiguration: {
            logDriver: "awslogs",
            options: {
              "awslogs-group" => log_group_ref.name,
              "awslogs-region" => "${AWS::Region}",
              "awslogs-stream-prefix" => "#{component_attrs.log_stream_prefix}/xray"
            }
          }
        }
      end
      
      # Create ECS Task Definition
      task_def_ref = aws_ecs_task_definition(component_resource_name(name, :task_definition), {
        family: component_attrs.task_definition_family,
        network_mode: "awsvpc",
        requires_compatibilities: [component_attrs.launch_type],
        cpu: component_attrs.task_cpu,
        memory: component_attrs.task_memory,
        task_role_arn: component_attrs.task_role_arn,
        execution_role_arn: component_attrs.execution_role_arn,
        container_definitions: JSON.generate(container_defs),
        tags: component_tag_set
      }.compact)
      resources[:task_definition] = task_def_ref
      
      # Create Service Discovery Service if configured
      service_registry = nil
      if component_attrs.service_discovery
        sd_config = component_attrs.service_discovery
        
        sd_service_ref = aws_service_discovery_service(
          component_resource_name(name, :service_discovery),
          {
            name: sd_config.service_name,
            dns_config: sd_config.dns_config,
            health_check_custom_config: sd_config.health_check_custom_config,
            namespace_id: sd_config.namespace_id,
            tags: component_tag_set
          }
        )
        resources[:service_discovery] = sd_service_ref
        
        service_registry = [{
          registry_arn: sd_service_ref.arn,
          container_name: component_attrs.container_name || container_defs.find { |c| c[:essential] }[:name],
          container_port: component_attrs.container_port
        }]
      end
      
      # Configure load balancer targets
      load_balancers = component_attrs.target_group_refs.map do |tg_ref|
        {
          target_group_arn: tg_ref.arn,
          container_name: component_attrs.container_name || container_defs.find { |c| c[:essential] }[:name],
          container_port: component_attrs.container_port
        }
      end
      
      # Create ECS Service with circuit breaker and deployment configuration
      service_attrs = {
        name: "#{name}-service",
        cluster: component_attrs.cluster_ref.arn,
        task_definition: task_def_ref.arn,
        desired_count: component_attrs.desired_count,
        launch_type: component_attrs.launch_type,
        platform_version: component_attrs.platform_version,
        enable_execute_command: component_attrs.enable_execute_command,
        
        network_configuration: {
          awsvpc_configuration: {
            subnets: component_attrs.subnet_refs.map(&:id),
            security_groups: component_attrs.security_group_refs.map(&:id),
            assign_public_ip: component_attrs.assign_public_ip ? "ENABLED" : "DISABLED"
          }
        },
        
        deployment_configuration: {
          maximum_percent: component_attrs.deployment_maximum_percent,
          minimum_healthy_percent: component_attrs.deployment_minimum_healthy_percent,
          deployment_circuit_breaker: {
            enable: component_attrs.circuit_breaker.enabled,
            rollback: component_attrs.circuit_breaker.rollback
          }
        },
        
        health_check_grace_period_seconds: load_balancers.any? ? component_attrs.health_check_grace_period : nil,
        load_balancer: load_balancers.empty? ? nil : load_balancers,
        service_registries: service_registry,
        
        tags: component_tag_set
      }.compact
      
      service_ref = aws_ecs_service(component_resource_name(name, :service), service_attrs)
      resources[:service] = service_ref
      
      # Create Auto Scaling Target and Policies if enabled
      if component_attrs.auto_scaling.enabled
        # Create scalable target
        scalable_target_ref = aws_appautoscaling_target(
          component_resource_name(name, :scalable_target),
          {
            service_namespace: "ecs",
            resource_id: "service/#{component_attrs.cluster_ref.name}/#{service_ref.name}",
            scalable_dimension: "ecs:service:DesiredCount",
            min_capacity: component_attrs.auto_scaling.min_tasks,
            max_capacity: component_attrs.auto_scaling.max_tasks
          }
        )
        resources[:scalable_target] = scalable_target_ref
        
        # Create CPU scaling policy
        cpu_policy_ref = aws_appautoscaling_policy(
          component_resource_name(name, :cpu_scaling_policy),
          {
            name: "#{name}-cpu-scaling",
            service_namespace: "ecs",
            resource_id: scalable_target_ref.resource_id,
            scalable_dimension: scalable_target_ref.scalable_dimension,
            policy_type: "TargetTrackingScaling",
            target_tracking_scaling_policy_configuration: {
              target_value: component_attrs.auto_scaling.target_cpu,
              predefined_metric_specification: {
                predefined_metric_type: "ECSServiceAverageCPUUtilization"
              },
              scale_out_cooldown: component_attrs.auto_scaling.scale_out_cooldown,
              scale_in_cooldown: component_attrs.auto_scaling.scale_in_cooldown
            }
          }
        )
        resources[:cpu_scaling_policy] = cpu_policy_ref
        
        # Create Memory scaling policy
        memory_policy_ref = aws_appautoscaling_policy(
          component_resource_name(name, :memory_scaling_policy),
          {
            name: "#{name}-memory-scaling",
            service_namespace: "ecs",
            resource_id: scalable_target_ref.resource_id,
            scalable_dimension: scalable_target_ref.scalable_dimension,
            policy_type: "TargetTrackingScaling",
            target_tracking_scaling_policy_configuration: {
              target_value: component_attrs.auto_scaling.target_memory,
              predefined_metric_specification: {
                predefined_metric_type: "ECSServiceAverageMemoryUtilization"
              },
              scale_out_cooldown: component_attrs.auto_scaling.scale_out_cooldown,
              scale_in_cooldown: component_attrs.auto_scaling.scale_in_cooldown
            }
          }
        )
        resources[:memory_scaling_policy] = memory_policy_ref
      end
      
      # Create CloudWatch alarms for monitoring
      alarms = {}
      
      # Service CPU utilization alarm
      cpu_alarm_ref = aws_cloudwatch_metric_alarm(
        component_resource_name(name, :cpu_alarm),
        {
          alarm_name: "#{name}-service-cpu-high",
          comparison_operator: "GreaterThanThreshold",
          evaluation_periods: "2",
          metric_name: "CPUUtilization",
          namespace: "AWS/ECS",
          period: "300",
          statistic: "Average",
          threshold: "85.0",
          alarm_description: "Service CPU utilization is high",
          dimensions: {
            ServiceName: service_ref.name,
            ClusterName: component_attrs.cluster_ref.name
          },
          tags: component_tag_set
        }
      )
      alarms[:cpu_high] = cpu_alarm_ref
      
      # Service memory utilization alarm
      memory_alarm_ref = aws_cloudwatch_metric_alarm(
        component_resource_name(name, :memory_alarm),
        {
          alarm_name: "#{name}-service-memory-high",
          comparison_operator: "GreaterThanThreshold",
          evaluation_periods: "2",
          metric_name: "MemoryUtilization",
          namespace: "AWS/ECS",
          period: "300",
          statistic: "Average",
          threshold: "85.0",
          alarm_description: "Service memory utilization is high",
          dimensions: {
            ServiceName: service_ref.name,
            ClusterName: component_attrs.cluster_ref.name
          },
          tags: component_tag_set
        }
      )
      alarms[:memory_high] = memory_alarm_ref
      
      # Running task count alarm
      task_count_alarm_ref = aws_cloudwatch_metric_alarm(
        component_resource_name(name, :task_count_alarm),
        {
          alarm_name: "#{name}-service-tasks-low",
          comparison_operator: "LessThanThreshold",
          evaluation_periods: "2",
          metric_name: "RunningTaskCount",
          namespace: "AWS/ECS",
          period: "60",
          statistic: "Average",
          threshold: component_attrs.auto_scaling.enabled ? 
            component_attrs.auto_scaling.min_tasks.to_s : 
            component_attrs.desired_count.to_s,
          alarm_description: "Service has fewer running tasks than expected",
          dimensions: {
            ServiceName: service_ref.name,
            ClusterName: component_attrs.cluster_ref.name
          },
          tags: component_tag_set
        }
      )
      alarms[:task_count_low] = task_count_alarm_ref
      
      resources[:alarms] = alarms
      
      # Create X-Ray sampling rule if tracing is enabled
      if component_attrs.tracing.enabled && component_attrs.tracing.x_ray
        sampling_rule_ref = aws_xray_sampling_rule(
          component_resource_name(name, :xray_sampling_rule),
          {
            rule_name: "#{name}-sampling",
            priority: 9000,
            version: 1,
            reservoir_size: 1,
            fixed_rate: component_attrs.tracing.sampling_rate,
            url_path: "*",
            host: "*",
            http_method: "*",
            service_type: "*",
            service_name: component_attrs.task_definition_family,
            resource_arn: "*",
            attributes: {},
            tags: component_tag_set
          }
        )
        resources[:xray_sampling_rule] = sampling_rule_ref
      end
      
      # Calculate outputs
      outputs = {
        service_name: service_ref.name,
        service_arn: service_ref.id,
        task_definition_arn: task_def_ref.arn,
        task_definition_family: component_attrs.task_definition_family,
        cluster_name: component_attrs.cluster_ref.name,
        desired_count: component_attrs.desired_count,
        launch_type: component_attrs.launch_type,
        log_group_name: log_group_ref.name,
        
        service_discovery_endpoint: component_attrs.service_discovery ? 
          "#{component_attrs.service_discovery.service_name}.#{component_attrs.service_discovery.namespace_id}" : nil,
        
        resilience_features: [
          ("Circuit Breaker" if component_attrs.circuit_breaker.enabled),
          ("Auto Scaling" if component_attrs.auto_scaling.enabled),
          ("Health Checks" if load_balancers.any?),
          ("Service Discovery" if component_attrs.service_discovery),
          ("Distributed Tracing" if component_attrs.tracing.enabled),
          ("Blue-Green Deployment" if component_attrs.enable_blue_green)
        ].compact,
        
        monitoring_features: [
          "CloudWatch Logs",
          "CloudWatch Alarms",
          ("X-Ray Tracing" if component_attrs.tracing.x_ray),
          ("Jaeger Tracing" if component_attrs.tracing.jaeger),
          ("Zipkin Tracing" if component_attrs.tracing.zipkin)
        ].compact,
        
        estimated_monthly_cost: estimate_microservice_cost(component_attrs)
      }
      
      create_component_reference(
        'microservice_deployment',
        name,
        component_attrs.to_h,
        resources,
        outputs
      )
    end
    
    private
    
    def estimate_microservice_cost(attrs)
      cost = 0.0
      
      # ECS Fargate pricing (per vCPU per hour and per GB per hour)
      vcpu_hour_cost = 0.04048
      gb_hour_cost = 0.004445
      
      # Calculate vCPU and memory
      vcpus = attrs.task_cpu.to_f / 1024
      memory_gb = attrs.task_memory.to_f / 1024
      
      # Calculate hourly cost per task
      hourly_cost_per_task = (vcpus * vcpu_hour_cost) + (memory_gb * gb_hour_cost)
      
      # Calculate monthly cost based on desired count
      task_count = attrs.auto_scaling.enabled ? attrs.auto_scaling.min_tasks : attrs.desired_count
      monthly_hours = 730
      
      cost += hourly_cost_per_task * task_count * monthly_hours
      
      # Add CloudWatch Logs cost (estimated)
      cost += 5.0
      
      # Add Load Balancer cost if using ALB
      cost += 22.0 if attrs.target_group_refs.any?
      
      # Add Service Discovery cost if enabled
      cost += 1.0 if attrs.service_discovery
      
      # Add X-Ray cost if enabled (estimated)
      cost += 5.0 if attrs.tracing.enabled && attrs.tracing.x_ray
      
      cost.round(2)
    end
  end
end