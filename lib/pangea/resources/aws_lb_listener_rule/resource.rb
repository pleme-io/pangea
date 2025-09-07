# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_lb_listener_rule/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Load Balancer Listener Rule with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Listener rule attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_lb_listener_rule(name, attributes = {})
        # Validate attributes using dry-struct
        rule_attrs = Types::LoadBalancerListenerRuleAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_lb_listener_rule, name) do
          listener_arn rule_attrs.listener_arn
          priority rule_attrs.priority
          
          # Actions configuration
          rule_attrs.action.each_with_index do |action, index|
            action do
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
          
          # Conditions configuration
          rule_attrs.condition.each_with_index do |condition, index|
            condition do
              # Legacy condition format (deprecated but supported)
              if condition[:field] && condition[:values]
                field condition[:field]
                values condition[:values]
              end
              
              # Modern condition types
              if condition[:host_header]
                host_header do
                  values condition[:host_header][:values]
                end
              end
              
              if condition[:path_pattern]
                path_pattern do
                  values condition[:path_pattern][:values]
                end
              end
              
              if condition[:http_method]
                http_method do
                  values condition[:http_method][:values]
                end
              end
              
              if condition[:query_string]
                condition[:query_string][:values].each do |qs|
                  query_string do
                    key qs[:key] if qs[:key]
                    value qs[:value]
                  end
                end
              end
              
              if condition[:http_header]
                http_header do
                  http_header_name condition[:http_header][:http_header_name]
                  values condition[:http_header][:values]
                end
              end
              
              if condition[:source_ip]
                source_ip do
                  values condition[:source_ip][:values]
                end
              end
            end
          end
          
          # Apply tags if present
          if rule_attrs.tags.any?
            tags do
              rule_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_lb_listener_rule',
          name: name,
          resource_attributes: rule_attrs.to_h,
          outputs: {
            id: "${aws_lb_listener_rule.#{name}.id}",
            arn: "${aws_lb_listener_rule.#{name}.arn}",
            listener_arn: "${aws_lb_listener_rule.#{name}.listener_arn}",
            priority: "${aws_lb_listener_rule.#{name}.priority}"
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)