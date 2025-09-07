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
require 'pangea/resources/aws_lb_listener/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Load Balancer Listener with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Listener attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_lb_listener(name, attributes = {})
        # Validate attributes using dry-struct
        listener_attrs = AWS::Types::Types::LoadBalancerListenerAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_lb_listener, name) do
          load_balancer_arn listener_attrs.load_balancer_arn
          port listener_attrs.port
          protocol listener_attrs.protocol
          
          # SSL configuration for HTTPS/TLS listeners
          if ['HTTPS', 'TLS'].include?(listener_attrs.protocol)
            ssl_policy listener_attrs.ssl_policy
            certificate_arn listener_attrs.certificate_arn
          end
          
          # ALPN policy for HTTP/2 support
          alpn_policy listener_attrs.alpn_policy if listener_attrs.alpn_policy
          
          # Default actions
          listener_attrs.default_action.each_with_index do |action, index|
            default_action do
              type action[:type]
              order action[:order] if action[:order]
              
              case action[:type]
              when 'forward'
                if action[:target_group_arn]
                  target_group_arn action[:target_group_arn]
                elsif action[:forward]
                  forward do
                    action[:forward][:target_groups].each do |tg|
                      target_group do
                        arn tg[:arn]
                        weight tg[:weight] if tg[:weight] != 100
                      end
                    end
                    
                    if action[:forward][:stickiness]
                      stickiness do
                        enabled action[:forward][:stickiness][:enabled]
                        duration action[:forward][:stickiness][:duration] if action[:forward][:stickiness][:duration]
                      end
                    end
                  end
                end
                
              when 'redirect'
                redirect do
                  protocol action[:redirect][:protocol] if action[:redirect][:protocol]
                  port action[:redirect][:port] if action[:redirect][:port]
                  host action[:redirect][:host] if action[:redirect][:host]
                  path action[:redirect][:path] if action[:redirect][:path]
                  query action[:redirect][:query] if action[:redirect][:query]
                  status_code action[:redirect][:status_code]
                end
                
              when 'fixed-response'
                fixed_response do
                  content_type action[:fixed_response][:content_type] if action[:fixed_response][:content_type]
                  message_body action[:fixed_response][:message_body] if action[:fixed_response][:message_body]
                  status_code action[:fixed_response][:status_code]
                end
                
              when 'authenticate-cognito'
                authenticate_cognito do
                  user_pool_arn action[:authenticate_cognito][:user_pool_arn]
                  user_pool_client_id action[:authenticate_cognito][:user_pool_client_id]
                  user_pool_domain action[:authenticate_cognito][:user_pool_domain]
                  
                  if action[:authenticate_cognito][:authentication_request_extra_params]
                    authentication_request_extra_params do
                      action[:authenticate_cognito][:authentication_request_extra_params].each do |key, value|
                        public_send(key, value)
                      end
                    end
                  end
                  
                  on_unauthenticated_request action[:authenticate_cognito][:on_unauthenticated_request] if action[:authenticate_cognito][:on_unauthenticated_request]
                  scope action[:authenticate_cognito][:scope] if action[:authenticate_cognito][:scope]
                  session_cookie_name action[:authenticate_cognito][:session_cookie_name] if action[:authenticate_cognito][:session_cookie_name]
                  session_timeout action[:authenticate_cognito][:session_timeout] if action[:authenticate_cognito][:session_timeout]
                end
                
              when 'authenticate-oidc'
                authenticate_oidc do
                  authorization_endpoint action[:authenticate_oidc][:authorization_endpoint]
                  client_id action[:authenticate_oidc][:client_id]
                  client_secret action[:authenticate_oidc][:client_secret]
                  issuer action[:authenticate_oidc][:issuer]
                  token_endpoint action[:authenticate_oidc][:token_endpoint]
                  user_info_endpoint action[:authenticate_oidc][:user_info_endpoint]
                  
                  if action[:authenticate_oidc][:authentication_request_extra_params]
                    authentication_request_extra_params do
                      action[:authenticate_oidc][:authentication_request_extra_params].each do |key, value|
                        public_send(key, value)
                      end
                    end
                  end
                  
                  on_unauthenticated_request action[:authenticate_oidc][:on_unauthenticated_request] if action[:authenticate_oidc][:on_unauthenticated_request]
                  scope action[:authenticate_oidc][:scope] if action[:authenticate_oidc][:scope]
                  session_cookie_name action[:authenticate_oidc][:session_cookie_name] if action[:authenticate_oidc][:session_cookie_name]
                  session_timeout action[:authenticate_oidc][:session_timeout] if action[:authenticate_oidc][:session_timeout]
                end
              end
            end
          end
          
          # Apply tags if present
          if listener_attrs.tags.any?
            tags do
              listener_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Create resource reference
        ref = ResourceReference.new(
          type: 'aws_lb_listener',
          name: name,
          resource_attributes: listener_attrs.to_h,
          outputs: {
            id: "${aws_lb_listener.#{name}.id}",
            arn: "${aws_lb_listener.#{name}.arn}",
            load_balancer_arn: "${aws_lb_listener.#{name}.load_balancer_arn}",
            port: "${aws_lb_listener.#{name}.port}",
            protocol: "${aws_lb_listener.#{name}.protocol}",
            ssl_policy: "${aws_lb_listener.#{name}.ssl_policy}",
            certificate_arn: "${aws_lb_listener.#{name}.certificate_arn}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:is_secure?) { ['HTTPS', 'TLS'].include?(listener_attrs.protocol) }
        ref.define_singleton_method(:requires_ssl?) { ['HTTPS', 'TLS'].include?(listener_attrs.protocol) }
        ref.define_singleton_method(:is_http_based?) { ['HTTP', 'HTTPS'].include?(listener_attrs.protocol) }
        ref.define_singleton_method(:is_tcp_based?) { ['TCP', 'TLS', 'TCP_UDP'].include?(listener_attrs.protocol) }
        ref.define_singleton_method(:supports_rules?) { ['HTTP', 'HTTPS'].include?(listener_attrs.protocol) }
        ref.define_singleton_method(:action_count) { listener_attrs.default_action.size }
        ref.define_singleton_method(:has_authentication?) do
          listener_attrs.default_action.any? { |a| ['authenticate-cognito', 'authenticate-oidc'].include?(a[:type]) }
        end
        ref.define_singleton_method(:has_weighted_routing?) do
          listener_attrs.default_action.any? { |a| a[:type] == 'forward' && a[:forward] }
        end
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)