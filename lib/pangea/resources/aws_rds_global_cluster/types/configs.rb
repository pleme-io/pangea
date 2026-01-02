# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        module RdsGlobalClusterConfigs
          def self.production_mysql(identifier: nil)
            { global_cluster_identifier: identifier, engine: 'aurora-mysql', engine_version: '8.0.mysql_aurora.3.02.0',
              storage_encrypted: true, manage_master_user_password: true,
              backup_configuration: { backup_retention_period: 14, preferred_backup_window: '03:00-04:00', copy_tags_to_snapshot: true },
              tags: { Environment: 'production', Engine: 'mysql', Type: 'global' } }
          end

          def self.production_postgresql(identifier: nil)
            { global_cluster_identifier: identifier, engine: 'aurora-postgresql', engine_version: '14.9',
              storage_encrypted: true, manage_master_user_password: true,
              backup_configuration: { backup_retention_period: 14, preferred_backup_window: '02:00-03:00', copy_tags_to_snapshot: true },
              tags: { Environment: 'production', Engine: 'postgresql', Type: 'global' } }
          end

          def self.development(engine: 'aurora-mysql', identifier: nil)
            base = { global_cluster_identifier: identifier, engine: engine, storage_encrypted: true, manage_master_user_password: true,
                     force_destroy: true, backup_configuration: { backup_retention_period: 7, preferred_backup_window: '05:00-06:00', copy_tags_to_snapshot: false },
                     tags: { Environment: 'development', Type: 'global', Purpose: 'testing' } }
            version = engine.include?('postgresql') ? { engine_version: '14.9' } : { engine_version: '8.0.mysql_aurora.3.02.0' }
            base.merge(version)
          end

          def self.disaster_recovery(primary_region:, engine: 'aurora-mysql')
            { engine: engine, storage_encrypted: true, manage_master_user_password: true,
              backup_configuration: { backup_retention_period: 35, preferred_backup_window: '04:00-05:00', copy_tags_to_snapshot: true },
              tags: { Purpose: 'disaster-recovery', PrimaryRegion: primary_region, Type: 'global', Recovery: 'cross-region' } }
          end

          def self.from_existing_cluster(source_cluster_identifier:, engine: 'aurora-mysql')
            { engine: engine, source_db_cluster_identifier: source_cluster_identifier, storage_encrypted: true,
              backup_configuration: { backup_retention_period: 14, preferred_backup_window: '03:00-04:00', copy_tags_to_snapshot: true },
              tags: { Source: 'existing-cluster', Type: 'global', Migration: 'cluster-to-global' } }
          end
        end
      end
    end
  end
end
