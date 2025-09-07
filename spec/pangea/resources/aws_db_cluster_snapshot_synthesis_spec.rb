# frozen_string_literal: true

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/aws_db_cluster_snapshot/resource'
require 'pangea/resources/aws_db_cluster_snapshot/types'

RSpec.describe 'aws_db_cluster_snapshot synthesis' do
  include Pangea::Resources::AWS
  
  let(:synthesizer) { TerraformSynthesizer.new }
  
  describe 'terraform synthesis' do
    it 'synthesizes basic DB cluster snapshot' do
      synthesizer.instance_eval do
        aws_db_cluster_snapshot(:basic_snapshot, {
          db_cluster_identifier: "test-cluster",
          db_cluster_snapshot_identifier: "test-cluster-snapshot"
        })
      end
      
      result = synthesizer.synthesis
      snapshot = result[:resource][:aws_rds_cluster_snapshot][:basic_snapshot]
      
      expect(snapshot).to include(
        db_cluster_identifier: "test-cluster",
        db_cluster_snapshot_identifier: "test-cluster-snapshot"
      )
      expect(snapshot).not_to have_key(:tags)
    end
    
    it 'synthesizes snapshot with tags' do
      synthesizer.instance_eval do
        aws_db_cluster_snapshot(:tagged_snapshot, {
          db_cluster_identifier: "prod-aurora-cluster",
          db_cluster_snapshot_identifier: "prod-aurora-backup-20250103",
          tags: {
            Environment: "production",
            Purpose: "backup",
            Engine: "aurora-mysql",
            Automated: "false"
          }
        })
      end
      
      result = synthesizer.synthesis
      snapshot = result[:resource][:aws_rds_cluster_snapshot][:tagged_snapshot]
      
      expect(snapshot[:db_cluster_identifier]).to eq("prod-aurora-cluster")
      expect(snapshot[:db_cluster_snapshot_identifier]).to eq("prod-aurora-backup-20250103")
      expect(snapshot[:tags]).to include(
        Environment: "production",
        Purpose: "backup",
        Engine: "aurora-mysql",
        Automated: "false"
      )
    end
    
    it 'synthesizes production Aurora backup' do
      synthesizer.instance_eval do
        config = Pangea::Resources::AWS::DbClusterSnapshotConfigs.aurora_production_backup(
          cluster_id: "prod-aurora-cluster"
        )
        aws_db_cluster_snapshot(:prod_backup, config)
      end
      
      result = synthesizer.synthesis
      snapshot = result[:resource][:aws_rds_cluster_snapshot][:prod_backup]
      
      expect(snapshot[:db_cluster_identifier]).to eq("prod-aurora-cluster")
      expect(snapshot[:db_cluster_snapshot_identifier]).to match(/prod-aurora-cluster-prod-backup-cluster-\d{8}-\d{6}/)
      expect(snapshot[:tags]).to include(
        Purpose: "backup",
        Environment: "production",
        Engine: "aurora"
      )
    end
    
    it 'synthesizes global cluster backup' do
      synthesizer.instance_eval do
        config = Pangea::Resources::AWS::DbClusterSnapshotConfigs.global_cluster_backup(
          cluster_id: "global-aurora-cluster",
          region: "eu-west-1"
        )
        aws_db_cluster_snapshot(:global_backup, config)
      end
      
      result = synthesizer.synthesis
      snapshot = result[:resource][:aws_rds_cluster_snapshot][:global_backup]
      
      expect(snapshot[:db_cluster_identifier]).to eq("global-aurora-cluster")
      expect(snapshot[:db_cluster_snapshot_identifier]).to match(/global-aurora-cluster-global-eu-west-1-cluster-\d{8}-\d{6}/)
      expect(snapshot[:tags]).to include(
        Purpose: "global-backup",
        Region: "eu-west-1",
        Type: "global-cluster"
      )
    end
    
    it 'synthesizes pre-upgrade snapshot' do
      synthesizer.instance_eval do
        config = Pangea::Resources::AWS::DbClusterSnapshotConfigs.pre_upgrade_snapshot(
          cluster_id: "prod-postgres-cluster",
          from_version: "13.7",
          to_version: "14.6"
        )
        aws_db_cluster_snapshot(:upgrade_backup, config)
      end
      
      result = synthesizer.synthesis
      snapshot = result[:resource][:aws_rds_cluster_snapshot][:upgrade_backup]
      
      expect(snapshot[:db_cluster_identifier]).to eq("prod-postgres-cluster")
      expect(snapshot[:db_cluster_snapshot_identifier]).to match(/prod-postgres-cluster-pre-upgrade-cluster-\d{8}-\d{6}/)
      expect(snapshot[:tags]).to include(
        Purpose: "pre-upgrade",
        FromVersion: "13.7",
        ToVersion: "14.6",
        Critical: "true"
      )
    end
    
    it 'synthesizes disaster recovery snapshot' do
      synthesizer.instance_eval do
        config = Pangea::Resources::AWS::DbClusterSnapshotConfigs.disaster_recovery_snapshot(
          cluster_id: "critical-app-cluster",
          primary_region: "us-east-1",
          dr_region: "us-west-2"
        )
        aws_db_cluster_snapshot(:dr_backup, config)
      end
      
      result = synthesizer.synthesis
      snapshot = result[:resource][:aws_rds_cluster_snapshot][:dr_backup]
      
      expect(snapshot[:db_cluster_identifier]).to eq("critical-app-cluster")
      expect(snapshot[:tags]).to include(
        Purpose: "disaster-recovery",
        PrimaryRegion: "us-east-1",
        DRRegion: "us-west-2",
        Type: "cross-region",
        Critical: "true",
        RetentionDays: "90"
      )
    end
    
    it 'synthesizes development snapshot' do
      synthesizer.instance_eval do
        config = Pangea::Resources::AWS::DbClusterSnapshotConfigs.development_snapshot(
          cluster_id: "dev-test-cluster",
          purpose: "integration-testing"
        )
        aws_db_cluster_snapshot(:dev_snapshot, config)
      end
      
      result = synthesizer.synthesis
      snapshot = result[:resource][:aws_rds_cluster_snapshot][:dev_snapshot]
      
      expect(snapshot[:db_cluster_identifier]).to eq("dev-test-cluster")
      expect(snapshot[:tags]).to include(
        Purpose: "integration-testing",
        Environment: "development",
        Temporary: "true",
        RetentionDays: "3"
      )
    end
    
    it 'synthesizes PITR baseline snapshot' do
      synthesizer.instance_eval do
        config = Pangea::Resources::AWS::DbClusterSnapshotConfigs.pitr_baseline(
          cluster_id: "prod-cluster",
          restore_point: "2025-01-03T12:00:00Z"
        )
        aws_db_cluster_snapshot(:pitr_snapshot, config)
      end
      
      result = synthesizer.synthesis
      snapshot = result[:resource][:aws_rds_cluster_snapshot][:pitr_snapshot]
      
      expect(snapshot[:db_cluster_identifier]).to eq("prod-cluster")
      expect(snapshot[:tags]).to include(
        Purpose: "pitr-baseline",
        RestorePoint: "2025-01-03T12:00:00Z",
        Type: "recovery",
        Baseline: "true"
      )
    end
    
    it 'synthesizes multiple snapshots with resource references' do
      synthesizer.instance_eval do
        # Create a cluster reference
        cluster_ref = ref(:aws_rds_cluster, :aurora_cluster, :id)
        
        # Production backup
        aws_db_cluster_snapshot(:prod_backup, {
          db_cluster_identifier: cluster_ref,
          db_cluster_snapshot_identifier: "aurora-prod-backup"
        })
        
        # Pre-maintenance snapshot
        aws_db_cluster_snapshot(:pre_maint, {
          db_cluster_identifier: cluster_ref,
          db_cluster_snapshot_identifier: "aurora-pre-maintenance",
          tags: {
            Purpose: "pre-maintenance",
            MaintenanceWindow: "2025-01-10"
          }
        })
      end
      
      result = synthesizer.synthesis
      
      prod_backup = result[:resource][:aws_rds_cluster_snapshot][:prod_backup]
      expect(prod_backup[:db_cluster_identifier]).to eq("${aws_rds_cluster.aurora_cluster.id}")
      expect(prod_backup[:db_cluster_snapshot_identifier]).to eq("aurora-prod-backup")
      
      pre_maint = result[:resource][:aws_rds_cluster_snapshot][:pre_maint]
      expect(pre_maint[:db_cluster_identifier]).to eq("${aws_rds_cluster.aurora_cluster.id}")
      expect(pre_maint[:tags][:Purpose]).to eq("pre-maintenance")
    end
    
    it 'handles empty tags gracefully' do
      synthesizer.instance_eval do
        aws_db_cluster_snapshot(:no_tags, {
          db_cluster_identifier: "test-cluster",
          db_cluster_snapshot_identifier: "test-snapshot",
          tags: {}
        })
      end
      
      result = synthesizer.synthesis
      snapshot = result[:resource][:aws_rds_cluster_snapshot][:no_tags]
      
      expect(snapshot).not_to have_key(:tags)
    end
    
    it 'generates correct JSON for terraform' do
      synthesizer.instance_eval do
        aws_db_cluster_snapshot(:json_test, {
          db_cluster_identifier: "aurora-mysql-cluster",
          db_cluster_snapshot_identifier: "aurora-mysql-backup-20250103-120000",
          tags: {
            Environment: "production",
            Engine: "aurora-mysql",
            Version: "8.0.mysql_aurora.3.04.0",
            Backup: "manual"
          }
        })
      end
      
      json_output = JSON.pretty_generate(synthesizer.synthesis)
      parsed = JSON.parse(json_output, symbolize_names: true)
      
      snapshot = parsed[:resource][:aws_rds_cluster_snapshot][:json_test]
      expect(snapshot[:db_cluster_identifier]).to eq("aurora-mysql-cluster")
      expect(snapshot[:db_cluster_snapshot_identifier]).to eq("aurora-mysql-backup-20250103-120000")
      expect(snapshot[:tags]).to be_a(Hash)
      expect(snapshot[:tags][:Engine]).to eq("aurora-mysql")
    end
    
    it 'synthesizes complete snapshot lifecycle' do
      synthesizer.instance_eval do
        # Initial backup
        initial = aws_db_cluster_snapshot(:initial_backup, {
          db_cluster_identifier: "prod-cluster",
          db_cluster_snapshot_identifier: "prod-cluster-initial-20250101",
          tags: { Stage: "initial", Purpose: "backup" }
        })
        
        # Pre-upgrade backup
        pre_upgrade = aws_db_cluster_snapshot(:pre_upgrade, {
          db_cluster_identifier: "prod-cluster",
          db_cluster_snapshot_identifier: "prod-cluster-pre-upgrade-20250103",
          tags: { Stage: "pre-upgrade", FromVersion: "13.7", ToVersion: "14.6" }
        })
        
        # Post-upgrade verification
        post_upgrade = aws_db_cluster_snapshot(:post_upgrade, {
          db_cluster_identifier: "prod-cluster",
          db_cluster_snapshot_identifier: "prod-cluster-post-upgrade-20250103",
          tags: { Stage: "post-upgrade", Version: "14.6", Verified: "true" }
        })
      end
      
      result = synthesizer.synthesis
      resources = result[:resource][:aws_rds_cluster_snapshot]
      
      expect(resources).to have_key(:initial_backup)
      expect(resources).to have_key(:pre_upgrade)
      expect(resources).to have_key(:post_upgrade)
      
      expect(resources[:initial_backup][:tags][:Stage]).to eq("initial")
      expect(resources[:pre_upgrade][:tags][:Stage]).to eq("pre-upgrade")
      expect(resources[:post_upgrade][:tags][:Stage]).to eq("post-upgrade")
    end
  end
end