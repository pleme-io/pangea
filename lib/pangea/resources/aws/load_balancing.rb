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

require_relative 'load_balancing/lb_trust_store'
require_relative 'load_balancing/lb_trust_store_revocation'
require_relative 'load_balancing/alb_target_group_attachment'
require_relative 'load_balancing/lb_target_group_attachment'
require_relative 'load_balancing/lb_ssl_negotiation_policy'
require_relative 'load_balancing/lb_cookie_stickiness_policy'
require_relative 'load_balancing/elb_attachment'
require_relative 'load_balancing/elb_service_account'
require_relative 'load_balancing/proxy_protocol_policy'
require_relative 'load_balancing/load_balancer_backend_server_policy'
require_relative 'load_balancing/load_balancer_listener_policy'
require_relative 'load_balancing/load_balancer_policy'
require_relative 'load_balancing/classic_elb_dsl'

module Pangea
  module Resources
    module AWS
      # AWS Load Balancing Extended service module
      # Provides type-safe resource functions for advanced load balancer configuration
      module LoadBalancing
        include ClassicElbDsl

        # Creates a load balancer trust store for SSL/TLS certificate validation
        #
        # @param name [Symbol] Unique name for the trust store resource
        # @param attributes [Hash] Configuration attributes for the trust store
        # @return [LoadBalancing::LbTrustStore::LbTrustStoreReference] Reference to the created trust store
        def aws_lb_trust_store(name, attributes = {})
          resource = LoadBalancing::LbTrustStore.new(
            name: name,
            synthesizer: synthesizer,
            attributes: LoadBalancing::LbTrustStore::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates a load balancer trust store revocation for certificate revocation lists
        #
        # @param name [Symbol] Unique name for the trust store revocation resource
        # @param attributes [Hash] Configuration attributes for the revocation
        # @return [LoadBalancing::LbTrustStoreRevocation::LbTrustStoreRevocationReference] Reference to the created revocation
        def aws_lb_trust_store_revocation(name, attributes = {})
          resource = LoadBalancing::LbTrustStoreRevocation.new(
            name: name,
            synthesizer: synthesizer,
            attributes: LoadBalancing::LbTrustStoreRevocation::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates an ALB target group attachment for Application Load Balancer targets
        #
        # @param name [Symbol] Unique name for the target group attachment resource
        # @param attributes [Hash] Configuration attributes for the attachment
        # @return [LoadBalancing::AlbTargetGroupAttachment::AlbTargetGroupAttachmentReference] Reference to the created attachment
        def aws_alb_target_group_attachment(name, attributes = {})
          resource = LoadBalancing::AlbTargetGroupAttachment.new(
            name: name,
            synthesizer: synthesizer,
            attributes: LoadBalancing::AlbTargetGroupAttachment::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates a load balancer target group attachment for load balancer targets
        #
        # @param name [Symbol] Unique name for the target group attachment resource
        # @param attributes [Hash] Configuration attributes for the attachment
        # @return [LoadBalancing::LbTargetGroupAttachment::LbTargetGroupAttachmentReference] Reference to the created attachment
        def aws_lb_target_group_attachment(name, attributes = {})
          resource = LoadBalancing::LbTargetGroupAttachment.new(
            name: name,
            synthesizer: synthesizer,
            attributes: LoadBalancing::LbTargetGroupAttachment::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end
      end
    end
  end
end
