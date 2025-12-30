# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require_relative 'instance_methods'

module Pangea
  module Resources
    module AWS
      module Types
        class RdsClusterInstanceAttributes < Dry::Struct
          include RdsClusterInstanceMethods

          INSTANCE_CLASSES = %w[
            db.t3.small db.t3.medium db.t3.large db.t3.xlarge db.t3.2xlarge
            db.t4g.micro db.t4g.small db.t4g.medium db.t4g.large db.t4g.xlarge db.t4g.2xlarge
            db.r5.large db.r5.xlarge db.r5.2xlarge db.r5.4xlarge db.r5.8xlarge db.r5.12xlarge db.r5.16xlarge db.r5.24xlarge
            db.r6g.large db.r6g.xlarge db.r6g.2xlarge db.r6g.4xlarge db.r6g.8xlarge db.r6g.12xlarge db.r6g.16xlarge
            db.r6i.large db.r6i.xlarge db.r6i.2xlarge db.r6i.4xlarge db.r6i.8xlarge db.r6i.12xlarge db.r6i.16xlarge db.r6i.24xlarge db.r6i.32xlarge
            db.x2g.medium db.x2g.large db.x2g.xlarge db.x2g.2xlarge db.x2g.4xlarge db.x2g.8xlarge db.x2g.12xlarge db.x2g.16xlarge
            serverless
          ].freeze

          attribute :identifier, Resources::Types::String.optional
          attribute :identifier_prefix, Resources::Types::String.optional
          attribute :cluster_identifier, Resources::Types::String
          attribute :instance_class, Resources::Types::String.enum(*INSTANCE_CLASSES)
          attribute :engine, Resources::Types::String.optional
          attribute :engine_version, Resources::Types::String.optional
          attribute :availability_zone, Resources::Types::String.optional
          attribute :db_parameter_group_name, Resources::Types::String.optional
          attribute :publicly_accessible, Resources::Types::Bool.default(false)
          attribute :monitoring_interval, Resources::Types::Integer.default(0).constrained(gteq: 0, lteq: 60)
          attribute :monitoring_role_arn, Resources::Types::String.optional
          attribute :performance_insights_enabled, Resources::Types::Bool.default(false)
          attribute :performance_insights_kms_key_id, Resources::Types::String.optional
          attribute :performance_insights_retention_period, Resources::Types::Integer.default(7).constrained(gteq: 7, lteq: 731)
          attribute :preferred_backup_window, Resources::Types::String.optional
          attribute :preferred_maintenance_window, Resources::Types::String.optional
          attribute :auto_minor_version_upgrade, Resources::Types::Bool.default(true)
          attribute :apply_immediately, Resources::Types::Bool.default(false)
          attribute :copy_tags_to_snapshot, Resources::Types::Bool.default(true)
          attribute :ca_cert_identifier, Resources::Types::String.optional
          attribute :promotion_tier, Resources::Types::Integer.default(1).constrained(gteq: 0, lteq: 15)
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          def self.new(attributes = {})
            attrs = super(attributes)
            raise Dry::Struct::Error, "Cannot specify both 'identifier' and 'identifier_prefix'" if attrs.identifier && attrs.identifier_prefix
            raise Dry::Struct::Error, 'monitoring_role_arn is required when monitoring_interval > 0' if attrs.monitoring_interval.positive? && !attrs.monitoring_role_arn
            raise Dry::Struct::Error, 'performance_insights_retention_period must be at least 7 days when Performance Insights is enabled' if attrs.performance_insights_enabled && attrs.performance_insights_retention_period < 7
            raise Dry::Struct::Error, 'Enhanced monitoring is not supported for serverless instances' if attrs.instance_class == 'serverless' && attrs.monitoring_interval.positive?
            attrs
          end
        end
      end
    end
  end
end
