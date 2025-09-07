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
require 'pangea/resources/aws_cognito_user/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Cognito User with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Cognito user attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_cognito_user(name, attributes = {})
        # Validate attributes using dry-struct
        user_attrs = Types::CognitoUserAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_cognito_user, name) do
          username user_attrs.username
          user_pool_id user_attrs.user_pool_id

          # User attributes
          if user_attrs.attributes && user_attrs.attributes.any?
            attributes do
              user_attrs.attributes.each do |attr_name, attr_value|
                public_send(attr_name.gsub(':', '_'), attr_value)
              end
            end
          end

          temporary_password user_attrs.temporary_password if user_attrs.temporary_password
          force_alias_creation user_attrs.force_alias_creation
          message_action user_attrs.message_action if user_attrs.message_action

          if user_attrs.desired_delivery_mediums
            desired_delivery_mediums user_attrs.desired_delivery_mediums
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_cognito_user',
          name: name,
          resource_attributes: user_attrs.to_h,
          outputs: {
            username: "${aws_cognito_user.#{name}.username}",
            status: "${aws_cognito_user.#{name}.status}",
            sub: "${aws_cognito_user.#{name}.sub}"
          },
          computed_properties: {
            has_email: user_attrs.has_email?,
            has_phone_number: user_attrs.has_phone_number?,
            has_custom_attributes: user_attrs.has_custom_attributes?,
            custom_attributes: user_attrs.custom_attributes,
            standard_attributes: user_attrs.standard_attributes
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)