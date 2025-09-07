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
require 'pangea/components/global_traffic_manager/types'
require 'pangea/resources/aws'
require 'json'

module Pangea
  module Components
    # Intelligent global traffic distribution with multiple routing strategies
    # Creates Global Accelerator, Route 53 policies, CloudFront, and health checks
    def global_traffic_manager(name, attributes = {})
      include Base
      include Resources::AWS
      
      # Validate and set defaults
      component_attrs = GlobalTrafficManager::GlobalTrafficManagerAttributes.new(attributes)
      component_attrs.validate!
      
      # Generate component-specific tags
      component_tag_set = component_tags('GlobalTrafficManager', name, component_attrs.tags)
      
      resources = {}
      
      # Create or reference Route 53 hosted zone
      hosted_zone_ref = component_attrs.route53_hosted_zone_ref || aws_route53_zone(
        component_resource_name(name, :hosted_zone),
        {
          name: component_attrs.domain_name,
          comment: "Hosted zone for #{component_attrs.manager_name}",
          tags: component_tag_set
        }
      )
      resources[:hosted_zone] = hosted_zone_ref
      
      # Create Global Accelerator if enabled
      if component_attrs.enable_global_accelerator
        ga_resources = create_global_accelerator(name, component_attrs, component_tag_set)
        resources[:global_accelerator] = ga_resources
      end
      
      # Create CloudFront distribution if enabled
      if component_attrs.cloudfront.enabled
        cf_resources = create_cloudfront_distribution(name, component_attrs, component_tag_set)
        resources[:cloudfront] = cf_resources
      end
      
      # Create health checks for each endpoint
      health_checks = {}
      component_attrs.endpoints.each do |endpoint|
        if endpoint.health_check_enabled
          health_check_ref = create_endpoint_health_check(name, endpoint, component_attrs, component_tag_set)
          health_checks[endpoint.region.to_sym] = health_check_ref
        end
      end
      resources[:health_checks] = health_checks
      
      # Create Route 53 traffic policies if enabled
      if component_attrs.enable_route53_policies
        traffic_policy_resources = create_route53_traffic_policies(
          name, component_attrs, hosted_zone_ref, health_checks, component_tag_set
        )
        resources[:traffic_policies] = traffic_policy_resources
      end
      
      # Create geo-routing rules if enabled
      if component_attrs.geo_routing.enabled
        geo_routing_resources = create_geo_routing(
          name, component_attrs, hosted_zone_ref, health_checks, component_tag_set
        )
        resources[:geo_routing] = geo_routing_resources
      end
      
      # Create monitoring and alerting resources
      if component_attrs.observability.cloudwatch_enabled
        monitoring_resources = create_monitoring_stack(name, component_attrs, resources, component_tag_set)
        resources[:monitoring] = monitoring_resources
      end
      
      # Create security resources if configured
      if component_attrs.security.waf_enabled || component_attrs.security.ddos_protection
        security_resources = create_security_resources(name, component_attrs, resources, component_tag_set)
        resources[:security] = security_resources
      end
      
      # Create synthetic monitoring if configured
      if component_attrs.observability.synthetic_checks.any?
        synthetic_resources = create_synthetic_monitoring(name, component_attrs, component_tag_set)
        resources[:synthetic_monitoring] = synthetic_resources
      end
      
      # Create advanced routing features
      if component_attrs.advanced_routing.canary_deployment.any? || 
         component_attrs.advanced_routing.blue_green_deployment.any?
        advanced_routing_resources = create_advanced_routing(
          name, component_attrs, resources, component_tag_set
        )
        resources[:advanced_routing] = advanced_routing_resources
      end
      
      # Calculate outputs
      outputs = {
        manager_name: component_attrs.manager_name,
        domain_name: component_attrs.domain_name,
        hosted_zone_id: hosted_zone_ref.zone_id,
        
        endpoints: component_attrs.endpoints.map { |e| 
          {
            region: e.region,
            endpoint_id: e.endpoint_id,
            weight: e.weight,
            enabled: e.enabled
          }
        },
        
        global_accelerator_dns: resources.dig(:global_accelerator, :accelerator)&.dns_name,
        global_accelerator_ips: extract_global_accelerator_ips(resources[:global_accelerator]),
        
        cloudfront_distribution_id: resources.dig(:cloudfront, :distribution)&.id,
        cloudfront_domain_name: resources.dig(:cloudfront, :distribution)&.domain_name,
        
        routing_strategies: extract_routing_strategies(component_attrs),
        
        health_check_status: health_checks.transform_values { |hc| "Configured" },
        
        security_features: [
          ("DDoS Protection" if component_attrs.security.ddos_protection),
          ("WAF Enabled" if component_attrs.security.waf_enabled),
          ("Geo-blocking" if component_attrs.security.blocked_countries.any?),
          ("Rate Limiting" if component_attrs.security.rate_limiting.any?),
          ("IP Allowlist" if component_attrs.security.ip_allowlist.any?)
        ].compact,
        
        observability_features: [
          ("CloudWatch Metrics" if component_attrs.observability.cloudwatch_enabled),
          ("Flow Logs" if component_attrs.performance.flow_logs_enabled),
          ("Access Logs" if component_attrs.observability.access_logs_enabled),
          ("Distributed Tracing" if component_attrs.observability.distributed_tracing),
          ("Synthetic Monitoring" if component_attrs.observability.synthetic_checks.any?),
          ("Real User Monitoring" if component_attrs.observability.real_user_monitoring)
        ].compact,
        
        performance_optimizations: [
          ("TCP Optimization" if component_attrs.performance.tcp_optimization),
          ("Origin Shield" if component_attrs.cloudfront.origin_shield_enabled),
          ("Compression" if component_attrs.cloudfront.compress),
          ("Multi-CDN" if component_attrs.enable_multi_cdn)
        ].compact,
        
        estimated_monthly_cost: estimate_traffic_manager_cost(component_attrs, resources)
      }
      
      create_component_reference(
        'global_traffic_manager',
        name,
        component_attrs.to_h,
        resources,
        outputs
      )
    end
    
    private
    
    def create_global_accelerator(name, attrs, tags)
      ga_resources = {}
      
      # Create Global Accelerator
      accelerator_ref = aws_globalaccelerator_accelerator(
        component_resource_name(name, :accelerator),
        {
          name: "#{name}-global-accelerator",
          ip_address_type: "IPV4",
          enabled: true,
          attributes: attrs.global_accelerator_attributes.merge({
            flow_logs_enabled: attrs.performance.flow_logs_enabled,
            flow_logs_s3_bucket: attrs.performance.flow_logs_s3_bucket,
            flow_logs_s3_prefix: "#{attrs.performance.flow_logs_s3_prefix}global-accelerator/"
          }).compact,
          tags: tags
        }
      )
      ga_resources[:accelerator] = accelerator_ref
      
      # Create listeners based on endpoint configuration
      listener_configs = extract_listener_configs(attrs.endpoints)
      
      listener_configs.each do |config|
        listener_ref = aws_globalaccelerator_listener(
          component_resource_name(name, :ga_listener, config[:protocol].downcase.to_sym),
          {
            accelerator_arn: accelerator_ref.arn,
            client_affinity: attrs.advanced_routing.weighted_distribution.any? ? "SOURCE_IP" : "NONE",
            protocol: config[:protocol],
            port_ranges: config[:port_ranges]
          }
        )
        ga_resources["listener_#{config[:protocol].downcase}".to_sym] = listener_ref
        
        # Create endpoint groups for each region
        attrs.endpoints.group_by(&:region).each do |region, region_endpoints|
          endpoint_group_ref = aws_globalaccelerator_endpoint_group(
            component_resource_name(name, :ga_endpoint_group, "#{config[:protocol].downcase}_#{region}".to_sym),
            {
              listener_arn: listener_ref.arn,
              endpoint_group_region: region,
              traffic_dial_percentage: attrs.advanced_routing.traffic_dials[region] || 100.0,
              health_check_interval_seconds: 30,
              health_check_path: attrs.traffic_policies.first&.health_check_path || "/health",
              health_check_port: config[:port_ranges].first[:from_port],
              health_check_protocol: config[:protocol],
              threshold_count: 3,
              
              endpoint_configuration: region_endpoints.map do |endpoint|
                {
                  endpoint_id: endpoint.endpoint_id,
                  weight: endpoint.weight,
                  client_ip_preservation_enabled: endpoint.client_ip_preservation
                }
              end
            }
          )
          ga_resources["endpoint_group_#{config[:protocol].downcase}_#{region}".to_sym] = endpoint_group_ref
        end
      end
      
      ga_resources
    end
    
    def create_cloudfront_distribution(name, attrs, tags)
      cf_resources = {}
      
      # Create CloudFront origin access identity
      oai_ref = aws_cloudfront_origin_access_identity(
        component_resource_name(name, :cf_oai),
        {
          comment: "OAI for #{attrs.manager_name}"
        }
      )
      cf_resources[:oai] = oai_ref
      
      # Create CloudFront distribution
      distribution_ref = aws_cloudfront_distribution(
        component_resource_name(name, :cf_distribution),
        {
          comment: attrs.manager_description,
          enabled: true,
          is_ipv6_enabled: true,
          price_class: attrs.cloudfront.price_class,
          
          aliases: [attrs.domain_name],
          
          viewer_certificate: attrs.certificate_arn ? {
            acm_certificate_arn: attrs.certificate_arn,
            ssl_support_method: "sni-only",
            minimum_protocol_version: "TLSv1.2_2021"
          } : {
            cloudfront_default_certificate: true
          },
          
          origin: attrs.endpoints.map do |endpoint|
            {
              domain_name: endpoint.endpoint_id,
              origin_id: "origin-#{endpoint.region}",
              
              custom_origin_config: {
                http_port: 80,
                https_port: 443,
                origin_protocol_policy: "https-only",
                origin_ssl_protocols: ["TLSv1.2"],
                origin_keepalive_timeout: attrs.performance.idle_timeout,
                origin_read_timeout: 30
              },
              
              origin_shield: attrs.cloudfront.origin_shield_enabled ? {
                enabled: true,
                origin_shield_region: attrs.cloudfront.origin_shield_region || endpoint.region
              } : nil,
              
              custom_header: attrs.advanced_routing.custom_headers.map do |header|
                {
                  name: header[:name],
                  value: header[:value]
                }
              end
            }.compact
          end,
          
          default_cache_behavior: {
            target_origin_id: "origin-#{attrs.endpoints.first.region}",
            viewer_protocol_policy: attrs.cloudfront.viewer_protocol_policy,
            
            allowed_methods: ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"],
            cached_methods: ["GET", "HEAD", "OPTIONS"],
            
            forwarded_values: {
              query_string: true,
              headers: ["*"],
              cookies: {
                forward: "all"
              }
            },
            
            compress: attrs.cloudfront.compress,
            
            min_ttl: 0,
            default_ttl: 86400,
            max_ttl: 31536000,
            
            lambda_function_association: create_edge_functions(name, attrs, tags)
          },
          
          ordered_cache_behavior: attrs.cloudfront.cache_behaviors.map do |behavior|
            {
              path_pattern: behavior[:path_pattern],
              target_origin_id: behavior[:origin_id] || "origin-#{attrs.endpoints.first.region}",
              viewer_protocol_policy: behavior[:viewer_protocol_policy] || attrs.cloudfront.viewer_protocol_policy,
              
              allowed_methods: behavior[:allowed_methods] || ["GET", "HEAD"],
              cached_methods: behavior[:cached_methods] || ["GET", "HEAD"],
              
              forwarded_values: {
                query_string: behavior[:forward_query_string] || false,
                headers: behavior[:forward_headers] || [],
                cookies: {
                  forward: behavior[:forward_cookies] || "none"
                }
              },
              
              min_ttl: behavior[:min_ttl] || 0,
              default_ttl: behavior[:default_ttl] || 300,
              max_ttl: behavior[:max_ttl] || 86400,
              
              compress: behavior[:compress] || attrs.cloudfront.compress
            }
          end,
          
          restrictions: {
            geo_restriction: {
              restriction_type: attrs.security.blocked_countries.any? ? "blacklist" : "none",
              locations: attrs.security.blocked_countries
            }
          },
          
          web_acl_id: attrs.security.waf_acl_ref&.arn,
          
          logging_config: attrs.observability.access_logs_enabled ? {
            bucket: "#{attrs.performance.flow_logs_s3_bucket}.s3.amazonaws.com",
            prefix: "#{attrs.performance.flow_logs_s3_prefix}cloudfront/",
            include_cookies: true
          } : nil,
          
          custom_error_response: attrs.cloudfront.custom_error_responses.map do |error_response|
            {
              error_code: error_response[:error_code],
              response_code: error_response[:response_code],
              response_page_path: error_response[:response_page_path],
              error_caching_min_ttl: error_response[:caching_min_ttl] || 300
            }
          end,
          
          tags: tags
        }.compact
      )
      cf_resources[:distribution] = distribution_ref
      
      cf_resources
    end
    
    def create_endpoint_health_check(name, endpoint, attrs, tags)
      policy = attrs.traffic_policies.find { |p| p.policy_name == attrs.default_policy } || 
               attrs.traffic_policies.first ||
               GlobalTrafficManager::TrafficPolicyConfig.new({ policy_name: 'default' })
      
      aws_route53_health_check(
        component_resource_name(name, :health_check, endpoint.region.to_sym),
        {
          fqdn: endpoint.endpoint_id,
          port: 443,
          type: policy.health_check_protocol == 'TCP' ? 'TCP' : policy.health_check_protocol,
          resource_path: policy.health_check_protocol != 'TCP' ? policy.health_check_path : nil,
          failure_threshold: policy.unhealthy_threshold.to_s,
          request_interval: policy.health_check_interval.to_s,
          measure_latency: true,
          tags: tags.merge(
            Region: endpoint.region,
            EndpointType: endpoint.endpoint_type
          )
        }.compact
      )
    end
    
    def create_route53_traffic_policies(name, attrs, hosted_zone, health_checks, tags)
      policy_resources = {}
      
      # Create traffic policy based on default policy type
      case attrs.default_policy
      when 'latency'
        attrs.endpoints.each do |endpoint|
          next unless endpoint.enabled
          
          record_ref = aws_route53_record(
            component_resource_name(name, :route53_latency, endpoint.region.to_sym),
            {
              zone_id: hosted_zone.zone_id,
              name: attrs.domain_name,
              type: "A",
              set_identifier: "#{endpoint.region}-latency",
              
              alias: {
                name: endpoint.endpoint_id,
                zone_id: get_endpoint_zone_id(endpoint),
                evaluate_target_health: false
              },
              
              latency_routing_policy: {
                region: endpoint.region
              },
              
              health_check_id: health_checks[endpoint.region.to_sym]&.id
            }.compact
          )
          policy_resources["latency_#{endpoint.region}".to_sym] = record_ref
        end
        
      when 'weighted'
        total_weight = attrs.endpoints.select(&:enabled).sum(&:weight)
        
        attrs.endpoints.each do |endpoint|
          next unless endpoint.enabled
          
          record_ref = aws_route53_record(
            component_resource_name(name, :route53_weighted, endpoint.region.to_sym),
            {
              zone_id: hosted_zone.zone_id,
              name: attrs.domain_name,
              type: "A",
              set_identifier: "#{endpoint.region}-weighted",
              
              alias: {
                name: endpoint.endpoint_id,
                zone_id: get_endpoint_zone_id(endpoint),
                evaluate_target_health: false
              },
              
              weighted_routing_policy: {
                weight: endpoint.weight
              },
              
              health_check_id: health_checks[endpoint.region.to_sym]&.id
            }.compact
          )
          policy_resources["weighted_#{endpoint.region}".to_sym] = record_ref
        end
        
      when 'geoproximity'
        # Create geoproximity routing policy
        attrs.endpoints.each do |endpoint|
          next unless endpoint.enabled
          
          bias = attrs.geo_routing.bias_adjustments[endpoint.region] || 0
          
          record_ref = aws_route53_record(
            component_resource_name(name, :route53_geoprox, endpoint.region.to_sym),
            {
              zone_id: hosted_zone.zone_id,
              name: attrs.domain_name,
              type: "A",
              set_identifier: "#{endpoint.region}-geoproximity",
              
              alias: {
                name: endpoint.endpoint_id,
                zone_id: get_endpoint_zone_id(endpoint),
                evaluate_target_health: false
              },
              
              geoproximity_routing_policy: {
                aws_region: endpoint.region,
                bias: bias
              },
              
              health_check_id: health_checks[endpoint.region.to_sym]&.id
            }.compact
          )
          policy_resources["geoprox_#{endpoint.region}".to_sym] = record_ref
        end
      end
      
      policy_resources
    end
    
    def create_geo_routing(name, attrs, hosted_zone, health_checks, tags)
      geo_resources = {}
      
      # Create geo-location routing records
      attrs.geo_routing.location_rules.each_with_index do |rule, index|
        endpoint = attrs.endpoints.find { |e| e.region == rule[:endpoint_region] }
        next unless endpoint
        
        record_ref = aws_route53_record(
          component_resource_name(name, :route53_geo, "rule#{index}".to_sym),
          {
            zone_id: hosted_zone.zone_id,
            name: attrs.domain_name,
            type: "A",
            set_identifier: "geo-#{rule[:location]}-#{index}",
            
            alias: {
              name: endpoint.endpoint_id,
              zone_id: get_endpoint_zone_id(endpoint),
              evaluate_target_health: false
            },
            
            geolocation_routing_policy: parse_geolocation(rule[:location]),
            
            health_check_id: health_checks[endpoint.region.to_sym]&.id
          }.compact
        )
        geo_resources["geo_rule_#{index}".to_sym] = record_ref
      end
      
      # Create default geo record
      default_endpoint = attrs.endpoints.find { |e| e.priority == attrs.endpoints.map(&:priority).max }
      if default_endpoint
        default_record_ref = aws_route53_record(
          component_resource_name(name, :route53_geo_default),
          {
            zone_id: hosted_zone.zone_id,
            name: attrs.domain_name,
            type: "A",
            set_identifier: "geo-default",
            
            alias: {
              name: default_endpoint.endpoint_id,
              zone_id: get_endpoint_zone_id(default_endpoint),
              evaluate_target_health: false
            },
            
            geolocation_routing_policy: {
              country_code: "*"
            },
            
            health_check_id: health_checks[default_endpoint.region.to_sym]&.id
          }.compact
        )
        geo_resources[:geo_default] = default_record_ref
      end
      
      geo_resources
    end
    
    def create_monitoring_stack(name, attrs, resources, tags)
      monitoring_resources = {}
      
      # Create CloudWatch dashboard
      dashboard_widgets = []
      
      # Global Accelerator metrics widget
      if attrs.enable_global_accelerator
        dashboard_widgets << {
          type: "metric",
          x: 0,
          y: 0,
          width: 12,
          height: 6,
          properties: {
            title: "Global Accelerator Traffic",
            metrics: [
              ["AWS/GlobalAccelerator", "NewFlowCount", { AcceleratorArn: resources[:global_accelerator][:accelerator].arn }],
              [".", "ProcessedBytesIn", { AcceleratorArn: resources[:global_accelerator][:accelerator].arn }],
              [".", "ProcessedBytesOut", { AcceleratorArn: resources[:global_accelerator][:accelerator].arn }]
            ],
            period: 300,
            stat: "Sum",
            region: "us-west-2",
            yAxis: { left: { label: "Count/Bytes" } }
          }
        }
      end
      
      # CloudFront metrics widget
      if attrs.cloudfront.enabled
        dashboard_widgets << {
          type: "metric",
          x: 12,
          y: 0,
          width: 12,
          height: 6,
          properties: {
            title: "CloudFront Performance",
            metrics: [
              ["AWS/CloudFront", "Requests", { DistributionId: resources[:cloudfront][:distribution].id }],
              [".", "BytesDownloaded", { DistributionId: resources[:cloudfront][:distribution].id }],
              [".", "OriginLatency", { DistributionId: resources[:cloudfront][:distribution].id }, { stat: "Average" }]
            ],
            period: 300,
            stat: "Sum",
            region: "us-east-1"
          }
        }
      end
      
      # Endpoint health status widget
      dashboard_widgets << {
        type: "metric",
        x: 0,
        y: 6,
        width: 24,
        height: 6,
        properties: {
          title: "Endpoint Health Status",
          metrics: attrs.endpoints.map do |endpoint|
            health_check = resources[:health_checks][endpoint.region.to_sym]
            next unless health_check
            
            ["AWS/Route53", "HealthCheckStatus", { HealthCheckId: health_check.id }]
          end.compact,
          period: 60,
          stat: "Average",
          region: "us-east-1",
          yAxis: { left: { min: 0, max: 1 } },
          annotations: {
            horizontal: [
              { label: "Healthy", value: 1, fill: "above" },
              { label: "Unhealthy", value: 0, fill: "below" }
            ]
          }
        }
      }
      
      # Traffic distribution by region
      dashboard_widgets << {
        type: "metric",
        x: 0,
        y: 12,
        width: 12,
        height: 6,
        properties: {
          title: "Traffic Distribution by Region",
          metrics: [],
          period: 300,
          stat: "Sum",
          region: "us-east-1",
          stacked: true
        }
      }
      
      dashboard_ref = aws_cloudwatch_dashboard(
        component_resource_name(name, :dashboard),
        {
          dashboard_name: "#{name}-global-traffic",
          dashboard_body: JSON.generate({
            widgets: dashboard_widgets,
            periodOverride: "auto",
            start: "-PT6H"
          })
        }
      )
      monitoring_resources[:dashboard] = dashboard_ref
      
      # Create alarms if enabled
      if attrs.observability.alerting_enabled
        # Global Accelerator flow count alarm
        if attrs.enable_global_accelerator
          ga_alarm_ref = aws_cloudwatch_metric_alarm(
            component_resource_name(name, :alarm_ga_flows),
            {
              alarm_name: "#{name}-ga-high-flow-count",
              comparison_operator: "GreaterThanThreshold",
              evaluation_periods: "2",
              metric_name: "NewFlowCount",
              namespace: "AWS/GlobalAccelerator",
              period: "300",
              statistic: "Sum",
              threshold: "10000",
              alarm_description: "High number of new flows to Global Accelerator",
              dimensions: {
                AcceleratorArn: resources[:global_accelerator][:accelerator].arn
              },
              alarm_actions: attrs.observability.notification_topic_ref ? [attrs.observability.notification_topic_ref.arn] : nil,
              tags: tags
            }.compact
          )
          monitoring_resources[:ga_alarm] = ga_alarm_ref
        end
        
        # Endpoint health alarms
        attrs.endpoints.each do |endpoint|
          health_check = resources[:health_checks][endpoint.region.to_sym]
          next unless health_check
          
          health_alarm_ref = aws_cloudwatch_metric_alarm(
            component_resource_name(name, :alarm_health, endpoint.region.to_sym),
            {
              alarm_name: "#{name}-#{endpoint.region}-unhealthy",
              comparison_operator: "LessThanThreshold",
              evaluation_periods: "2",
              metric_name: "HealthCheckStatus",
              namespace: "AWS/Route53",
              period: "60",
              statistic: "Minimum",
              threshold: "1",
              alarm_description: "Endpoint unhealthy in #{endpoint.region}",
              dimensions: {
                HealthCheckId: health_check.id
              },
              alarm_actions: attrs.observability.notification_topic_ref ? [attrs.observability.notification_topic_ref.arn] : nil,
              tags: tags.merge(Region: endpoint.region)
            }.compact
          )
          monitoring_resources["health_alarm_#{endpoint.region}".to_sym] = health_alarm_ref
        end
      end
      
      monitoring_resources
    end
    
    def create_security_resources(name, attrs, resources, tags)
      security_resources = {}
      
      # Create Shield Advanced protection if DDoS protection enabled
      if attrs.security.ddos_protection
        if attrs.enable_global_accelerator
          shield_ga_ref = aws_shield_protection(
            component_resource_name(name, :shield_ga),
            {
              name: "#{name}-ga-shield",
              resource_arn: resources[:global_accelerator][:accelerator].arn,
              tags: tags
            }
          )
          security_resources[:shield_ga] = shield_ga_ref
        end
        
        if attrs.cloudfront.enabled
          shield_cf_ref = aws_shield_protection(
            component_resource_name(name, :shield_cf),
            {
              name: "#{name}-cf-shield",
              resource_arn: resources[:cloudfront][:distribution].arn,
              tags: tags
            }
          )
          security_resources[:shield_cf] = shield_cf_ref
        end
      end
      
      # Create WAF rules if not using existing ACL
      if attrs.security.waf_enabled && !attrs.security.waf_acl_ref
        waf_resources = create_waf_rules(name, attrs, tags)
        security_resources[:waf] = waf_resources
      end
      
      security_resources
    end
    
    def create_synthetic_monitoring(name, attrs, tags)
      synthetic_resources = {}
      
      attrs.observability.synthetic_checks.each_with_index do |check, index|
        canary_ref = aws_synthetics_canary(
          component_resource_name(name, :canary, "check#{index}".to_sym),
          {
            name: "#{name}-synthetic-#{index}",
            artifact_s3_location: "s3://#{attrs.performance.flow_logs_s3_bucket}/synthetics/",
            execution_role_arn: "arn:aws:iam::ACCOUNT:role/CloudWatchSyntheticsRole",
            handler: check[:handler] || "pageLoadBlueprint.handler",
            runtime_version: check[:runtime] || "syn-nodejs-puppeteer-3.5",
            
            schedule: {
              expression: check[:schedule] || "rate(5 minutes)"
            },
            
            run_config: {
              timeout_in_seconds: check[:timeout] || 60,
              memory_in_mb: check[:memory] || 960,
              active_tracing: attrs.observability.distributed_tracing
            },
            
            success_retention_period_in_days: 31,
            failure_retention_period_in_days: 31,
            
            tags: tags.merge(CheckType: check[:type] || "availability")
          }
        )
        synthetic_resources["canary_#{index}".to_sym] = canary_ref
      end
      
      synthetic_resources
    end
    
    def create_advanced_routing(name, attrs, resources, tags)
      routing_resources = {}
      
      # Create canary deployment resources
      if attrs.advanced_routing.canary_deployment.any?
        canary_config = attrs.advanced_routing.canary_deployment
        
        # Create Lambda@Edge function for canary routing
        canary_lambda_ref = aws_lambda_function(
          component_resource_name(name, :canary_router),
          {
            function_name: "#{name}-canary-router",
            role: "arn:aws:iam::ACCOUNT:role/LambdaEdgeRole",
            handler: "index.handler",
            runtime: "nodejs18.x",
            timeout: 5,
            memory_size: 128,
            
            environment: {
              variables: {
                CANARY_PERCENTAGE: canary_config[:percentage].to_s,
                CANARY_ENDPOINT: canary_config[:endpoint],
                STABLE_ENDPOINT: canary_config[:stable_endpoint]
              }
            },
            
            code: {
              zip_file: generate_canary_router_code(canary_config)
            },
            
            tags: tags
          }
        )
        routing_resources[:canary_lambda] = canary_lambda_ref
      end
      
      # Create blue-green deployment resources
      if attrs.advanced_routing.blue_green_deployment.any?
        bg_config = attrs.advanced_routing.blue_green_deployment
        
        # Create weighted routing for blue-green
        ['blue', 'green'].each do |color|
          endpoint = attrs.endpoints.find { |e| e.metadata[:deployment] == color }
          next unless endpoint
          
          bg_record_ref = aws_route53_record(
            component_resource_name(name, :bg_record, color.to_sym),
            {
              zone_id: resources[:hosted_zone].zone_id,
              name: "#{color}.#{attrs.domain_name}",
              type: "A",
              ttl: "60",
              records: [endpoint.endpoint_id],
              
              weighted_routing_policy: {
                weight: bg_config["#{color}_weight".to_sym] || 0
              },
              
              set_identifier: "bg-#{color}"
            }
          )
          routing_resources["bg_#{color}".to_sym] = bg_record_ref
        end
      end
      
      routing_resources
    end
    
    def create_waf_rules(name, attrs, tags)
      waf_resources = {}
      
      # Create IP set for allowlist
      if attrs.security.ip_allowlist.any?
        ip_set_ref = aws_wafv2_ip_set(
          component_resource_name(name, :waf_ip_allowlist),
          {
            name: "#{name}-ip-allowlist",
            scope: "CLOUDFRONT",
            ip_address_version: "IPV4",
            addresses: attrs.security.ip_allowlist,
            tags: tags
          }
        )
        waf_resources[:ip_allowlist] = ip_set_ref
      end
      
      # Create rate limit rule
      if attrs.security.rate_limiting.any?
        rate_limit_rule = {
          name: "RateLimitRule",
          priority: 1,
          statement: {
            rate_based_statement: {
              limit: attrs.security.rate_limiting[:limit] || 2000,
              aggregate_key_type: attrs.security.rate_limiting[:key_type] || "IP"
            }
          },
          action: {
            block: {}
          },
          visibility_config: {
            sampled_requests_enabled: true,
            cloudwatch_metrics_enabled: true,
            metric_name: "RateLimitRule"
          }
        }
      end
      
      # Create Web ACL
      web_acl_ref = aws_wafv2_web_acl(
        component_resource_name(name, :waf_acl),
        {
          name: "#{name}-web-acl",
          scope: "CLOUDFRONT",
          
          default_action: {
            allow: {}
          },
          
          rule: [
            rate_limit_rule,
            attrs.security.ip_allowlist.any? ? {
              name: "IPAllowlistRule",
              priority: 0,
              statement: {
                ip_set_reference_statement: {
                  arn: waf_resources[:ip_allowlist].arn
                }
              },
              action: {
                allow: {}
              },
              visibility_config: {
                sampled_requests_enabled: true,
                cloudwatch_metrics_enabled: true,
                metric_name: "IPAllowlistRule"
              }
            } : nil
          ].compact,
          
          visibility_config: {
            cloudwatch_metrics_enabled: true,
            metric_name: "#{name}-waf-metrics",
            sampled_requests_enabled: true
          },
          
          tags: tags
        }
      )
      waf_resources[:web_acl] = web_acl_ref
      
      waf_resources
    end
    
    def create_edge_functions(name, attrs, tags)
      edge_functions = []
      
      # Add security headers function
      if attrs.security.ddos_protection || attrs.security.waf_enabled
        security_headers_function = {
          event_type: "origin-response",
          lambda_arn: "arn:aws:lambda:us-east-1:ACCOUNT:function:security-headers:1"
        }
        edge_functions << security_headers_function
      end
      
      # Add request routing function for advanced routing
      if attrs.advanced_routing.request_routing_rules.any?
        request_router_function = {
          event_type: "viewer-request",
          lambda_arn: "arn:aws:lambda:us-east-1:ACCOUNT:function:request-router:1"
        }
        edge_functions << request_router_function
      end
      
      edge_functions
    end
    
    def extract_listener_configs(endpoints)
      configs = []
      
      # Group by common protocols and ports
      endpoints.group_by { |e| [e.endpoint_type, e.metadata[:port] || 443] }.each do |(type, port), _|
        protocol = port == 443 ? "TCP" : "TCP"
        configs << {
          protocol: protocol,
          port_ranges: [{
            from_port: port,
            to_port: port
          }]
        }
      end
      
      configs.uniq
    end
    
    def get_endpoint_zone_id(endpoint)
      # Return appropriate zone ID based on endpoint type and region
      case endpoint.endpoint_type
      when 'ALB'
        # ALB zone IDs by region
        alb_zone_ids = {
          'us-east-1' => 'Z35SXDOTRQ7X7K',
          'us-west-2' => 'Z1H1FL5HABSF5',
          'eu-west-1' => 'Z32O12XQLNTSW2',
          'ap-southeast-1' => 'Z1LMS91P8CMLE5'
        }
        alb_zone_ids[endpoint.region] || 'Z35SXDOTRQ7X7K'
      when 'NLB'
        # NLB zone IDs by region
        'Z26RNL4JYFTOTI'
      else
        # Default
        'Z35SXDOTRQ7X7K'
      end
    end
    
    def parse_geolocation(location)
      if location.length == 2
        # Country code
        { country_code: location }
      elsif location.start_with?('US-')
        # US state
        { country_code: 'US', subdivision_code: location.split('-')[1] }
      else
        # Continent
        { continent_code: location }
      end
    end
    
    def generate_canary_router_code(config)
      <<~JS
        exports.handler = async (event) => {
          const request = event.Records[0].cf.request;
          const canaryPercentage = parseInt(process.env.CANARY_PERCENTAGE);
          const random = Math.random() * 100;
          
          if (random < canaryPercentage) {
            request.origin = {
              custom: {
                domainName: process.env.CANARY_ENDPOINT,
                port: 443,
                protocol: 'https'
              }
            };
            request.headers['x-deployment-version'] = [{ key: 'X-Deployment-Version', value: 'canary' }];
          } else {
            request.headers['x-deployment-version'] = [{ key: 'X-Deployment-Version', value: 'stable' }];
          }
          
          return request;
        };
      JS
    end
    
    def extract_global_accelerator_ips(ga_resources)
      return [] unless ga_resources&.dig(:accelerator)
      
      # In real implementation, would extract from accelerator.ip_sets
      # For now, return placeholder
      ["192.0.2.1", "192.0.2.2"]
    end
    
    def extract_routing_strategies(attrs)
      strategies = []
      
      strategies << attrs.default_policy.capitalize
      strategies << "Geo-routing" if attrs.geo_routing.enabled
      strategies << "Canary Deployment" if attrs.advanced_routing.canary_deployment.any?
      strategies << "Blue-Green" if attrs.advanced_routing.blue_green_deployment.any?
      strategies << "Weighted Distribution" if attrs.advanced_routing.weighted_distribution.any?
      
      strategies
    end
    
    def estimate_traffic_manager_cost(attrs, resources)
      cost = 0.0
      
      # Global Accelerator costs
      if attrs.enable_global_accelerator
        cost += 0.025 * 24 * 30  # $0.025 per hour
        
        # Data processing costs (estimate 1TB/month)
        cost += 0.015 * 1000
      end
      
      # CloudFront costs
      if attrs.cloudfront.enabled
        # Distribution cost included in data transfer
        # Data transfer costs (estimate 5TB/month)
        case attrs.cloudfront.price_class
        when 'PriceClass_All'
          cost += 0.085 * 5000  # Average global rate
        when 'PriceClass_200'
          cost += 0.080 * 5000
        when 'PriceClass_100'
          cost += 0.075 * 5000
        end
        
        # Origin requests
        cost += 0.0075 * 10  # 10M requests estimate
      end
      
      # Route 53 costs
      cost += 0.50  # Hosted zone
      
      # Health checks
      cost += attrs.endpoints.count { |e| e.health_check_enabled } * 0.50
      
      # Traffic policies
      if attrs.enable_route53_policies
        cost += attrs.traffic_policies.length * 50.0  # $50 per policy
      end
      
      # WAF costs
      if attrs.security.waf_enabled
        cost += 5.00  # Web ACL
        cost += 1.00  # Rule group
        cost += 0.60 * 10  # 10M requests
      end
      
      # Shield Advanced
      if attrs.security.ddos_protection
        cost += 3000.0  # Shield Advanced subscription
      end
      
      # Monitoring costs
      if attrs.observability.cloudwatch_enabled
        cost += 10.0  # Dashboards and alarms
      end
      
      # Synthetic monitoring
      if attrs.observability.synthetic_checks.any?
        cost += attrs.observability.synthetic_checks.length * 8.64  # 1 run per 5 min
      end
      
      cost.round(2)
    end
  end
end