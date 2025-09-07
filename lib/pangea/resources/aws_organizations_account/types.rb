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


require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        class OrganizationsAccountAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :name, Resources::Types::String
          attribute :email, Resources::Types::String
          attribute :iam_user_access_to_billing, Resources::Types::String.default("DENY")
          attribute :parent_id, Resources::Types::String.optional.default(nil)
          attribute :role_name, Resources::Types::String.optional.default("OrganizationAccountAccessRole")
          attribute :close_on_deletion, Resources::Types::Bool.default(false)
          
          attribute :tags, Resources::Types::AwsTags
          
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            if attrs[:email]
              email = attrs[:email]
              unless email.match?(/\A[^@\s]+@[^@\s]+\z/)
                raise Dry::Struct::Error, "Invalid email format"
              end
            end
            
            if attrs[:iam_user_access_to_billing]
              valid_values = ["ALLOW", "DENY"]
              unless valid_values.include?(attrs[:iam_user_access_to_billing])
                raise Dry::Struct::Error, "iam_user_access_to_billing must be ALLOW or DENY"
              end
            end
            
            super(attrs)
          end
          
          def has_parent_id?
            !parent_id.nil?
          end
          
          def allows_billing_access?
            iam_user_access_to_billing == "ALLOW"
          end
          
          def estimated_monthly_cost_usd
            # Account creation and management is free
            # Consider potential service usage costs
            0.0
          end
          
          def to_h
            {
              name: name,
              email: email,
              iam_user_access_to_billing: iam_user_access_to_billing,
              parent_id: parent_id,
              role_name: role_name,
              close_on_deletion: close_on_deletion,
              tags: tags
            }.compact
          end
        end
      end
    end
  end
end