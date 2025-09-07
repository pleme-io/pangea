# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS RDS Cluster Instance resources
      class RdsClusterInstanceAttributes < Dry::Struct
        # Instance identifier (optional, AWS will generate if not provided)
        attribute :identifier, Resources::Types::String.optional

        # Instance identifier prefix (alternative to identifier)
        attribute :identifier_prefix, Resources::Types::String.optional

        # Cluster identifier that this instance belongs to (required)
        attribute :cluster_identifier, Resources::Types::String

        # Instance class for Aurora instances
        attribute :instance_class, Resources::Types::String.enum(
          # Burstable performance instances
          "db.t3.small", "db.t3.medium", "db.t3.large", "db.t3.xlarge", "db.t3.2xlarge",
          "db.t4g.micro", "db.t4g.small", "db.t4g.medium", "db.t4g.large", 
          "db.t4g.xlarge", "db.t4g.2xlarge",
          
          # Memory optimized instances - R5
          "db.r5.large", "db.r5.xlarge", "db.r5.2xlarge", "db.r5.4xlarge", 
          "db.r5.8xlarge", "db.r5.12xlarge", "db.r5.16xlarge", "db.r5.24xlarge",
          
          # Memory optimized instances - R6g (Graviton2)
          "db.r6g.large", "db.r6g.xlarge", "db.r6g.2xlarge", "db.r6g.4xlarge",
          "db.r6g.8xlarge", "db.r6g.12xlarge", "db.r6g.16xlarge",
          
          # Memory optimized instances - R6i
          "db.r6i.large", "db.r6i.xlarge", "db.r6i.2xlarge", "db.r6i.4xlarge",
          "db.r6i.8xlarge", "db.r6i.12xlarge", "db.r6i.16xlarge", "db.r6i.24xlarge", "db.r6i.32xlarge",
          
          # Memory optimized instances - X2g (Graviton2)
          "db.x2g.medium", "db.x2g.large", "db.x2g.xlarge", "db.x2g.2xlarge", 
          "db.x2g.4xlarge", "db.x2g.8xlarge", "db.x2g.12xlarge", "db.x2g.16xlarge",
          
          # Serverless v2 (special handling)
          "serverless"
        )

        # Database engine (inherited from cluster, used for validation)
        attribute :engine, Resources::Types::String.optional

        # Engine version (optional, usually inherited from cluster)
        attribute :engine_version, Resources::Types::String.optional

        # Availability zone for this instance (optional, AWS will choose)
        attribute :availability_zone, Resources::Types::String.optional

        # DB parameter group for this instance (optional)
        attribute :db_parameter_group_name, Resources::Types::String.optional

        # Publicly accessible (inherited from cluster subnet group usually)
        attribute :publicly_accessible, Resources::Types::Bool.default(false)

        # Monitoring configuration
        attribute :monitoring_interval, Resources::Types::Integer.default(0).constrained(gteq: 0, lteq: 60)
        attribute :monitoring_role_arn, Resources::Types::String.optional

        # Performance Insights
        attribute :performance_insights_enabled, Resources::Types::Bool.default(false)
        attribute :performance_insights_kms_key_id, Resources::Types::String.optional
        attribute :performance_insights_retention_period, Resources::Types::Integer.default(7).constrained(gteq: 7, lteq: 731)

        # Backup and maintenance (usually inherited from cluster)
        attribute :preferred_backup_window, Resources::Types::String.optional
        attribute :preferred_maintenance_window, Resources::Types::String.optional

        # Additional options
        attribute :auto_minor_version_upgrade, Resources::Types::Bool.default(true)
        attribute :apply_immediately, Resources::Types::Bool.default(false)

        # Copy tags from cluster to snapshots
        attribute :copy_tags_to_snapshot, Resources::Types::Bool.default(true)

        # CA certificate identifier
        attribute :ca_cert_identifier, Resources::Types::String.optional

        # Promotion tier (0-15, 0 = highest priority for failover)
        attribute :promotion_tier, Resources::Types::Integer.default(1).constrained(gteq: 0, lteq: 15)

        # Tags to apply to the instance
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Cannot specify both identifier and identifier_prefix
          if attrs.identifier && attrs.identifier_prefix
            raise Dry::Struct::Error, "Cannot specify both 'identifier' and 'identifier_prefix'"
          end

          # Monitoring role required for enhanced monitoring
          if attrs.monitoring_interval > 0 && !attrs.monitoring_role_arn
            raise Dry::Struct::Error, "monitoring_role_arn is required when monitoring_interval > 0"
          end

          # Performance insights retention validation
          if attrs.performance_insights_enabled && attrs.performance_insights_retention_period < 7
            raise Dry::Struct::Error, "performance_insights_retention_period must be at least 7 days when Performance Insights is enabled"
          end

          # Serverless instance class validation
          if attrs.instance_class == "serverless"
            # Serverless instances have different constraints
            if attrs.monitoring_interval > 0
              raise Dry::Struct::Error, "Enhanced monitoring is not supported for serverless instances"
            end
          end

          # Promotion tier validation
          if attrs.promotion_tier < 0 || attrs.promotion_tier > 15
            raise Dry::Struct::Error, "promotion_tier must be between 0 and 15"
          end

          attrs
        end

        # Check if this is a serverless instance
        def is_serverless?
          instance_class == "serverless"
        end

        # Check if this is a burstable performance instance
        def is_burstable?
          instance_class.include?("t3") || instance_class.include?("t4g")
        end

        # Check if this is a memory-optimized instance
        def is_memory_optimized?
          instance_class.include?("r5") || instance_class.include?("r6") || 
          instance_class.include?("x2g")
        end

        # Check if this is a Graviton-based instance
        def is_graviton?
          instance_class.include?("t4g") || instance_class.include?("r6g") || 
          instance_class.include?("x2g")
        end

        # Check if enhanced monitoring is enabled
        def has_enhanced_monitoring?
          monitoring_interval > 0
        end

        # Check if Performance Insights is enabled
        def has_performance_insights?
          performance_insights_enabled
        end

        # Get instance family
        def instance_family
          return "serverless" if is_serverless?
          
          case instance_class
          when /^db\.t3/ then "t3"
          when /^db\.t4g/ then "t4g" 
          when /^db\.r5/ then "r5"
          when /^db\.r6g/ then "r6g"
          when /^db\.r6i/ then "r6i"
          when /^db\.x2g/ then "x2g"
          else "unknown"
          end
        end

        # Get instance size
        def instance_size
          return "serverless" if is_serverless?
          
          parts = instance_class.split('.')
          parts.last if parts.length >= 3
        end

        # Check if this instance can be a writer
        def can_be_writer?
          promotion_tier == 0
        end

        # Check if this is likely a reader instance
        def is_likely_reader?
          promotion_tier > 0
        end

        # Get the role description based on promotion tier
        def role_description
          case promotion_tier
          when 0
            "Primary writer instance"
          when 1
            "Primary failover target"
          else
            "Reader instance (tier #{promotion_tier})"
          end
        end

        # Estimate instance vCPUs
        def estimated_vcpus
          return "variable" if is_serverless?
          
          case instance_class
          when /micro/ then 1
          when /small/ then 1
          when /medium/ then 2
          when /large$/ then 2
          when /xlarge$/ then 4
          when /2xlarge/ then 8
          when /4xlarge/ then 16
          when /8xlarge/ then 32
          when /12xlarge/ then 48
          when /16xlarge/ then 64
          when /24xlarge/ then 96
          when /32xlarge/ then 128
          else 2  # Default estimate
          end
        end

        # Estimate instance memory (GB)
        def estimated_memory_gb
          return "variable" if is_serverless?
          
          case instance_class
          when /t3\.micro/ then 1
          when /t3\.small/ then 2
          when /t3\.medium/ then 4
          when /t3\.large/ then 8
          when /t3\.xlarge/ then 16
          when /t3\.2xlarge/ then 32
          when /t4g\.micro/ then 1
          when /t4g\.small/ then 2
          when /t4g\.medium/ then 4
          when /t4g\.large/ then 8
          when /t4g\.xlarge/ then 16
          when /t4g\.2xlarge/ then 32
          when /r5\.large/ then 16
          when /r5\.xlarge/ then 32
          when /r5\.2xlarge/ then 64
          when /r5\.4xlarge/ then 128
          when /r5\.8xlarge/ then 256
          when /r5\.12xlarge/ then 384
          when /r5\.16xlarge/ then 512
          when /r5\.24xlarge/ then 768
          when /r6g\.large/ then 16
          when /r6g\.xlarge/ then 32
          when /r6g\.2xlarge/ then 64
          when /r6g\.4xlarge/ then 128
          when /r6g\.8xlarge/ then 256
          when /r6g\.12xlarge/ then 384
          when /r6g\.16xlarge/ then 512
          else 8  # Default estimate
          end
        end

        # Estimate monthly cost (rough estimate)
        def estimated_monthly_cost
          return "Variable based on Aurora Capacity Units" if is_serverless?
          
          # Rough hourly rates for Aurora instances
          hourly_rate = case instance_class
                       when /t3\.small/ then 0.041
                       when /t3\.medium/ then 0.082
                       when /t3\.large/ then 0.164
                       when /t3\.xlarge/ then 0.328
                       when /t3\.2xlarge/ then 0.656
                       when /t4g\.medium/ then 0.073
                       when /t4g\.large/ then 0.146
                       when /r5\.large/ then 0.240
                       when /r5\.xlarge/ then 0.480
                       when /r5\.2xlarge/ then 0.960
                       when /r5\.4xlarge/ then 1.920
                       when /r6g\.large/ then 0.216
                       when /r6g\.xlarge/ then 0.432
                       when /r6g\.2xlarge/ then 0.864
                       else 0.200  # Default estimate
                       end

          monthly_cost = hourly_rate * 730  # Hours in a month
          "~$#{monthly_cost.round(2)}/month"
        end

        # Check if instance supports specific features
        def supports_performance_insights?
          !is_serverless?  # Serverless doesn't support Performance Insights
        end

        def supports_enhanced_monitoring?
          !is_serverless?  # Serverless doesn't support enhanced monitoring
        end

        # Performance characteristics
        def performance_characteristics
          {
            vcpus: estimated_vcpus,
            memory_gb: estimated_memory_gb,
            instance_family: instance_family,
            instance_size: instance_size,
            is_burstable: is_burstable?,
            is_memory_optimized: is_memory_optimized?,
            is_graviton: is_graviton?,
            supports_performance_insights: supports_performance_insights?,
            supports_enhanced_monitoring: supports_enhanced_monitoring?
          }
        end
      end

      # Common Aurora cluster instance configurations
      module AuroraInstanceConfigs
        # Writer instance configurations
        def self.writer_instance(instance_class: "db.r5.large")
          {
            instance_class: instance_class,
            promotion_tier: 0,
            performance_insights_enabled: true,
            monitoring_interval: 60,
            tags: { Role: "writer", Tier: "primary" }
          }
        end

        # Reader instance configurations
        def self.reader_instance(instance_class: "db.r5.large", tier: 1)
          {
            instance_class: instance_class,
            promotion_tier: tier,
            performance_insights_enabled: true,
            monitoring_interval: 30,
            tags: { Role: "reader", Tier: "tier-#{tier}" }
          }
        end

        # Development instance (cost-optimized)
        def self.development_instance
          {
            instance_class: "db.t3.medium",
            promotion_tier: 0,
            performance_insights_enabled: false,
            monitoring_interval: 0,
            auto_minor_version_upgrade: true,
            tags: { Environment: "development", CostOptimized: "true" }
          }
        end

        # Production writer instance (performance-optimized)
        def self.production_writer
          {
            instance_class: "db.r5.2xlarge",
            promotion_tier: 0,
            performance_insights_enabled: true,
            performance_insights_retention_period: 93,
            monitoring_interval: 15,  # Most frequent monitoring
            tags: { 
              Environment: "production", 
              Role: "writer", 
              CriticalSystem: "true"
            }
          }
        end

        # Production reader instance
        def self.production_reader(tier: 1)
          {
            instance_class: "db.r5.xlarge",
            promotion_tier: tier,
            performance_insights_enabled: true,
            performance_insights_retention_period: 31,
            monitoring_interval: 60,
            tags: { 
              Environment: "production", 
              Role: "reader", 
              Tier: "tier-#{tier}"
            }
          }
        end

        # Graviton-based instances (cost-optimized)
        def self.graviton_writer
          {
            instance_class: "db.r6g.large",
            promotion_tier: 0,
            performance_insights_enabled: true,
            monitoring_interval: 60,
            tags: { 
              Role: "writer", 
              Architecture: "graviton2",
              CostOptimized: "true"
            }
          }
        end

        def self.graviton_reader(tier: 1)
          {
            instance_class: "db.r6g.large",
            promotion_tier: tier,
            performance_insights_enabled: true,
            monitoring_interval: 30,
            tags: { 
              Role: "reader", 
              Architecture: "graviton2",
              Tier: "tier-#{tier}",
              CostOptimized: "true"
            }
          }
        end

        # Multi-AZ deployment pattern
        def self.multi_az_deployment
          {
            writer: writer_instance(instance_class: "db.r5.large"),
            reader_az_b: reader_instance(instance_class: "db.r5.large", tier: 1),
            reader_az_c: reader_instance(instance_class: "db.r5.large", tier: 2)
          }
        end
      end
    end
      end
    end
  end
end