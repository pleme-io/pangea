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
        # Policy related resource methods
        module Policies
          def aws_lb_ssl_negotiation_policy(name, attributes = {})
            resource = LoadBalancing::LbSslNegotiationPolicy.new(
              name: name,
              synthesizer: synthesizer,
              attributes: LoadBalancing::LbSslNegotiationPolicy::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end

          def aws_lb_cookie_stickiness_policy(name, attributes = {})
            resource = LoadBalancing::LbCookieStickinessPolicy.new(
              name: name,
              synthesizer: synthesizer,
              attributes: LoadBalancing::LbCookieStickinessPolicy::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end

          def aws_proxy_protocol_policy(name, attributes = {})
            resource = LoadBalancing::ProxyProtocolPolicy.new(
              name: name,
              synthesizer: synthesizer,
              attributes: LoadBalancing::ProxyProtocolPolicy::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end

          def aws_load_balancer_backend_server_policy(name, attributes = {})
            resource = LoadBalancing::LoadBalancerBackendServerPolicy.new(
              name: name,
              synthesizer: synthesizer,
              attributes: LoadBalancing::LoadBalancerBackendServerPolicy::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end

          def aws_load_balancer_listener_policy(name, attributes = {})
            resource = LoadBalancing::LoadBalancerListenerPolicy.new(
              name: name,
              synthesizer: synthesizer,
              attributes: LoadBalancing::LoadBalancerListenerPolicy::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end

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
