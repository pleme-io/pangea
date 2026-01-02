# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # Pre-configured user pool templates for common scenarios
        module UserPoolTemplates
          def self.basic_email_auth(pool_name)
            {
              name: pool_name,
              username_attributes: ['email'],
              auto_verified_attributes: ['email'],
              password_policy: { minimum_length: 8, require_lowercase: true, require_uppercase: true, require_numbers: true },
              account_recovery_setting: { recovery_mechanisms: [{ name: 'verified_email', priority: 1 }] },
              admin_create_user_config: { allow_admin_create_user_only: false }
            }
          end

          def self.phone_auth(pool_name, sns_role_arn)
            {
              name: pool_name,
              username_attributes: ['phone_number'],
              auto_verified_attributes: ['phone_number'],
              sms_configuration: { external_id: "#{pool_name}-external", sns_caller_arn: sns_role_arn },
              account_recovery_setting: { recovery_mechanisms: [{ name: 'verified_phone_number', priority: 1 }] }
            }
          end

          def self.mfa_enabled(pool_name)
            basic_email_auth(pool_name).merge(mfa_configuration: 'ON', software_token_mfa_configuration: { enabled: true })
          end

          def self.enterprise_security(pool_name)
            basic_email_auth(pool_name).merge(
              user_pool_add_ons: { advanced_security_mode: 'ENFORCED' },
              mfa_configuration: 'OPTIONAL',
              device_configuration: { challenge_required_on_new_device: true, device_only_remembered_on_user_prompt: true }
            )
          end

          def self.social_signin(pool_name)
            {
              name: pool_name,
              username_attributes: ['email'],
              auto_verified_attributes: ['email'],
              admin_create_user_config: { allow_admin_create_user_only: true },
              account_recovery_setting: { recovery_mechanisms: [{ name: 'admin_only', priority: 1 }] }
            }
          end
        end
      end
    end
  end
end
