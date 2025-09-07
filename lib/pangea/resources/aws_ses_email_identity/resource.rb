# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_ses_email_identity/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS SES Email Identity for email sending
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Email identity attributes
      # @option attributes [String] :email The email address to verify
      # @return [ResourceReference] Reference object with outputs
      def aws_ses_email_identity(name, attributes = {})
        # Validate attributes using dry-struct
        identity_attrs = Types::Types::SesEmailIdentityAttributes.new(attributes)
        
        # Generate terraform resource block
        resource(:aws_ses_email_identity, name) do
          email identity_attrs.email
        end
        
        # Return resource reference with outputs
        ResourceReference.new(
          type: 'aws_ses_email_identity',
          name: name,
          resource_attributes: identity_attrs.to_h,
          outputs: {
            email: "${aws_ses_email_identity.#{name}.email}",
            arn: "${aws_ses_email_identity.#{name}.arn}"
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)