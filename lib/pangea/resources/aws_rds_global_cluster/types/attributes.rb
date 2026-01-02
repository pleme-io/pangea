# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require_relative 'backup_config'

module Pangea
  module Resources
    module AWS
      module Types
        class RdsGlobalClusterAttributes < Dry::Struct
          attribute :global_cluster_identifier, Resources::Types::String.optional
          attribute :engine, Resources::Types::String.enum('aurora', 'aurora-mysql', 'aurora-postgresql')
          attribute :engine_version, Resources::Types::String.optional
          attribute :database_name, Resources::Types::String.optional
          attribute :master_username, Resources::Types::String.optional
          attribute :master_password, Resources::Types::String.optional
          attribute :manage_master_user_password, Resources::Types::Bool.default(true)
          attribute :master_user_secret_kms_key_id, Resources::Types::String.optional
          attribute :storage_encrypted, Resources::Types::Bool.default(true)
          attribute :kms_key_id, Resources::Types::String.optional
          attribute :force_destroy, Resources::Types::Bool.default(false)
          attribute :source_db_cluster_identifier, Resources::Types::String.optional
          attribute :engine_lifecycle_support, Resources::Types::String.enum('open-source-rds-extended-support', 'open-source-rds-extended-support-disabled').optional
          attribute? :backup_configuration, GlobalClusterBackupConfiguration.optional
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          def self.new(attributes = {})
            attrs = super(attributes)
            raise Dry::Struct::Error, "Cannot specify both 'master_password' and 'manage_master_user_password'" if attrs.master_password && attrs.manage_master_user_password
            if attrs.source_db_cluster_identifier
              raise Dry::Struct::Error, 'database_name, master_username, and master_password are inherited from source cluster' if attrs.database_name || attrs.master_username || attrs.master_password
            else
              raise Dry::Struct::Error, 'master_username is required when not using source_db_cluster_identifier' unless attrs.master_username
            end
            raise Dry::Struct::Error, "Invalid engine version '#{attrs.engine_version}' for engine '#{attrs.engine}'" if attrs.engine_version && !valid_engine_version?(attrs.engine, attrs.engine_version)
            attrs
          end

          def self.valid_engine_version?(engine, version)
            case engine
            when 'aurora', 'aurora-mysql' then version.match?(/^(5\.7|8\.0)\.mysql_aurora\.\d+\.\d+\.\d+$/)
            when 'aurora-postgresql' then version.match?(/^\d{1,2}\.\d+$/)
            else false
            end
          end

          def engine_family = engine.include?('postgresql') ? 'postgresql' : 'mysql'
          def is_mysql? = engine.include?('mysql') || engine == 'aurora'
          def is_postgresql? = engine.include?('postgresql')
          def uses_managed_password? = manage_master_user_password
          def created_from_source? = !source_db_cluster_identifier.nil?
          def is_encrypted? = storage_encrypted
          def allows_force_destroy? = force_destroy
          def has_backup_configuration? = !backup_configuration.nil?
          def effective_backup_retention_period = backup_configuration&.backup_retention_period || 7
          def effective_backup_window = backup_configuration&.preferred_backup_window || '03:00-04:00'

          def engine_major_version
            case engine
            when 'aurora', 'aurora-mysql' then engine_version&.match(/^(\d+\.\d+)/)&.[](1) || '8.0'
            when 'aurora-postgresql' then engine_version&.match(/^(\d{1,2})/)&.[](1) || '14'
            else 'unknown'
            end
          end

          SUPPORTED_REGIONS = %w[us-east-1 us-east-2 us-west-1 us-west-2 ca-central-1 eu-west-1 eu-west-2 eu-west-3 eu-central-1 eu-north-1 ap-northeast-1 ap-northeast-2 ap-southeast-1 ap-southeast-2 ap-south-1 sa-east-1].freeze
          def supported_regions = SUPPORTED_REGIONS
          def supports_region?(region) = SUPPORTED_REGIONS.include?(region)

          def estimated_monthly_cost
            base_cost = engine_family == 'postgresql' ? '~$120-600/month per region' : '~$100-500/month per region'
            "#{base_cost} + cross-region data transfer costs"
          end

          def configuration_summary
            summary = ["Engine: #{engine_family}", 'Regions: Global (multi-region)', "Encryption: #{is_encrypted? ? 'enabled' : 'disabled'}"]
            summary << "Source: #{source_db_cluster_identifier}" if created_from_source?
            summary << "Backup: #{effective_backup_retention_period} days" if has_backup_configuration?
            summary.join('; ')
          end

          def recommended_secondary_regions(primary_region)
            { 'us-east-1' => %w[us-west-2 eu-west-1], 'us-west-2' => %w[us-east-1 eu-west-1], 'eu-west-1' => %w[us-east-1 ap-northeast-1], 'ap-northeast-1' => %w[us-west-2 eu-west-1] }[primary_region] || %w[us-east-1 us-west-2 eu-west-1].reject { |r| r == primary_region }
          end
        end
      end
    end
  end
end
