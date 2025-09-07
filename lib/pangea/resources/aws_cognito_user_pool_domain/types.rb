# frozen_string_literal: true

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

          # Validate domain format
          domain = attrs.domain
          
          # Check if it's a custom domain (contains dots) or Cognito domain prefix
          if domain.include?('.')
            # Custom domain validation
            if !attrs.certificate_arn
              raise Dry::Struct::Error, "certificate_arn is required for custom domains"
            end
            
            # Basic domain format validation
            unless domain =~ /\A[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*\z/
              raise Dry::Struct::Error, "Invalid custom domain format"
            end
            
            # Check for valid TLD (basic validation)
            unless domain =~ /\.[a-zA-Z]{2,}$/
              raise Dry::Struct::Error, "Custom domain must have valid top-level domain"
            end
          else
            # Cognito domain prefix validation
            if attrs.certificate_arn
              raise Dry::Struct::Error, "certificate_arn is not supported for Cognito domain prefixes"
            end
            
            # Cognito domain prefix must be 3-63 characters
            unless domain.length >= 3 && domain.length <= 63
              raise Dry::Struct::Error, "Cognito domain prefix must be 3-63 characters long"
            end
            
            # Cognito domain prefix format validation
            unless domain =~ /\A[a-z0-9]([a-z0-9-]*[a-z0-9])?\z/
              raise Dry::Struct::Error, "Cognito domain prefix must contain only lowercase letters, numbers, and hyphens, and must start and end with alphanumeric characters"
            end
            
            # Cannot start or end with hyphen
            if domain.start_with?('-') || domain.end_with?('-')
              raise Dry::Struct::Error, "Cognito domain prefix cannot start or end with hyphen"
            end
          end

          attrs
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
          if custom_domain?
            "https://#{domain}"
          else
            "https://#{domain}.auth.#{region}.amazoncognito.com"
          end
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
          
          # Basic ARN format validation for ACM certificates
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

      # Pre-configured domain templates for common scenarios
      module UserPoolDomainTemplates
        # Cognito-hosted domain with prefix
        def self.cognito_domain(domain_prefix, user_pool_id)
          {
            domain: domain_prefix,
            user_pool_id: user_pool_id
          }
        end

        # Custom domain with SSL certificate
        def self.custom_domain(custom_domain_name, user_pool_id, certificate_arn)
          {
            domain: custom_domain_name,
            user_pool_id: user_pool_id,
            certificate_arn: certificate_arn
          }
        end

        # Development domain with predictable naming
        def self.development_domain(app_name, user_pool_id, stage = 'dev')
          domain_prefix = "#{app_name}-#{stage}-auth"
          cognito_domain(domain_prefix, user_pool_id)
        end

        # Production custom domain
        def self.production_custom_domain(base_domain, user_pool_id, certificate_arn)
          auth_domain = "auth.#{base_domain}"
          custom_domain(auth_domain, user_pool_id, certificate_arn)
        end

        # Staging environment domain
        def self.staging_domain(base_domain, user_pool_id, certificate_arn = nil)
          if certificate_arn
            staging_domain = "auth-staging.#{base_domain}"
            custom_domain(staging_domain, user_pool_id, certificate_arn)
          else
            # Use Cognito domain for staging if no certificate
            staging_prefix = base_domain.gsub('.', '-') + '-staging-auth'
            cognito_domain(staging_prefix, user_pool_id)
          end
        end

        # Multi-environment domain strategy
        def self.environment_domain(base_domain, environment, user_pool_id, certificate_arn = nil)
          case environment.to_sym
          when :production
            if certificate_arn
              production_custom_domain(base_domain, user_pool_id, certificate_arn)
            else
              raise ArgumentError, "Certificate ARN required for production custom domain"
            end
          when :staging
            staging_domain(base_domain, user_pool_id, certificate_arn)
          when :development
            app_name = base_domain.split('.').first
            development_domain(app_name, user_pool_id, environment)
          else
            # Generic environment
            domain_prefix = "#{base_domain.gsub('.', '-')}-#{environment}-auth"
            cognito_domain(domain_prefix, user_pool_id)
          end
        end
      end

      # Domain validation helpers
      module DomainValidation
        # Validate domain availability (would typically check via AWS API)
        def self.domain_available?(domain)
          # In real implementation, this would make AWS API call
          # to check domain availability
          true
        end

        # Generate suggested domain names if preferred is not available
        def self.suggest_domains(base_name, count = 5)
          suggestions = []
          suggestions << base_name
          
          (1..count-1).each do |i|
            suggestions << "#{base_name}-#{i}"
            suggestions << "#{base_name}#{i}"
          end
          
          suggestions
        end

        # Validate certificate compatibility
        def self.certificate_compatible?(certificate_arn, domain)
          # In real implementation, this would validate that the certificate
          # matches the domain and is in the correct region
          return false unless certificate_arn
          
          # Certificate must be in us-east-1 for CloudFront distribution
          certificate_arn.include?(':us-east-1:')
        end

        # Extract domain components
        def self.parse_domain(domain)
          if domain.include?('.')
            parts = domain.split('.')
            {
              subdomain: parts.first,
              root_domain: parts[1..-1].join('.'),
              tld: parts.last,
              type: :custom
            }
          else
            {
              prefix: domain,
              type: :cognito
            }
          end
        end
      end
    end
      end
    end
  end
end