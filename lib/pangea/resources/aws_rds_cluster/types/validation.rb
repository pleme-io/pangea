# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        module RdsClusterValidation
          def self.validate(attrs)
            raise Dry::Struct::Error, "Cannot specify both 'cluster_identifier' and 'cluster_identifier_prefix'" if attrs.cluster_identifier && attrs.cluster_identifier_prefix
            raise Dry::Struct::Error, "Cannot specify both 'master_password' and 'manage_master_user_password'" if attrs.master_password && attrs.manage_master_user_password
            raise Dry::Struct::Error, "Cannot specify both 'scaling_configuration' and 'serverless_v2_scaling_configuration'" if attrs.scaling_configuration && attrs.serverless_v2_scaling_configuration
            raise Dry::Struct::Error, "Serverless configurations only valid when engine_mode is 'serverless'" if attrs.engine_mode != 'serverless' && (attrs.scaling_configuration || attrs.enable_http_endpoint)
            raise Dry::Struct::Error, 'Backtrack is only supported by Aurora MySQL clusters' if attrs.backtrack_window && !attrs.engine.include?('mysql')
            raise Dry::Struct::Error, "global_cluster_identifier can only be used with engine_mode 'global'" if attrs.global_cluster_identifier && attrs.engine_mode != 'global'
            raise Dry::Struct::Error, 'monitoring_role_arn is required when monitoring_interval > 0' if attrs.monitoring_interval.positive? && !attrs.monitoring_role_arn
            raise Dry::Struct::Error, 'performance_insights_retention_period must be at least 7 days when Performance Insights is enabled' if attrs.performance_insights_enabled && attrs.performance_insights_retention_period < 7
            raise Dry::Struct::Error, 'final_snapshot_identifier is required when skip_final_snapshot is false' if !attrs.skip_final_snapshot && !attrs.final_snapshot_identifier
            raise Dry::Struct::Error, "iops must be specified when storage_type is 'io1'" if attrs.engine_mode == 'provisioned' && attrs.storage_type == 'io1' && !attrs.iops
          end
        end
      end
    end
  end
end
