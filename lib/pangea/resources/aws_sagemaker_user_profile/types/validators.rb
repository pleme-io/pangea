# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        class SageMakerUserProfileAttributes
          module Validators
            extend self

            def validate_domain_id(attrs)
              return unless attrs[:domain_id] && attrs[:domain_id] !~ /\Ad-[a-z0-9]{13}\z/
              raise Dry::Struct::Error, "domain_id must be valid format (d-xxxxxxxxxxxxx)"
            end

            def validate_sso_settings(attrs)
              id = attrs[:single_sign_on_user_identifier]
              val = attrs[:single_sign_on_user_value]
              raise Dry::Struct::Error, "SSO value required with identifier" if id && val.nil?
              raise Dry::Struct::Error, "SSO identifier required with value" if val && id.nil?
            end

            def validate_execution_role(attrs)
              role = attrs.dig(:user_settings, :execution_role)
              return unless role && role !~ /\Aarn:aws:iam::\d{12}:role\//
              raise Dry::Struct::Error, "execution_role must be valid IAM role ARN"
            end

            def validate_storage_settings(attrs)
              storage = attrs.dig(:user_settings, :space_storage_settings, :default_ebs_storage_settings)
              return unless storage
              default = storage[:default_ebs_volume_size_in_gb]
              max = storage[:maximum_ebs_volume_size_in_gb]
              return unless default && max && default > max
              raise Dry::Struct::Error, "default_ebs_volume_size_in_gb cannot exceed maximum"
            end

            def validate_posix_config(attrs)
              posix = attrs.dig(:user_settings, :custom_posix_user_config)
              return unless posix
              raise Dry::Struct::Error, "POSIX UID must be >= 1001" if posix[:uid]&.< 1001
              raise Dry::Struct::Error, "POSIX GID must be >= 1001" if posix[:gid]&.< 1001
            end

            def validate_canvas_oauth(attrs)
              oauth = attrs.dig(:user_settings, :canvas_app_settings, :identity_provider_oauth_settings)
              return unless oauth
              oauth.each do |s|
                next unless s[:status] == 'ENABLED' && s[:secret_arn].nil?
                raise Dry::Struct::Error, "secret_arn required when OAuth ENABLED"
              end
            end
          end
        end
      end
    end
  end
end
