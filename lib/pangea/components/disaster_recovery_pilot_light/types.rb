# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Components
    module DisasterRecoveryPilotLight
      # Primary region configuration
      class PrimaryRegionConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :region, Types::String
        attribute :vpc_ref, Types::ResourceReference.optional
        attribute :vpc_cidr, Types::String.default('10.0.0.0/16')
        attribute :availability_zones, Types::Array.of(Types::String).constrained(min_size: 2)
        attribute :critical_resources, Types::Array.of(Types::Hash).default([].freeze)
        attribute :backup_schedule, Types::String.default('cron(0 2 * * ? *)')
      end
      
      # DR region configuration
      class DRRegionConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :region, Types::String
        attribute :vpc_ref, Types::ResourceReference.optional
        attribute :vpc_cidr, Types::String.default('10.1.0.0/16')
        attribute :availability_zones, Types::Array.of(Types::String).constrained(min_size: 2)
        attribute :standby_resources, Types::Hash.default({}.freeze)
        attribute :activation_priority, Types::Integer.default(100)
      end
      
      # Critical data configuration
      class CriticalDataConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :databases, Types::Array.of(Types::Hash).default([].freeze)
        attribute :s3_buckets, Types::Array.of(Types::String).default([].freeze)
        attribute :efs_filesystems, Types::Array.of(Types::String).default([].freeze)
        attribute :backup_retention_days, Types::Integer.default(7)
        attribute :cross_region_backup, Types::Bool.default(true)
        attribute :point_in_time_recovery, Types::Bool.default(true)
      end
      
      # Pilot light resources configuration
      class PilotLightConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :minimal_compute, Types::Bool.default(true)
        attribute :database_replicas, Types::Bool.default(true)
        attribute :data_sync_interval, Types::Integer.default(300)
        attribute :standby_instance_type, Types::String.default('t3.small')
        attribute :auto_scaling_min, Types::Integer.default(0)
        attribute :auto_scaling_max, Types::Integer.default(10)
      end
      
      # Activation configuration
      class ActivationConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :activation_method, Types::String.enum('manual', 'automated', 'semi-automated').default('semi-automated')
        attribute :health_check_threshold, Types::Integer.default(3)
        attribute :activation_timeout, Types::Integer.default(900)
        attribute :pre_activation_checks, Types::Array.of(Types::Hash).default([].freeze)
        attribute :post_activation_validation, Types::Array.of(Types::Hash).default([].freeze)
        attribute :notification_channels, Types::Array.of(Types::ResourceReference).default([].freeze)
      end
      
      # Testing configuration
      class TestingConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :test_schedule, Types::String.default('cron(0 10 ? * SUN *)')
        attribute :test_scenarios, Types::Array.of(Types::String).default(['failover', 'data_recovery'].freeze)
        attribute :automated_testing, Types::Bool.default(true)
        attribute :test_notification_enabled, Types::Bool.default(true)
        attribute :rollback_after_test, Types::Bool.default(true)
        attribute :test_data_subset, Types::Bool.default(true)
      end
      
      # Cost optimization configuration
      class CostOptimizationConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :use_spot_instances, Types::Bool.default(false)
        attribute :reserved_capacity_percentage, Types::Integer.default(0)
        attribute :auto_shutdown_non_critical, Types::Bool.default(true)
        attribute :data_lifecycle_policies, Types::Bool.default(true)
        attribute :compress_backups, Types::Bool.default(true)
        attribute :dedup_enabled, Types::Bool.default(true)
      end
      
      # Monitoring and alerting configuration
      class MonitoringConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :primary_region_monitoring, Types::Bool.default(true)
        attribute :dr_region_monitoring, Types::Bool.default(true)
        attribute :replication_lag_threshold_seconds, Types::Integer.default(300)
        attribute :backup_monitoring, Types::Bool.default(true)
        attribute :synthetic_monitoring, Types::Bool.default(true)
        attribute :dashboard_enabled, Types::Bool.default(true)
        attribute :alerting_enabled, Types::Bool.default(true)
      end
      
      # Compliance configuration
      class ComplianceConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :rto_hours, Types::Integer.default(4)
        attribute :rpo_hours, Types::Integer.default(1)
        attribute :data_residency_requirements, Types::Array.of(Types::String).default([].freeze)
        attribute :encryption_required, Types::Bool.default(true)
        attribute :audit_logging, Types::Bool.default(true)
        attribute :compliance_standards, Types::Array.of(Types::String).default([].freeze)
      end
      
      # Main component attributes
      class DisasterRecoveryPilotLightAttributes < Dry::Struct
        transform_keys(&:to_sym)
        
        # Core configuration
        attribute :dr_name, Types::String
        attribute :dr_description, Types::String.default("Pilot light disaster recovery infrastructure")
        
        # Region configuration
        attribute :primary_region, PrimaryRegionConfig
        attribute :dr_region, DRRegionConfig
        
        # Critical data
        attribute :critical_data, CriticalDataConfig.default { CriticalDataConfig.new({}) }
        
        # Pilot light configuration
        attribute :pilot_light, PilotLightConfig.default { PilotLightConfig.new({}) }
        
        # Activation configuration
        attribute :activation, ActivationConfig.default { ActivationConfig.new({}) }
        
        # Testing configuration
        attribute :testing, TestingConfig.default { TestingConfig.new({}) }
        
        # Cost optimization
        attribute :cost_optimization, CostOptimizationConfig.default { CostOptimizationConfig.new({}) }
        
        # Monitoring
        attribute :monitoring, MonitoringConfig.default { MonitoringConfig.new({}) }
        
        # Compliance
        attribute :compliance, ComplianceConfig.default { ComplianceConfig.new({}) }
        
        # Advanced features
        attribute :enable_automated_failover, Types::Bool.default(false)
        attribute :enable_cross_region_vpc_peering, Types::Bool.default(true)
        attribute :enable_infrastructure_as_code_sync, Types::Bool.default(true)
        attribute :enable_application_config_sync, Types::Bool.default(true)
        
        # Resource tagging
        attribute :tags, Types::Hash.default({}.freeze)
        
        # Custom validations
        def validate!
          errors = []
          
          # Validate regions are different
          if primary_region.region == dr_region.region
            errors << "Primary and DR regions must be different"
          end
          
          # Validate CIDR blocks don't overlap
          if primary_region.vpc_cidr == dr_region.vpc_cidr && enable_cross_region_vpc_peering
            errors << "VPC CIDR blocks must not overlap when cross-region peering is enabled"
          end
          
          # Validate critical data configuration
          if critical_data.databases.empty? && critical_data.s3_buckets.empty? && critical_data.efs_filesystems.empty?
            errors << "At least one type of critical data must be specified"
          end
          
          # Validate backup retention
          if critical_data.backup_retention_days < 1 || critical_data.backup_retention_days > 35
            errors << "Backup retention must be between 1 and 35 days"
          end
          
          # Validate RTO/RPO
          if compliance.rto_hours < 1
            errors << "RTO must be at least 1 hour"
          end
          
          if compliance.rpo_hours < 0
            errors << "RPO cannot be negative"
          end
          
          if compliance.rpo_hours > compliance.rto_hours
            errors << "RPO should not exceed RTO"
          end
          
          # Validate activation configuration
          if activation.activation_method == 'automated' && !enable_automated_failover
            errors << "Automated activation requires enable_automated_failover to be true"
          end
          
          if activation.health_check_threshold < 1 || activation.health_check_threshold > 10
            errors << "Health check threshold must be between 1 and 10"
          end
          
          if activation.activation_timeout < 60 || activation.activation_timeout > 3600
            errors << "Activation timeout must be between 60 and 3600 seconds"
          end
          
          # Validate pilot light configuration
          if pilot_light.data_sync_interval < 60 || pilot_light.data_sync_interval > 86400
            errors << "Data sync interval must be between 60 and 86400 seconds"
          end
          
          if pilot_light.auto_scaling_min > pilot_light.auto_scaling_max
            errors << "Auto scaling min cannot exceed max"
          end
          
          # Validate monitoring configuration
          if monitoring.replication_lag_threshold_seconds < 1
            errors << "Replication lag threshold must be at least 1 second"
          end
          
          # Validate cost optimization
          if cost_optimization.reserved_capacity_percentage < 0 || cost_optimization.reserved_capacity_percentage > 100
            errors << "Reserved capacity percentage must be between 0 and 100"
          end
          
          # Validate testing configuration
          if testing.test_scenarios.empty? && testing.automated_testing
            errors << "Test scenarios must be specified when automated testing is enabled"
          end
          
          raise ArgumentError, errors.join(", ") unless errors.empty?
          
          true
        end
      end
    end
  end
end