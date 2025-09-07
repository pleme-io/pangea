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
      # User attribute configuration
      class CognitoUserAttribute < Dry::Struct
        attribute :name, Resources::Types::String
        attribute :value, Resources::Types::String
      end

      # Type-safe attributes for AWS Cognito User resources
      class CognitoUserAttributes < Dry::Struct
        # Username (required)
        attribute :username, Resources::Types::String

        # User pool ID (required)
        attribute :user_pool_id, Resources::Types::String

        # User attributes
        attribute :attributes, Resources::Types::Hash.optional

        # Temporary password for user
        attribute :temporary_password, Resources::Types::String.optional

        # Whether to force password change on first login
        attribute :force_alias_creation, Resources::Types::Bool.default(false)

        # Message action for user creation
        attribute :message_action, Resources::Types::String.enum('RESEND', 'SUPPRESS').optional

        # Desired delivery mediums
        attribute :desired_delivery_mediums, Resources::Types::Array.of(Types::String.enum('SMS', 'EMAIL')).optional

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate username format
          unless attrs.username.match?(/\A[\w\.\-@]+\z/)
            raise Dry::Struct::Error, "Username can only contain word characters, periods, hyphens, and at symbols"
          end

          # Validate email format if provided in attributes
          if attrs.attributes && attrs.attributes['email']
            email = attrs.attributes['email']
            unless email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
              raise Dry::Struct::Error, "Invalid email format in user attributes"
            end
          end

          attrs
        end

        # Check if user has email attribute
        def has_email?
          attributes&.key?('email')
        end

        # Check if user has phone number
        def has_phone_number?
          attributes&.key?('phone_number')
        end

        # Check if user has custom attributes
        def has_custom_attributes?
          return false unless attributes

          attributes.keys.any? { |key| key.start_with?('custom:') }
        end

        # Get custom attributes only
        def custom_attributes
          return {} unless attributes

          attributes.select { |key, _| key.start_with?('custom:') }
        end

        # Get standard attributes only
        def standard_attributes
          return {} unless attributes

          attributes.reject { |key, _| key.start_with?('custom:') }
        end
      end

      # Pre-configured user templates
      module UserTemplates
        # Standard user with email
        def self.email_user(username, user_pool_id, email, name = nil, temporary_password = nil)
          attrs = {
            'email' => email,
            'email_verified' => 'true'
          }
          attrs['name'] = name if name

          {
            username: username,
            user_pool_id: user_pool_id,
            attributes: attrs,
            temporary_password: temporary_password,
            desired_delivery_mediums: ['EMAIL']
          }
        end

        # Admin user with elevated attributes
        def self.admin_user(username, user_pool_id, email, name, temporary_password = nil)
          {
            username: username,
            user_pool_id: user_pool_id,
            attributes: {
              'email' => email,
              'email_verified' => 'true',
              'name' => name,
              'custom:role' => 'admin',
              'custom:created_by' => 'system'
            },
            temporary_password: temporary_password,
            desired_delivery_mediums: ['EMAIL'],
            force_alias_creation: true
          }
        end
      end
    end
      end
    end
  end
end