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
require 'pangea/components/application_load_balancer/types'
require 'pangea/resources/aws'

module Pangea
  module Components
    # Application Load Balancer component with target groups and health checks
    # Creates a production-ready ALB with comprehensive security and monitoring features
    def application_load_balancer(name, attributes = {})
      include Base
      include Resources::AWS
      
      # Validate and set defaults
      component_attrs = ApplicationLoadBalancer::ApplicationLoadBalancerAttributes.new(attributes)
      
      # Generate component-specific tags
      component_tag_set = component_tags('ApplicationLoadBalancer', name, component_attrs.tags)
      
      # Create the Application Load Balancer
      alb_ref = aws_lb(component_resource_name(name, :alb), {
        name: "#{name}-alb",
        load_balancer_type: "application",
        scheme: component_attrs.scheme,
        ip_address_type: component_attrs.ip_address_type,
        subnets: component_attrs.subnet_refs.map(&:id),
        security_groups: component_attrs.security_group_refs.map(&:id),
        idle_timeout: component_attrs.idle_timeout,
        enable_deletion_protection: component_attrs.enable_deletion_protection,
        enable_cross_zone_load_balancing: component_attrs.enable_cross_zone_load_balancing,
        enable_http2: component_attrs.enable_http2,
        enable_waf_fail_open: component_attrs.enable_waf_fail_open,
        access_logs: component_attrs.enable_access_logs ? {
          bucket: component_attrs.access_logs_bucket || "#{name}-alb-access-logs",
          prefix: component_attrs.access_logs_prefix,
          enabled: true
        } : { enabled: false },
        tags: component_tag_set
      })
      
      resources = { alb: alb_ref }
      target_groups = {}
      listeners = {}
      
      # Create default target group if requested
      if component_attrs.create_default_target_group
        default_tg_config = ApplicationLoadBalancer::TargetGroupConfig.new({
          name: "default",
          port: component_attrs.default_target_group_port,
          protocol: component_attrs.default_target_group_protocol
        })
        
        default_tg_ref = aws_lb_target_group(component_resource_name(name, :tg, :default), {
          name: "#{name}-default-tg",
          port: default_tg_config.port,
          protocol: default_tg_config.protocol,
          vpc_id: component_attrs.vpc_ref.id,
          target_type: default_tg_config.target_type,
          deregistration_delay: default_tg_config.deregistration_delay,
          stickiness: {
            enabled: default_tg_config.stickiness_enabled,
            type: default_tg_config.protocol == "HTTP" ? "lb_cookie" : "source_ip",
            cookie_duration: default_tg_config.stickiness_duration
          }.compact,
          health_check: {
            enabled: default_tg_config.health_check.enabled,
            healthy_threshold: default_tg_config.health_check.healthy_threshold,
            unhealthy_threshold: default_tg_config.health_check.unhealthy_threshold,
            timeout: default_tg_config.health_check.timeout,
            interval: default_tg_config.health_check.interval,
            path: default_tg_config.health_check.path,
            matcher: default_tg_config.health_check.matcher,
            protocol: default_tg_config.health_check.protocol,
            port: default_tg_config.health_check.port
          },
          tags: component_tag_set
        })
        
        target_groups[:default] = default_tg_ref
        resources[:target_groups] = target_groups
      end
      
      # Create additional target groups
      component_attrs.target_groups.each do |tg_config|
        tg_ref = aws_lb_target_group(component_resource_name(name, :tg, tg_config.name.to_sym), {
          name: "#{name}-#{tg_config.name}-tg",
          port: tg_config.port,
          protocol: tg_config.protocol,
          vpc_id: component_attrs.vpc_ref.id,
          target_type: tg_config.target_type,
          deregistration_delay: tg_config.deregistration_delay,
          stickiness: {
            enabled: tg_config.stickiness_enabled,
            type: tg_config.protocol == "HTTP" ? "lb_cookie" : "source_ip",
            cookie_duration: tg_config.stickiness_duration
          }.compact,
          health_check: {
            enabled: tg_config.health_check.enabled,
            healthy_threshold: tg_config.health_check.healthy_threshold,
            unhealthy_threshold: tg_config.health_check.unhealthy_threshold,
            timeout: tg_config.health_check.timeout,
            interval: tg_config.health_check.interval,
            path: tg_config.health_check.path,
            matcher: tg_config.health_check.matcher,
            protocol: tg_config.health_check.protocol,
            port: tg_config.health_check.port
          },
          tags: component_tag_set
        })
        
        target_groups[tg_config.name.to_sym] = tg_ref
      end
      
      resources[:target_groups] = target_groups unless target_groups.empty?
      
      # Create listeners
      component_attrs.listeners.each_with_index do |listener_config, index|
        listener_name = "listener_#{listener_config.port}_#{listener_config.protocol.downcase}"
        
        # Determine default action based on configuration
        default_actions = case listener_config.default_action_type
        when "forward"
          # Forward to default target group or first available
          target_group_arn = if target_groups[:default]
            target_groups[:default].arn
          elsif target_groups.any?
            target_groups.values.first.arn
          else
            raise "No target groups available for listener #{listener_name}"
          end
          
          [{
            type: "forward",
            target_group_arn: target_group_arn
          }]
        when "redirect"
          [{
            type: "redirect",
            redirect: listener_config.redirect_config || {
              protocol: "HTTPS",
              port: "443",
              status_code: "HTTP_301"
            }
          }]
        when "fixed-response"
          [{
            type: "fixed-response",
            fixed_response: listener_config.fixed_response_config || {
              content_type: "text/plain",
              message_body: "OK",
              status_code: "200"
            }
          }]
        end
        
        listener_attrs = {
          load_balancer_arn: alb_ref.arn,
          port: listener_config.port,
          protocol: listener_config.protocol,
          default_action: default_actions,
          tags: component_tag_set
        }
        
        # Add SSL policy and certificate for HTTPS/TLS
        if listener_config.protocol.include?('S') # HTTPS or TLS
          listener_attrs[:ssl_policy] = listener_config.ssl_policy || "ELBSecurityPolicy-TLS-1-2-2017-01"
          
          if listener_config.certificate_arn
            listener_attrs[:certificate_arn] = listener_config.certificate_arn
          elsif component_attrs.certificate_arn
            listener_attrs[:certificate_arn] = component_attrs.certificate_arn
          else
            raise "Certificate ARN required for HTTPS/TLS listener on port #{listener_config.port}"
          end
        end
        
        listener_ref = aws_lb_listener(component_resource_name(name, :listener, listener_name.to_sym), listener_attrs)
        listeners[listener_name.to_sym] = listener_ref
      end
      
      resources[:listeners] = listeners unless listeners.empty?
      
      # Create automatic HTTPS redirect listener if enabled
      if component_attrs.enable_https && component_attrs.ssl_redirect
        # Check if we don't already have an HTTP listener
        has_http_listener = component_attrs.listeners.any? { |l| l.port == 80 && l.protocol == "HTTP" }
        
        unless has_http_listener
          redirect_listener_ref = aws_lb_listener(component_resource_name(name, :listener, :http_redirect), {
            load_balancer_arn: alb_ref.arn,
            port: 80,
            protocol: "HTTP",
            default_action: [{
              type: "redirect",
              redirect: {
                protocol: "HTTPS",
                port: "443",
                status_code: "HTTP_301"
              }
            }],
            tags: component_tag_set
          })
          
          listeners[:http_redirect] = redirect_listener_ref
          resources[:listeners] = listeners
        end
      end
      
      # Create CloudWatch alarms for monitoring
      alarms = {}
      
      # Target response time alarm
      response_time_alarm = aws_cloudwatch_metric_alarm(component_resource_name(name, :alarm, :response_time), {
        alarm_name: "#{name}-alb-high-response-time",
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: "2",
        metric_name: "TargetResponseTime",
        namespace: "AWS/ApplicationELB",
        period: "300",
        statistic: "Average",
        threshold: "1.0",
        alarm_description: "ALB target response time is high",
        dimensions: {
          LoadBalancer: alb_ref.arn_suffix
        },
        tags: component_tag_set
      })
      alarms[:response_time] = response_time_alarm
      
      # Unhealthy host count alarm
      unhealthy_hosts_alarm = aws_cloudwatch_metric_alarm(component_resource_name(name, :alarm, :unhealthy_hosts), {
        alarm_name: "#{name}-alb-unhealthy-hosts",
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: "2",
        metric_name: "UnHealthyHostCount",
        namespace: "AWS/ApplicationELB",
        period: "300",
        statistic: "Average",
        threshold: "0",
        alarm_description: "ALB has unhealthy targets",
        dimensions: {
          LoadBalancer: alb_ref.arn_suffix
        },
        tags: component_tag_set
      })
      alarms[:unhealthy_hosts] = unhealthy_hosts_alarm
      
      # HTTP 5xx error rate alarm
      error_rate_alarm = aws_cloudwatch_metric_alarm(component_resource_name(name, :alarm, :error_rate), {
        alarm_name: "#{name}-alb-high-error-rate",
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: "3",
        metric_name: "HTTPCode_ELB_5XX_Count",
        namespace: "AWS/ApplicationELB", 
        period: "300",
        statistic: "Sum",
        threshold: "10",
        alarm_description: "ALB 5xx error rate is high",
        dimensions: {
          LoadBalancer: alb_ref.arn_suffix
        },
        tags: component_tag_set
      })
      alarms[:error_rate] = error_rate_alarm
      
      resources[:alarms] = alarms
      
      # Calculate outputs
      outputs = {
        alb_arn: alb_ref.arn,
        alb_dns_name: alb_ref.dns_name,
        alb_zone_id: alb_ref.zone_id,
        target_group_arns: target_groups.transform_values(&:arn),
        listener_arns: listeners.transform_values(&:arn),
        security_features: [
          "HTTPS Support",
          "Health Checks",
          "Access Logging", 
          "CloudWatch Monitoring",
          ("SSL Redirect" if component_attrs.ssl_redirect),
          ("Security Headers" if component_attrs.enable_security_headers)
        ].compact,
        health_check_paths: target_groups.transform_values { |tg| 
          # Extract health check path from target group config
          component_attrs.target_groups.find { |tg_config| 
            "#{name}-#{tg_config.name}-tg" == tg.name
          }&.health_check&.path || "/health"
        },
        estimated_monthly_cost: 22.0 + (target_groups.count * 8.0) # ALB + target groups
      }
      
      create_component_reference(
        'application_load_balancer',
        name,
        component_attrs.to_h,
        resources,
        outputs
      )
    end
  end
end