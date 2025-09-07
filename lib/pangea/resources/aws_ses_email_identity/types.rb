# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # SES Email Identity resource attributes
        class SesEmailIdentityAttributes < Dry::Struct
          transform_keys(&:to_sym)

          attribute :email, Resources::Types::EmailAddress

          # Custom validation for email format
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            # Additional email validation beyond basic format
            if attrs[:email]
              email = attrs[:email].downcase
              
              # Check for common invalid patterns
              if email.include?('..')
                raise Dry::Struct::Error, "Email address cannot contain consecutive dots: #{attrs[:email]}"
              end
              
              if email.start_with?('.') || email.end_with?('.')
                raise Dry::Struct::Error, "Email address cannot start or end with a dot: #{attrs[:email]}"
              end
              
              # Update with normalized email
              attrs[:email] = email
            end

            super(attrs)
          end

          # Get the domain part of the email
          def domain_part
            email.split('@')[1]
          end

          # Get the local part of the email  
          def local_part
            email.split('@')[0]
          end

          # Check if email uses a common provider
          def common_provider?
            common_domains = %w[gmail.com yahoo.com hotmail.com outlook.com]
            common_domains.include?(domain_part.downcase)
          end
        end
      end
    end
  end
end