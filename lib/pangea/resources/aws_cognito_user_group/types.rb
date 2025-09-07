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
      # Type-safe attributes for AWS Cognito User Group resources
      class CognitoUserGroupAttributes < Dry::Struct
        # Group name (required)
        attribute :name, Resources::Types::String

        # User pool ID (required)
        attribute :user_pool_id, Resources::Types::String

        # Group description
        attribute :description, Resources::Types::String.optional

        # Group precedence (lower number = higher precedence)
        attribute :precedence, Resources::Types::Integer.optional.constrained(gteq: 0)

        # IAM role ARN for group members
        attribute :role_arn, Resources::Types::String.optional

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate group name
          unless attrs.name.match?(/\A[\w\+=,.@-]+\z/)
            raise Dry::Struct::Error, "Group name can only contain word characters, plus, equals, comma, period, at, hyphen"
          end

          # Validate role ARN format if provided
          if attrs.role_arn && !attrs.role_arn.match?(/\Aarn:aws:iam::\d{12}:role\/.+\z/)
            raise Dry::Struct::Error, "Invalid IAM role ARN format"
          end

          attrs
        end

        # Check if group has an IAM role
        def has_role?
          !role_arn.nil?
        end

        # Check if group has precedence set
        def has_precedence?
          !precedence.nil?
        end

        # Get group type based on configuration
        def group_type
          if has_role? && has_precedence?
            :privileged
          elsif has_role?
            :role_based
          elsif has_precedence?
            :priority_based
          else
            :basic
          end
        end
      end

      # Pre-configured user group templates
      module UserGroupTemplates
        # Admin group with highest precedence
        def self.admin_group(user_pool_id, admin_role_arn)
          {
            name: 'Administrators',
            user_pool_id: user_pool_id,
            description: 'System administrators with full access',
            precedence: 1,
            role_arn: admin_role_arn
          }
        end

        # Manager group with medium precedence
        def self.manager_group(user_pool_id, manager_role_arn)
          {
            name: 'Managers',
            user_pool_id: user_pool_id,
            description: 'Managers with elevated permissions',
            precedence: 10,
            role_arn: manager_role_arn
          }
        end

        # Standard user group
        def self.user_group(user_pool_id, user_role_arn = nil)
          {
            name: 'Users',
            user_pool_id: user_pool_id,
            description: 'Standard application users',
            precedence: 100,
            role_arn: user_role_arn
          }
        end

        # Guest group with lowest precedence
        def self.guest_group(user_pool_id)
          {
            name: 'Guests',
            user_pool_id: user_pool_id,
            description: 'Guest users with limited access',
            precedence: 1000
          }
        end
      end
    end
      end
    end
  end
end