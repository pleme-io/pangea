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
  module Resources
    module AWS
      module LoadBalancing
        # DSL methods for Classic Elastic Load Balancer resources
        # Provides type-safe resource functions for Classic ELB configuration
        module ClassicElbDsl
          # Creates a load balancer SSL negotiation policy for Classic Load Balancer SSL configuration
          #
          # @param name [Symbol] Unique name for the SSL negotiation policy resource
          # @param attributes [Hash] Configuration attributes for the policy
          # @return [LoadBalancing::LbSslNegotiationPolicy::LbSslNegotiationPolicyReference] Reference to the created policy
          def aws_lb_ssl_negotiation_policy(name, attributes = {})
            resource = LoadBalancing::LbSslNegotiationPolicy.new(
              name: name,
              synthesizer: synthesizer,
              attributes: LoadBalancing::LbSslNegotiationPolicy::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end

          # Creates a load balancer cookie stickiness policy for session affinity
          #
          # @param name [Symbol] Unique name for the cookie stickiness policy resource
          # @param attributes [Hash] Configuration attributes for the policy
          # @return [LoadBalancing::LbCookieStickinessPolicy::LbCookieStickinessPolicyReference] Reference to the created policy
          def aws_lb_cookie_stickiness_policy(name, attributes = {})
            resource = LoadBalancing::LbCookieStickinessPolicy.new(
              name: name,
              synthesizer: synthesizer,
              attributes: LoadBalancing::LbCookieStickinessPolicy::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end

          # Creates an ELB attachment for Classic Load Balancer instance registration
          #
          # @param name [Symbol] Unique name for the ELB attachment resource
          # @param attributes [Hash] Configuration attributes for the attachment
          # @return [LoadBalancing::ElbAttachment::ElbAttachmentReference] Reference to the created attachment
          def aws_elb_attachment(name, attributes = {})
            resource = LoadBalancing::ElbAttachment.new(
              name: name,
              synthesizer: synthesizer,
              attributes: LoadBalancing::ElbAttachment::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end

          # Gets ELB service account data for access logging configuration
          #
          # @param name [Symbol] Unique name for the ELB service account data source
          # @param attributes [Hash] Configuration attributes for the data source
          # @return [LoadBalancing::ElbServiceAccount::ElbServiceAccountReference] Reference to the service account
          def aws_elb_service_account(name, attributes = {})
            resource = LoadBalancing::ElbServiceAccount.new(
              name: name,
              synthesizer: synthesizer,
              attributes: LoadBalancing::ElbServiceAccount::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end

          # Creates a proxy protocol policy for Classic Load Balancer proxy protocol support
          #
          # @param name [Symbol] Unique name for the proxy protocol policy resource
          # @param attributes [Hash] Configuration attributes for the policy
          # @return [LoadBalancing::ProxyProtocolPolicy::ProxyProtocolPolicyReference] Reference to the created policy
          def aws_proxy_protocol_policy(name, attributes = {})
            resource = LoadBalancing::ProxyProtocolPolicy.new(
              name: name,
              synthesizer: synthesizer,
              attributes: LoadBalancing::ProxyProtocolPolicy::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end

          # Creates a load balancer backend server policy for Classic Load Balancer backend configuration
          #
          # @param name [Symbol] Unique name for the backend server policy resource
          # @param attributes [Hash] Configuration attributes for the policy
          # @return [LoadBalancing::LoadBalancerBackendServerPolicy::LoadBalancerBackendServerPolicyReference] Reference to the created policy
          def aws_load_balancer_backend_server_policy(name, attributes = {})
            resource = LoadBalancing::LoadBalancerBackendServerPolicy.new(
              name: name,
              synthesizer: synthesizer,
              attributes: LoadBalancing::LoadBalancerBackendServerPolicy::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end

          # Creates a load balancer listener policy for Classic Load Balancer listener configuration
          #
          # @param name [Symbol] Unique name for the listener policy resource
          # @param attributes [Hash] Configuration attributes for the policy
          # @return [LoadBalancing::LoadBalancerListenerPolicy::LoadBalancerListenerPolicyReference] Reference to the created policy
          def aws_load_balancer_listener_policy(name, attributes = {})
            resource = LoadBalancing::LoadBalancerListenerPolicy.new(
              name: name,
              synthesizer: synthesizer,
              attributes: LoadBalancing::LoadBalancerListenerPolicy::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end

          # Creates a load balancer policy for Classic Load Balancer custom policies
          #
          # @param name [Symbol] Unique name for the load balancer policy resource
          # @param attributes [Hash] Configuration attributes for the policy
          # @return [LoadBalancing::LoadBalancerPolicy::LoadBalancerPolicyReference] Reference to the created policy
          def aws_load_balancer_policy(name, attributes = {})
            resource = LoadBalancing::LoadBalancerPolicy.new(
              name: name,
              synthesizer: synthesizer,
              attributes: LoadBalancing::LoadBalancerPolicy::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end
        end
      end
    end
  end
end
