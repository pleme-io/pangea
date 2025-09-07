# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_ses_domain_identity/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS SES Domain Identity for email sending
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Domain identity attributes
      # @option attributes [String] :domain The domain name to verify
      # @return [ResourceReference] Reference object with outputs
      def aws_ses_domain_identity(name, attributes = {})
        # Validate attributes using dry-struct
        identity_attrs = Types::Types::SesDomainIdentityAttributes.new(attributes)
        
        # Generate terraform resource block
        resource(:aws_ses_domain_identity, name) do
          domain identity_attrs.domain
        end
        
        # Return resource reference with outputs
        ResourceReference.new(
          type: 'aws_ses_domain_identity',
          name: name,
          resource_attributes: identity_attrs.to_h,
          outputs: {
            domain: "${aws_ses_domain_identity.#{name}.domain}",
            arn: "${aws_ses_domain_identity.#{name}.arn}",
            verification_token: "${aws_ses_domain_identity.#{name}.verification_token}"
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)