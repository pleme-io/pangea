# frozen_string_literal: true

require 'dry-struct'
require_relative '../types'

module Pangea
  module Architectures
    module WebApplicationArchitecture
      module Types
        include Dry.Types()
        include Pangea::Architectures::Types

        # Web Application specific configuration
        Input = Hash.schema(
          # Required attributes
          domain_name: DomainName,
          environment: Environment,
          
          # Network configuration
          region: Region.default('us-east-1'),
          vpc_cidr: String.constrained(format: /^\d+\.\d+\.\d+\.\d+\/\d+$/).default('10.0.0.0/16'),
          availability_zones: Array.of(AvailabilityZone).default(['us-east-1a', 'us-east-1b', 'us-east-1c']),
          
          # Compute configuration
          instance_type: InstanceType.default('t3.medium'),
          auto_scaling: AutoScalingConfig.default({ min: 1, max: 3, desired: 1 }),
          
          # Database configuration
          database_enabled: Bool.default(true),
          database_engine: DatabaseEngine.default('mysql'),
          database_instance_class: DatabaseInstanceClass.default('db.t3.micro'),
          database_allocated_storage: Integer.constrained(gteq: 20, lteq: 65536).default(20),
          
          # Load balancing and SSL
          ssl_certificate_arn: String.optional,
          allowed_cidr_blocks: Array.of(String).default(['0.0.0.0/0']),
          
          # High availability and scaling
          high_availability: Bool.default(true),
          
          # Performance features
          enable_caching: Bool.default(false),
          enable_cdn: Bool.default(false),
          
          # Monitoring and logging
          monitoring: MonitoringConfig.default({
            detailed_monitoring: true,
            enable_logging: true,
            log_retention_days: 30,
            enable_alerting: true,
            enable_tracing: false
          }),
          
          # Security settings
          security: SecurityConfig.default({
            encryption_at_rest: true,
            encryption_in_transit: true,
            enable_waf: false,
            enable_ddos_protection: false,
            compliance_standards: []
          }),
          
          # Backup configuration
          backup: BackupConfig.default({
            backup_schedule: 'daily',
            retention_days: 7,
            cross_region_backup: false,
            point_in_time_recovery: false
          }),
          
          # Cost optimization
          cost_optimization: CostOptimizationConfig.default({
            use_spot_instances: false,
            use_reserved_instances: false,
            enable_auto_shutdown: false
          }),
          
          # Tags
          tags: Tags.default({})
        )

        # Output type definition
        Output = Hash.schema(
          # Architecture reference
          architecture_reference: InstanceOf(Pangea::Architectures::ArchitectureReference),
          
          # Primary outputs
          application_url: String.optional,
          load_balancer_dns: String.optional,
          database_endpoint: String.optional,
          
          # Optional outputs
          cdn_domain: String.optional,
          monitoring_dashboard_url: String.optional,
          
          # Cost and capabilities
          estimated_monthly_cost: Float,
          capabilities: Hash.schema(
            high_availability: Bool,
            auto_scaling: Bool,
            caching: Bool,
            cdn: Bool,
            ssl_termination: Bool,
            monitoring: Bool,
            backup: Bool
          )
        )

        # Validation methods
        def self.validate_web_application_config(attributes)
          # Validate that auto scaling min <= desired <= max
          auto_scaling = attributes[:auto_scaling]
          if auto_scaling && auto_scaling[:desired]
            unless auto_scaling[:min] <= auto_scaling[:desired] && auto_scaling[:desired] <= auto_scaling[:max]
              raise ArgumentError, "Auto scaling desired capacity must be between min and max"
            end
          end
          
          # Validate availability zones match region
          region = attributes[:region]
          availability_zones = attributes[:availability_zones]
          if region && availability_zones
            unless availability_zones.all? { |az| az.start_with?(region) }
              raise ArgumentError, "All availability zones must be in the specified region: #{region}"
            end
          end
          
          # Validate database storage size for engine type
          if attributes[:database_enabled]
            storage = attributes[:database_allocated_storage]
            engine = attributes[:database_engine]
            
            case engine
            when 'aurora', 'aurora-mysql', 'aurora-postgresql'
              # Aurora has different storage requirements
              if storage < 10
                raise ArgumentError, "Aurora minimum storage is 10 GB"
              end
            else
              if storage < 20
                raise ArgumentError, "RDS minimum storage is 20 GB"
              end
            end
          end
          
          # Validate SSL certificate ARN format if provided
          ssl_arn = attributes[:ssl_certificate_arn]
          if ssl_arn && !ssl_arn.match?(/^arn:aws:acm:[a-z0-9-]+:\d+:certificate\/[a-f0-9-]+$/)
            raise ArgumentError, "Invalid SSL certificate ARN format"
          end
          
          # Validate CIDR block format and range
          vpc_cidr = attributes[:vpc_cidr]
          if vpc_cidr && !Pangea::Architectures::Types.validate_cidr_block(vpc_cidr)
            raise ArgumentError, "Invalid VPC CIDR block: #{vpc_cidr}"
          end
          
          true
        end

        def self.compute_defaults_for_environment(environment)
          base_defaults = Pangea::Architectures::Types.defaults_for_environment(environment)
          
          web_app_defaults = case environment.to_s
                           when 'development'
                             {
                               instance_type: 't3.micro',
                               auto_scaling: { min: 1, max: 2, desired: 1 },
                               database_instance_class: 'db.t3.micro',
                               enable_caching: false,
                               enable_cdn: false,
                               high_availability: false
                             }
                           when 'staging'
                             {
                               instance_type: 't3.small',
                               auto_scaling: { min: 1, max: 4, desired: 2 },
                               database_instance_class: 'db.t3.small',
                               enable_caching: true,
                               enable_cdn: false,
                               high_availability: true
                             }
                           when 'production'
                             {
                               instance_type: 't3.medium',
                               auto_scaling: { min: 2, max: 10, desired: 3 },
                               database_instance_class: 'db.r5.large',
                               enable_caching: true,
                               enable_cdn: true,
                               high_availability: true
                             }
                           else
                             {}
                           end
          
          base_defaults.merge(web_app_defaults)
        end

        # Coercion methods
        def self.coerce_input(raw_attributes)
          # Apply environment-specific defaults
          if raw_attributes[:environment]
            defaults = compute_defaults_for_environment(raw_attributes[:environment])
            raw_attributes = defaults.merge(raw_attributes)
          end
          
          # Coerce types
          coerced = {}
          
          # Handle tags coercion
          coerced[:tags] = Pangea::Architectures::Types.coerce_tags(raw_attributes[:tags])
          
          # Handle auto scaling config coercion
          if raw_attributes[:auto_scaling]
            coerced[:auto_scaling] = Pangea::Architectures::Types.coerce_auto_scaling_config(raw_attributes[:auto_scaling])
          end
          
          # Merge coerced values
          final_attributes = raw_attributes.merge(coerced)
          
          # Validate the final configuration
          validate_web_application_config(final_attributes)
          
          Input.new(final_attributes)
        end

        # Cost estimation helpers
        def self.estimate_monthly_cost(attributes)
          cost = 0.0
          
          # Load balancer cost
          cost += 22.0 # ALB base cost
          
          # EC2 instances
          instance_cost = case attributes[:instance_type]
                         when /t3\.micro/ then 8.5
                         when /t3\.small/ then 17.0
                         when /t3\.medium/ then 34.0
                         when /t3\.large/ then 67.0
                         when /c5\.large/ then 72.0
                         else 50.0
                         end
          cost += instance_cost * attributes[:auto_scaling][:min]
          
          # Database cost
          if attributes[:database_enabled]
            db_cost = case attributes[:database_instance_class]
                     when /db\.t3\.micro/ then 16.0
                     when /db\.t3\.small/ then 32.0
                     when /db\.r5\.large/ then 180.0
                     else 80.0
                     end
            cost += db_cost
            
            # Additional cost for Multi-AZ
            cost += db_cost * 0.5 if attributes[:high_availability]
          end
          
          # Caching cost
          cost += 15.0 if attributes[:enable_caching]
          
          # CDN cost
          cost += 10.0 if attributes[:enable_cdn]
          
          # Storage costs
          cost += 5.0 # S3 buckets for logs, assets
          
          # Additional costs based on environment
          case attributes[:environment]
          when 'production'
            cost *= 1.2 # Additional monitoring, backups, etc.
          when 'staging'
            cost *= 1.1 # Some additional features
          end
          
          cost.round(2)
        end
      end
    end
  end
end