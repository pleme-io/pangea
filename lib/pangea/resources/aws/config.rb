# frozen_string_literal: true

require 'pangea/resources/aws/config/organization_conformance_pack'
require 'pangea/resources/aws/config/organization_custom_rule'
require 'pangea/resources/aws/config/organization_managed_rule'
require 'pangea/resources/aws/config/stored_query'
require 'pangea/resources/aws/config/remediation_configuration'
require 'pangea/resources/aws/config/retention_configuration'
require 'pangea/resources/aws/config/aggregate_authorization'
require 'pangea/resources/aws/config/configuration_aggregator_organization'

module Pangea
  module Resources
    module AWS
      # AWS Config Extended resources module
      # Advanced Config service resources for compliance management,
      # organization-wide configurations, and automated remediation.
      module Config
        include OrganizationConformancePack
        include OrganizationCustomRule
        include OrganizationManagedRule
        include StoredQuery
        include RemediationConfiguration
        include RetentionConfiguration
        include AggregateAuthorization
        include ConfigurationAggregatorOrganization
      end
    end
  end
end