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
require 'pangea/components/zero_trust_network/types'
require_relative 'policies'
require_relative 'audit'
require_relative 'networking'
require_relative 'segments'
require_relative 'endpoints'
require_relative 'security_automation'
require_relative 'monitoring'
require_relative 'threat_detection'
require_relative 'compliance'

module Pangea
  module Components
    module ZeroTrustNetwork
      include Policies
      include Audit
      include Networking
      include Segments
      include Endpoints
      include SecurityAutomation
      include Monitoring
      include ThreatDetection
      include Compliance

      # Zero Trust Network Architecture Component
      def zero_trust_network(name, attributes = {})
        attrs = Attributes.new(attributes)
        resources = initialize_resources

        create_trust_provider(name, attrs, resources)
        create_verified_access_instance(name, attrs, resources)
        create_access_logging(name, attrs, resources)
        create_network_segments(name, attrs, resources)
        create_verified_access_group(name, attrs, resources)
        create_endpoints(name, attrs, resources)
        create_vpc_endpoints(name, attrs, resources)
        create_flow_logs(name, attrs, resources) if attrs.monitoring_config[:enable_flow_logs]
        create_security_automation(name, attrs, resources)
        create_monitoring_alarms(name, attrs, resources)
        create_threat_detection(name, attrs, resources) if threat_detection_enabled?(attrs)

        create_component_reference('zero_trust_network', name, attrs.to_h, resources, build_outputs(name, attrs, resources))
      end

      private

      def initialize_resources
        {
          trust_provider: nil, verified_access_instance: nil, verified_access_groups: {},
          verified_access_endpoints: {}, security_groups: {}, network_acls: {},
          vpc_endpoints: {}, flow_logs: {}, cloudwatch_logs: {}, s3_buckets: {},
          lambda_functions: {}, event_rules: {}, alarms: {}
        }
      end

      def create_trust_provider(name, attrs, resources)
        trust_provider_name = component_resource_name(name, :trust_provider)
        resources[:trust_provider] = attrs.trust_provider_type == 'user' ?
          create_user_trust_provider(trust_provider_name, attrs) :
          create_device_trust_provider(trust_provider_name, attrs)
      end

      def create_user_trust_provider(trust_provider_name, attrs)
        aws_verifiedaccess_trust_provider(trust_provider_name, {
          trust_provider_type: attrs.trust_provider_type,
          user_trust_provider_type: attrs.identity_provider[:type],
          oidc_options: attrs.identity_provider[:type] == 'oidc' ? oidc_options(attrs) : nil,
          tags: component_tags('zero_trust_network', trust_provider_name, attrs.tags)
        })
      end

      def create_device_trust_provider(trust_provider_name, attrs)
        aws_verifiedaccess_trust_provider(trust_provider_name, {
          trust_provider_type: attrs.trust_provider_type,
          device_trust_provider_type: 'jamf',
          tags: component_tags('zero_trust_network', trust_provider_name, attrs.tags)
        })
      end

      def oidc_options(attrs)
        ip = attrs.identity_provider
        { issuer: ip[:issuer], authorization_endpoint: ip[:authorization_endpoint],
          token_endpoint: ip[:token_endpoint], user_info_endpoint: ip[:user_info_endpoint],
          client_id: ip[:client_id], client_secret: ip[:client_secret], scope: ip[:scope] }
      end

      def create_verified_access_instance(name, attrs, resources)
        instance_name = component_resource_name(name, :verified_access)
        resources[:verified_access_instance] = aws_verifiedaccess_instance(instance_name, {
          description: "Zero Trust Network for #{name}",
          trust_provider_ids: [resources[:trust_provider].id],
          tags: component_tags('zero_trust_network', name, attrs.tags)
        })
      end

      def create_access_logging(name, attrs, resources)
        log_group_name = component_resource_name(name, :access_logs)
        resources[:cloudwatch_logs][:access] = aws_cloudwatch_log_group(log_group_name, {
          name: "/aws/verified-access/#{name}",
          retention_in_days: attrs.monitoring_config[:log_retention_days],
          tags: component_tags('zero_trust_network', name, attrs.tags)
        })

        instance_name = component_resource_name(name, :verified_access)
        aws_verifiedaccess_instance_logging_configuration(:"#{instance_name}_logging", {
          verified_access_instance_id: resources[:verified_access_instance].id,
          access_logs: build_access_logs_config(name, attrs, resources)
        })
      end

      def build_access_logs_config(name, attrs, resources)
        config = { cloudwatch_logs: { enabled: true, log_group: resources[:cloudwatch_logs][:access].name } }
        if %w[s3 both].include?(attrs.audit_config[:audit_log_destination])
          config[:s3] = { enabled: true, bucket_name: create_audit_bucket(name, attrs, resources) }
        end
        config
      end

      def create_verified_access_group(name, attrs, resources)
        group_name = component_resource_name(name, :group)
        resources[:verified_access_groups][:main] = aws_verifiedaccess_group(group_name, {
          verified_access_instance_id: resources[:verified_access_instance].id,
          description: "Main access group for #{name}",
          policy_document: generate_default_policy(attrs),
          tags: component_tags('zero_trust_network', name, attrs.tags)
        })
      end

      def threat_detection_enabled?(attrs)
        attrs.threat_protection[:enable_ids] || attrs.threat_protection[:enable_ips]
      end

      def build_outputs(_name, attrs, resources)
        {
          verified_access_instance_id: resources[:verified_access_instance].id,
          verified_access_instance_arn: resources[:verified_access_instance].arn,
          trust_provider_id: resources[:trust_provider].id,
          verified_access_group_id: resources[:verified_access_groups][:main].id,
          endpoints: resources[:verified_access_endpoints].transform_values(&:id),
          security_groups: resources[:security_groups].transform_values(&:id),
          compliance_status: generate_compliance_status(attrs),
          security_score: calculate_security_score(attrs, resources)
        }
      end

      def aws_region
        'us-east-1'
      end

      def aws_account_id
        '123456789012'
      end

      include Base
    end
  end
end
