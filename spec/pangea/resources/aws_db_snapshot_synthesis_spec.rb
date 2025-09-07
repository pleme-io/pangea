# frozen_string_literal: true

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/aws_db_snapshot/resource'
require 'pangea/resources/aws_db_snapshot/types'

RSpec.describe 'aws_db_snapshot synthesis' do
  include Pangea::Resources::AWS
  
  let(:synthesizer) { TerraformSynthesizer.new }
  
  describe 'terraform synthesis' do
    it 'synthesizes basic DB snapshot' do
      synthesizer.instance_eval do
        aws_db_snapshot(:basic_snapshot, {
          db_instance_identifier: "test-instance",
          db_snapshot_identifier: "test-instance-snapshot"
        })
      end
      
      result = synthesizer.synthesis
      snapshot = result[:resource][:aws_db_snapshot][:basic_snapshot]
      
      expect(snapshot).to include(
        db_instance_identifier: "test-instance",
        db_snapshot_identifier: "test-instance-snapshot"
      )
      expect(snapshot).not_to have_key(:tags)
    end
    
    it 'synthesizes snapshot with tags' do
      synthesizer.instance_eval do
        aws_db_snapshot(:tagged_snapshot, {
          db_instance_identifier: "prod-mysql-instance",
          db_snapshot_identifier: "prod-mysql-backup-20250103",
          tags: {
            Environment: "production",
            Purpose: "backup",
            Engine: "mysql",
            Automated: "false"
          }
        })
      end
      
      result = synthesizer.synthesis
      snapshot = result[:resource][:aws_db_snapshot][:tagged_snapshot]
      
      expect(snapshot[:db_instance_identifier]).to eq("prod-mysql-instance")
      expect(snapshot[:db_snapshot_identifier]).to eq("prod-mysql-backup-20250103")
      expect(snapshot[:tags]).to include(
        Environment: "production",
        Purpose: "backup",
        Engine: "mysql",
        Automated: "false"
      )
    end
    
    it 'synthesizes production backup' do
      synthesizer.instance_eval do
        config = Pangea::Resources::AWS::DbSnapshotConfigs.production_backup(
          db_instance_id: "prod-postgres-instance"
        )
        aws_db_snapshot(:prod_backup, config)
      end
      
      result = synthesizer.synthesis
      snapshot = result[:resource][:aws_db_snapshot][:prod_backup]
      
      expect(snapshot[:db_instance_identifier]).to eq("prod-postgres-instance")
      expect(snapshot[:db_snapshot_identifier]).to match(/prod-postgres-instance-backup-\d{8}-\d{6}/)
      expect(snapshot[:tags]).to include(
        Purpose: "backup",
        Environment: "production"
      )
    end
    
    it 'synthesizes pre-maintenance snapshot' do
      synthesizer.instance_eval do
        config = Pangea::Resources::AWS::DbSnapshotConfigs.pre_maintenance(
          db_instance_id: "prod-mariadb-instance",
          maintenance_type: "upgrade"
        )
        aws_db_snapshot(:pre_maint, config)
      end
      
      result = synthesizer.synthesis
      snapshot = result[:resource][:aws_db_snapshot][:pre_maint]
      
      expect(snapshot[:db_instance_identifier]).to eq("prod-mariadb-instance")
      expect(snapshot[:db_snapshot_identifier]).to match(/prod-mariadb-instance-pre-upgrade-\d{8}-\d{6}/)
      expect(snapshot[:tags]).to include(
        Purpose: "pre-maintenance",
        MaintenanceType: "upgrade",
        Type: "safety"
      )
    end
    
    it 'synthesizes development snapshot' do
      synthesizer.instance_eval do
        config = Pangea::Resources::AWS::DbSnapshotConfigs.development_snapshot(
          db_instance_id: "dev-test-instance",
          purpose: "integration-testing"
        )
        aws_db_snapshot(:dev_snapshot, config)
      end
      
      result = synthesizer.synthesis
      snapshot = result[:resource][:aws_db_snapshot][:dev_snapshot]
      
      expect(snapshot[:db_instance_identifier]).to eq("dev-test-instance")
      expect(snapshot[:db_snapshot_identifier]).to match(/dev-test-instance-integration-testing-\d{8}-\d{6}/)
      expect(snapshot[:tags]).to include(
        Purpose: "integration-testing",
        Environment: "development",
        Temporary: "true"
      )
    end
    
    it 'synthesizes migration snapshot' do
      synthesizer.instance_eval do
        config = Pangea::Resources::AWS::DbSnapshotConfigs.migration_snapshot(
          db_instance_id: "prod-app-db",
          migration_id: "schema-v2"
        )
        aws_db_snapshot(:migration_backup, config)
      end
      
      result = synthesizer.synthesis
      snapshot = result[:resource][:aws_db_snapshot][:migration_backup]
      
      expect(snapshot[:db_instance_identifier]).to eq("prod-app-db")
      expect(snapshot[:db_snapshot_identifier]).to eq("prod-app-db-migration-schema-v2")
      expect(snapshot[:tags]).to include(
        Purpose: "migration",
        MigrationId: "schema-v2",
        Type: "safety",
        Critical: "true"
      )
    end
    
    it 'synthesizes multiple snapshots with resource references' do
      synthesizer.instance_eval do
        # Create an instance reference
        instance_ref = ref(:aws_db_instance, :mysql_instance, :id)
        
        # Production backup
        aws_db_snapshot(:prod_backup, {
          db_instance_identifier: instance_ref,
          db_snapshot_identifier: "mysql-prod-backup"
        })
        
        # Pre-upgrade snapshot
        aws_db_snapshot(:pre_upgrade, {
          db_instance_identifier: instance_ref,
          db_snapshot_identifier: "mysql-pre-upgrade",
          tags: {
            Purpose: "pre-upgrade",
            FromVersion: "5.7",
            ToVersion: "8.0"
          }
        })
      end
      
      result = synthesizer.synthesis
      
      prod_backup = result[:resource][:aws_db_snapshot][:prod_backup]
      expect(prod_backup[:db_instance_identifier]).to eq("${aws_db_instance.mysql_instance.id}")
      expect(prod_backup[:db_snapshot_identifier]).to eq("mysql-prod-backup")
      
      pre_upgrade = result[:resource][:aws_db_snapshot][:pre_upgrade]
      expect(pre_upgrade[:db_instance_identifier]).to eq("${aws_db_instance.mysql_instance.id}")
      expect(pre_upgrade[:tags][:Purpose]).to eq("pre-upgrade")
      expect(pre_upgrade[:tags][:ToVersion]).to eq("8.0")
    end
    
    it 'handles empty tags gracefully' do
      synthesizer.instance_eval do
        aws_db_snapshot(:no_tags, {
          db_instance_identifier: "test-instance",
          db_snapshot_identifier: "test-snapshot",
          tags: {}
        })
      end
      
      result = synthesizer.synthesis
      snapshot = result[:resource][:aws_db_snapshot][:no_tags]
      
      expect(snapshot).not_to have_key(:tags)
    end
    
    it 'generates correct JSON for terraform' do
      synthesizer.instance_eval do
        aws_db_snapshot(:json_test, {
          db_instance_identifier: "mysql-instance",
          db_snapshot_identifier: "mysql-backup-20250103-120000",
          tags: {
            Environment: "production",
            Engine: "mysql",
            Version: "8.0.35",
            Backup: "manual"
          }
        })
      end
      
      json_output = JSON.pretty_generate(synthesizer.synthesis)
      parsed = JSON.parse(json_output, symbolize_names: true)
      
      snapshot = parsed[:resource][:aws_db_snapshot][:json_test]
      expect(snapshot[:db_instance_identifier]).to eq("mysql-instance")
      expect(snapshot[:db_snapshot_identifier]).to eq("mysql-backup-20250103-120000")
      expect(snapshot[:tags]).to be_a(Hash)
      expect(snapshot[:tags][:Engine]).to eq("mysql")
    end
    
    it 'synthesizes complete snapshot lifecycle' do
      synthesizer.instance_eval do
        # Initial backup
        initial = aws_db_snapshot(:initial_backup, {
          db_instance_identifier: "prod-db",
          db_snapshot_identifier: "prod-db-initial-20250101",
          tags: { Stage: "initial", Purpose: "backup" }
        })
        
        # Pre-maintenance backup
        pre_maint = aws_db_snapshot(:pre_maint, {
          db_instance_identifier: "prod-db",
          db_snapshot_identifier: "prod-db-pre-maint-20250103",
          tags: { Stage: "pre-maintenance", MaintenanceWindow: "2025-01-03" }
        })
        
        # Post-maintenance verification
        post_maint = aws_db_snapshot(:post_maint, {
          db_instance_identifier: "prod-db",
          db_snapshot_identifier: "prod-db-post-maint-20250103",
          tags: { Stage: "post-maintenance", Verified: "true" }
        })
      end
      
      result = synthesizer.synthesis
      resources = result[:resource][:aws_db_snapshot]
      
      expect(resources).to have_key(:initial_backup)
      expect(resources).to have_key(:pre_maint)
      expect(resources).to have_key(:post_maint)
      
      expect(resources[:initial_backup][:tags][:Stage]).to eq("initial")
      expect(resources[:pre_maint][:tags][:Stage]).to eq("pre-maintenance")
      expect(resources[:post_maint][:tags][:Stage]).to eq("post-maintenance")
    end
    
    it 'synthesizes snapshots for different database engines' do
      synthesizer.instance_eval do
        # MySQL snapshot
        aws_db_snapshot(:mysql_backup, {
          db_instance_identifier: "mysql-db",
          db_snapshot_identifier: "mysql-backup",
          tags: { Engine: "mysql", Version: "8.0" }
        })
        
        # PostgreSQL snapshot
        aws_db_snapshot(:postgres_backup, {
          db_instance_identifier: "postgres-db",
          db_snapshot_identifier: "postgres-backup",
          tags: { Engine: "postgres", Version: "14.6" }
        })
        
        # MariaDB snapshot
        aws_db_snapshot(:mariadb_backup, {
          db_instance_identifier: "mariadb-db",
          db_snapshot_identifier: "mariadb-backup",
          tags: { Engine: "mariadb", Version: "10.6" }
        })
      end
      
      result = synthesizer.synthesis
      snapshots = result[:resource][:aws_db_snapshot]
      
      expect(snapshots[:mysql_backup][:tags][:Engine]).to eq("mysql")
      expect(snapshots[:postgres_backup][:tags][:Engine]).to eq("postgres")
      expect(snapshots[:mariadb_backup][:tags][:Engine]).to eq("mariadb")
    end
    
    it 'synthesizes cross-region snapshot copy scenario' do
      synthesizer.instance_eval do
        # Source region snapshot
        aws_db_snapshot(:source_snapshot, {
          db_instance_identifier: "prod-db",
          db_snapshot_identifier: "prod-db-source-us-east-1",
          tags: {
            Region: "us-east-1",
            Type: "source",
            Purpose: "cross-region-copy"
          }
        })
        
        # Target region snapshot (would be copied)
        aws_db_snapshot(:target_snapshot, {
          db_instance_identifier: "prod-db",
          db_snapshot_identifier: "prod-db-copy-us-west-2",
          tags: {
            Region: "us-west-2",
            Type: "copy",
            SourceRegion: "us-east-1",
            Purpose: "disaster-recovery"
          }
        })
      end
      
      result = synthesizer.synthesis
      snapshots = result[:resource][:aws_db_snapshot]
      
      expect(snapshots[:source_snapshot][:tags][:Type]).to eq("source")
      expect(snapshots[:target_snapshot][:tags][:Type]).to eq("copy")
      expect(snapshots[:target_snapshot][:tags][:SourceRegion]).to eq("us-east-1")
    end
  end
end