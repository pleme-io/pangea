# frozen_string_literal: true

require 'spec_helper'
require 'pangea/resources/aws_rds_cluster/resource'
require 'pangea/resources/aws_rds_cluster/types'

RSpec.describe 'Pangea::Resources::AWS#aws_rds_cluster' do
  include Pangea::Resources::AWS
  
  let(:mock_terraform_synthesizer) { instance_double(TerraformSynthesizer) }
  let(:mock_synthesis_context) { double('SynthesisContext') }
  
  before do
    allow(TerraformSynthesizer).to receive(:new).and_return(mock_terraform_synthesizer)
    allow(mock_terraform_synthesizer).to receive(:instance_eval)
    allow(mock_terraform_synthesizer).to receive(:synthesis).and_return(mock_synthesis_context)
    
    # Mock the resource method with all necessary methods
    allow(self).to receive(:resource) do |resource_type, name, &block|
      if block_given?
        mock_resource_context = Object.new
        
        # Define all expected methods
        %w[cluster_identifier cluster_identifier_prefix engine engine_version engine_mode
           database_name master_username master_password manage_master_user_password
           master_user_secret_kms_key_id db_subnet_group_name vpc_security_group_ids
           availability_zones db_cluster_parameter_group_name port backup_retention_period
           preferred_backup_window preferred_maintenance_window copy_tags_to_snapshot
           storage_encrypted kms_key_id storage_type allocated_storage iops
           global_cluster_identifier scaling_configuration serverless_v2_scaling_configuration
           restore_to_point_in_time snapshot_identifier source_region enabled_cloudwatch_logs_exports
           monitoring_interval monitoring_role_arn performance_insights_enabled
           performance_insights_kms_key_id performance_insights_retention_period
           backtrack_window apply_immediately auto_minor_version_upgrade deletion_protection
           skip_final_snapshot final_snapshot_identifier enable_http_endpoint tags].each do |method_name|
          mock_resource_context.define_singleton_method(method_name) { |value = nil, &inner_block| }
        end
        
        mock_resource_context.instance_eval(&block)
      end
    end
  end

  describe '#aws_rds_cluster' do
    context 'with valid attributes' do
      it 'creates a basic Aurora MySQL cluster' do
        result = aws_rds_cluster(:basic_cluster, {
          engine: "aurora-mysql"
        })
        
        expect(result).to be_a(Pangea::Resources::ResourceReference)
        expect(result.type).to eq('aws_rds_cluster')
        expect(result.name).to eq(:basic_cluster)
        expect(result.resource_attributes[:engine]).to eq("aurora-mysql")
      end
      
      it 'creates an Aurora PostgreSQL cluster' do
        result = aws_rds_cluster(:postgres_cluster, {
          engine: "aurora-postgresql",
          database_name: "app_db",
          master_username: "dbadmin"
        })
        
        expect(result.is_postgresql?).to be true
        expect(result.engine_family).to eq("postgresql")
        expect(result.effective_port).to eq(5432)
      end
      
      it 'creates a cluster with Serverless v2 scaling' do
        result = aws_rds_cluster(:serverless_cluster, {
          engine: "aurora-mysql",
          serverless_v2_scaling_configuration: {
            min_capacity: 0.5,
            max_capacity: 16.0
          }
        })
        
        expect(result.supports_serverless_v2?).to be true
        scaling = result.resource_attributes[:serverless_v2_scaling_configuration]
        expect(scaling.min_capacity).to eq(0.5)
        expect(scaling.max_capacity).to eq(16.0)
      end
      
      it 'creates a global Aurora cluster' do
        result = aws_rds_cluster(:global_cluster, {
          engine: "aurora-mysql",
          engine_mode: "global",
          global_cluster_identifier: "my-global-cluster"
        })
        
        expect(result.is_global?).to be true
        expect(result.supports_global?).to be true
      end
      
      it 'creates a cluster with backtrack enabled' do
        result = aws_rds_cluster(:backtrack_cluster, {
          engine: "aurora-mysql",
          backtrack_window: 259200  # 72 hours
        })
        
        expect(result.has_backtrack?).to be true
        expect(result.supports_backtrack?).to be true
      end
      
      it 'creates a cluster with enhanced monitoring' do
        result = aws_rds_cluster(:monitored_cluster, {
          engine: "aurora-mysql",
          monitoring_interval: 60,
          monitoring_role_arn: "arn:aws:iam::123456789012:role/rds-monitoring-role",
          performance_insights_enabled: true
        })
        
        expect(result.has_enhanced_monitoring?).to be true
        expect(result.has_performance_insights?).to be true
      end
      
      it 'creates a cluster with point-in-time restore' do
        result = aws_rds_cluster(:restored_cluster, {
          engine: "aurora-mysql",
          restore_to_point_in_time: {
            source_cluster_identifier: "source-cluster",
            use_latest_restorable_time: true
          }
        })
        
        restore_config = result.resource_attributes[:restore_to_point_in_time]
        expect(restore_config.uses_latest_time?).to be true
        expect(restore_config.source_cluster_identifier).to eq("source-cluster")
      end
      
      it 'returns reference with all terraform outputs' do
        result = aws_rds_cluster(:full_output, {
          engine: "aurora-mysql"
        })
        
        expect(result.id).to eq("${aws_rds_cluster.full_output.id}")
        expect(result.arn).to eq("${aws_rds_cluster.full_output.arn}")
        expect(result.endpoint).to eq("${aws_rds_cluster.full_output.endpoint}")
        expect(result.reader_endpoint).to eq("${aws_rds_cluster.full_output.reader_endpoint}")
        expect(result.cluster_members).to eq("${aws_rds_cluster.full_output.cluster_members}")
        expect(result.master_user_secret).to eq("${aws_rds_cluster.full_output.master_user_secret}")
      end
      
      it 'provides computed properties' do
        result = aws_rds_cluster(:computed_props, {
          engine: "aurora-mysql",
          engine_mode: "provisioned"
        })
        
        expect(result.is_mysql?).to be true
        expect(result.is_postgresql?).to be false
        expect(result.is_serverless?).to be false
        expect(result.engine_family).to eq("mysql")
        expect(result.default_cloudwatch_logs_exports).to include("slowquery")
        expect(result.estimated_monthly_cost).to be_a(String)
      end
    end
    
    context 'with invalid attributes' do
      it 'raises error for missing engine' do
        expect {
          aws_rds_cluster(:invalid, {})
        }.to raise_error(Dry::Struct::Error, /engine is missing/)
      end
      
      it 'raises error for conflicting cluster identifiers' do
        expect {
          aws_rds_cluster(:invalid, {
            engine: "aurora-mysql",
            cluster_identifier: "my-cluster",
            cluster_identifier_prefix: "prefix"
          })
        }.to raise_error(Dry::Struct::Error, /Cannot specify both 'cluster_identifier' and 'cluster_identifier_prefix'/)
      end
      
      it 'raises error for conflicting password configurations' do
        expect {
          aws_rds_cluster(:invalid, {
            engine: "aurora-mysql",
            master_password: "secret",
            manage_master_user_password: true
          })
        }.to raise_error(Dry::Struct::Error, /Cannot specify both 'master_password' and 'manage_master_user_password'/)
      end
      
      it 'raises error for backtrack on PostgreSQL' do
        expect {
          aws_rds_cluster(:invalid, {
            engine: "aurora-postgresql",
            backtrack_window: 3600
          })
        }.to raise_error(Dry::Struct::Error, /Backtrack is only supported by Aurora MySQL/)
      end
      
      it 'raises error for global cluster without global engine mode' do
        expect {
          aws_rds_cluster(:invalid, {
            engine: "aurora-mysql",
            engine_mode: "provisioned",
            global_cluster_identifier: "global-cluster"
          })
        }.to raise_error(Dry::Struct::Error, /global_cluster_identifier can only be used with engine_mode 'global'/)
      end
      
      it 'raises error for monitoring without role' do
        expect {
          aws_rds_cluster(:invalid, {
            engine: "aurora-mysql",
            monitoring_interval: 60
          })
        }.to raise_error(Dry::Struct::Error, /monitoring_role_arn is required when monitoring_interval > 0/)
      end
      
      it 'raises error for io1 storage without iops' do
        expect {
          aws_rds_cluster(:invalid, {
            engine: "aurora-mysql",
            storage_type: "io1"
          })
        }.to raise_error(Dry::Struct::Error, /iops must be specified when storage_type is 'io1'/)
      end
    end
  end
  
  describe Pangea::Resources::AWS::ServerlessV2Scaling do
    it 'validates capacity constraints' do
      expect {
        described_class.new(min_capacity: 2.0, max_capacity: 1.0)
      }.to raise_error(Dry::Struct::Error, /min_capacity.*cannot be greater than max_capacity/)
    end
    
    it 'identifies minimal scaling configuration' do
      scaling = described_class.new(min_capacity: 0.5, max_capacity: 2.0)
      expect(scaling.is_minimal?).to be true
    end
    
    it 'identifies high-performance scaling configuration' do
      scaling = described_class.new(min_capacity: 8.0, max_capacity: 32.0)
      expect(scaling.is_high_performance?).to be true
    end
    
    it 'calculates scaling range' do
      scaling = described_class.new(min_capacity: 2.0, max_capacity: 16.0)
      expect(scaling.scaling_range).to eq(14.0)
    end
    
    it 'estimates hourly cost range' do
      scaling = described_class.new(min_capacity: 1.0, max_capacity: 8.0)
      cost_range = scaling.estimated_hourly_cost_range
      expect(cost_range).to eq("$0.12-0.96/hour")
    end
  end
  
  describe Pangea::Resources::AWS::RestoreToPointInTime do
    it 'requires source cluster identifier' do
      expect {
        described_class.new({
          use_latest_restorable_time: true
        })
      }.to raise_error(Dry::Struct::Error, /source_cluster_identifier is required/)
    end
    
    it 'requires either restore_to_time or use_latest_restorable_time' do
      expect {
        described_class.new({
          source_cluster_identifier: "source-cluster"
        })
      }.to raise_error(Dry::Struct::Error, /Must specify either 'restore_to_time' or set 'use_latest_restorable_time'/)
    end
    
    it 'prevents both restore_to_time and use_latest_restorable_time' do
      expect {
        described_class.new({
          source_cluster_identifier: "source-cluster",
          restore_to_time: "2025-01-01T12:00:00Z",
          use_latest_restorable_time: true
        })
      }.to raise_error(Dry::Struct::Error, /Cannot specify both 'restore_to_time' and 'use_latest_restorable_time'/)
    end
    
    it 'identifies latest time usage' do
      restore = described_class.new({
        source_cluster_identifier: "source-cluster",
        use_latest_restorable_time: true
      })
      expect(restore.uses_latest_time?).to be true
      expect(restore.uses_specific_time?).to be false
    end
    
    it 'identifies specific time usage' do
      restore = described_class.new({
        source_cluster_identifier: "source-cluster",
        restore_to_time: "2025-01-01T12:00:00Z"
      })
      expect(restore.uses_specific_time?).to be true
      expect(restore.uses_latest_time?).to be false
    end
  end
  
  describe Pangea::Resources::AWS::RdsClusterAttributes do
    describe 'engine family detection' do
      it 'identifies MySQL family' do
        cluster = described_class.new(engine: "aurora-mysql")
        expect(cluster.engine_family).to eq("mysql")
        expect(cluster.is_mysql?).to be true
        expect(cluster.is_postgresql?).to be false
      end
      
      it 'identifies PostgreSQL family' do
        cluster = described_class.new(engine: "aurora-postgresql")
        expect(cluster.engine_family).to eq("postgresql")
        expect(cluster.is_postgresql?).to be true
        expect(cluster.is_mysql?).to be false
      end
    end
    
    describe 'port resolution' do
      it 'uses engine defaults' do
        mysql_cluster = described_class.new(engine: "aurora-mysql")
        expect(mysql_cluster.effective_port).to eq(3306)
        
        postgres_cluster = described_class.new(engine: "aurora-postgresql")
        expect(postgres_cluster.effective_port).to eq(5432)
      end
      
      it 'uses specified port over default' do
        cluster = described_class.new(engine: "aurora-mysql", port: 3307)
        expect(cluster.effective_port).to eq(3307)
      end
    end
    
    describe 'feature support' do
      it 'checks backtrack support' do
        mysql_cluster = described_class.new(engine: "aurora-mysql", engine_mode: "provisioned")
        expect(mysql_cluster.supports_backtrack?).to be true
        
        postgres_cluster = described_class.new(engine: "aurora-postgresql")
        expect(postgres_cluster.supports_backtrack?).to be false
        
        serverless_cluster = described_class.new(engine: "aurora-mysql", engine_mode: "serverless")
        expect(serverless_cluster.supports_backtrack?).to be false
      end
      
      it 'checks global database support' do
        provisioned_cluster = described_class.new(engine: "aurora-mysql", engine_mode: "provisioned")
        expect(provisioned_cluster.supports_global?).to be true
        
        serverless_cluster = described_class.new(engine: "aurora-mysql", engine_mode: "serverless")
        expect(serverless_cluster.supports_global?).to be false
      end
      
      it 'checks serverless v2 support' do
        provisioned_cluster = described_class.new(engine: "aurora-mysql", engine_mode: "provisioned")
        expect(provisioned_cluster.supports_serverless_v2?).to be true
        
        serverless_v1_cluster = described_class.new(engine: "aurora-mysql", engine_mode: "serverless")
        expect(serverless_v1_cluster.supports_serverless_v2?).to be false
      end
    end
    
    describe 'CloudWatch logs exports' do
      it 'provides engine-specific defaults' do
        mysql_cluster = described_class.new(engine: "aurora-mysql")
        expect(mysql_cluster.default_cloudwatch_logs_exports).to include("slowquery", "error", "audit")
        
        postgres_cluster = described_class.new(engine: "aurora-postgresql")
        expect(postgres_cluster.default_cloudwatch_logs_exports).to include("postgresql")
      end
    end
  end
  
  describe Pangea::Resources::AWS::AuroraClusterConfigs do
    describe '.mysql_development' do
      it 'provides development MySQL configuration' do
        config = described_class.mysql_development
        expect(config[:engine]).to eq("aurora-mysql")
        expect(config[:backup_retention_period]).to eq(1)
        expect(config[:skip_final_snapshot]).to be true
        expect(config[:deletion_protection]).to be false
      end
    end
    
    describe '.mysql_production' do
      it 'provides production MySQL configuration' do
        config = described_class.mysql_production
        expect(config[:engine]).to eq("aurora-mysql")
        expect(config[:backup_retention_period]).to eq(14)
        expect(config[:skip_final_snapshot]).to be false
        expect(config[:deletion_protection]).to be true
        expect(config[:performance_insights_enabled]).to be true
        expect(config[:backtrack_window]).to eq(259200)
      end
    end
    
    describe '.postgresql_development' do
      it 'provides development PostgreSQL configuration' do
        config = described_class.postgresql_development
        expect(config[:engine]).to eq("aurora-postgresql")
        expect(config[:enabled_cloudwatch_logs_exports]).to include("postgresql")
      end
    end
    
    describe '.serverless_v2' do
      it 'provides Serverless v2 configuration with custom capacity' do
        config = described_class.serverless_v2(min_capacity: 1.0, max_capacity: 32.0)
        expect(config[:serverless_v2_scaling_configuration][:min_capacity]).to eq(1.0)
        expect(config[:serverless_v2_scaling_configuration][:max_capacity]).to eq(32.0)
      end
    end
    
    describe '.global_mysql' do
      it 'provides global cluster configuration' do
        config = described_class.global_mysql
        expect(config[:engine]).to eq("aurora-mysql")
        expect(config[:engine_mode]).to eq("global")
        expect(config[:deletion_protection]).to be true
      end
    end
  end
end