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

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS Cognito User Pool Domain resources
        class CognitoUserPoolDomainAttributes < Dry::Struct
          # Domain name (required) - can be custom domain or Cognito domain prefix
          attribute :domain, Resources::Types::String

          # User pool ID (required)
          attribute :user_pool_id, Resources::Types::String

          # Certificate ARN for custom domains (HTTPS only)
          attribute :certificate_arn, Resources::Types::String.optional

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)
            validate_domain(attrs)
            attrs
          end

          # Validates domain format and certificate requirements
          def self.validate_domain(attrs)
            domain = attrs.domain

            if domain.include?('.')
              validate_custom_domain(attrs, domain)
            else
              validate_cognito_domain(attrs, domain)
            end
          end

          # Validates custom domain format and certificate
          def self.validate_custom_domain(attrs, domain)
            raise Dry::Struct::Error, 'certificate_arn is required for custom domains' unless attrs.certificate_arn

            domain_pattern = /\A[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*\z/
            raise Dry::Struct::Error, 'Invalid custom domain format' unless domain =~ domain_pattern
            raise Dry::Struct::Error, 'Custom domain must have valid top-level domain' unless domain =~ /\.[a-zA-Z]{2,}$/
          end

          # Validates Cognito domain prefix format
          def self.validate_cognito_domain(attrs, domain)
            raise Dry::Struct::Error, 'certificate_arn is not supported for Cognito domain prefixes' if attrs.certificate_arn
            raise Dry::Struct::Error, 'Cognito domain prefix must be 3-63 characters long' unless domain.length.between?(3, 63)

            prefix_pattern = /\A[a-z0-9]([a-z0-9-]*[a-z0-9])?\z/
            unless domain =~ prefix_pattern
              raise Dry::Struct::Error,
                    'Cognito domain prefix must contain only lowercase letters, numbers, and hyphens, ' \
                    'and must start and end with alphanumeric characters'
            end

            raise Dry::Struct::Error, 'Cognito domain prefix cannot start or end with hyphen' if domain.start_with?('-') || domain.end_with?('-')
          end

          # Check if this is a custom domain
          def custom_domain?
            domain.include?('.')
          end

          # Check if this is a Cognito domain prefix
          def cognito_domain?
            !domain.include?('.')
          end

          # Get the full Cognito domain URL
          def cognito_domain_url(region = 'us-east-1')
            custom_domain? ? "https://#{domain}" : "https://#{domain}.auth.#{region}.amazoncognito.com"
          end

          # Get domain type description
          def domain_type
            custom_domain? ? :custom : :cognito
          end

          # Check if SSL/TLS is required
          def ssl_required?
            custom_domain?
          end

          # Validate certificate ARN format
          def certificate_arn_valid?
            return true unless certificate_arn

            certificate_arn.match?(/\Aarn:aws:acm:[a-z0-9-]+:\d{12}:certificate\/[a-f0-9-]+\z/)
          end

          # Extract region from certificate ARN
          def certificate_region
            return nil unless certificate_arn

            match = certificate_arn.match(/arn:aws:acm:([a-z0-9-]+):/)
            match ? match[1] : nil
          end

          # Check if certificate is in us-east-1 (required for CloudFront)
          def certificate_in_us_east_1?
            certificate_region == 'us-east-1'
          end
        end
      end
    end
  end
end
