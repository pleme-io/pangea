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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_lb_target_group/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Load Balancer Target Group with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Target Group attributes
      # @option attributes [Integer] :port The port for targets (required)
      # @option attributes [String] :protocol The protocol (HTTP, HTTPS, TCP, etc.) (required)
      # @option attributes [String] :vpc_id The VPC ID (required)
      # @option attributes [String] :target_type Target type (instance, ip, lambda, alb)
      # @option attributes [Hash] :health_check Health check configuration
      # @option attributes [Hash] :stickiness Session stickiness configuration
      # @option attributes [Hash] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs and computed properties
      #
      # @example Basic HTTP target group
      #   tg = aws_lb_target_group(:web, {
      #     port: 80,
      #     protocol: "HTTP",
      #     vpc_id: vpc.id,
      #     health_check: {
      #       enabled: true,
      #       path: "/health",
      #       healthy_threshold: 2,
      #       unhealthy_threshold: 3
      #     },
      #     tags: { Name: "web-target-group" }
      #   })
      #
      # @example Target group with stickiness
      #   tg = aws_lb_target_group(:app, {
      #     port: 443,
      #     protocol: "HTTPS",
      #     vpc_id: vpc.id,
      #     target_type: "ip",
      #     stickiness: {
      #       enabled: true,
      #       type: "lb_cookie",
      #       duration: 86400
      #     }
      #   })
      def aws_lb_target_group(name, attributes = {})
        # Validate attributes using dry-struct
        tg_attrs = Types::Types::TargetGroupAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_lb_target_group, name) do
          # Name or name_prefix
          if tg_attrs.name
            __send__(:name, tg_attrs.name)
          elsif tg_attrs.name_prefix
            name_prefix tg_attrs.name_prefix
          end
          
          # Required attributes
          port tg_attrs.port
          protocol tg_attrs.protocol
          vpc_id tg_attrs.vpc_id
          
          # Optional attributes
          target_type tg_attrs.target_type if tg_attrs.target_type != 'instance'
          deregistration_delay tg_attrs.deregistration_delay if tg_attrs.deregistration_delay != 300
          slow_start tg_attrs.slow_start if tg_attrs.slow_start > 0
          proxy_protocol_v2 tg_attrs.proxy_protocol_v2 if tg_attrs.proxy_protocol_v2
          preserve_client_ip tg_attrs.preserve_client_ip unless tg_attrs.preserve_client_ip.nil?
          ip_address_type tg_attrs.ip_address_type if tg_attrs.ip_address_type != 'ipv4'
          protocol_version tg_attrs.protocol_version if tg_attrs.protocol_version
          
          # Health check configuration
          if tg_attrs.health_check
            health_check do
              hc = tg_attrs.health_check
              enabled hc.enabled
              interval hc.interval
              path hc.path if tg_attrs.supports_health_check_path?
              port hc.port
              protocol hc.protocol
              timeout hc.timeout
              healthy_threshold hc.healthy_threshold
              unhealthy_threshold hc.unhealthy_threshold
              matcher hc.matcher if tg_attrs.supports_health_check_path?
            end
          end
          
          # Stickiness configuration
          if tg_attrs.stickiness && tg_attrs.supports_stickiness?
            stickiness do
              s = tg_attrs.stickiness
              enabled s.enabled
              type s.type
              duration s.duration if s.type == 'lb_cookie'
              cookie_name s.cookie_name if s.cookie_name
            end
          end
          
          # Apply tags if present
          if tg_attrs.tags.any?
            tags do
              tg_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs and computed properties
        ref = ResourceReference.new(
          type: 'aws_lb_target_group',
          name: name,
          resource_attributes: tg_attrs.to_h,
          outputs: {
            id: "${aws_lb_target_group.#{name}.id}",
            arn: "${aws_lb_target_group.#{name}.arn}",
            arn_suffix: "${aws_lb_target_group.#{name}.arn_suffix}",
            name: "${aws_lb_target_group.#{name}.name}",
            port: "${aws_lb_target_group.#{name}.port}",
            protocol: "${aws_lb_target_group.#{name}.protocol}",
            vpc_id: "${aws_lb_target_group.#{name}.vpc_id}",
            target_type: "${aws_lb_target_group.#{name}.target_type}",
            health_check: "${aws_lb_target_group.#{name}.health_check}",
            stickiness: "${aws_lb_target_group.#{name}.stickiness}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:supports_stickiness?) { tg_attrs.supports_stickiness? }
        ref.define_singleton_method(:supports_health_check_path?) { tg_attrs.supports_health_check_path? }
        ref.define_singleton_method(:is_network_load_balancer?) { tg_attrs.is_network_load_balancer? }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)