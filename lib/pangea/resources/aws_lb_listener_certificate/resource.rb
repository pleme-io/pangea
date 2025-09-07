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
require 'pangea/resources/aws_lb_listener_certificate/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Load Balancer Listener Certificate attachment with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Listener certificate attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_lb_listener_certificate(name, attributes = {})
        # Validate attributes using dry-struct
        cert_attrs = Types::LoadBalancerListenerCertificateAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_lb_listener_certificate, name) do
          listener_arn cert_attrs.listener_arn
          certificate_arn cert_attrs.certificate_arn
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_lb_listener_certificate',
          name: name,
          resource_attributes: cert_attrs.to_h,
          outputs: {
            listener_arn: "${aws_lb_listener_certificate.#{name}.listener_arn}",
            certificate_arn: "${aws_lb_listener_certificate.#{name}.certificate_arn}"
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)