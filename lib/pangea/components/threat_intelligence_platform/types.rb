# frozen_string_literal: true

require 'dry-struct'
require 'pangea/components/types'

module Pangea
  module Components
    module ThreatIntelligencePlatform
      # Threat Intelligence Platform attributes
      class Attributes < Dry::Struct
        transform_keys(&:to_sym)
        schema schema.strict
        
        # VPC reference for deployment
        attribute :vpc_ref, Types::VpcReference
        
        # Subnet references for Lambda functions
        attribute :subnet_refs, Types::SubnetReferences
        
        # Threat intelligence sources
        attribute :threat_sources, Types::Array.of(
          Types::Hash.schema(
            name: Types::String,
            type: Types::String.enum('osint', 'commercial', 'government', 'custom', 'community'),
            category: Types::String.enum('ip', 'domain', 'url', 'hash', 'email', 'cve', 'ttp', 'ioc'),
            source_url?: Types::String.optional,
            api_endpoint?: Types::String.optional,
            api_key_secret_arn?: Types::String.optional,
            format: Types::String.enum('stix', 'taxii', 'json', 'csv', 'xml', 'misp').default('json'),
            polling_interval: Types::Integer.default(3600).constrained(gteq: 300),
            confidence_threshold?: Types::Integer.default(70).constrained(gteq: 0, lteq: 100),
            enabled?: Types::Bool.default(true),
            authentication?: Types::Hash.schema(
              type: Types::String.enum('none', 'api_key', 'oauth', 'basic'),
              credentials_secret_arn?: Types::String.optional
            ).optional
          )
        ).constrained(min_size: 1)
        
        # IOC (Indicator of Compromise) processing
        attribute :ioc_processing, Types::Hash.schema(
          enable_deduplication?: Types::Bool.default(true),
          enable_enrichment?: Types::Bool.default(true),
          enable_validation?: Types::Bool.default(true),
          enable_normalization?: Types::Bool.default(true),
          retention_days?: Types::Integer.default(90).constrained(gteq: 1, lteq: 3653),
          archive_after_days?: Types::Integer.default(30).constrained(gteq: 1, lteq: 365),
          max_ioc_age_days?: Types::Integer.default(180).constrained(gteq: 1, lteq: 730)
        ).default({}.freeze)
        
        # Threat scoring configuration
        attribute :threat_scoring, Types::Hash.schema(
          scoring_model: Types::String.enum('weighted', 'ml_based', 'rule_based', 'hybrid').default('hybrid'),
          base_scores?: Types::Hash.schema(
            ip: Types::Integer.default(60),
            domain: Types::Integer.default(70),
            url: Types::Integer.default(75),
            hash: Types::Integer.default(90),
            email: Types::Integer.default(50)
          ).default({}.freeze),
          source_weights?: Types::Hash.default({}.freeze),
          decay_enabled?: Types::Bool.default(true),
          decay_rate?: Types::Float.default(0.95).constrained(gteq: 0.0, lteq: 1.0),
          confidence_multiplier?: Types::Float.default(1.2).constrained(gteq: 0.5, lteq: 2.0)
        ).default({}.freeze)
        
        # Enrichment sources
        attribute :enrichment_sources, Types::Array.of(
          Types::Hash.schema(
            name: Types::String,
            type: Types::String.enum('geoip', 'whois', 'dns', 'asn', 'reputation', 'sandbox', 'virustotal'),
            api_endpoint?: Types::String.optional,
            api_key_secret_arn?: Types::String.optional,
            enabled?: Types::Bool.default(true),
            cache_ttl?: Types::Integer.default(86400)
          )
        ).default([
          { name: 'GeoIP', type: 'geoip', enabled: true },
          { name: 'WHOIS', type: 'whois', enabled: true },
          { name: 'DNS', type: 'dns', enabled: true }
        ].freeze)
        
        # Threat feed integration
        attribute :threat_feeds, Types::Array.of(
          Types::Hash.schema(
            name: Types::String,
            description?: Types::String.optional,
            feed_url?: Types::String.optional,
            feed_type: Types::String.enum('public', 'private', 'sharing_group'),
            tlp_level: Types::String.enum('white', 'green', 'amber', 'red').default('amber'),
            sharing_enabled?: Types::Bool.default(false),
            auto_publish?: Types::Bool.default(false),
            tags?: Types::Array.of(Types::String).default([].freeze)
          )
        ).default([].freeze)
        
        # Correlation rules
        attribute :correlation_rules, Types::Array.of(
          Types::Hash.schema(
            name: Types::String,
            description: Types::String,
            rule_type: Types::String.enum('simple', 'complex', 'ml_based', 'graph_based'),
            conditions: Types::Array.of(Types::Hash),
            actions: Types::Array.of(
              Types::String.enum('alert', 'enrich', 'block', 'investigate', 'share')
            ).default(['alert'].freeze),
            severity: Types::String.enum('critical', 'high', 'medium', 'low').default('medium'),
            enabled?: Types::Bool.default(true)
          )
        ).default([].freeze)
        
        # Automated response configuration
        attribute :automated_response, Types::Hash.schema(
          enable_auto_blocking?: Types::Bool.default(false),
          blocking_threshold?: Types::Integer.default(90).constrained(gteq: 50, lteq: 100),
          enable_auto_investigation?: Types::Bool.default(true),
          investigation_threshold?: Types::Integer.default(70).constrained(gteq: 50, lteq: 100),
          enable_auto_sharing?: Types::Bool.default(false),
          sharing_threshold?: Types::Integer.default(80).constrained(gteq: 50, lteq: 100),
          response_playbooks?: Types::Array.of(
            Types::Hash.schema(
              name: Types::String,
              trigger_score: Types::Integer,
              actions: Types::Array.of(Types::String)
            )
          ).default([].freeze)
        ).default({}.freeze)
        
        # Threat hunting features
        attribute :threat_hunting, Types::Hash.schema(
          enable_proactive_hunting?: Types::Bool.default(true),
          hunting_queries?: Types::Array.of(
            Types::Hash.schema(
              name: Types::String,
              query: Types::String,
              schedule: Types::String.enum('hourly', 'daily', 'weekly').default('daily'),
              enabled?: Types::Bool.default(true)
            )
          ).default([].freeze),
          enable_ml_hunting?: Types::Bool.default(true),
          anomaly_detection_models?: Types::Array.of(Types::String).default([].freeze)
        ).default({}.freeze)
        
        # API configuration for sharing
        attribute :api_config, Types::Hash.schema(
          enable_api?: Types::Bool.default(true),
          rate_limiting?: Types::Hash.schema(
            requests_per_minute: Types::Integer.default(100),
            requests_per_hour: Types::Integer.default(1000),
            requests_per_day: Types::Integer.default(10000)
          ).default({}.freeze),
          authentication_required?: Types::Bool.default(true),
          allowed_operations?: Types::Array.of(
            Types::String.enum('read', 'write', 'update', 'delete', 'share')
          ).default(['read'].freeze)
        ).default({}.freeze)
        
        # Reporting and analytics
        attribute :reporting_config, Types::Hash.schema(
          enable_daily_reports?: Types::Bool.default(true),
          enable_weekly_reports?: Types::Bool.default(true),
          enable_threat_landscape?: Types::Bool.default(true),
          report_recipients?: Types::Array.of(Types::String).default([].freeze),
          custom_reports?: Types::Array.of(
            Types::Hash.schema(
              name: Types::String,
              schedule: Types::String,
              query: Types::String,
              format: Types::String.enum('pdf', 'html', 'json', 'csv').default('pdf')
            )
          ).default([].freeze)
        ).default({}.freeze)
        
        # Storage configuration
        attribute :storage_config, Types::Hash.schema(
          primary_storage: Types::String.enum('dynamodb', 'elasticsearch', 'both').default('both'),
          enable_compression?: Types::Bool.default(true),
          enable_archival?: Types::Bool.default(true),
          archive_storage: Types::String.enum('s3', 'glacier').default('s3'),
          enable_replication?: Types::Bool.default(true),
          replication_regions?: Types::Array.of(Types::String).default([].freeze)
        ).default({}.freeze)
        
        # Tags for resource management
        attribute :tags, Types::AwsTags.default({}.freeze)
      end
    end
  end
end