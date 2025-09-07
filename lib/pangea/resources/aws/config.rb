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