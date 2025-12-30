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
require_relative 'types/trust_policies'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS IAM Role resources
        class IamRoleAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Role name (optional, AWS will generate if not provided)
          attribute :name, Resources::Types::String.optional

          # Role name prefix (optional, alternative to name)
          attribute :name_prefix, Resources::Types::String.optional

          # Path for the role (default: "/")
          attribute :path, Resources::Types::String.default("/")

          # Description of the role
          attribute :description, Resources::Types::String.optional

          # Assume role policy document (required)
          # Can be a Hash or a policy document structure
          attribute :assume_role_policy, Resources::Types::Hash.schema(
            Version: Types::String.default("2012-10-17"),
            Statement: Types::Array.of(
              Types::Hash.schema(
                Effect: Types::String.enum("Allow", "Deny"),
                Principal: Types::Hash.schema(
                  Service?: Types::String | Types::Array.of(Types::String),
                  AWS?: Types::String | Types::Array.of(Types::String),
                  Federated?: Types::String | Types::Array.of(Types::String)
                ).optional,
                Action: Types::String | Types::Array.of(Types::String),
                Condition?: Types::Hash.optional
              )
            )
          )

          # Force detach policies on deletion
          attribute :force_detach_policies, Resources::Types::Bool.default(false)

          # Maximum session duration in seconds (1 hour to 12 hours)
          attribute :max_session_duration, Resources::Types::Integer.default(3600).constrained(gteq: 3600, lteq: 43200)

          # Permissions boundary ARN
          attribute :permissions_boundary, Resources::Types::String.optional

          # Inline policies (policy name => policy document)
          attribute :inline_policies, Resources::Types::Hash.default({}.freeze)

          # Tags to apply to the role
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)

            # Cannot specify both name and name_prefix
            if attrs.name && attrs.name_prefix
              raise Dry::Struct::Error, "Cannot specify both 'name' and 'name_prefix'"
            end

            # Validate assume role policy has at least one statement
            if attrs.assume_role_policy[:Statement].empty?
              raise Dry::Struct::Error, "Assume role policy must have at least one statement"
            end

            attrs
          end

          # Helper method to extract service principal from assume role policy
          def service_principal
            statements = assume_role_policy[:Statement]
            return nil if statements.empty?

            first_statement = statements.first
            principal = first_statement[:Principal]
            return nil unless principal

            if principal[:Service].is_a?(String)
              principal[:Service]
            elsif principal[:Service].is_a?(Array)
              principal[:Service].first
            end
          end

          # Check if this is a service role (vs user/federated role)
          def is_service_role?
            statements = assume_role_policy[:Statement]
            return false if statements.empty?

            statements.any? do |statement|
              statement[:Principal] && statement[:Principal][:Service]
            end
          end

          # Check if this is a federated role
          def is_federated_role?
            statements = assume_role_policy[:Statement]
            return false if statements.empty?

            statements.any? do |statement|
              statement[:Principal] && statement[:Principal][:Federated]
            end
          end

          # Determine trust policy type
          def trust_policy_type
            if is_service_role?
              :service
            elsif is_federated_role?
              :federated
            else
              :aws_account
            end
          end
        end

        # Common IAM policy document structure
        class IamPolicyDocument < Dry::Struct
          attribute :Version, Resources::Types::String.default("2012-10-17")
          attribute :Statement, Resources::Types::Array.of(
            Types::Hash.schema(
              Sid?: Types::String.optional,
              Effect: Types::String.enum("Allow", "Deny"),
              Action: Types::String | Types::Array.of(Types::String),
              Resource: Types::String | Types::Array.of(Types::String),
              Condition?: Types::Hash.optional
            )
          )
        end
      end
    end
  end
end
