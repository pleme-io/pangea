# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'pangea/resources/types'
require_relative 'nested_types'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS Cognito User Pool resources
        class CognitoUserPoolAttributes < Dry::Struct
          attribute :name, Resources::Types::String.optional
          attribute :alias_attributes, Resources::Types::Array.of(Types::String.enum('phone_number', 'email', 'preferred_username')).optional
          attribute :auto_verified_attributes, Resources::Types::Array.of(Types::String.enum('phone_number', 'email')).optional
          attribute :username_attributes, Resources::Types::Array.of(Types::String.enum('phone_number', 'email')).optional
          attribute :username_configuration, Resources::Types::Hash.schema(case_sensitive: Types::Bool).optional
          attribute? :password_policy, CognitoUserPoolPasswordPolicy.optional
          attribute :mfa_configuration, Resources::Types::String.enum('ON', 'OFF', 'OPTIONAL').default('OFF')
          attribute :sms_authentication_message, Resources::Types::String.optional
          attribute? :sms_configuration, CognitoUserPoolSmsConfiguration.optional
          attribute :software_token_mfa_configuration, Resources::Types::Hash.schema(enabled: Types::Bool).optional
          attribute? :device_configuration, CognitoUserPoolDeviceConfiguration.optional
          attribute? :email_configuration, CognitoUserPoolEmailConfiguration.optional
          attribute :email_verification_message, Resources::Types::String.optional
          attribute :email_verification_subject, Resources::Types::String.optional
          attribute :sms_verification_message, Resources::Types::String.optional
          attribute? :lambda_config, CognitoUserPoolLambdaConfig.optional
          attribute :schema, Resources::Types::Array.of(CognitoUserPoolSchemaAttribute).optional
          attribute? :user_attribute_update_settings, CognitoUserPoolUserAttributeUpdateSettings.optional
          attribute? :verification_message_template, CognitoUserPoolVerificationMessageTemplate.optional
          attribute? :account_recovery_setting, CognitoUserPoolAccountRecoverySetting.optional
          attribute? :admin_create_user_config, CognitoUserPoolAdminCreateUserConfig.optional
          attribute? :user_pool_add_ons, CognitoUserPoolUserPoolAddOns.optional
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)
          attribute :deletion_protection, Resources::Types::String.enum('ACTIVE', 'INACTIVE').default('INACTIVE')

          def self.new(attributes = {})
            attrs = super(attributes)

            if attrs.account_recovery_setting
              priorities = attrs.account_recovery_setting.recovery_mechanisms.map { |m| m[:priority] }
              raise Dry::Struct::Error, 'Account recovery mechanisms must have unique priorities' if priorities.length != priorities.uniq.length
            end

            if attrs.username_attributes && attrs.alias_attributes
              overlap = attrs.username_attributes & attrs.alias_attributes
              raise Dry::Struct::Error, 'Cannot specify the same attribute in both username_attributes and alias_attributes' unless overlap.empty?
            end

            attrs
          end

          def uses_email_auth?
            return false unless username_attributes || alias_attributes

            ((username_attributes || []) + (alias_attributes || [])).include?('email')
          end

          def uses_phone_auth?
            return false unless username_attributes || alias_attributes

            ((username_attributes || []) + (alias_attributes || [])).include?('phone_number')
          end

          def mfa_enabled? = mfa_configuration == 'ON'
          def mfa_optional? = mfa_configuration == 'OPTIONAL'

          def primary_auth_method
            return :username if username_attributes.nil? && alias_attributes.nil?

            auth_attrs = username_attributes || alias_attributes || []
            return :email if auth_attrs.include?('email')
            return :phone if auth_attrs.include?('phone_number')

            :username
          end

          def advanced_security_enabled?
            user_pool_add_ons&.advanced_security_mode != 'OFF'
          end
        end
      end
    end
  end
end
