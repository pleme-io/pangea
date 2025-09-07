# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_cognito_user_pool_domain/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Cognito User Pool Domain with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Cognito user pool domain attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_cognito_user_pool_domain(name, attributes = {})
        # Validate attributes using dry-struct
        domain_attrs = Types::CognitoUserPoolDomainAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_cognito_user_pool_domain, name) do
          domain domain_attrs.domain
          user_pool_id domain_attrs.user_pool_id
          
          # Certificate ARN for custom domains
          certificate_arn domain_attrs.certificate_arn if domain_attrs.certificate_arn
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_cognito_user_pool_domain',
          name: name,
          resource_attributes: domain_attrs.to_h,
          outputs: {
            aws_account_id: "${aws_cognito_user_pool_domain.#{name}.aws_account_id}",
            cloudfront_distribution_arn: "${aws_cognito_user_pool_domain.#{name}.cloudfront_distribution_arn}",
            domain: "${aws_cognito_user_pool_domain.#{name}.domain}",
            s3_bucket: "${aws_cognito_user_pool_domain.#{name}.s3_bucket}",
            version: "${aws_cognito_user_pool_domain.#{name}.version}"
          },
          computed_properties: {
            custom_domain: domain_attrs.custom_domain?,
            cognito_domain: domain_attrs.cognito_domain?,
            domain_type: domain_attrs.domain_type,
            ssl_required: domain_attrs.ssl_required?,
            certificate_arn_valid: domain_attrs.certificate_arn_valid?,
            certificate_region: domain_attrs.certificate_region,
            certificate_in_us_east_1: domain_attrs.certificate_in_us_east_1?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)