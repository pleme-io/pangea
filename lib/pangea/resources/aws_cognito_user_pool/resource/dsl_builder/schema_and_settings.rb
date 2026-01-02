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

module Pangea
  module Resources
    module AWS
      module CognitoUserPool
        class DSLBuilder
          # Schema and user settings configuration building methods
          module SchemaAndSettings
            def build_schema(ctx)
              return unless attrs.schema

              attrs.schema.each do |schema_attr|
                ctx.schema do
                  attribute_data_type schema_attr.attribute_data_type
                  name schema_attr.name
                  developer_only_attribute schema_attr.developer_only_attribute if schema_attr.developer_only_attribute
                  mutable schema_attr.mutable if schema_attr.mutable
                  required schema_attr.required if schema_attr.required
                  build_number_constraints(self, schema_attr)
                  build_string_constraints(self, schema_attr)
                end
              end
            end

            def build_user_settings(ctx)
              build_user_attribute_update_settings(ctx)
              build_verification_message_template(ctx)
              build_account_recovery(ctx)
              build_admin_create_user_config(ctx)
              build_user_pool_add_ons(ctx)
            end

            def build_tags(ctx)
              return unless attrs.tags.any?

              ctx.tags do
                attrs.tags.each { |key, value| public_send(key, value) }
              end
            end

            private

            def build_number_constraints(ctx, schema_attr)
              return unless schema_attr.number_attribute_constraints

              constraints = schema_attr.number_attribute_constraints
              ctx.number_attribute_constraints do
                max_value constraints[:max_value] if constraints[:max_value]
                min_value constraints[:min_value] if constraints[:min_value]
              end
            end

            def build_string_constraints(ctx, schema_attr)
              return unless schema_attr.string_attribute_constraints

              constraints = schema_attr.string_attribute_constraints
              ctx.string_attribute_constraints do
                max_length constraints[:max_length] if constraints[:max_length]
                min_length constraints[:min_length] if constraints[:min_length]
              end
            end

            def build_user_attribute_update_settings(ctx)
              return unless attrs.user_attribute_update_settings

              ctx.user_attribute_update_settings do
                attributes_require_verification_before_update attrs.user_attribute_update_settings.attributes_require_verification_before_update
              end
            end

            def build_verification_message_template(ctx)
              return unless attrs.verification_message_template

              template = attrs.verification_message_template
              ctx.verification_message_template do
                default_email_option template.default_email_option if template.default_email_option
                email_message template.email_message if template.email_message
                email_message_by_link template.email_message_by_link if template.email_message_by_link
                email_subject template.email_subject if template.email_subject
                email_subject_by_link template.email_subject_by_link if template.email_subject_by_link
                sms_message template.sms_message if template.sms_message
              end
            end

            def build_account_recovery(ctx)
              return unless attrs.account_recovery_setting

              ctx.account_recovery_setting do
                attrs.account_recovery_setting.recovery_mechanisms.each do |mechanism|
                  recovery_mechanism do
                    name mechanism[:name]
                    priority mechanism[:priority]
                  end
                end
              end
            end

            def build_admin_create_user_config(ctx)
              return unless attrs.admin_create_user_config

              config = attrs.admin_create_user_config
              ctx.admin_create_user_config do
                allow_admin_create_user_only config.allow_admin_create_user_only if config.allow_admin_create_user_only
                unused_account_validity_days config.unused_account_validity_days if config.unused_account_validity_days
                build_invite_message_template(self, config.invite_message_template)
              end
            end

            def build_invite_message_template(ctx, template)
              return unless template

              ctx.invite_message_template do
                email_message template[:email_message] if template[:email_message]
                email_subject template[:email_subject] if template[:email_subject]
                sms_message template[:sms_message] if template[:sms_message]
              end
            end

            def build_user_pool_add_ons(ctx)
              return unless attrs.user_pool_add_ons

              ctx.user_pool_add_ons do
                advanced_security_mode attrs.user_pool_add_ons.advanced_security_mode
              end
            end
          end
        end
      end
    end
  end
end
