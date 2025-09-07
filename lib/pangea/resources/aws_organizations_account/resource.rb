# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_organizations_account/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      def aws_organizations_account(name, attributes = {})
        account_attrs = Types::Types::OrganizationsAccountAttributes.new(attributes)
        
        resource(:aws_organizations_account, name) do
          name account_attrs.name
          email account_attrs.email
          iam_user_access_to_billing account_attrs.iam_user_access_to_billing
          parent_id account_attrs.parent_id if account_attrs.has_parent_id?
          role_name account_attrs.role_name if account_attrs.role_name
          close_on_deletion account_attrs.close_on_deletion
          
          if account_attrs.tags.any?
            tags do
              account_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        ResourceReference.new(
          type: 'aws_organizations_account',
          name: name,
          resource_attributes: account_attrs.to_h,
          outputs: {
            id: "${aws_organizations_account.#{name}.id}",
            arn: "${aws_organizations_account.#{name}.arn}",
            email: "${aws_organizations_account.#{name}.email}",
            name: "${aws_organizations_account.#{name}.name}",
            status: "${aws_organizations_account.#{name}.status}",
            tags_all: "${aws_organizations_account.#{name}.tags_all}"
          },
          computed_properties: {
            has_parent_id: account_attrs.has_parent_id?,
            allows_billing_access: account_attrs.allows_billing_access?,
            estimated_monthly_cost_usd: account_attrs.estimated_monthly_cost_usd
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)