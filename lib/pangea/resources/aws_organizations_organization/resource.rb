# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_organizations_organization/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Organizations Organization with type-safe attributes
      def aws_organizations_organization(name, attributes = {})
        org_attrs = Types::Types::OrganizationsOrganizationAttributes.new(attributes)
        
        resource(:aws_organizations_organization, name) do
          aws_service_access_principals org_attrs.aws_service_access_principals if org_attrs.has_service_access_principals?
          enabled_policy_types org_attrs.enabled_policy_types if org_attrs.has_enabled_policy_types?
          feature_set org_attrs.feature_set
        end
        
        ResourceReference.new(
          type: 'aws_organizations_organization',
          name: name,
          resource_attributes: org_attrs.to_h,
          outputs: {
            id: "${aws_organizations_organization.#{name}.id}",
            arn: "${aws_organizations_organization.#{name}.arn}",
            master_account_arn: "${aws_organizations_organization.#{name}.master_account_arn}",
            master_account_id: "${aws_organizations_organization.#{name}.master_account_id}",
            master_account_email: "${aws_organizations_organization.#{name}.master_account_email}",
            roots: "${aws_organizations_organization.#{name}.roots}",
            accounts: "${aws_organizations_organization.#{name}.accounts}"
          },
          computed_properties: {
            has_all_features: org_attrs.has_all_features?,
            has_service_access_principals: org_attrs.has_service_access_principals?,
            estimated_monthly_cost_usd: org_attrs.estimated_monthly_cost_usd
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)