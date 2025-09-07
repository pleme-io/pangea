# frozen_string_literal: true

require 'dry-struct'
require 'pangea/components/types'

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
        attribute :opensearch_config, Types::Hash.schema(
          domain_name: Types::String.constrained(
            format: /\A[a-z][a-z0-9-]*\z/,
            min_size: 3,
            max_size: 28
          ),
          engine_version: Types::String.default('OpenSearch_2.11'),
          instance_type: Types::String.default('r5.large.search'),
          instance_count: Types::Integer.default(3).constrained(gteq: 1),
          dedicated_master_enabled?: Types::Bool.default(true),
          dedicated_master_type?: Types::String.default('r5.large.search'),
          dedicated_master_count?: Types::Integer.default(3),
          zone_awareness_enabled?: Types::Bool.default(true),
          availability_zone_count?: Types::Integer.default(3).constrained(included_in: [2, 3]),
          ebs_enabled?: Types::Bool.default(true),
          volume_type?: Types::String.enum('gp3', 'gp2', 'io1').default('gp3'),
          volume_size?: Types::Integer.default(100).constrained(gteq: 10, lteq: 16384),
          iops?: Types::Integer.optional,
          throughput?: Types::Integer.optional
        )
        
        # Log sources configuration
        attribute :log_sources, Types::Array.of(
          Types::Hash.schema(
            name: Types::String,
            type: Types::String.enum('cloudtrail', 'vpc_flow_logs', 'cloudwatch', 'waf', 's3_access', 'alb', 'custom'),
            source_arn?: Types::String.optional,
            log_group_name?: Types::String.optional,
            s3_bucket?: Types::String.optional,
            s3_prefix?: Types::String.optional,
            format?: Types::String.enum('json', 'csv', 'syslog', 'cef', 'leef').default('json'),
            transformation?: Types::String.optional,
            enrichment?: Types::Bool.default(true)
          )
        ).constrained(min_size: 1)
        
        # Kinesis Firehose configuration
        attribute :firehose_config, Types::Hash.schema(
          buffer_size?: Types::Integer.default(5).constrained(gteq: 1, lteq: 128),
          buffer_interval?: Types::Integer.default(300).constrained(gteq: 60, lteq: 900),
          compression_format?: Types::String.enum('GZIP', 'SNAPPY', 'ZIP', 'UNCOMPRESSED').default('GZIP'),
          error_output_prefix?: Types::String.default('errors/'),
          enable_data_transformation?: Types::Bool.default(true),
          enable_data_validation?: Types::Bool.default(true)
        ).default({}.freeze)
        
        # Security correlation rules
        attribute :correlation_rules, Types::Array.of(
          Types::Hash.schema(
            name: Types::String,
            description: Types::String,
            severity: Types::String.enum('critical', 'high', 'medium', 'low', 'info').default('medium'),
            rule_type: Types::String.enum('threshold', 'pattern', 'anomaly', 'sequence', 'statistical'),
            conditions: Types::Array.of(Types::Hash).constrained(min_size: 1),
            time_window?: Types::Integer.default(300),
            threshold?: Types::Integer.optional,
            actions: Types::Array.of(
              Types::String.enum('alert', 'block', 'isolate', 'investigate', 'notify', 'custom')
            ).default(['alert'].freeze),
            enabled?: Types::Bool.default(true)
          )
        ).default([].freeze)
        
        # Threat detection configuration
        attribute :threat_detection, Types::Hash.schema(
          enable_ml_detection?: Types::Bool.default(true),
          anomaly_detectors?: Types::Array.of(
            Types::Hash.schema(
              name: Types::String,
              type: Types::String.enum('statistical', 'machine_learning', 'pattern_based'),
              sensitivity: Types::String.enum('low', 'medium', 'high').default('medium'),
              baseline_period?: Types::Integer.default(7)
            )
          ).default([].freeze),
          threat_intel_feeds?: Types::Array.of(
            Types::Hash.schema(
              name: Types::String,
              type: Types::String.enum('ip_reputation', 'domain_reputation', 'file_hash', 'indicators'),
              source_url?: Types::String.optional,
              update_frequency?: Types::Integer.default(3600),
              enabled?: Types::Bool.default(true)
            )
          ).default([].freeze),
          enable_behavior_analytics?: Types::Bool.default(true),
          enable_entity_analytics?: Types::Bool.default(true)
        ).default({}.freeze)
        
        # Incident response configuration
        attribute :incident_response, Types::Hash.schema(
          enable_automated_response?: Types::Bool.default(true),
          playbooks?: Types::Array.of(
            Types::Hash.schema(
              name: Types::String,
              trigger: Types::String,
              severity_threshold: Types::String.enum('critical', 'high', 'medium', 'low'),
              steps: Types::Array.of(Types::Hash),
              notification_channels?: Types::Array.of(Types::String).default([].freeze),
              escalation_policy?: Types::String.optional
            )
          ).default([].freeze),
          enable_case_management?: Types::Bool.default(true),
          enable_forensics_collection?: Types::Bool.default(true),
          retention_days?: Types::Integer.default(90).constrained(gteq: 1, lteq: 3653)
        ).default({}.freeze)
        
        # Dashboard and visualization
        attribute :dashboards, Types::Array.of(
          Types::Hash.schema(
            name: Types::String,
            type: Types::String.enum('security_overview', 'threat_hunting', 'compliance', 'incident_response', 'custom'),
            refresh_interval?: Types::Integer.default(300),
            widgets?: Types::Array.of(Types::Hash).default([].freeze),
            access_control?: Types::Hash.default({}.freeze)
          )
        ).default([
          { name: 'Security Overview', type: 'security_overview' },
          { name: 'Threat Hunting', type: 'threat_hunting' },
          { name: 'Compliance', type: 'compliance' },
          { name: 'Incident Response', type: 'incident_response' }
        ].freeze)
        
        # Compliance and reporting
        attribute :compliance_config, Types::Hash.schema(
          frameworks: Types::Array.of(
            Types::String.enum('soc2', 'iso27001', 'nist', 'pci-dss', 'hipaa', 'gdpr', 'ccpa')
          ).default(['soc2', 'iso27001'].freeze),
          enable_compliance_reporting?: Types::Bool.default(true),
          report_schedule?: Types::String.enum('daily', 'weekly', 'monthly').default('weekly'),
          evidence_collection?: Types::Bool.default(true),
          audit_trail_retention?: Types::Integer.default(2555).constrained(gteq: 365)
        ).default({}.freeze)
        
        # Advanced analytics
        attribute :analytics_config, Types::Hash.schema(
          enable_ueba?: Types::Bool.default(true),
          enable_network_analytics?: Types::Bool.default(true),
          enable_file_analytics?: Types::Bool.default(true),
          ml_models?: Types::Array.of(
            Types::Hash.schema(
              name: Types::String,
              type: Types::String.enum('anomaly', 'classification', 'prediction', 'clustering'),
              update_frequency?: Types::String.enum('realtime', 'hourly', 'daily').default('hourly'),
              training_data_days?: Types::Integer.default(30)
            )
          ).default([].freeze),
          enable_threat_hunting_queries?: Types::Bool.default(true)
        ).default({}.freeze)
        
        # Integration configuration
        attribute :integrations, Types::Array.of(
          Types::Hash.schema(
            name: Types::String,
            type: Types::String.enum('ticketing', 'soar', 'threat_intel', 'cmdb', 'notification'),
            endpoint?: Types::String.optional,
            api_key_secret_arn?: Types::String.optional,
            enabled?: Types::Bool.default(true)
          )
        ).default([].freeze)
        
        # Security configuration
        attribute :security_config, Types::Hash.schema(
          enable_encryption_at_rest?: Types::Bool.default(true),
          kms_key_id?: Types::String.optional,
          enable_encryption_in_transit?: Types::Bool.default(true),
          enable_fine_grained_access?: Types::Bool.default(true),
          master_user_arn?: Types::String.optional,
          enable_audit_logs?: Types::Bool.default(true),
          enable_slow_logs?: Types::Bool.default(true)
        ).default({}.freeze)
        
        # Performance and scaling
        attribute :scaling_config, Types::Hash.schema(
          enable_auto_scaling?: Types::Bool.default(true),
          min_instances?: Types::Integer.default(3),
          max_instances?: Types::Integer.default(10),
          target_cpu_utilization?: Types::Integer.default(70).constrained(gteq: 10, lteq: 90),
          scale_up_cooldown?: Types::Integer.default(300),
          scale_down_cooldown?: Types::Integer.default(900)
        ).default({}.freeze)
        
        # Tags for resource management
        attribute :tags, Types::AwsTags.default({}.freeze)
      end
    end
  end
end