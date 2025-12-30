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

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_cognito_user_pool/types'
require 'pangea/resource_registry'
require_relative 'resource/dsl_builder'

module Pangea
  module Resources
    module AWS
      # Create an AWS Cognito User Pool with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Cognito user pool attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_cognito_user_pool(name, attributes = {})
        user_pool_attrs = Types::CognitoUserPoolAttributes.new(attributes)
        builder = CognitoUserPool::DSLBuilder.new(user_pool_attrs)

        resource(:aws_cognito_user_pool, name) do
          pool_name user_pool_attrs.name if user_pool_attrs.name
          auto_verified_attributes user_pool_attrs.auto_verified_attributes if user_pool_attrs.auto_verified_attributes

          builder.build_username_config(self)
          builder.build_password_policy(self)
          builder.build_mfa_config(self)
          builder.build_device_configuration(self)
          builder.build_email_config(self)
          builder.build_lambda_config(self)
          builder.build_schema(self)
          builder.build_user_settings(self)

          deletion_protection user_pool_attrs.deletion_protection
          builder.build_tags(self)
        end

        build_cognito_resource_reference(name, user_pool_attrs)
      end

      private

      def build_cognito_resource_reference(name, attrs)
        ResourceReference.new(
          type: 'aws_cognito_user_pool',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: cognito_outputs(name),
          computed_properties: cognito_computed_properties(attrs)
        )
      end

      def cognito_outputs(name)
        {
          id: "${aws_cognito_user_pool.#{name}.id}",
          arn: "${aws_cognito_user_pool.#{name}.arn}",
          creation_date: "${aws_cognito_user_pool.#{name}.creation_date}",
          custom_domain: "${aws_cognito_user_pool.#{name}.custom_domain}",
          domain: "${aws_cognito_user_pool.#{name}.domain}",
          endpoint: "${aws_cognito_user_pool.#{name}.endpoint}",
          estimated_number_of_users: "${aws_cognito_user_pool.#{name}.estimated_number_of_users}",
          last_modified_date: "${aws_cognito_user_pool.#{name}.last_modified_date}",
          name: "${aws_cognito_user_pool.#{name}.name}"
        }
      end

      def cognito_computed_properties(attrs)
        {
          uses_email_auth: attrs.uses_email_auth?,
          uses_phone_auth: attrs.uses_phone_auth?,
          mfa_enabled: attrs.mfa_enabled?,
          mfa_optional: attrs.mfa_optional?,
          primary_auth_method: attrs.primary_auth_method,
          advanced_security_enabled: attrs.advanced_security_enabled?
        }
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)
