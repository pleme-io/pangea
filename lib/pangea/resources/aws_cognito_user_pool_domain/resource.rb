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