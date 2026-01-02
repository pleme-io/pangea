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
require 'pangea/components/application_load_balancer/target_groups'
require 'pangea/components/application_load_balancer/listeners'
require 'pangea/components/application_load_balancer/monitoring'
require 'pangea/resources/aws'

module Pangea
  module Components
    # Application Load Balancer component with target groups and health checks
    # Creates a production-ready ALB with comprehensive security and monitoring features
    def application_load_balancer(name, attributes = {})
      include Base
      include Resources::AWS

      component_attrs = ApplicationLoadBalancer::ApplicationLoadBalancerAttributes.new(attributes)
      component_tag_set = component_tags('ApplicationLoadBalancer', name, component_attrs.tags)

      alb_ref = create_alb(name, component_attrs, component_tag_set)

      target_groups = ApplicationLoadBalancer::TargetGroups.create_target_groups(
        name, component_attrs, component_tag_set, self
      )

      listeners = ApplicationLoadBalancer::Listeners.create_listeners(
        name, alb_ref, target_groups, component_attrs, component_tag_set, self
      )

      alarms = ApplicationLoadBalancer::Monitoring.create_alarms(
        name, alb_ref, component_tag_set, self
      )

      resources = build_resources(alb_ref, target_groups, listeners, alarms)
      outputs = build_outputs(name, alb_ref, target_groups, listeners, component_attrs)

      create_component_reference(
        'application_load_balancer',
        name,
        component_attrs.to_h,
        resources,
        outputs
      )
    end

    private

    def create_alb(name, component_attrs, component_tag_set)
      aws_lb(component_resource_name(name, :alb), {
        name: "#{name}-alb",
        load_balancer_type: 'application',
        scheme: component_attrs.scheme,
        ip_address_type: component_attrs.ip_address_type,
        subnets: component_attrs.subnet_refs.map(&:id),
        security_groups: component_attrs.security_group_refs.map(&:id),
        idle_timeout: component_attrs.idle_timeout,
        enable_deletion_protection: component_attrs.enable_deletion_protection,
        enable_cross_zone_load_balancing: component_attrs.enable_cross_zone_load_balancing,
        enable_http2: component_attrs.enable_http2,
        enable_waf_fail_open: component_attrs.enable_waf_fail_open,
        access_logs: build_access_logs_config(name, component_attrs),
        tags: component_tag_set
      })
    end

    def build_access_logs_config(name, component_attrs)
      if component_attrs.enable_access_logs
        {
          bucket: component_attrs.access_logs_bucket || "#{name}-alb-access-logs",
          prefix: component_attrs.access_logs_prefix,
          enabled: true
        }
      else
        { enabled: false }
      end
    end

    def build_resources(alb_ref, target_groups, listeners, alarms)
      resources = { alb: alb_ref, alarms: alarms }
      resources[:target_groups] = target_groups unless target_groups.empty?
      resources[:listeners] = listeners unless listeners.empty?
      resources
    end

    def build_outputs(name, alb_ref, target_groups, listeners, component_attrs)
      {
        alb_arn: alb_ref.arn,
        alb_dns_name: alb_ref.dns_name,
        alb_zone_id: alb_ref.zone_id,
        target_group_arns: target_groups.transform_values(&:arn),
        listener_arns: listeners.transform_values(&:arn),
        security_features: build_security_features(component_attrs),
        health_check_paths: build_health_check_paths(name, target_groups, component_attrs),
        estimated_monthly_cost: 22.0 + (target_groups.count * 8.0)
      }
    end

    def build_security_features(component_attrs)
      [
        'HTTPS Support',
        'Health Checks',
        'Access Logging',
        'CloudWatch Monitoring',
        (component_attrs.ssl_redirect ? 'SSL Redirect' : nil),
        (component_attrs.enable_security_headers ? 'Security Headers' : nil)
      ].compact
    end

    def build_health_check_paths(name, target_groups, component_attrs)
      target_groups.transform_values do |tg|
        tg_config = component_attrs.target_groups.find do |config|
          "#{name}-#{config.name}-tg" == tg.name
        end
        tg_config&.health_check&.path || '/health'
      end
    end
  end
end
