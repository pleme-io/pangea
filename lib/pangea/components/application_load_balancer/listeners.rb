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
      # Creates and manages ALB listeners
      module Listeners
        extend self

        def create_listeners(name, alb_ref, target_groups, component_attrs, component_tag_set, context)
          listeners = {}

          component_attrs.listeners.each do |listener_config|
            listener_ref = create_listener(
              name, alb_ref, target_groups, listener_config, component_attrs, component_tag_set, context
            )
            listener_name = "listener_#{listener_config.port}_#{listener_config.protocol.downcase}".to_sym
            listeners[listener_name] = listener_ref
          end

          create_https_redirect_listener(name, alb_ref, component_attrs, component_tag_set, listeners, context)

          listeners
        end

        private

        def create_listener(name, alb_ref, target_groups, listener_config, component_attrs, component_tag_set, context)
          listener_name = "listener_#{listener_config.port}_#{listener_config.protocol.downcase}"
          default_actions = build_default_actions(listener_config, target_groups, listener_name)

          listener_attrs = {
            load_balancer_arn: alb_ref.arn,
            port: listener_config.port,
            protocol: listener_config.protocol,
            default_action: default_actions,
            tags: component_tag_set
          }

          add_ssl_config!(listener_attrs, listener_config, component_attrs)

          context.aws_lb_listener(
            context.component_resource_name(name, :listener, listener_name.to_sym),
            listener_attrs
          )
        end

        def build_default_actions(listener_config, target_groups, listener_name)
          case listener_config.default_action_type
          when 'forward'
            build_forward_action(target_groups, listener_name)
          when 'redirect'
            build_redirect_action(listener_config)
          when 'fixed-response'
            build_fixed_response_action(listener_config)
          end
        end

        def build_forward_action(target_groups, listener_name)
          target_group_arn = if target_groups[:default]
                               target_groups[:default].arn
                             elsif target_groups.any?
                               target_groups.values.first.arn
                             else
                               raise "No target groups available for listener #{listener_name}"
                             end

          [{ type: 'forward', target_group_arn: target_group_arn }]
        end

        def build_redirect_action(listener_config)
          redirect_config = listener_config.redirect_config || {
            protocol: 'HTTPS',
            port: '443',
            status_code: 'HTTP_301'
          }
          [{ type: 'redirect', redirect: redirect_config }]
        end

        def build_fixed_response_action(listener_config)
          fixed_response = listener_config.fixed_response_config || {
            content_type: 'text/plain',
            message_body: 'OK',
            status_code: '200'
          }
          [{ type: 'fixed-response', fixed_response: fixed_response }]
        end

        def add_ssl_config!(listener_attrs, listener_config, component_attrs)
          return unless listener_config.protocol.include?('S')

          listener_attrs[:ssl_policy] = listener_config.ssl_policy || 'ELBSecurityPolicy-TLS-1-2-2017-01'

          cert_arn = listener_config.certificate_arn || component_attrs.certificate_arn
          raise "Certificate ARN required for HTTPS/TLS listener on port #{listener_config.port}" unless cert_arn

          listener_attrs[:certificate_arn] = cert_arn
        end

        def create_https_redirect_listener(name, alb_ref, component_attrs, component_tag_set, listeners, context)
          return unless component_attrs.enable_https && component_attrs.ssl_redirect

          has_http_listener = component_attrs.listeners.any? { |l| l.port == 80 && l.protocol == 'HTTP' }
          return if has_http_listener

          redirect_listener_ref = context.aws_lb_listener(
            context.component_resource_name(name, :listener, :http_redirect),
            {
              load_balancer_arn: alb_ref.arn,
              port: 80,
              protocol: 'HTTP',
              default_action: [{
                type: 'redirect',
                redirect: { protocol: 'HTTPS', port: '443', status_code: 'HTTP_301' }
              }],
              tags: component_tag_set
            }
          )

          listeners[:http_redirect] = redirect_listener_ref
        end
      end
    end
  end
end
