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

require 'pangea/components/base'
require 'pangea/components/siem_security_platform/types'
require_relative 'modules/helpers'
require_relative 'modules/security'
require_relative 'modules/storage'
require_relative 'modules/ingestion'
require_relative 'modules/processing'
require_relative 'modules/threat_detection'
require_relative 'modules/incident_response'
require_relative 'modules/monitoring'
require_relative 'modules/integrations'

module Pangea
  module Components
    module SiemSecurityPlatform
      include Helpers
      include Security
      include Storage
      include Ingestion
      include Processing
      include ThreatDetection
      include IncidentResponse
      include Monitoring
      include Integrations

      # SIEM Security Platform Component
      # Implements comprehensive security information and event management
      def siem_security_platform(name, attributes = {})
        attrs = Attributes.new(attributes)
        resources = initialize_resources

        # Create resources in dependency order
        create_security_resources(name, attrs, resources)
        create_storage_resources(name, attrs, resources)
        create_ingestion_resources(name, attrs, resources)
        create_processing_resources(name, attrs, resources)
        create_threat_detection_resources(name, attrs, resources)
        create_incident_response_resources(name, attrs, resources)
        create_monitoring_resources(name, attrs, resources)
        create_integration_resources(name, attrs, resources)

        # Create component reference with outputs
        create_component_reference(
          'siem_security_platform',
          name,
          attrs.to_h,
          resources,
          build_outputs(name, attrs, resources)
        )
      end

      private

      def initialize_resources
        {
          opensearch_domain: nil,
          firehose_streams: {},
          lambda_functions: {},
          cloudwatch_logs: {},
          s3_buckets: {},
          sns_topics: {},
          sqs_queues: {},
          event_rules: {},
          step_functions: {},
          iam_roles: {},
          security_groups: {},
          kms_keys: {},
          secrets: {},
          alarms: {}
        }
      end

      def build_outputs(name, attrs, resources)
        {
          opensearch_domain_endpoint: resources[:opensearch_domain]&.endpoint,
          opensearch_domain_arn: resources[:opensearch_domain]&.arn,
          opensearch_dashboard_url: opensearch_dashboard_url(resources),
          firehose_streams: resources[:firehose_streams].transform_values(&:arn),
          correlation_engine_arn: resources[:step_functions][:correlation_engine]&.arn,
          incident_response_arn: resources[:step_functions][:incident_response]&.arn,
          security_score: calculate_siem_security_score(attrs),
          compliance_status: generate_siem_compliance_status(attrs)
        }
      end

      def opensearch_dashboard_url(resources)
        return nil unless resources[:opensearch_domain]

        "https://#{resources[:opensearch_domain].endpoint}/_dashboards/"
      end

      include Base
    end
  end
end
