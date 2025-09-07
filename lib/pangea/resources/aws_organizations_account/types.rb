# frozen_string_literal: true

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