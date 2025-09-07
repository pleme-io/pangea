# frozen_string_literal: true
# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/aws_rds_cluster/resource'
require 'pangea/resources/aws_rds_cluster/types'

RSpec.describe 'aws_rds_cluster synthesis' do
  include Pangea::Resources::AWS
  
  let(:synthesizer) { TerraformSynthesizer.new }
  
  describe 'terraform synthesis' do
    it 'synthesizes basic Aurora MySQL cluster' do
      synthesizer.instance_eval do
        aws_rds_cluster(:basic_aurora, {
          engine: "aurora-mysql"
        })
      end
      
      result = synthesizer.synthesis
      cluster = result[:resource][:aws_rds_cluster][:basic_aurora]
      
      expect(cluster).to include(
        engine: "aurora-mysql",
        backup_retention_period: 7,
        copy_tags_to_snapshot: true,
        storage_encrypted: true,
        manage_master_user_password: true,
        auto_minor_version_upgrade: true,
        deletion_protection: false,
        skip_final_snapshot: false
      )
      expect(cluster).not_to have_key(:engine_mode)  # Default is provisioned
    end
    
    it 'synthesizes Aurora PostgreSQL cluster with configuration' do
      synthesizer.instance_eval do
        aws_rds_cluster(:postgres_cluster, {
          engine: "aurora-postgresql",
          cluster_identifier: "prod-postgres-cluster",
          database_name: "app_database",
          master_username: "dbadmin",
          port: 5432,
          backup_retention_period: 14,
          enabled_cloudwatch_logs_exports: ["postgresql"],
          tags: {
            Environment: "production",
            Engine: "postgresql"
          }
        })
      end
      
      result = synthesizer.synthesis
      cluster = result[:resource][:aws_rds_cluster][:postgres_cluster]
      
      expect(cluster[:cluster_identifier]).to eq("prod-postgres-cluster")
      expect(cluster[:engine]).to eq("aurora-postgresql")
      expect(cluster[:database_name]).to eq("app_database")
      expect(cluster[:master_username]).to eq("dbadmin")
      expect(cluster[:port]).to eq(5432)
      expect(cluster[:backup_retention_period]).to eq(14)
      expect(cluster[:enabled_cloudwatch_logs_exports]).to eq(["postgresql"])
    end
    
    it 'synthesizes serverless v2 Aurora cluster' do
      synthesizer.instance_eval do
        aws_rds_cluster(:serverless_v2, {
          engine: "aurora-mysql",
          engine_mode: "provisioned",
          serverless_v2_scaling_configuration: {
            min_capacity: 0.5,
            max_capacity: 16.0
          },
          tags: {
            ServerlessVersion: "v2",
            AutoScaling: "enabled"
          }
        })
      end
      
      result = synthesizer.synthesis
      cluster = result[:resource][:aws_rds_cluster][:serverless_v2]
      
      expect(cluster[:engine_mode]).to eq("provisioned")
      expect(cluster[:serverless_v2_scaling_configuration]).to include(
        min_capacity: 0.5,
        max_capacity: 16.0
      )
      expect(cluster[:tags][:ServerlessVersion]).to eq("v2")
    end
    
    it 'synthesizes global Aurora cluster' do
      synthesizer.instance_eval do
        aws_rds_cluster(:global_primary, {
          engine: "aurora-mysql",
          engine_mode: "global",
          global_cluster_identifier: "my-global-cluster",
          backup_retention_period: 14,
          deletion_protection: true,
          tags: {
            ClusterType: "global-primary",
            Region: "us-east-1"
          }
        })
      end
      
      result = synthesizer.synthesis
      cluster = result[:resource][:aws_rds_cluster][:global_primary]
      
      expect(cluster[:engine_mode]).to eq("global")
      expect(cluster[:global_cluster_identifier]).to eq("my-global-cluster")
      expect(cluster[:deletion_protection]).to be true
    end
    
    it 'synthesizes cluster with enhanced monitoring and insights' do
      synthesizer.instance_eval do
        aws_rds_cluster(:monitored_cluster, {
          engine: "aurora-mysql",
          monitoring_interval: 60,
          monitoring_role_arn: "arn:aws:iam::123456789012:role/rds-monitoring-role",
          performance_insights_enabled: true,
          performance_insights_kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678",
          performance_insights_retention_period: 90,
          enabled_cloudwatch_logs_exports: ["audit", "error", "general", "slowquery"]
        })
      end
      
      result = synthesizer.synthesis
      cluster = result[:resource][:aws_rds_cluster][:monitored_cluster]
      
      expect(cluster[:monitoring_interval]).to eq(60)
      expect(cluster[:monitoring_role_arn]).to include("arn:aws:iam")
      expect(cluster[:performance_insights_enabled]).to be true
      expect(cluster[:performance_insights_retention_period]).to eq(90)
      expect(cluster[:enabled_cloudwatch_logs_exports]).to include("slowquery")
    end
    
    it 'synthesizes cluster with backtrack enabled' do
      synthesizer.instance_eval do
        aws_rds_cluster(:backtrack_cluster, {
          engine: "aurora-mysql",
          backtrack_window: 259200,  # 72 hours
          tags: {
            Backtrack: "enabled",
            BacktrackHours: "72"
          }
        })
      end
      
      result = synthesizer.synthesis
      cluster = result[:resource][:aws_rds_cluster][:backtrack_cluster]
      
      expect(cluster[:backtrack_window]).to eq(259200)
      expect(cluster[:tags][:Backtrack]).to eq("enabled")
    end
    
    it 'synthesizes cluster with point-in-time restore' do
      synthesizer.instance_eval do
        aws_rds_cluster(:restored_cluster, {
          engine: "aurora-mysql",
          restore_to_point_in_time: {
            source_cluster_identifier: "source-prod-cluster",
            use_latest_restorable_time: true,
            restore_type: "full-copy"
          }
        })
      end
      
      result = synthesizer.synthesis
      cluster = result[:resource][:aws_rds_cluster][:restored_cluster]
      
      expect(cluster[:restore_to_point_in_time]).to include(
        source_cluster_identifier: "source-prod-cluster",
        use_latest_restorable_time: true,
        restore_type: "full-copy"
      )
    end
    
    it 'synthesizes cluster with specific restore time' do
      synthesizer.instance_eval do
        aws_rds_cluster(:time_restored, {
          engine: "aurora-postgresql",
          restore_to_point_in_time: {
            source_cluster_identifier: "source-postgres-cluster",
            restore_to_time: "2025-01-03T14:30:00Z"
          }
        })
      end
      
      result = synthesizer.synthesis
      cluster = result[:resource][:aws_rds_cluster][:time_restored]
      
      expect(cluster[:restore_to_point_in_time]).to include(
        source_cluster_identifier: "source-postgres-cluster",
        restore_to_time: "2025-01-03T14:30:00Z"
      )
      expect(cluster[:restore_to_point_in_time]).not_to have_key(:use_latest_restorable_time)
    end
    
    it 'synthesizes cluster with network configuration' do
      synthesizer.instance_eval do
        aws_rds_cluster(:network_cluster, {
          engine: "aurora-mysql",
          db_subnet_group_name: "aurora-subnet-group",
          vpc_security_group_ids: ["sg-12345678", "sg-87654321"],
          availability_zones: ["us-east-1a", "us-east-1b", "us-east-1c"],
          db_cluster_parameter_group_name: "aurora-mysql-params"
        })
      end
      
      result = synthesizer.synthesis
      cluster = result[:resource][:aws_rds_cluster][:network_cluster]
      
      expect(cluster[:db_subnet_group_name]).to eq("aurora-subnet-group")
      expect(cluster[:vpc_security_group_ids]).to include("sg-12345678", "sg-87654321")
      expect(cluster[:availability_zones]).to include("us-east-1a", "us-east-1b")
      expect(cluster[:db_cluster_parameter_group_name]).to eq("aurora-mysql-params")
    end
    
    it 'synthesizes cluster from snapshot' do
      synthesizer.instance_eval do
        aws_rds_cluster(:from_snapshot, {
          engine: "aurora-mysql",
          snapshot_identifier: "prod-cluster-snapshot-20250103",
          source_region: "us-west-2"
        })
      end
      
      result = synthesizer.synthesis
      cluster = result[:resource][:aws_rds_cluster][:from_snapshot]
      
      expect(cluster[:snapshot_identifier]).to eq("prod-cluster-snapshot-20250103")
      expect(cluster[:source_region]).to eq("us-west-2")
    end
    
    it 'synthesizes cluster with encryption and storage config' do
      synthesizer.instance_eval do
        aws_rds_cluster(:encrypted_cluster, {
          engine: "aurora-mysql",
          storage_encrypted: true,
          kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678",
          storage_type: "aurora-iopt1",
          allocated_storage: 100,
          iops: 1000
        })
      end
      
      result = synthesizer.synthesis
      cluster = result[:resource][:aws_rds_cluster][:encrypted_cluster]
      
      expect(cluster[:storage_encrypted]).to be true
      expect(cluster[:kms_key_id]).to include("arn:aws:kms")
      expect(cluster[:storage_type]).to eq("aurora-iopt1")
      expect(cluster[:allocated_storage]).to eq(100)
      expect(cluster[:iops]).to eq(1000)
    end
    
    it 'handles empty tags gracefully' do
      synthesizer.instance_eval do
        aws_rds_cluster(:no_tags, {
          engine: "aurora-mysql",
          tags: {}
        })
      end
      
      result = synthesizer.synthesis
      cluster = result[:resource][:aws_rds_cluster][:no_tags]
      
      expect(cluster).not_to have_key(:tags)
    end
    
    it 'generates correct JSON for terraform' do
      synthesizer.instance_eval do
        aws_rds_cluster(:json_test, {
          engine: "aurora-postgresql",
          cluster_identifier: "test-postgres-cluster",
          database_name: "test_db",
          backup_retention_period: 30,
          deletion_protection: true,
          performance_insights_enabled: true,
          tags: {
            Name: "test-cluster",
            Environment: "testing",
            Engine: "aurora-postgresql"
          }
        })
      end
      
      json_output = JSON.pretty_generate(synthesizer.synthesis)
      parsed = JSON.parse(json_output, symbolize_names: true)
      
      cluster = parsed[:resource][:aws_rds_cluster][:json_test]
      expect(cluster[:cluster_identifier]).to eq("test-postgres-cluster")
      expect(cluster[:engine]).to eq("aurora-postgresql")
      expect(cluster[:backup_retention_period]).to eq(30)
      expect(cluster[:tags]).to be_a(Hash)
      expect(cluster[:tags][:Engine]).to eq("aurora-postgresql")
    end
    
    it 'synthesizes complete production cluster setup' do
      synthesizer.instance_eval do
        # Production Aurora MySQL cluster
        aws_rds_cluster(:prod_primary, {
          engine: "aurora-mysql",
          cluster_identifier: "prod-mysql-primary",
          database_name: "production_db",
          master_username: "admin",
          backup_retention_period: 30,
          preferred_backup_window: "03:00-04:00",
          preferred_maintenance_window: "sun:04:00-sun:05:00",
          deletion_protection: true,
          storage_encrypted: true,
          kms_key_id: "alias/rds-encryption-key",
          monitoring_interval: 60,
          monitoring_role_arn: "arn:aws:iam::123456789012:role/rds-monitoring-role",
          performance_insights_enabled: true,
          backtrack_window: 259200,
          enabled_cloudwatch_logs_exports: ["audit", "error", "general", "slowquery"],
          serverless_v2_scaling_configuration: {
            min_capacity: 2.0,
            max_capacity: 64.0
          },
          tags: {
            Environment: "production",
            Application: "webapp",
            BackupTier: "critical",
            Owner: "platform-team"
          }
        })
      end
      
      result = synthesizer.synthesis
      cluster = result[:resource][:aws_rds_cluster][:prod_primary]
      
      # Verify production configuration
      expect(cluster[:deletion_protection]).to be true
      expect(cluster[:backup_retention_period]).to eq(30)
      expect(cluster[:storage_encrypted]).to be true
      expect(cluster[:performance_insights_enabled]).to be true
      expect(cluster[:backtrack_window]).to eq(259200)
      expect(cluster[:serverless_v2_scaling_configuration][:max_capacity]).to eq(64.0)
      expect(cluster[:tags][:Environment]).to eq("production")
    end
  end
end