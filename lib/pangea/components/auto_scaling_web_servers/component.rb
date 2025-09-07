# frozen_string_literal: true

require 'pangea/components/base'
require 'pangea/components/auto_scaling_web_servers/types'
require 'pangea/resources/aws'
require 'base64'

module Pangea
  module Components
    # Auto Scaling Group for web servers with CPU-based scaling and health checks
    # Creates a production-ready ASG with launch template, scaling policies, and monitoring
    def auto_scaling_web_servers(name, attributes = {})
      include Base
      include Resources::AWS
      
      # Validate and set defaults
      component_attrs = AutoScalingWebServers::AutoScalingWebServersAttributes.new(attributes)
      
      # Generate component-specific tags
      component_tag_set = component_tags('AutoScalingWebServers', name, component_attrs.tags)
      
      resources = {}
      
      # Prepare user data
      user_data_encoded = if component_attrs.user_data_base64
        component_attrs.user_data_base64
      elsif component_attrs.user_data
        Base64.strict_encode64(component_attrs.user_data)
      else
        # Default user data script for web servers
        default_user_data = <<~SCRIPT
          #!/bin/bash
          yum update -y
          yum install -y httpd
          systemctl start httpd
          systemctl enable httpd
          
          # Create a simple health check endpoint
          echo '<html><body><h1>Health Check OK</h1></body></html>' > /var/www/html/health
          
          # Configure CloudWatch agent for monitoring
          yum install -y amazon-cloudwatch-agent
          
          # Start CloudWatch agent
          systemctl start amazon-cloudwatch-agent
          systemctl enable amazon-cloudwatch-agent
          
          # Signal Auto Scaling that instance is ready
          /opt/aws/bin/cfn-signal -e $? --stack ${AWS::StackName} --resource AutoScalingGroup --region ${AWS::Region}
        SCRIPT
        Base64.strict_encode64(default_user_data)
      end
      
      # Create Launch Template
      launch_template_ref = aws_launch_template(component_resource_name(name, :launch_template), {
        name: "#{name}-launch-template",
        description: "Launch template for #{name} web servers",
        image_id: component_attrs.ami_id,
        instance_type: component_attrs.instance_type,
        key_name: component_attrs.key_name,
        vpc_security_group_ids: component_attrs.security_group_refs.map(&:id),
        user_data: user_data_encoded,
        iam_instance_profile: component_attrs.iam_instance_profile ? {
          name: component_attrs.iam_instance_profile
        } : nil,
        block_device_mappings: component_attrs.block_device_mappings.map do |bdm|
          {
            device_name: bdm.device_name,
            ebs: {
              volume_type: bdm.volume_type,
              volume_size: bdm.volume_size,
              iops: bdm.iops,
              throughput: bdm.throughput,
              encrypted: bdm.encrypted,
              delete_on_termination: bdm.delete_on_termination
            }.compact
          }
        end,
        metadata_options: component_attrs.metadata_options,
        monitoring: {
          enabled: component_attrs.monitoring.enabled
        },
        placement: component_attrs.placement_group ? {
          group_name: component_attrs.placement_group
        } : nil,
        tag_specifications: [{
          resource_type: "instance",
          tags: component_tag_set.merge({
            Name: "#{name}-web-server"
          })
        }, {
          resource_type: "volume", 
          tags: component_tag_set.merge({
            Name: "#{name}-web-server-volume"
          })
        }],
        tags: component_tag_set
      }.compact)
      
      resources[:launch_template] = launch_template_ref
      
      # Prepare ASG tags for propagation
      asg_tags_list = component_attrs.asg_tags.merge(component_tag_set).map do |key, value|
        {
          key: key.to_s,
          value: value.to_s,
          propagate_at_launch: component_attrs.propagate_at_launch
        }
      end
      
      # Create Auto Scaling Group
      asg_attrs = {
        name: "#{name}-asg",
        launch_template: {
          id: launch_template_ref.id,
          version: "$Latest"
        },
        min_size: component_attrs.min_size,
        max_size: component_attrs.max_size,
        desired_capacity: component_attrs.desired_capacity,
        default_cooldown: component_attrs.default_cooldown,
        health_check_type: component_attrs.health_check_type,
        health_check_grace_period: component_attrs.health_check_grace_period,
        vpc_zone_identifier: component_attrs.subnet_refs.map(&:id),
        availability_zones: component_attrs.availability_zones,
        target_group_arns: component_attrs.target_group_refs.map(&:arn),
        load_balancers: component_attrs.load_balancer_names,
        termination_policies: component_attrs.termination_policies,
        protect_from_scale_in: component_attrs.protect_from_scale_in,
        service_linked_role_arn: component_attrs.service_linked_role_arn,
        enabled_metrics: component_attrs.monitoring.enabled_metrics,
        tag: asg_tags_list,
        tags: component_tag_set
      }.compact
      
      # Add mixed instances policy if enabled
      if component_attrs.enable_mixed_instances && component_attrs.mixed_instances_policy
        asg_attrs[:mixed_instances_policy] = component_attrs.mixed_instances_policy
        # Remove launch_template when using mixed instances policy
        asg_attrs.delete(:launch_template)
      end
      
      # Add warm pool if enabled
      if component_attrs.enable_warm_pool && component_attrs.warm_pool_config
        asg_attrs[:warm_pool] = component_attrs.warm_pool_config
      end
      
      asg_ref = aws_autoscaling_group(component_resource_name(name, :asg), asg_attrs)
      resources[:asg] = asg_ref
      
      # Create target group attachments if target groups are provided
      attachments = {}
      component_attrs.target_group_refs.each_with_index do |tg_ref, index|
        attachment_ref = aws_autoscaling_attachment(
          component_resource_name(name, :attachment, "tg#{index}".to_sym),
          {
            autoscaling_group_name: asg_ref.name,
            alb_target_group_arn: tg_ref.arn
          }
        )
        attachments["tg#{index}".to_sym] = attachment_ref
      end
      resources[:attachments] = attachments unless attachments.empty?
      
      # Create scaling policies
      policies = {}
      alarms = {}
      
      # Default CPU scaling policy if enabled
      if component_attrs.enable_cpu_scaling
        cpu_policy_ref = aws_autoscaling_policy(component_resource_name(name, :policy, :cpu), {
          name: "#{name}-cpu-scaling-policy",
          autoscaling_group_name: asg_ref.name,
          policy_type: "TargetTrackingScaling",
          target_tracking_configuration: {
            target_value: component_attrs.cpu_target_value,
            predefined_metric_specification: {
              predefined_metric_type: "ASGAverageCPUUtilization"
            },
            scale_out_cooldown: 300,
            scale_in_cooldown: 300,
            disable_scale_in: false
          }
        })
        policies[:cpu_scaling] = cpu_policy_ref
      end
      
      # Create custom scaling policies
      component_attrs.scaling_policies.each_with_index do |policy_config, index|
        policy_name = "custom_#{index}"
        
        case policy_config.policy_type
        when "TargetTrackingScaling"
          predefined_metric = case policy_config.metric_type
          when "ASGAverageCPUUtilization"
            { predefined_metric_type: "ASGAverageCPUUtilization" }
          when "ASGAverageNetworkIn"
            { predefined_metric_type: "ASGAverageNetworkIn" }
          when "ASGAverageNetworkOut"
            { predefined_metric_type: "ASGAverageNetworkOut" }
          when "ALBRequestCountPerTarget"
            {
              predefined_metric_type: "ALBRequestCountPerTarget",
              resource_label: policy_config.target_group_arn
            }
          end
          
          policy_ref = aws_autoscaling_policy(
            component_resource_name(name, :policy, policy_name.to_sym),
            {
              name: "#{name}-#{policy_name}-policy",
              autoscaling_group_name: asg_ref.name,
              policy_type: "TargetTrackingScaling",
              target_tracking_configuration: {
                target_value: policy_config.target_value,
                predefined_metric_specification: predefined_metric,
                scale_out_cooldown: policy_config.scale_out_cooldown,
                scale_in_cooldown: policy_config.scale_in_cooldown,
                disable_scale_in: policy_config.disable_scale_in
              }.compact
            }
          )
          policies[policy_name.to_sym] = policy_ref
          
        when "StepScaling", "SimpleScaling"
          policy_attrs = {
            name: "#{name}-#{policy_name}-policy",
            autoscaling_group_name: asg_ref.name,
            policy_type: policy_config.policy_type,
            adjustment_type: policy_config.adjustment_type,
            cooldown: policy_config.scale_out_cooldown
          }
          
          if policy_config.policy_type == "StepScaling"
            policy_attrs[:step_adjustments] = policy_config.step_adjustments
            policy_attrs[:min_adjustment_magnitude] = policy_config.min_adjustment_magnitude
          else
            policy_attrs[:scaling_adjustment] = policy_config.scaling_adjustment
          end
          
          policy_ref = aws_autoscaling_policy(
            component_resource_name(name, :policy, policy_name.to_sym),
            policy_attrs.compact
          )
          policies[policy_name.to_sym] = policy_ref
        end
      end
      
      resources[:policies] = policies unless policies.empty?
      
      # Create CloudWatch alarms for monitoring
      
      # CPU Utilization alarm
      cpu_alarm = aws_cloudwatch_metric_alarm(component_resource_name(name, :alarm, :cpu_high), {
        alarm_name: "#{name}-asg-cpu-utilization-high",
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: "2",
        metric_name: "CPUUtilization",
        namespace: "AWS/EC2",
        period: "300",
        statistic: "Average",
        threshold: "80.0",
        alarm_description: "ASG CPU utilization is consistently high",
        dimensions: {
          AutoScalingGroupName: asg_ref.name
        },
        tags: component_tag_set
      })
      alarms[:cpu_high] = cpu_alarm
      
      # Instance count alarm (ensure minimum instances running)
      instance_count_alarm = aws_cloudwatch_metric_alarm(component_resource_name(name, :alarm, :instance_count), {
        alarm_name: "#{name}-asg-instance-count-low",
        comparison_operator: "LessThanThreshold",
        evaluation_periods: "2",
        metric_name: "GroupInServiceInstances",
        namespace: "AWS/AutoScaling",
        period: "300",
        statistic: "Average",
        threshold: component_attrs.min_size.to_s,
        alarm_description: "ASG has fewer instances than minimum required",
        dimensions: {
          AutoScalingGroupName: asg_ref.name
        },
        tags: component_tag_set
      })
      alarms[:instance_count] = instance_count_alarm
      
      # Network utilization alarm
      network_alarm = aws_cloudwatch_metric_alarm(component_resource_name(name, :alarm, :network_high), {
        alarm_name: "#{name}-asg-network-utilization-high",
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: "3",
        metric_name: "NetworkOut",
        namespace: "AWS/EC2",
        period: "300",
        statistic: "Average",
        threshold: "100000000", # 100MB
        alarm_description: "ASG network utilization is high",
        dimensions: {
          AutoScalingGroupName: asg_ref.name
        },
        tags: component_tag_set
      })
      alarms[:network_high] = network_alarm
      
      resources[:alarms] = alarms
      
      # Create lifecycle hooks if specified
      hooks = {}
      component_attrs.lifecycle_hooks.each_with_index do |hook_config, index|
        hook_ref = aws_autoscaling_lifecycle_hook(
          component_resource_name(name, :hook, "hook#{index}".to_sym),
          hook_config.merge({
            autoscaling_group_name: asg_ref.name
          })
        )
        hooks["hook#{index}".to_sym] = hook_ref
      end
      resources[:hooks] = hooks unless hooks.empty?
      
      # Calculate outputs
      outputs = {
        asg_name: asg_ref.name,
        asg_arn: asg_ref.arn,
        launch_template_id: launch_template_ref.id,
        launch_template_version: launch_template_ref.latest_version,
        min_size: component_attrs.min_size,
        max_size: component_attrs.max_size,
        desired_capacity: component_attrs.desired_capacity || component_attrs.min_size,
        target_group_arns: component_attrs.target_group_refs.map(&:arn),
        security_features: [
          "Encrypted EBS Volumes",
          "IMDSv2 Required",
          "Auto Scaling Policies",
          "CloudWatch Monitoring",
          ("Health Check Integration" if component_attrs.health_check_type == "ELB"),
          ("Mixed Instance Types" if component_attrs.enable_mixed_instances),
          ("Warm Pool" if component_attrs.enable_warm_pool)
        ].compact,
        availability_zones: component_attrs.subnet_refs.map { |subnet| 
          # Extract AZ from subnet - this is a simplification
          subnet.respond_to?(:availability_zone) ? subnet.availability_zone : nil
        }.compact.uniq,
        estimated_monthly_cost: (component_attrs.desired_capacity || component_attrs.min_size) * estimate_instance_cost(component_attrs.instance_type)
      }
      
      create_component_reference(
        'auto_scaling_web_servers',
        name,
        component_attrs.to_h,
        resources,
        outputs
      )
    end
    
    private
    
    def estimate_instance_cost(instance_type)
      case instance_type
      when /^t3\.nano$/
        4.0
      when /^t3\.micro$/
        8.0
      when /^t3\.small$/
        16.0
      when /^t3\.medium$/
        32.0
      when /^t3\.large$/
        64.0
      when /^c5\.large$/
        70.0
      when /^c5\.xlarge$/
        140.0
      when /^r5\.large$/
        100.0
      else
        50.0  # Default estimate
      end
    end
  end
end