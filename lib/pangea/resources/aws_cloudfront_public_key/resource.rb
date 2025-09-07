# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_cloudfront_public_key/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS CloudFront Public Key with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] CloudFront public key attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_cloudfront_public_key(name, attributes = {})
        # Validate attributes using dry-struct
        public_key_attrs = Types::CloudFrontPublicKeyAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_cloudfront_public_key, name) do
          name public_key_attrs.name
          encoded_key public_key_attrs.encoded_key
          comment public_key_attrs.comment if public_key_attrs.comment
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_cloudfront_public_key',
          name: name,
          resource_attributes: public_key_attrs.to_h,
          outputs: {
            id: "${aws_cloudfront_public_key.#{name}.id}",
            name: "${aws_cloudfront_public_key.#{name}.name}",
            encoded_key: "${aws_cloudfront_public_key.#{name}.encoded_key}",
            comment: "${aws_cloudfront_public_key.#{name}.comment}",
            caller_reference: "${aws_cloudfront_public_key.#{name}.caller_reference}",
            etag: "${aws_cloudfront_public_key.#{name}.etag}"
          },
          computed_properties: {
            key_type: public_key_attrs.key_type,
            key_size: public_key_attrs.key_size,
            security_level: public_key_attrs.security_level,
            strong_key: public_key_attrs.strong_key?,
            configuration_warnings: public_key_attrs.validate_configuration,
            estimated_monthly_cost: public_key_attrs.estimated_monthly_cost
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)