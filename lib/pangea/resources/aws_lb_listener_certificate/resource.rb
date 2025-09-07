# frozen_string_literal: true

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