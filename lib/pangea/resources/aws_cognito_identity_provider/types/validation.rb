# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        module CognitoProviderValidation
          def self.validate(attrs)
            case attrs.provider_type
            when 'SAML' then validate_saml(attrs.provider_details)
            when 'OIDC' then validate_oidc(attrs.provider_details)
            when 'Facebook' then validate_facebook(attrs.provider_details)
            when 'Google' then validate_google(attrs.provider_details)
            when 'LoginWithAmazon' then validate_amazon(attrs.provider_details)
            when 'Apple' then validate_apple(attrs.provider_details)
            when 'Twitter' then validate_twitter(attrs.provider_details)
            end
          end

          def self.validate_saml(details)
            return unless details
            raise Dry::Struct::Error, 'MetadataURL is required for SAML provider' unless details['MetadataURL']
            raise Dry::Struct::Error, 'MetadataURL must be a valid HTTPS URL' unless details['MetadataURL'].match?(/\Ahttps:\/\/.+\z/)
          end

          def self.validate_oidc(details)
            return unless details
            %w[client_id client_secret oidc_issuer authorize_scopes].each { |f| raise Dry::Struct::Error, "#{f} is required for OIDC provider" unless details[f] }
            raise Dry::Struct::Error, 'oidc_issuer must be a valid HTTPS URL' unless details['oidc_issuer'].match?(/\Ahttps:\/\/.+\z/)
            raise Dry::Struct::Error, 'authorize_scopes must contain only letters, numbers, and spaces' unless details['authorize_scopes'].match?(/\A[\w\s]+\z/)
          end

          def self.validate_facebook(details)
            return unless details
            raise Dry::Struct::Error, 'Facebook client_id must be numeric' if details['client_id'] && !details['client_id'].match?(/\A\d+\z/)
            raise Dry::Struct::Error, 'Facebook client_secret appears to be invalid (too short)' if details['client_secret']&.length.to_i < 32
          end

          def self.validate_google(details)
            return unless details
            raise Dry::Struct::Error, 'Google client_id must be in format: numbers-string.apps.googleusercontent.com' if details['client_id'] && !details['client_id'].match?(/\A\d+-.+\.apps\.googleusercontent\.com\z/)
          end

          def self.validate_amazon(details)
            return unless details
            raise Dry::Struct::Error, "Amazon client_id must start with 'amzn1.application-oa2-client.'" if details['client_id'] && !details['client_id'].match?(/\Aamzn1\.application-oa2-client\..+\z/)
          end

          def self.validate_apple(details)
            return unless details
            %w[client_id team_id key_id private_key].each { |f| raise Dry::Struct::Error, "#{f} is required for Apple provider" unless details[f] }
            raise Dry::Struct::Error, 'Apple team_id must be 10 alphanumeric characters' if details['team_id'] && !details['team_id'].match?(/\A[A-Z0-9]{10}\z/)
            raise Dry::Struct::Error, 'Apple key_id must be 10 alphanumeric characters' if details['key_id'] && !details['key_id'].match?(/\A[A-Z0-9]{10}\z/)
          end

          def self.validate_twitter(details)
            return unless details
            %w[client_id client_secret].each { |f| raise Dry::Struct::Error, "#{f} is required for Twitter provider" unless details[f] }
          end
        end
      end
    end
  end
end
