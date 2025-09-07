# frozen_string_literal: true

require 'spec_helper'
require 'pangea/resources/aws_db_snapshot/resource'
require 'pangea/resources/aws_db_snapshot/types'

RSpec.describe 'Pangea::Resources::AWS#aws_db_snapshot' do
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
        mock_resource_context.define_singleton_method(:db_instance_identifier) { |value| }
        mock_resource_context.define_singleton_method(:db_snapshot_identifier) { |value| }
        mock_resource_context.define_singleton_method(:tags) { |&inner_block| }
        mock_resource_context.instance_eval(&block)
      end
    end
  end

  describe '#aws_db_snapshot' do
    context 'with valid attributes' do
      it 'creates a basic DB snapshot' do
        result = aws_db_snapshot(:test_snapshot, {
          db_instance_identifier: "test-instance",
          db_snapshot_identifier: "test-instance-snapshot"
        })
        
        expect(result).to be_a(Pangea::Resources::ResourceReference)
        expect(result.type).to eq('aws_db_snapshot')
        expect(result.name).to eq(:test_snapshot)
      end
      
      it 'creates a snapshot with tags' do
        result = aws_db_snapshot(:tagged_snapshot, {
          db_instance_identifier: "prod-mysql-instance",
          db_snapshot_identifier: "prod-mysql-backup-20250101",
          tags: {
            Environment: "production",
            Purpose: "backup",
            Engine: "mysql"
          }
        })
        
        expect(result.resource_attributes[:tags]).to include(
          Environment: "production",
          Purpose: "backup",
          Engine: "mysql"
        )
      end
      
      it 'returns reference with all terraform outputs' do
        result = aws_db_snapshot(:full_output, {
          db_instance_identifier: "test-instance",
          db_snapshot_identifier: "test-snapshot"
        })
        
        expect(result.id).to eq("${aws_db_snapshot.full_output.id}")
        expect(result.arn).to eq("${aws_db_snapshot.full_output.db_snapshot_arn}")
        expect(result.db_instance_identifier).to eq("${aws_db_snapshot.full_output.db_instance_identifier}")
        expect(result.allocated_storage).to eq("${aws_db_snapshot.full_output.allocated_storage}")
        expect(result.availability_zone).to eq("${aws_db_snapshot.full_output.availability_zone}")
        expect(result.engine).to eq("${aws_db_snapshot.full_output.engine}")
        expect(result.engine_version).to eq("${aws_db_snapshot.full_output.engine_version}")
        expect(result.storage_type).to eq("${aws_db_snapshot.full_output.storage_type}")
        expect(result.vpc_id).to eq("${aws_db_snapshot.full_output.vpc_id}")
      end
      
      it 'provides computed properties' do
        result = aws_db_snapshot(:computed_props, {
          db_instance_identifier: "mysql-instance",
          db_snapshot_identifier: "mysql-backup-20250103-142530"
        })
        
        expect(result).to respond_to(:follows_naming_convention?)
        expect(result).to respond_to(:base_name)
        expect(result).to respond_to(:timestamp)
        expect(result).to respond_to(:age_in_days)
        expect(result).to respond_to(:snapshot_summary)
        expect(result).to respond_to(:estimated_monthly_storage_cost)
      end
    end
    
    context 'with invalid attributes' do
      it 'raises error for missing db_instance_identifier' do
        expect {
          aws_db_snapshot(:invalid, {
            db_snapshot_identifier: "snapshot-id"
          })
        }.to raise_error(Dry::Struct::Error, /db_instance_identifier is missing/)
      end
      
      it 'raises error for missing db_snapshot_identifier' do
        expect {
          aws_db_snapshot(:invalid, {
            db_instance_identifier: "instance-id"
          })
        }.to raise_error(Dry::Struct::Error, /db_snapshot_identifier is missing/)
      end
      
      it 'raises error for invalid snapshot identifier format' do
        expect {
          aws_db_snapshot(:invalid, {
            db_instance_identifier: "instance-id",
            db_snapshot_identifier: "123-invalid-start"
          })
        }.to raise_error(Dry::Struct::Error, /must start with a letter/)
      end
      
      it 'raises error for too long snapshot identifier' do
        expect {
          aws_db_snapshot(:invalid, {
            db_instance_identifier: "instance-id",
            db_snapshot_identifier: "a" * 256
          })
        }.to raise_error(Dry::Struct::Error, /cannot exceed 255 characters/)
      end
    end
  end
  
  describe Pangea::Resources::AWS::DbSnapshotAttributes do
    describe 'validation' do
      it 'validates snapshot identifier format' do
        expect {
          described_class.new(
            db_instance_identifier: "test-instance",
            db_snapshot_identifier: "test-snapshot-123"
          )
        }.not_to raise_error
        
        expect {
          described_class.new(
            db_instance_identifier: "test-instance",
            db_snapshot_identifier: "_invalid-start"
          )
        }.to raise_error(Dry::Struct::Error)
      end
      
      it 'allows hyphens and alphanumeric characters' do
        expect {
          described_class.new(
            db_instance_identifier: "test-instance",
            db_snapshot_identifier: "valid-snapshot-name-123"
          )
        }.not_to raise_error
      end
    end
    
    describe '.timestamped_identifier' do
      it 'generates timestamped identifier' do
        identifier = described_class.timestamped_identifier("myapp")
        expect(identifier).to match(/^myapp-\d{8}-\d{6}$/)
      end
    end
    
    describe '#follows_naming_convention?' do
      it 'returns true for convention-compliant names' do
        attrs = described_class.new(
          db_instance_identifier: "test-instance",
          db_snapshot_identifier: "myapp-backup-20250103-142530"
        )
        expect(attrs.follows_naming_convention?).to be true
      end
      
      it 'returns false for non-compliant names' do
        attrs = described_class.new(
          db_instance_identifier: "test-instance",
          db_snapshot_identifier: "custom-snapshot-name"
        )
        expect(attrs.follows_naming_convention?).to be false
      end
    end
    
    describe '#base_name' do
      it 'extracts base name from convention-compliant identifier' do
        attrs = described_class.new(
          db_instance_identifier: "test-instance",
          db_snapshot_identifier: "myapp-production-20250103-142530"
        )
        expect(attrs.base_name).to eq("myapp-production")
      end
      
      it 'returns nil for non-compliant names' do
        attrs = described_class.new(
          db_instance_identifier: "test-instance",
          db_snapshot_identifier: "custom-name"
        )
        expect(attrs.base_name).to be_nil
      end
    end
    
    describe '#timestamp' do
      it 'extracts timestamp from convention-compliant identifier' do
        attrs = described_class.new(
          db_instance_identifier: "test-instance",
          db_snapshot_identifier: "myapp-backup-20250103-142530"
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
          db_instance_identifier: "test-instance",
          db_snapshot_identifier: "custom-name"
        )
        expect(attrs.timestamp).to be_nil
      end
    end
    
    describe '#age_in_days' do
      it 'calculates age for timestamped snapshots' do
        # Create a snapshot with a timestamp from 5 days ago
        five_days_ago = (DateTime.now - 5).strftime("%Y%m%d-%H%M%S")
        attrs = described_class.new(
          db_instance_identifier: "test-instance",
          db_snapshot_identifier: "myapp-backup-#{five_days_ago}"
        )
        
        expect(attrs.age_in_days).to be_between(4, 6)
      end
    end
    
    describe '#older_than?' do
      it 'checks if snapshot is older than specified days' do
        # Create a snapshot from 10 days ago
        ten_days_ago = (DateTime.now - 10).strftime("%Y%m%d-%H%M%S")
        attrs = described_class.new(
          db_instance_identifier: "test-instance",
          db_snapshot_identifier: "myapp-backup-#{ten_days_ago}"
        )
        
        expect(attrs.older_than?(5)).to be true
        expect(attrs.older_than?(15)).to be false
      end
    end
    
    describe '#snapshot_summary' do
      it 'generates comprehensive summary' do
        attrs = described_class.new(
          db_instance_identifier: "prod-mysql-instance",
          db_snapshot_identifier: "prod-backup-20250103-120000"
        )
        
        summary = attrs.snapshot_summary
        expect(summary).to include("Source: prod-mysql-instance")
        expect(summary).to include("Age:")
        expect(summary).to include("Convention: compliant")
      end
    end
  end
  
  describe Pangea::Resources::AWS::DbSnapshotConfigs do
    describe '.production_backup' do
      it 'creates production backup configuration' do
        config = described_class.production_backup(
          db_instance_id: "prod-mysql-instance"
        )
        
        expect(config[:db_instance_identifier]).to eq("prod-mysql-instance")
        expect(config[:db_snapshot_identifier]).to match(/prod-mysql-instance-backup-\d{8}-\d{6}/)
        expect(config[:tags]).to include(
          Purpose: "backup",
          Environment: "production",
          Automated: "false",
          Type: "manual"
        )
      end
      
      it 'accepts custom snapshot identifier' do
        config = described_class.production_backup(
          db_instance_id: "prod-instance",
          snapshot_id: "custom-backup-id"
        )
        
        expect(config[:db_snapshot_identifier]).to eq("custom-backup-id")
      end
    end
    
    describe '.pre_maintenance' do
      it 'creates pre-maintenance snapshot configuration' do
        config = described_class.pre_maintenance(
          db_instance_id: "prod-instance",
          maintenance_type: "patching"
        )
        
        expect(config[:db_instance_identifier]).to eq("prod-instance")
        expect(config[:db_snapshot_identifier]).to match(/prod-instance-pre-patching-\d{8}-\d{6}/)
        expect(config[:tags]).to include(
          Purpose: "pre-maintenance",
          MaintenanceType: "patching",
          Type: "safety"
        )
      end
    end
    
    describe '.development_snapshot' do
      it 'creates development snapshot configuration' do
        config = described_class.development_snapshot(
          db_instance_id: "dev-instance",
          purpose: "feature-testing"
        )
        
        expect(config[:db_instance_identifier]).to eq("dev-instance")
        expect(config[:db_snapshot_identifier]).to match(/dev-instance-feature-testing-\d{8}-\d{6}/)
        expect(config[:tags]).to include(
          Purpose: "feature-testing",
          Environment: "development",
          Temporary: "true"
        )
      end
    end
    
    describe '.migration_snapshot' do
      it 'creates migration snapshot configuration' do
        config = described_class.migration_snapshot(
          db_instance_id: "prod-instance",
          migration_id: "v2-upgrade"
        )
        
        expect(config[:db_instance_identifier]).to eq("prod-instance")
        expect(config[:db_snapshot_identifier]).to eq("prod-instance-migration-v2-upgrade")
        expect(config[:tags]).to include(
          Purpose: "migration",
          MigrationId: "v2-upgrade",
          Type: "safety",
          Critical: "true"
        )
      end
    end
  end
end