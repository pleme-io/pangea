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
require 'pangea/resources/aws_db_cluster_snapshot/resource'
require 'pangea/resources/aws_db_cluster_snapshot/types'

RSpec.describe 'Pangea::Resources::AWS#aws_db_cluster_snapshot' do
  include Pangea::Resources::AWS
  
  let(:mock_terraform_synthesizer) { instance_double(TerraformSynthesizer) }
  let(:mock_synthesis_context) { double('SynthesisContext') }
  
  before do
    allow(TerraformSynthesizer).to receive(:new).and_return(mock_terraform_synthesizer)
    allow(mock_terraform_synthesizer).to receive(:instance_eval)
    allow(mock_terraform_synthesizer).to receive(:synthesis).and_return(mock_synthesis_context)
    
    # Mock the resource method
    allow(self).to receive(:resource) do |resource_type, name, &block|
      if block_given?
        mock_resource_context = Object.new
        mock_resource_context.define_singleton_method(:db_cluster_identifier) { |value| }
        mock_resource_context.define_singleton_method(:db_cluster_snapshot_identifier) { |value| }
        mock_resource_context.define_singleton_method(:tags) { |&inner_block| }
        mock_resource_context.instance_eval(&block)
      end
    end
  end

  describe '#aws_db_cluster_snapshot' do
    context 'with valid attributes' do
      it 'creates a basic DB cluster snapshot' do
        result = aws_db_cluster_snapshot(:test_snapshot, {
          db_cluster_identifier: "test-cluster",
          db_cluster_snapshot_identifier: "test-cluster-snapshot"
        })
        
        expect(result).to be_a(Pangea::Resources::ResourceReference)
        expect(result.type).to eq('aws_rds_cluster_snapshot')
        expect(result.name).to eq(:test_snapshot)
      end
      
      it 'creates a snapshot with tags' do
        result = aws_db_cluster_snapshot(:tagged_snapshot, {
          db_cluster_identifier: "prod-aurora-cluster",
          db_cluster_snapshot_identifier: "prod-aurora-snapshot-20250101",
          tags: {
            Environment: "production",
            Purpose: "backup"
          }
        })
        
        expect(result.resource_attributes[:tags]).to include(
          Environment: "production",
          Purpose: "backup"
        )
      end
      
      it 'returns reference with all terraform outputs' do
        result = aws_db_cluster_snapshot(:full_output, {
          db_cluster_identifier: "test-cluster",
          db_cluster_snapshot_identifier: "test-snapshot"
        })
        
        expect(result.id).to eq("${aws_rds_cluster_snapshot.full_output.id}")
        expect(result.arn).to eq("${aws_rds_cluster_snapshot.full_output.db_cluster_snapshot_arn}")
        expect(result.db_cluster_identifier).to eq("${aws_rds_cluster_snapshot.full_output.db_cluster_identifier}")
        expect(result.allocated_storage).to eq("${aws_rds_cluster_snapshot.full_output.allocated_storage}")
        expect(result.engine).to eq("${aws_rds_cluster_snapshot.full_output.engine}")
        expect(result.engine_version).to eq("${aws_rds_cluster_snapshot.full_output.engine_version}")
        expect(result.kms_key_id).to eq("${aws_rds_cluster_snapshot.full_output.kms_key_id}")
        expect(result.storage_encrypted).to eq("${aws_rds_cluster_snapshot.full_output.storage_encrypted}")
        expect(result.vpc_id).to eq("${aws_rds_cluster_snapshot.full_output.vpc_id}")
      end
      
      it 'provides computed properties' do
        result = aws_db_cluster_snapshot(:computed_props, {
          db_cluster_identifier: "aurora-cluster",
          db_cluster_snapshot_identifier: "aurora-cluster-20250103-142530"
        })
        
        expect(result).to respond_to(:follows_naming_convention?)
        expect(result).to respond_to(:base_name)
        expect(result).to respond_to(:timestamp)
        expect(result).to respond_to(:age_in_days)
        expect(result).to respond_to(:is_global_cluster_snapshot?)
        expect(result).to respond_to(:is_aurora_snapshot?)
        expect(result).to respond_to(:snapshot_summary)
        expect(result).to respond_to(:estimated_monthly_storage_cost)
        expect(result).to respond_to(:recommended_retention_days)
      end
    end
    
    context 'with invalid attributes' do
      it 'raises error for missing db_cluster_identifier' do
        expect {
          aws_db_cluster_snapshot(:invalid, {
            db_cluster_snapshot_identifier: "snapshot-id"
          })
        }.to raise_error(Dry::Struct::Error, /db_cluster_identifier is missing/)
      end
      
      it 'raises error for missing db_cluster_snapshot_identifier' do
        expect {
          aws_db_cluster_snapshot(:invalid, {
            db_cluster_identifier: "cluster-id"
          })
        }.to raise_error(Dry::Struct::Error, /db_cluster_snapshot_identifier is missing/)
      end
      
      it 'raises error for invalid snapshot identifier format' do
        expect {
          aws_db_cluster_snapshot(:invalid, {
            db_cluster_identifier: "cluster-id",
            db_cluster_snapshot_identifier: "123-invalid-start"
          })
        }.to raise_error(Dry::Struct::Error, /must start with a letter/)
      end
      
      it 'raises error for too long snapshot identifier' do
        expect {
          aws_db_cluster_snapshot(:invalid, {
            db_cluster_identifier: "cluster-id",
            db_cluster_snapshot_identifier: "a" * 256
          })
        }.to raise_error(Dry::Struct::Error, /cannot exceed 255 characters/)
      end
    end
  end
  
  describe Pangea::Resources::AWS::DbClusterSnapshotAttributes do
    describe 'validation' do
      it 'validates snapshot identifier format' do
        expect {
          described_class.new(
            db_cluster_identifier: "test-cluster",
            db_cluster_snapshot_identifier: "test-snapshot-123"
          )
        }.not_to raise_error
        
        expect {
          described_class.new(
            db_cluster_identifier: "test-cluster",
            db_cluster_snapshot_identifier: "_invalid-start"
          )
        }.to raise_error(Dry::Struct::Error)
      end
      
      it 'allows hyphens and alphanumeric characters' do
        expect {
          described_class.new(
            db_cluster_identifier: "test-cluster",
            db_cluster_snapshot_identifier: "valid-snapshot-name-123"
          )
        }.not_to raise_error
      end
    end
    
    describe '.timestamped_identifier' do
      it 'generates timestamped identifier' do
        identifier = described_class.timestamped_identifier("myapp")
        expect(identifier).to match(/^myapp-cluster-\d{8}-\d{6}$/)
      end
    end
    
    describe '#follows_naming_convention?' do
      it 'returns true for convention-compliant names' do
        attrs = described_class.new(
          db_cluster_identifier: "test-cluster",
          db_cluster_snapshot_identifier: "myapp-cluster-20250103-142530"
        )
        expect(attrs.follows_naming_convention?).to be true
      end
      
      it 'returns false for non-compliant names' do
        attrs = described_class.new(
          db_cluster_identifier: "test-cluster",
          db_cluster_snapshot_identifier: "custom-snapshot-name"
        )
        expect(attrs.follows_naming_convention?).to be false
      end
    end
    
    describe '#base_name' do
      it 'extracts base name from convention-compliant identifier' do
        attrs = described_class.new(
          db_cluster_identifier: "test-cluster",
          db_cluster_snapshot_identifier: "myapp-production-cluster-20250103-142530"
        )
        expect(attrs.base_name).to eq("myapp-production")
      end
      
      it 'returns nil for non-compliant names' do
        attrs = described_class.new(
          db_cluster_identifier: "test-cluster",
          db_cluster_snapshot_identifier: "custom-name"
        )
        expect(attrs.base_name).to be_nil
      end
    end
    
    describe '#timestamp' do
      it 'extracts timestamp from convention-compliant identifier' do
        attrs = described_class.new(
          db_cluster_identifier: "test-cluster",
          db_cluster_snapshot_identifier: "myapp-cluster-20250103-142530"
        )
        
        timestamp = attrs.timestamp
        expect(timestamp).to be_a(DateTime)
        expect(timestamp.year).to eq(2025)
        expect(timestamp.month).to eq(1)
        expect(timestamp.day).to eq(3)
        expect(timestamp.hour).to eq(14)
        expect(timestamp.minute).to eq(25)
        expect(timestamp.second).to eq(30)
      end
      
      it 'returns nil for non-compliant names' do
        attrs = described_class.new(
          db_cluster_identifier: "test-cluster",
          db_cluster_snapshot_identifier: "custom-name"
        )
        expect(attrs.timestamp).to be_nil
      end
    end
    
    describe '#age_in_days' do
      it 'calculates age for timestamped snapshots' do
        # Create a snapshot with a timestamp from 5 days ago
        five_days_ago = (DateTime.now - 5).strftime("%Y%m%d-%H%M%S")
        attrs = described_class.new(
          db_cluster_identifier: "test-cluster",
          db_cluster_snapshot_identifier: "myapp-cluster-#{five_days_ago}"
        )
        
        expect(attrs.age_in_days).to be_between(4, 6)
      end
    end
    
    describe '#older_than?' do
      it 'checks if snapshot is older than specified days' do
        # Create a snapshot from 10 days ago
        ten_days_ago = (DateTime.now - 10).strftime("%Y%m%d-%H%M%S")
        attrs = described_class.new(
          db_cluster_identifier: "test-cluster",
          db_cluster_snapshot_identifier: "myapp-cluster-#{ten_days_ago}"
        )
        
        expect(attrs.older_than?(5)).to be true
        expect(attrs.older_than?(15)).to be false
      end
    end
    
    describe '#is_global_cluster_snapshot?' do
      it 'detects global cluster snapshots by identifier' do
        attrs = described_class.new(
          db_cluster_identifier: "global-aurora-cluster",
          db_cluster_snapshot_identifier: "global-snapshot"
        )
        expect(attrs.is_global_cluster_snapshot?).to be true
      end
      
      it 'detects global cluster snapshots by tags' do
        attrs = described_class.new(
          db_cluster_identifier: "aurora-cluster",
          db_cluster_snapshot_identifier: "snapshot",
          tags: { Type: "Global", Region: "us-west-2" }
        )
        expect(attrs.is_global_cluster_snapshot?).to be true
      end
    end
    
    describe '#is_aurora_snapshot?' do
      it 'detects Aurora snapshots by identifier' do
        attrs = described_class.new(
          db_cluster_identifier: "aurora-mysql-cluster",
          db_cluster_snapshot_identifier: "aurora-snapshot"
        )
        expect(attrs.is_aurora_snapshot?).to be true
      end
      
      it 'detects Aurora snapshots by tags' do
        attrs = described_class.new(
          db_cluster_identifier: "prod-cluster",
          db_cluster_snapshot_identifier: "snapshot",
          tags: { Engine: "aurora-postgresql" }
        )
        expect(attrs.is_aurora_snapshot?).to be true
      end
    end
    
    describe '#snapshot_summary' do
      it 'generates comprehensive summary' do
        attrs = described_class.new(
          db_cluster_identifier: "aurora-global-cluster",
          db_cluster_snapshot_identifier: "aurora-global-cluster-20250103-120000"
        )
        
        summary = attrs.snapshot_summary
        expect(summary).to include("Source cluster: aurora-global-cluster")
        expect(summary).to include("Age:")
        expect(summary).to include("Type: Aurora cluster")
        expect(summary).to include("Global: yes")
        expect(summary).to include("Convention: compliant")
      end
    end
    
    describe '#recommended_retention_days' do
      it 'recommends retention based on purpose tag' do
        backup = described_class.new(
          db_cluster_identifier: "cluster",
          db_cluster_snapshot_identifier: "snapshot",
          tags: { Purpose: "backup" }
        )
        expect(backup.recommended_retention_days).to eq(30)
        
        migration = described_class.new(
          db_cluster_identifier: "cluster",
          db_cluster_snapshot_identifier: "snapshot",
          tags: { Purpose: "migration" }
        )
        expect(migration.recommended_retention_days).to eq(7)
        
        testing = described_class.new(
          db_cluster_identifier: "cluster",
          db_cluster_snapshot_identifier: "snapshot",
          tags: { Purpose: "testing" }
        )
        expect(testing.recommended_retention_days).to eq(3)
        
        default = described_class.new(
          db_cluster_identifier: "cluster",
          db_cluster_snapshot_identifier: "snapshot"
        )
        expect(default.recommended_retention_days).to eq(14)
      end
    end
  end
  
  describe Pangea::Resources::AWS::DbClusterSnapshotConfigs do
    describe '.aurora_production_backup' do
      it 'creates production Aurora backup configuration' do
        config = described_class.aurora_production_backup(
          cluster_id: "prod-aurora-cluster"
        )
        
        expect(config[:db_cluster_identifier]).to eq("prod-aurora-cluster")
        expect(config[:db_cluster_snapshot_identifier]).to match(/prod-aurora-cluster-prod-backup-cluster-\d{8}-\d{6}/)
        expect(config[:tags]).to include(
          Purpose: "backup",
          Environment: "production",
          Engine: "aurora",
          RetentionDays: "30"
        )
      end
    end
    
    describe '.global_cluster_backup' do
      it 'creates global cluster backup configuration' do
        config = described_class.global_cluster_backup(
          cluster_id: "global-aurora",
          region: "us-west-2"
        )
        
        expect(config[:db_cluster_identifier]).to eq("global-aurora")
        expect(config[:db_cluster_snapshot_identifier]).to match(/global-aurora-global-us-west-2-cluster-\d{8}-\d{6}/)
        expect(config[:tags]).to include(
          Purpose: "global-backup",
          Region: "us-west-2",
          Type: "global-cluster",
          CrossRegion: "true"
        )
      end
    end
    
    describe '.pre_upgrade_snapshot' do
      it 'creates pre-upgrade snapshot configuration' do
        config = described_class.pre_upgrade_snapshot(
          cluster_id: "prod-cluster",
          from_version: "13.7",
          to_version: "14.6"
        )
        
        expect(config[:db_cluster_identifier]).to eq("prod-cluster")
        expect(config[:db_cluster_snapshot_identifier]).to match(/prod-cluster-pre-upgrade-cluster-\d{8}-\d{6}/)
        expect(config[:tags]).to include(
          Purpose: "pre-upgrade",
          FromVersion: "13.7",
          ToVersion: "14.6",
          Critical: "true"
        )
      end
    end
    
    describe '.development_snapshot' do
      it 'creates development snapshot configuration' do
        config = described_class.development_snapshot(
          cluster_id: "dev-cluster",
          purpose: "feature-testing"
        )
        
        expect(config[:db_cluster_identifier]).to eq("dev-cluster")
        expect(config[:db_cluster_snapshot_identifier]).to match(/dev-cluster-dev-feature-testing-cluster-\d{8}-\d{6}/)
        expect(config[:tags]).to include(
          Purpose: "feature-testing",
          Environment: "development",
          Temporary: "true",
          RetentionDays: "3"
        )
      end
    end
    
    describe '.disaster_recovery_snapshot' do
      it 'creates disaster recovery snapshot configuration' do
        config = described_class.disaster_recovery_snapshot(
          cluster_id: "critical-cluster",
          primary_region: "us-east-1",
          dr_region: "us-west-2"
        )
        
        expect(config[:db_cluster_identifier]).to eq("critical-cluster")
        expect(config[:db_cluster_snapshot_identifier]).to match(/critical-cluster-dr-us-west-2-cluster-\d{8}-\d{6}/)
        expect(config[:tags]).to include(
          Purpose: "disaster-recovery",
          PrimaryRegion: "us-east-1",
          DRRegion: "us-west-2",
          Type: "cross-region",
          Critical: "true",
          RetentionDays: "90"
        )
      end
    end
    
    describe '.pitr_baseline' do
      it 'creates point-in-time recovery baseline configuration' do
        config = described_class.pitr_baseline(
          cluster_id: "prod-cluster",
          restore_point: "2025-01-03T14:30:00Z"
        )
        
        expect(config[:db_cluster_identifier]).to eq("prod-cluster")
        expect(config[:db_cluster_snapshot_identifier]).to match(/prod-cluster-pitr-baseline-cluster-\d{8}-\d{6}/)
        expect(config[:tags]).to include(
          Purpose: "pitr-baseline",
          RestorePoint: "2025-01-03T14:30:00Z",
          Type: "recovery",
          Baseline: "true"
        )
      end
    end
  end
end