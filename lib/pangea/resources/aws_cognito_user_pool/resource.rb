# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_cognito_user_pool/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Cognito User Pool with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Cognito user pool attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_cognito_user_pool(name, attributes = {})
        # Validate attributes using dry-struct
        user_pool_attrs = Types::CognitoUserPoolAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_cognito_user_pool, name) do
          pool_name user_pool_attrs.name if user_pool_attrs.name
          
          # Alias and username configuration
          if user_pool_attrs.alias_attributes
            alias_attributes user_pool_attrs.alias_attributes
          end
          
          if user_pool_attrs.auto_verified_attributes
            auto_verified_attributes user_pool_attrs.auto_verified_attributes
          end

          if user_pool_attrs.username_attributes
            username_attributes user_pool_attrs.username_attributes
          end

          if user_pool_attrs.username_configuration
            username_configuration do
              case_sensitive user_pool_attrs.username_configuration[:case_sensitive]
            end
          end

          # Password policy
          if user_pool_attrs.password_policy
            password_policy do
              minimum_length user_pool_attrs.password_policy.minimum_length
              require_lowercase user_pool_attrs.password_policy.require_lowercase if user_pool_attrs.password_policy.require_lowercase
              require_numbers user_pool_attrs.password_policy.require_numbers if user_pool_attrs.password_policy.require_numbers
              require_symbols user_pool_attrs.password_policy.require_symbols if user_pool_attrs.password_policy.require_symbols
              require_uppercase user_pool_attrs.password_policy.require_uppercase if user_pool_attrs.password_policy.require_uppercase
              temporary_password_validity_days user_pool_attrs.password_policy.temporary_password_validity_days if user_pool_attrs.password_policy.temporary_password_validity_days
            end
          end

          # MFA configuration
          mfa_configuration user_pool_attrs.mfa_configuration
          sms_authentication_message user_pool_attrs.sms_authentication_message if user_pool_attrs.sms_authentication_message

          if user_pool_attrs.sms_configuration
            sms_configuration do
              external_id user_pool_attrs.sms_configuration.external_id
              sns_caller_arn user_pool_attrs.sms_configuration.sns_caller_arn
              sns_region user_pool_attrs.sms_configuration.sns_region if user_pool_attrs.sms_configuration.sns_region
            end
          end

          if user_pool_attrs.software_token_mfa_configuration
            software_token_mfa_configuration do
              enabled user_pool_attrs.software_token_mfa_configuration[:enabled]
            end
          end

          # Device configuration
          if user_pool_attrs.device_configuration
            device_configuration do
              challenge_required_on_new_device user_pool_attrs.device_configuration.challenge_required_on_new_device if user_pool_attrs.device_configuration.challenge_required_on_new_device
              device_only_remembered_on_user_prompt user_pool_attrs.device_configuration.device_only_remembered_on_user_prompt if user_pool_attrs.device_configuration.device_only_remembered_on_user_prompt
            end
          end

          # Email configuration
          if user_pool_attrs.email_configuration
            email_configuration do
              configuration_set user_pool_attrs.email_configuration.configuration_set if user_pool_attrs.email_configuration.configuration_set
              email_sending_account user_pool_attrs.email_configuration.email_sending_account
              from_email_address user_pool_attrs.email_configuration.from_email_address if user_pool_attrs.email_configuration.from_email_address
              reply_to_email_address user_pool_attrs.email_configuration.reply_to_email_address if user_pool_attrs.email_configuration.reply_to_email_address
              source_arn user_pool_attrs.email_configuration.source_arn if user_pool_attrs.email_configuration.source_arn
            end
          end

          email_verification_message user_pool_attrs.email_verification_message if user_pool_attrs.email_verification_message
          email_verification_subject user_pool_attrs.email_verification_subject if user_pool_attrs.email_verification_subject
          sms_verification_message user_pool_attrs.sms_verification_message if user_pool_attrs.sms_verification_message

          # Lambda configuration
          if user_pool_attrs.lambda_config
            lambda_config do
              create_auth_challenge user_pool_attrs.lambda_config.create_auth_challenge if user_pool_attrs.lambda_config.create_auth_challenge
              custom_message user_pool_attrs.lambda_config.custom_message if user_pool_attrs.lambda_config.custom_message
              define_auth_challenge user_pool_attrs.lambda_config.define_auth_challenge if user_pool_attrs.lambda_config.define_auth_challenge
              post_authentication user_pool_attrs.lambda_config.post_authentication if user_pool_attrs.lambda_config.post_authentication
              post_confirmation user_pool_attrs.lambda_config.post_confirmation if user_pool_attrs.lambda_config.post_confirmation
              pre_authentication user_pool_attrs.lambda_config.pre_authentication if user_pool_attrs.lambda_config.pre_authentication
              pre_sign_up user_pool_attrs.lambda_config.pre_sign_up if user_pool_attrs.lambda_config.pre_sign_up
              pre_token_generation user_pool_attrs.lambda_config.pre_token_generation if user_pool_attrs.lambda_config.pre_token_generation
              user_migration user_pool_attrs.lambda_config.user_migration if user_pool_attrs.lambda_config.user_migration
              verify_auth_challenge_response user_pool_attrs.lambda_config.verify_auth_challenge_response if user_pool_attrs.lambda_config.verify_auth_challenge_response
              kms_key_id user_pool_attrs.lambda_config.kms_key_id if user_pool_attrs.lambda_config.kms_key_id
            end
          end

          # Schema configuration
          if user_pool_attrs.schema
            user_pool_attrs.schema.each do |schema_attr|
              schema do
                attribute_data_type schema_attr.attribute_data_type
                name schema_attr.name
                developer_only_attribute schema_attr.developer_only_attribute if schema_attr.developer_only_attribute
                mutable schema_attr.mutable if schema_attr.mutable
                required schema_attr.required if schema_attr.required

                if schema_attr.number_attribute_constraints
                  number_attribute_constraints do
                    max_value schema_attr.number_attribute_constraints[:max_value] if schema_attr.number_attribute_constraints[:max_value]
                    min_value schema_attr.number_attribute_constraints[:min_value] if schema_attr.number_attribute_constraints[:min_value]
                  end
                end

                if schema_attr.string_attribute_constraints
                  string_attribute_constraints do
                    max_length schema_attr.string_attribute_constraints[:max_length] if schema_attr.string_attribute_constraints[:max_length]
                    min_length schema_attr.string_attribute_constraints[:min_length] if schema_attr.string_attribute_constraints[:min_length]
                  end
                end
              end
            end
          end

          # User attribute update settings
          if user_pool_attrs.user_attribute_update_settings
            user_attribute_update_settings do
              attributes_require_verification_before_update user_pool_attrs.user_attribute_update_settings.attributes_require_verification_before_update
            end
          end

          # Verification message template
          if user_pool_attrs.verification_message_template
            verification_message_template do
              default_email_option user_pool_attrs.verification_message_template.default_email_option if user_pool_attrs.verification_message_template.default_email_option
              email_message user_pool_attrs.verification_message_template.email_message if user_pool_attrs.verification_message_template.email_message
              email_message_by_link user_pool_attrs.verification_message_template.email_message_by_link if user_pool_attrs.verification_message_template.email_message_by_link
              email_subject user_pool_attrs.verification_message_template.email_subject if user_pool_attrs.verification_message_template.email_subject
              email_subject_by_link user_pool_attrs.verification_message_template.email_subject_by_link if user_pool_attrs.verification_message_template.email_subject_by_link
              sms_message user_pool_attrs.verification_message_template.sms_message if user_pool_attrs.verification_message_template.sms_message
            end
          end

          # Account recovery
          if user_pool_attrs.account_recovery_setting
            account_recovery_setting do
              user_pool_attrs.account_recovery_setting.recovery_mechanisms.each do |mechanism|
                recovery_mechanism do
                  name mechanism[:name]
                  priority mechanism[:priority]
                end
              end
            end
          end

          # Admin create user config
          if user_pool_attrs.admin_create_user_config
            admin_create_user_config do
              allow_admin_create_user_only user_pool_attrs.admin_create_user_config.allow_admin_create_user_only if user_pool_attrs.admin_create_user_config.allow_admin_create_user_only
              unused_account_validity_days user_pool_attrs.admin_create_user_config.unused_account_validity_days if user_pool_attrs.admin_create_user_config.unused_account_validity_days
              
              if user_pool_attrs.admin_create_user_config.invite_message_template
                invite_message_template do
                  email_message user_pool_attrs.admin_create_user_config.invite_message_template[:email_message] if user_pool_attrs.admin_create_user_config.invite_message_template[:email_message]
                  email_subject user_pool_attrs.admin_create_user_config.invite_message_template[:email_subject] if user_pool_attrs.admin_create_user_config.invite_message_template[:email_subject]
                  sms_message user_pool_attrs.admin_create_user_config.invite_message_template[:sms_message] if user_pool_attrs.admin_create_user_config.invite_message_template[:sms_message]
                end
              end
            end
          end

          # User pool add-ons
          if user_pool_attrs.user_pool_add_ons
            user_pool_add_ons do
              advanced_security_mode user_pool_attrs.user_pool_add_ons.advanced_security_mode
            end
          end

          deletion_protection user_pool_attrs.deletion_protection

          # Apply tags if present
          if user_pool_attrs.tags.any?
            tags do
              user_pool_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_cognito_user_pool',
          name: name,
          resource_attributes: user_pool_attrs.to_h,
          outputs: {
            id: "${aws_cognito_user_pool.#{name}.id}",
            arn: "${aws_cognito_user_pool.#{name}.arn}",
            creation_date: "${aws_cognito_user_pool.#{name}.creation_date}",
            custom_domain: "${aws_cognito_user_pool.#{name}.custom_domain}",
            domain: "${aws_cognito_user_pool.#{name}.domain}",
            endpoint: "${aws_cognito_user_pool.#{name}.endpoint}",
            estimated_number_of_users: "${aws_cognito_user_pool.#{name}.estimated_number_of_users}",
            last_modified_date: "${aws_cognito_user_pool.#{name}.last_modified_date}",
            name: "${aws_cognito_user_pool.#{name}.name}"
          },
          computed_properties: {
            uses_email_auth: user_pool_attrs.uses_email_auth?,
            uses_phone_auth: user_pool_attrs.uses_phone_auth?,
            mfa_enabled: user_pool_attrs.mfa_enabled?,
            mfa_optional: user_pool_attrs.mfa_optional?,
            primary_auth_method: user_pool_attrs.primary_auth_method,
            advanced_security_enabled: user_pool_attrs.advanced_security_enabled?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)