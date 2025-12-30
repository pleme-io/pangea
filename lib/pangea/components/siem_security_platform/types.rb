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
require 'pangea/components/types'

require_relative 'types/opensearch_config'
require_relative 'types/log_collection_configs'
require_relative 'types/detection_configs'
require_relative 'types/response_configs'
require_relative 'types/operational_configs'
require_relative 'types/security_configs'

module Pangea
  module Components
    module SiemSecurityPlatform
      # SIEM Security Platform attributes
      class Attributes < Dry::Struct
        transform_keys(&:to_sym)
        schema schema.strict

        # VPC reference for SIEM deployment
        attribute :vpc_ref, Types::VpcReference

        # Subnet references for OpenSearch domain
        attribute :subnet_refs, Types::SubnetReferences.constrained(min_size: 2)

        # OpenSearch configuration
        attribute :opensearch_config, OpenSearchConfig

        # Log sources configuration
        attribute :log_sources, Types::Array.of(LogSourceEntry).constrained(min_size: 1)

        # Kinesis Firehose configuration
        attribute :firehose_config, FirehoseConfig.default { FirehoseConfig.new({}) }

        # Security correlation rules
        attribute :correlation_rules, Types::Array.of(CorrelationRuleEntry).default([].freeze)

        # Threat detection configuration
        attribute :threat_detection, ThreatDetectionConfig.default { ThreatDetectionConfig.new({}) }

        # Incident response configuration
        attribute :incident_response, IncidentResponseConfig.default { IncidentResponseConfig.new({}) }

        # Dashboard and visualization
        attribute :dashboards, Types::Array.of(DashboardEntry).default(DEFAULT_DASHBOARDS)

        # Compliance and reporting
        attribute :compliance_config, ComplianceConfig.default { ComplianceConfig.new({}) }

        # Advanced analytics
        attribute :analytics_config, AnalyticsConfig.default { AnalyticsConfig.new({}) }

        # Integration configuration
        attribute :integrations, Types::Array.of(IntegrationEntry).default([].freeze)

        # Security configuration
        attribute :security_config, SecurityConfig.default { SecurityConfig.new({}) }

        # Performance and scaling
        attribute :scaling_config, ScalingConfig.default { ScalingConfig.new({}) }

        # Tags for resource management
        attribute :tags, Types::AwsTags.default({}.freeze)
      end
    end
  end
end
