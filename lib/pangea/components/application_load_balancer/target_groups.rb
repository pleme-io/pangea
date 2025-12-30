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
    module ApplicationLoadBalancer
      # Creates and manages ALB target groups
      module TargetGroups
        extend self

        def create_target_groups(name, component_attrs, component_tag_set, context)
          target_groups = {}

          if component_attrs.create_default_target_group
            default_tg_ref = create_default_target_group(name, component_attrs, component_tag_set, context)
            target_groups[:default] = default_tg_ref
          end

          component_attrs.target_groups.each do |tg_config|
            tg_ref = create_target_group(name, tg_config, component_attrs, component_tag_set, context)
            target_groups[tg_config.name.to_sym] = tg_ref
          end

          target_groups
        end

        private

        def create_default_target_group(name, component_attrs, component_tag_set, context)
          default_tg_config = TargetGroupConfig.new({
            name: 'default',
            port: component_attrs.default_target_group_port,
            protocol: component_attrs.default_target_group_protocol
          })

          context.aws_lb_target_group(
            context.component_resource_name(name, :tg, :default),
            build_target_group_attrs(name, default_tg_config, component_attrs, component_tag_set)
          )
        end

        def create_target_group(name, tg_config, component_attrs, component_tag_set, context)
          context.aws_lb_target_group(
            context.component_resource_name(name, :tg, tg_config.name.to_sym),
            build_target_group_attrs(name, tg_config, component_attrs, component_tag_set)
          )
        end

        def build_target_group_attrs(name, tg_config, component_attrs, component_tag_set)
          {
            name: "#{name}-#{tg_config.name}-tg",
            port: tg_config.port,
            protocol: tg_config.protocol,
            vpc_id: component_attrs.vpc_ref.id,
            target_type: tg_config.target_type,
            deregistration_delay: tg_config.deregistration_delay,
            stickiness: build_stickiness_config(tg_config),
            health_check: build_health_check_config(tg_config),
            tags: component_tag_set
          }
        end

        def build_stickiness_config(tg_config)
          {
            enabled: tg_config.stickiness_enabled,
            type: tg_config.protocol == 'HTTP' ? 'lb_cookie' : 'source_ip',
            cookie_duration: tg_config.stickiness_duration
          }.compact
        end

        def build_health_check_config(tg_config)
          hc = tg_config.health_check
          {
            enabled: hc.enabled,
            healthy_threshold: hc.healthy_threshold,
            unhealthy_threshold: hc.unhealthy_threshold,
            timeout: hc.timeout,
            interval: hc.interval,
            path: hc.path,
            matcher: hc.matcher,
            protocol: hc.protocol,
            port: hc.port
          }
        end
      end
    end
  end
end
