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

module Pangea
  module Components
    module ZeroTrustNetwork
      # Zero Trust Network architecture attributes
      class Attributes < Dry::Struct
        transform_keys(&:to_sym)
        schema schema.strict
        
        # VPC reference for zero trust deployment
        attribute :vpc_ref, Types::VpcReference
        
        # Subnet references for verified access endpoints
        attribute :subnet_refs, Types::SubnetReferences
        
        # Identity provider configuration
        attribute :identity_provider, Types::Hash.schema(
          type: Types::String.enum('oidc', 'saml'),
          issuer: Types::String,
          authorization_endpoint?: Types::String.optional,
          token_endpoint?: Types::String.optional,
          user_info_endpoint?: Types::String.optional,
          client_id?: Types::String.optional,
          client_secret?: Types::String.optional,
          scope?: Types::String.default('openid profile email'),
          identity_provider_arn?: Types::String.optional
        )
        
        # Trust provider configuration
        attribute :trust_provider_type, Types::String.enum('user', 'device').default('user')
        
        # Policy documents for zero trust access
        attribute :access_policies, Types::Hash.schema(
          default_policy?: Types::String.optional,
          endpoint_policies?: Types::Hash.default({}.freeze),
          group_policies?: Types::Hash.default({}.freeze),
          conditional_policies?: Types::Array.of(
            Types::Hash.schema(
              name: Types::String,
              condition: Types::String,
              policy: Types::String,
              priority?: Types::Integer.default(100)
            )
          ).default([].freeze)
        ).default({}.freeze)
        
        # Network segmentation configuration
        attribute :network_segments, Types::Array.of(
          Types::Hash.schema(
            name: Types::String,
            cidr_blocks: Types::Array.of(Types::CidrBlock),
            description?: Types::String.optional,
            security_groups?: Types::SecurityGroupReferences.default([].freeze),
            nacl_rules?: Types::Array.of(Types::Hash).default([].freeze)
          )
        ).constrained(min_size: 1)
        
        # Endpoint configuration
        attribute :endpoints, Types::Array.of(
          Types::Hash.schema(
            name: Types::String,
            type: Types::String.enum('network', 'application'),
            domain_name?: Types::String.optional,
            port?: Types::Port.default(443),
            protocol?: Types::String.enum('tcp', 'udp').default('tcp'),
            target_type?: Types::String.enum('vpc', 'network-interface', 'alb').default('vpc'),
            target_id?: Types::String.optional,
            policy_document?: Types::String.optional
          )
        ).default([].freeze)
        
        # Continuous verification settings
        attribute :verification_settings, Types::Hash.schema(
          session_duration?: Types::Integer.default(3600).constrained(gteq: 300, lteq: 43200),
          require_mfa?: Types::Bool.default(true),
          device_trust?: Types::Bool.default(false),
          risk_based_authentication?: Types::Bool.default(true),
          continuous_verification_interval?: Types::Integer.default(300),
          max_failed_attempts?: Types::Integer.default(3)
        ).default({}.freeze)
        
        # Compliance framework configuration
        attribute :compliance_frameworks, Types::Array.of(
          Types::String.enum('soc2', 'iso27001', 'nist', 'pci-dss', 'hipaa', 'fedramp')
        ).default(['soc2', 'iso27001'].freeze)
        
        # Security monitoring configuration
        attribute :monitoring_config, Types::Hash.schema(
          enable_access_logs?: Types::Bool.default(true),
          enable_flow_logs?: Types::Bool.default(true),
          enable_cloudtrail?: Types::Bool.default(true),
          log_retention_days?: Types::Integer.default(90).constrained(gteq: 1, lteq: 3653),
          enable_anomaly_detection?: Types::Bool.default(true),
          alert_on_policy_violations?: Types::Bool.default(true),
          alert_on_suspicious_activity?: Types::Bool.default(true)
        ).default({}.freeze)
        
        # Advanced threat protection
        attribute :threat_protection, Types::Hash.schema(
          enable_ids?: Types::Bool.default(true),
          enable_ips?: Types::Bool.default(true),
          enable_waf?: Types::Bool.default(true),
          enable_ddos_protection?: Types::Bool.default(true),
          threat_intelligence_feeds?: Types::Array.of(Types::String).default([].freeze),
          automated_response?: Types::Bool.default(false)
        ).default({}.freeze)
        
        # Audit and compliance logging
        attribute :audit_config, Types::Hash.schema(
          enable_audit_logs?: Types::Bool.default(true),
          audit_log_destination?: Types::String.enum('s3', 'cloudwatch', 'both').default('both'),
          enable_tamper_protection?: Types::Bool.default(true),
          enable_forensics_mode?: Types::Bool.default(false),
          compliance_reporting?: Types::Bool.default(true)
        ).default({}.freeze)
        
        # Tags for resource management
        attribute :tags, Types::AwsTags.default({}.freeze)
        
        # Advanced options
        attribute :advanced_options, Types::Hash.schema(
          enable_microsegmentation?: Types::Bool.default(true),
          enable_east_west_inspection?: Types::Bool.default(true),
          enable_lateral_movement_detection?: Types::Bool.default(true),
          enable_privileged_access_management?: Types::Bool.default(true),
          enable_security_automation?: Types::Bool.default(true),
          custom_policy_engine?: Types::Bool.default(false)
        ).default({}.freeze)
      end
    end
  end
end