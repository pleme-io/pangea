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


require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS Load Balancer Listener resources
        class LoadBalancerListenerAttributes < Dry::Struct
          transform_keys(&:to_sym)
          # The ARN of the load balancer to attach the listener to
          attribute :load_balancer_arn, Pangea::Resources::Types::String
        
          # The port on which the load balancer is listening
          attribute :port, Pangea::Resources::Types::ListenerPort
        
          # The protocol for connections from clients to the load balancer
          attribute :protocol, Pangea::Resources::Types::ListenerProtocol
        
          # The security policy for HTTPS/TLS listeners (required for HTTPS/TLS)
          attribute? :ssl_policy, Pangea::Resources::Types::SslPolicy.optional
        
          # The ARN of the default SSL server certificate (required for HTTPS/TLS)
          attribute? :certificate_arn, Pangea::Resources::Types::String.optional
        
          # The ALPN policy for HTTPS listeners
          attribute? :alpn_policy, Pangea::Resources::Types::String.constrained(included_in: ['HTTP1Only', 'HTTP2Only', 'HTTP2Optional', 'HTTP2Preferred', 'None']).optional
        
          # Default actions for the listener
          attribute :default_action, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::Hash.schema(
              type: Pangea::Resources::Types::ListenerActionType,
              target_group_arn?: Pangea::Resources::Types::String.optional,
              forward?: Pangea::Resources::Types::ListenerForwardAction.optional,
              redirect?: Pangea::Resources::Types::ListenerRedirectAction.optional,
              fixed_response?: Pangea::Resources::Types::ListenerFixedResponseAction.optional,
              authenticate_cognito?: Pangea::Resources::Types::ListenerAuthenticateCognitoAction.optional,
              authenticate_oidc?: Pangea::Resources::Types::ListenerAuthenticateOidcAction.optional,
              order?: Pangea::Resources::Types::Integer.constrained(gteq: 1, lteq: 50000).optional
            )
          ).constrained(min_size: 1)
        
          # Tags to apply to the listener
          attribute :tags, Pangea::Resources::Types::Hash.default({}.freeze)

          # Custom validation for protocol-specific requirements
          def self.new(attributes = {})
            attrs = super(attributes)
          
            # Validate HTTPS/TLS requirements
            if ['HTTPS', 'TLS'].include?(attrs.protocol)
              if attrs.ssl_policy.nil?
                raise Dry::Struct::Error, "ssl_policy is required for #{attrs.protocol} listeners"
              end
              
              if attrs.certificate_arn.nil?
                raise Dry::Struct::Error, "certificate_arn is required for #{attrs.protocol} listeners"
              end
            elsif !attrs.ssl_policy.nil? || !attrs.certificate_arn.nil?
              raise Dry::Struct::Error, "ssl_policy and certificate_arn can only be specified for HTTPS/TLS listeners"
            end

            # Validate protocol-specific ports
            case attrs.protocol
            when 'HTTP'
              # HTTP commonly uses port 80, but can use others
            when 'HTTPS'  
              # HTTPS commonly uses port 443, but can use others
            when 'TCP', 'TLS'
              # TCP/TLS can use any valid port
            when 'UDP', 'TCP_UDP'
              # UDP protocols - validate they're used with Network Load Balancer
            when 'GENEVE'
              # GENEVE protocol - used with Gateway Load Balancer
            end

            # Validate default actions
            attrs.default_action.each do |action|
              case action[:type]
              when 'forward'
                unless action[:target_group_arn] || action[:forward]
                  raise Dry::Struct::Error, "forward action requires either target_group_arn or forward configuration"
                end
              when 'redirect'
                unless action[:redirect]
                  raise Dry::Struct::Error, "redirect action requires redirect configuration"
                end
              when 'fixed-response'
                unless action[:fixed_response]
                  raise Dry::Struct::Error, "fixed-response action requires fixed_response configuration"
                end
              when 'authenticate-cognito'
                unless action[:authenticate_cognito]
                  raise Dry::Struct::Error, "authenticate-cognito action requires authenticate_cognito configuration"
                end
              when 'authenticate-oidc'
                unless action[:authenticate_oidc]
                  raise Dry::Struct::Error, "authenticate-oidc action requires authenticate_oidc configuration"
                end
              end
            end

            attrs
          end
        end
      end
    end
  end
end