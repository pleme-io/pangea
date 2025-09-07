# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS Load Balancer Listener Certificate resources
      class LoadBalancerListenerCertificateAttributes < Dry::Struct
        # The ARN of the listener to attach the certificate to
        attribute :listener_arn, Resources::Types::String.constrained(
          format: /\Aarn:aws:elasticloadbalancing:[a-z0-9-]+:\d{12}:listener\/[a-zA-Z0-9\/-]+\z/
        )
        
        # The ARN of the SSL certificate to attach
        attribute :certificate_arn, Resources::Types::String.constrained(
          format: /\Aarn:aws:acm:[a-z0-9-]+:\d{12}:certificate\/[a-f0-9-]+\z/
        )

        # Custom validation for certificate-listener compatibility
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Extract regions from ARNs for validation
          listener_region = attrs.listener_arn.split(':')[3]
          cert_region = attrs.certificate_arn.split(':')[3]
          
          if listener_region != cert_region
            raise Dry::Struct::Error, "Certificate region (#{cert_region}) must match listener region (#{listener_region})"
          end

          attrs
        end
      end
    end
      end
    end
  end
end