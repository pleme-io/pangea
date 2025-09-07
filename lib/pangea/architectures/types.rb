# frozen_string_literal: true

require 'dry-struct'
require 'dry-types'

module Pangea
  module Architectures
    module Types
      include Dry.Types()

      # Common architecture configuration types
      Environment = String.enum('development', 'staging', 'production')
      
      Region = String.constrained(
        format: /^[a-z]{2}-[a-z]+-[0-9]$/
      )
      
      AvailabilityZone = String.constrained(
        format: /^[a-z]{2}-[a-z]+-[0-9][a-z]$/
      )
      
      DomainName = String.constrained(
        format: /^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]?\.[a-zA-Z]{2,}$/
      )
      
      InstanceType = String.constrained(
        format: /^[a-z]+[0-9]+[a-z]*\.(nano|micro|small|medium|large|xlarge|[0-9]+xlarge)$/
      )

      # Auto scaling configuration
      AutoScalingConfig = Hash.schema(
        min: Integer.constrained(gteq: 1),
        max: Integer.constrained(gteq: 1),
        desired: Integer.constrained(gteq: 1).optional
      ).constrained(rule: ->(config) { config[:min] <= config[:max] })

      # Database configuration types
      DatabaseEngine = String.enum(
        'mysql', 'postgresql', 'mariadb', 'aurora', 'aurora-mysql', 'aurora-postgresql'
      )
      
      DatabaseInstanceClass = String.constrained(
        format: /^db\.[a-z]+[0-9]+[a-z]*\.(nano|micro|small|medium|large|xlarge|[0-9]+xlarge)$/
      )

      # Traffic routing policies
      RoutingPolicy = String.enum('latency', 'geolocation', 'geoproximity', 'failover', 'weighted')

      # Consistency models for distributed systems  
      ConsistencyModel = String.enum('strong', 'eventual', 'bounded_staleness', 'session')

      # High availability configuration
      HighAvailabilityConfig = Hash.schema(
        multi_az: Bool.default(true),
        backup_retention_days: Integer.constrained(gteq: 0, lteq: 35).default(7),
        automated_backup: Bool.default(true),
        cross_region_backup: Bool.default(false)
      )

      # Security configuration
      SecurityConfig = Hash.schema(
        encryption_at_rest: Bool.default(true),
        encryption_in_transit: Bool.default(true),
        enable_waf: Bool.default(false),
        enable_ddos_protection: Bool.default(false),
        compliance_standards: Array.of(String).default([])
      )

      # Monitoring configuration
      MonitoringConfig = Hash.schema(
        detailed_monitoring: Bool.default(true),
        enable_logging: Bool.default(true),
        log_retention_days: Integer.constrained(gteq: 1, lteq: 3653).default(30),
        enable_alerting: Bool.default(true),
        enable_tracing: Bool.default(false)
      )

      # Cost optimization configuration
      CostOptimizationConfig = Hash.schema(
        use_spot_instances: Bool.default(false),
        use_reserved_instances: Bool.default(false),
        enable_auto_shutdown: Bool.default(false),
        cost_budget_monthly: Float.optional
      )

      # Network configuration
      NetworkConfig = Hash.schema(
        vpc_cidr: String.constrained(format: /^\d+\.\d+\.\d+\.\d+\/\d+$/),
        availability_zones: Array.of(AvailabilityZone).constrained(min_size: 1, max_size: 6),
        enable_nat_gateway: Bool.default(true),
        enable_vpc_endpoints: Bool.default(false)
      )

      # Backup configuration
      BackupConfig = Hash.schema(
        backup_schedule: String.default('daily'),
        retention_days: Integer.constrained(gteq: 1, lteq: 2555).default(30),
        cross_region_backup: Bool.default(false),
        point_in_time_recovery: Bool.default(false)
      )

      # Disaster recovery configuration
      DisasterRecoveryConfig = Hash.schema(
        rto_hours: Float.constrained(gteq: 0.0, lteq: 72.0),
        rpo_hours: Float.constrained(gteq: 0.0, lteq: 24.0),
        dr_region: Region,
        automated_failover: Bool.default(false),
        testing_schedule: String.default('monthly')
      )

      # Performance configuration
      PerformanceConfig = Hash.schema(
        enable_caching: Bool.default(false),
        cache_engine: String.enum('redis', 'memcached').default('redis'),
        enable_cdn: Bool.default(false),
        connection_pooling: Bool.default(true)
      )

      # Scaling configuration  
      ScalingConfig = Hash.schema(
        auto_scaling: AutoScalingConfig,
        scale_out_cooldown: Integer.constrained(gteq: 60, lteq: 3600).default(300),
        scale_in_cooldown: Integer.constrained(gteq: 60, lteq: 3600).default(300),
        target_cpu_utilization: Float.constrained(gteq: 10.0, lteq: 90.0).default(70.0)
      )

      # Common tag structure
      Tags = Hash.map(Symbol, String)

      # Base architecture attributes that all architectures inherit
      BaseArchitectureAttributes = Hash.schema(
        name: String,
        environment: Environment,
        region: Region,
        tags: Tags.default({})
      )

      # Validation helpers
      def self.validate_cidr_block(cidr)
        return false unless cidr.is_a?(String)
        return false unless cidr.match?(/^\d+\.\d+\.\d+\.\d+\/\d+$/)
        
        ip, prefix = cidr.split('/')
        return false unless (8..30).include?(prefix.to_i)
        
        octets = ip.split('.').map(&:to_i)
        octets.all? { |octet| (0..255).include?(octet) }
      end

      def self.validate_domain_name(domain)
        return false unless domain.is_a?(String)
        return false if domain.length > 253
        
        domain.match?(/^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]?\.[a-zA-Z]{2,}$/)
      end

      def self.validate_auto_scaling_config(config)
        return false unless config.is_a?(Hash)
        return false unless config[:min] && config[:max]
        return false unless config[:min] <= config[:max]
        
        if config[:desired]
          return false unless config[:min] <= config[:desired] && config[:desired] <= config[:max]
        end
        
        true
      end

      def self.validate_availability_zones(azs, region = nil)
        return false unless azs.is_a?(Array) && azs.any?
        return false unless azs.all? { |az| az.match?(/^[a-z]{2}-[a-z]+-[0-9][a-z]$/) }
        
        if region
          return false unless azs.all? { |az| az.start_with?(region) }
        end
        
        true
      end

      def self.validate_instance_type(instance_type)
        return false unless instance_type.is_a?(String)
        
        instance_type.match?(/^[a-z]+[0-9]+[a-z]*\.(nano|micro|small|medium|large|xlarge|[0-9]+xlarge)$/)
      end

      def self.validate_database_engine(engine)
        %w[mysql postgresql mariadb aurora aurora-mysql aurora-postgresql].include?(engine)
      end

      def self.validate_environment(environment)
        %w[development staging production].include?(environment)
      end

      def self.validate_region(region)
        return false unless region.is_a?(String)
        
        region.match?(/^[a-z]{2}-[a-z]+-[0-9]$/)
      end

      # Type coercion helpers
      def self.coerce_tags(tags)
        case tags
        when Hash
          tags.transform_keys(&:to_sym).transform_values(&:to_s)
        when NilClass
          {}
        else
          raise ArgumentError, "Tags must be a Hash, got #{tags.class}"
        end
      end

      def self.coerce_auto_scaling_config(config)
        case config
        when Hash
          {
            min: config[:min]&.to_i,
            max: config[:max]&.to_i,
            desired: config[:desired]&.to_i
          }.compact
        else
          raise ArgumentError, "Auto scaling config must be a Hash, got #{config.class}"
        end
      end

      # Default configurations for common scenarios
      DEVELOPMENT_DEFAULTS = {
        environment: 'development',
        high_availability: false,
        auto_scaling: { min: 1, max: 2, desired: 1 },
        monitoring: { detailed_monitoring: false },
        backup: { retention_days: 1 },
        security: { enable_waf: false, enable_ddos_protection: false }
      }.freeze

      STAGING_DEFAULTS = {
        environment: 'staging',
        high_availability: false,
        auto_scaling: { min: 1, max: 3, desired: 1 },
        monitoring: { detailed_monitoring: true },
        backup: { retention_days: 3 },
        security: { enable_waf: false, enable_ddos_protection: false }
      }.freeze

      PRODUCTION_DEFAULTS = {
        environment: 'production',
        high_availability: true,
        auto_scaling: { min: 2, max: 10, desired: 2 },
        monitoring: { detailed_monitoring: true, enable_alerting: true },
        backup: { retention_days: 30, cross_region_backup: true },
        security: { enable_waf: true, enable_ddos_protection: true }
      }.freeze

      def self.defaults_for_environment(environment)
        case environment.to_s
        when 'development'
          DEVELOPMENT_DEFAULTS
        when 'staging'
          STAGING_DEFAULTS
        when 'production'
          PRODUCTION_DEFAULTS
        else
          DEVELOPMENT_DEFAULTS
        end
      end
    end
  end
end