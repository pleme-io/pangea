# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        class RdsClusterAttributes < Dry::Struct
          attribute :cluster_identifier, Resources::Types::String.optional
          attribute :cluster_identifier_prefix, Resources::Types::String.optional
          attribute :engine, Resources::Types::String.constrained(included_in: %w[aurora aurora-mysql aurora-postgresql])
          attribute :engine_version, Resources::Types::String.optional
          attribute :engine_mode, Resources::Types::String.default('provisioned').constrained(included_in: %w[provisioned serverless parallelquery global])
          attribute :database_name, Resources::Types::String.optional
          attribute :master_username, Resources::Types::String.optional
          attribute :master_password, Resources::Types::String.optional
          attribute :manage_master_user_password, Resources::Types::Bool.default(true)
          attribute :master_user_secret_kms_key_id, Resources::Types::String.optional
          attribute :db_subnet_group_name, Resources::Types::String.optional
          attribute :vpc_security_group_ids, Resources::Types::Array.of(Types::String).default([].freeze)
          attribute :availability_zones, Resources::Types::Array.of(Types::String).optional
          attribute :db_cluster_parameter_group_name, Resources::Types::String.optional
          attribute :port, Resources::Types::Integer.optional
          attribute :backup_retention_period, Resources::Types::Integer.default(7).constrained(gteq: 1, lteq: 35)
          attribute :preferred_backup_window, Resources::Types::String.optional
          attribute :preferred_maintenance_window, Resources::Types::String.optional
          attribute :copy_tags_to_snapshot, Resources::Types::Bool.default(true)
          attribute :storage_encrypted, Resources::Types::Bool.default(true)
          attribute :kms_key_id, Resources::Types::String.optional
          attribute :storage_type, Resources::Types::String.optional
          attribute :allocated_storage, Resources::Types::Integer.optional
          attribute :iops, Resources::Types::Integer.optional
          attribute :global_cluster_identifier, Resources::Types::String.optional
          attribute :scaling_configuration, Resources::Types::Hash.optional
          attribute? :serverless_v2_scaling_configuration, ServerlessV2Scaling.optional
          attribute? :restore_to_point_in_time, RestoreToPointInTime.optional
          attribute :snapshot_identifier, Resources::Types::String.optional
          attribute :source_region, Resources::Types::String.optional
          attribute :enabled_cloudwatch_logs_exports, Resources::Types::Array.of(Types::String).default([].freeze)
          attribute :monitoring_interval, Resources::Types::Integer.default(0).constrained(gteq: 0, lteq: 60)
          attribute :monitoring_role_arn, Resources::Types::String.optional
          attribute :performance_insights_enabled, Resources::Types::Bool.default(false)
          attribute :performance_insights_kms_key_id, Resources::Types::String.optional
          attribute :performance_insights_retention_period, Resources::Types::Integer.default(7).constrained(gteq: 7, lteq: 731)
          attribute :backtrack_window, Resources::Types::Integer.optional.constrained(gteq: 0, lteq: 259_200)
          attribute :apply_immediately, Resources::Types::Bool.default(false)
          attribute :auto_minor_version_upgrade, Resources::Types::Bool.default(true)
          attribute :deletion_protection, Resources::Types::Bool.default(false)
          attribute :skip_final_snapshot, Resources::Types::Bool.default(false)
          attribute :final_snapshot_identifier, Resources::Types::String.optional
          attribute :enable_http_endpoint, Resources::Types::Bool.default(false)
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          def self.new(attributes = {})
            attrs = super(attributes)
            RdsClusterValidation.validate(attrs)
            attrs
          end

          def engine_family = engine.include?('mysql') || engine == 'aurora' ? 'mysql' : 'postgresql'
          def is_mysql? = engine.include?('mysql') || engine == 'aurora'
          def is_postgresql? = engine.include?('postgresql')
          def is_serverless? = engine_mode == 'serverless'
          def is_global? = engine_mode == 'global' || !global_cluster_identifier.nil?
          def has_enhanced_monitoring? = monitoring_interval.positive?
          def has_performance_insights? = performance_insights_enabled
          def has_backtrack? = backtrack_window&.positive?
          def has_http_endpoint? = enable_http_endpoint
          def effective_port = port || (is_mysql? ? 3306 : 5432)
          def default_cloudwatch_logs_exports = is_mysql? ? %w[audit error general slowquery] : %w[postgresql]
          def supports_backtrack? = is_mysql? && engine_mode == 'provisioned'
          def supports_global? = engine_mode == 'provisioned'
          def supports_serverless_v2? = engine_mode == 'provisioned'

          def estimated_monthly_cost
            return serverless_v2_scaling_configuration ? "#{serverless_v2_scaling_configuration.estimated_hourly_cost_range} (730 hours/month)" : '~$20-200/month (Aurora Serverless v1)' if is_serverless?
            'Depends on cluster instances (see aws_rds_cluster_instance costs)'
          end
        end
      end
    end
  end
end
