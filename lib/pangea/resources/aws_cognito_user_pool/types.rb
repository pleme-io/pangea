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
      # Password policy configuration for user pool
      class CognitoUserPoolPasswordPolicy < Dry::Struct
        attribute :minimum_length, Resources::Types::Integer.default(8).constrained(gteq: 6, lteq: 99)
        attribute :require_lowercase, Resources::Types::Bool.optional
        attribute :require_numbers, Resources::Types::Bool.optional
        attribute :require_symbols, Resources::Types::Bool.optional
        attribute :require_uppercase, Resources::Types::Bool.optional
        attribute :temporary_password_validity_days, Resources::Types::Integer.optional.constrained(gteq: 0, lteq: 365)
      end

      # MFA configuration for user pool
      class CognitoUserPoolMfaConfiguration < Dry::Struct
        attribute :mfa, Resources::Types::String.enum('ON', 'OFF', 'OPTIONAL').default('OFF')
        attribute :sms_configuration, Resources::Types::Hash.schema(
          external_id?: Types::String.optional,
          sns_caller_arn: Types::String
        ).optional
        attribute :software_token_mfa_configuration, Resources::Types::Hash.schema(
          enabled: Types::Bool
        ).optional
      end

      # User pool device configuration
      class CognitoUserPoolDeviceConfiguration < Dry::Struct
        attribute :challenge_required_on_new_device, Resources::Types::Bool.optional
        attribute :device_only_remembered_on_user_prompt, Resources::Types::Bool.optional
      end

      # Email configuration for user pool
      class CognitoUserPoolEmailConfiguration < Dry::Struct
        attribute :configuration_set, Resources::Types::String.optional
        attribute :email_sending_account, Resources::Types::String.enum('COGNITO_DEFAULT', 'DEVELOPER').default('COGNITO_DEFAULT')
        attribute :from_email_address, Resources::Types::String.optional
        attribute :reply_to_email_address, Resources::Types::String.optional
        attribute :source_arn, Resources::Types::String.optional
      end

      # SMS configuration for user pool
      class CognitoUserPoolSmsConfiguration < Dry::Struct
        attribute :external_id, Resources::Types::String
        attribute :sns_caller_arn, Resources::Types::String
        attribute :sns_region, Resources::Types::String.optional
      end

      # Lambda configuration triggers
      class CognitoUserPoolLambdaConfig < Dry::Struct
        attribute :create_auth_challenge, Resources::Types::String.optional
        attribute :custom_message, Resources::Types::String.optional
        attribute :define_auth_challenge, Resources::Types::String.optional
        attribute :post_authentication, Resources::Types::String.optional
        attribute :post_confirmation, Resources::Types::String.optional
        attribute :pre_authentication, Resources::Types::String.optional
        attribute :pre_sign_up, Resources::Types::String.optional
        attribute :pre_token_generation, Resources::Types::String.optional
        attribute :user_migration, Resources::Types::String.optional
        attribute :verify_auth_challenge_response, Resources::Types::String.optional
        attribute :kms_key_id, Resources::Types::String.optional
      end

      # User pool schema attribute  
      class CognitoUserPoolSchemaAttribute < Dry::Struct
        attribute :attribute_data_type, Resources::Types::String.enum('String', 'Number', 'DateTime', 'Boolean')
        attribute :name, Resources::Types::String
        attribute :developer_only_attribute, Resources::Types::Bool.optional
        attribute :mutable, Resources::Types::Bool.optional
        attribute :required, Resources::Types::Bool.optional
        
        attribute :number_attribute_constraints, Resources::Types::Hash.schema(
          max_value?: Types::String.optional,
          min_value?: Types::String.optional
        ).optional

        attribute :string_attribute_constraints, Resources::Types::Hash.schema(
          max_length?: Types::String.optional,
          min_length?: Types::String.optional
        ).optional
      end

      # User attribute update settings
      class CognitoUserPoolUserAttributeUpdateSettings < Dry::Struct
        attribute :attributes_require_verification_before_update, Resources::Types::Array.of(Types::String.enum('phone_number', 'email'))
      end

      # User pool verification message template
      class CognitoUserPoolVerificationMessageTemplate < Dry::Struct
        attribute :default_email_option, Resources::Types::String.enum('CONFIRM_WITH_LINK', 'CONFIRM_WITH_CODE').optional
        attribute :email_message, Resources::Types::String.optional
        attribute :email_message_by_link, Resources::Types::String.optional
        attribute :email_subject, Resources::Types::String.optional
        attribute :email_subject_by_link, Resources::Types::String.optional
        attribute :sms_message, Resources::Types::String.optional
      end

      # Account recovery setting
      class CognitoUserPoolAccountRecoverySetting < Dry::Struct
        attribute :recovery_mechanisms, Resources::Types::Array.of(
          Types::Hash.schema(
            name: Types::String.enum('verified_email', 'verified_phone_number', 'admin_only'),
            priority: Types::Integer.constrained(gteq: 1, lteq: 2)
          )
        ).constrained(min_size: 1, max_size: 2)
      end

      # Admin create user config
      class CognitoUserPoolAdminCreateUserConfig < Dry::Struct
        attribute :allow_admin_create_user_only, Resources::Types::Bool.optional
        attribute :invite_message_template, Resources::Types::Hash.schema(
          email_message?: Types::String.optional,
          email_subject?: Types::String.optional,
          sms_message?: Types::String.optional
        ).optional
        attribute :unused_account_validity_days, Resources::Types::Integer.optional.constrained(gteq: 0, lteq: 365)
      end

      # User pool add-ons configuration
      class CognitoUserPoolUserPoolAddOns < Dry::Struct
        attribute :advanced_security_mode, Resources::Types::String.enum('OFF', 'AUDIT', 'ENFORCED')
      end

      # Type-safe attributes for AWS Cognito User Pool resources
      class CognitoUserPoolAttributes < Dry::Struct
        # Pool name (optional, AWS will generate if not provided)
        attribute :name, Resources::Types::String.optional

        # Alias attributes for sign-in
        attribute :alias_attributes, Resources::Types::Array.of(Types::String.enum('phone_number', 'email', 'preferred_username')).optional

        # Auto-verified attributes
        attribute :auto_verified_attributes, Resources::Types::Array.of(Types::String.enum('phone_number', 'email')).optional

        # Username configuration
        attribute :username_attributes, Resources::Types::Array.of(Types::String.enum('phone_number', 'email')).optional
        attribute :username_configuration, Resources::Types::Hash.schema(
          case_sensitive: Types::Bool
        ).optional

        # Password policy
        attribute? :password_policy, CognitoUserPoolPasswordPolicy.optional

        # MFA configuration
        attribute :mfa_configuration, Resources::Types::String.enum('ON', 'OFF', 'OPTIONAL').default('OFF')
        attribute :sms_authentication_message, Resources::Types::String.optional
        attribute? :sms_configuration, CognitoUserPoolSmsConfiguration.optional
        attribute :software_token_mfa_configuration, Resources::Types::Hash.schema(
          enabled: Types::Bool
        ).optional

        # Device configuration
        attribute? :device_configuration, CognitoUserPoolDeviceConfiguration.optional

        # Email configuration
        attribute? :email_configuration, CognitoUserPoolEmailConfiguration.optional
        attribute :email_verification_message, Resources::Types::String.optional
        attribute :email_verification_subject, Resources::Types::String.optional

        # SMS verification
        attribute :sms_verification_message, Resources::Types::String.optional

        # Lambda triggers
        attribute? :lambda_config, CognitoUserPoolLambdaConfig.optional

        # User pool schema
        attribute :schema, Resources::Types::Array.of(CognitoUserPoolSchemaAttribute).optional

        # User attribute update settings
        attribute? :user_attribute_update_settings, CognitoUserPoolUserAttributeUpdateSettings.optional

        # Verification message template
        attribute? :verification_message_template, CognitoUserPoolVerificationMessageTemplate.optional

        # Account recovery
        attribute? :account_recovery_setting, CognitoUserPoolAccountRecoverySetting.optional

        # Admin create user config
        attribute? :admin_create_user_config, CognitoUserPoolAdminCreateUserConfig.optional

        # User pool add-ons
        attribute? :user_pool_add_ons, CognitoUserPoolUserPoolAddOns.optional

        # Tags
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Deletion protection
        attribute :deletion_protection, Resources::Types::String.enum('ACTIVE', 'INACTIVE').default('INACTIVE')

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate account recovery mechanisms have unique priorities
          if attrs.account_recovery_setting
            priorities = attrs.account_recovery_setting.recovery_mechanisms.map { |m| m[:priority] }
            if priorities.length != priorities.uniq.length
              raise Dry::Struct::Error, "Account recovery mechanisms must have unique priorities"
            end
          end

          # Validate username attributes compatibility
          if attrs.username_attributes && attrs.alias_attributes
            overlap = attrs.username_attributes & attrs.alias_attributes
            unless overlap.empty?
              raise Dry::Struct::Error, "Cannot specify the same attribute in both username_attributes and alias_attributes"
            end
          end

          attrs
        end

        # Check if pool uses email for authentication
        def uses_email_auth?
          return false unless username_attributes || alias_attributes
          
          auth_attrs = (username_attributes || []) + (alias_attributes || [])
          auth_attrs.include?('email')
        end

        # Check if pool uses phone for authentication  
        def uses_phone_auth?
          return false unless username_attributes || alias_attributes
          
          auth_attrs = (username_attributes || []) + (alias_attributes || [])
          auth_attrs.include?('phone_number')
        end

        # Check if MFA is enabled
        def mfa_enabled?
          mfa_configuration == 'ON'
        end

        # Check if MFA is optional
        def mfa_optional?
          mfa_configuration == 'OPTIONAL'
        end

        # Get primary authentication method
        def primary_auth_method
          return :username if username_attributes.nil? && alias_attributes.nil?
          
          auth_attrs = username_attributes || alias_attributes || []
          return :email if auth_attrs.include?('email')
          return :phone if auth_attrs.include?('phone_number')
          return :username
        end

        # Check if advanced security features are enabled
        def advanced_security_enabled?
          user_pool_add_ons&.advanced_security_mode != 'OFF'
        end
      end

      # Pre-configured user pool templates for common scenarios
      module UserPoolTemplates
        # Basic email/password authentication
        def self.basic_email_auth(pool_name)
          {
            name: pool_name,
            username_attributes: ['email'],
            auto_verified_attributes: ['email'],
            password_policy: {
              minimum_length: 8,
              require_lowercase: true,
              require_uppercase: true,
              require_numbers: true
            },
            account_recovery_setting: {
              recovery_mechanisms: [
                { name: 'verified_email', priority: 1 }
              ]
            },
            admin_create_user_config: {
              allow_admin_create_user_only: false
            }
          }
        end

        # SMS/phone-based authentication
        def self.phone_auth(pool_name, sns_role_arn)
          {
            name: pool_name,
            username_attributes: ['phone_number'],
            auto_verified_attributes: ['phone_number'],
            sms_configuration: {
              external_id: "#{pool_name}-external",
              sns_caller_arn: sns_role_arn
            },
            account_recovery_setting: {
              recovery_mechanisms: [
                { name: 'verified_phone_number', priority: 1 }
              ]
            }
          }
        end

        # Multi-factor authentication enabled
        def self.mfa_enabled(pool_name)
          basic_email_auth(pool_name).merge(
            mfa_configuration: 'ON',
            software_token_mfa_configuration: { enabled: true }
          )
        end

        # Enterprise with advanced security
        def self.enterprise_security(pool_name)
          basic_email_auth(pool_name).merge(
            user_pool_add_ons: {
              advanced_security_mode: 'ENFORCED'
            },
            mfa_configuration: 'OPTIONAL',
            device_configuration: {
              challenge_required_on_new_device: true,
              device_only_remembered_on_user_prompt: true
            }
          )
        end

        # Social sign-in focused (minimal local auth)
        def self.social_signin(pool_name)
          {
            name: pool_name,
            username_attributes: ['email'],
            auto_verified_attributes: ['email'],
            admin_create_user_config: {
              allow_admin_create_user_only: true
            },
            account_recovery_setting: {
              recovery_mechanisms: [
                { name: 'admin_only', priority: 1 }
              ]
            }
          }
        end
      end
    end
      end
    end
  end
end