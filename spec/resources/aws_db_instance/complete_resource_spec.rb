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

# Load aws_db_instance resource and types for testing
require 'pangea/resources/aws_db_instance/resource'
require 'pangea/resources/aws_db_instance/types'

RSpec.describe "aws_db_instance resource function" do
  # Create a test class that includes the AWS module and mocks terraform-synthesizer
  let(:test_class) do
    Class.new do
      include Pangea::Resources::AWS
      
      # Mock the terraform-synthesizer resource method
      def resource(type, name)
        @resources ||= {}
        resource_data = { type: type, name: name, attributes: {} }
        
        yield if block_given?
        
        @resources["#{type}.#{name}"] = resource_data
        resource_data
      end
      
      # Method missing to capture terraform attributes
      def method_missing(method_name, *args, &block)
        # Don't capture certain methods that might interfere
        return super if [:expect, :be_a, :eq].include?(method_name)
        # For terraform-synthesizer attribute calls, just return the value
        args.first if args.any?
      end
      
      def respond_to_missing?(method_name, include_private = false)
        true
      end
    end
  end
  
  let(:test_instance) { test_class.new }
  
  describe "DbInstanceAttributes validation" do
    it "accepts minimal configuration with required attributes" do
      attrs = Pangea::Resources::AWS::DbInstanceAttributes.new({
        engine: "postgres",
        instance_class: "db.t3.micro",
        allocated_storage: 20
      })
      
      expect(attrs.storage_type).to eq('gp3')
      expect(attrs.storage_encrypted).to eq(true)
      expect(attrs.manage_master_user_password).to eq(true)
      expect(attrs.backup_retention_period).to eq(7)
      expect(attrs.skip_final_snapshot).to eq(true)
    end
    
    it "accepts custom identifier" do
      attrs = Pangea::Resources::AWS::DbInstanceAttributes.new({
        identifier: "my-database-instance",
        engine: "mysql",
        instance_class: "db.t3.small",
        allocated_storage: 100
      })
      
      expect(attrs.identifier).to eq("my-database-instance")
    end
    
    it "accepts identifier prefix instead of identifier" do
      attrs = Pangea::Resources::AWS::DbInstanceAttributes.new({
        identifier_prefix: "myapp-db-",
        engine: "postgres",
        instance_class: "db.t3.medium",
        allocated_storage: 200
      })
      
      expect(attrs.identifier_prefix).to eq("myapp-db-")
    end
    
    it "accepts all supported database engines" do
      engines = ["mysql", "postgres", "mariadb", "oracle-se", "oracle-se1", "oracle-se2", 
                 "oracle-ee", "sqlserver-ee", "sqlserver-se", "sqlserver-ex", "sqlserver-web",
                 "aurora", "aurora-mysql", "aurora-postgresql"]
      
      engines.each do |engine|
        # Aurora doesn't need allocated_storage
        allocated_storage = engine.start_with?("aurora") ? nil : 20
        
        attrs = Pangea::Resources::AWS::DbInstanceAttributes.new({
          engine: engine,
          instance_class: "db.t3.micro",
          allocated_storage: allocated_storage
        }.compact)
        
        expect(attrs.engine).to eq(engine)
      end
    end
    
    it "accepts engine version" do
      attrs = Pangea::Resources::AWS::DbInstanceAttributes.new({
        engine: "postgres",
        engine_version: "15.3",
        instance_class: "db.t3.medium",
        allocated_storage: 100
      })
      
      expect(attrs.engine_version).to eq("15.3")
    end
    
    it "validates identifier and identifier_prefix are mutually exclusive" do
      expect {
        Pangea::Resources::AWS::DbInstanceAttributes.new({
          identifier: "my-db",
          identifier_prefix: "my-db-",
          engine: "mysql",
          instance_class: "db.t3.micro",
          allocated_storage: 20
        })
      }.to raise_error(Dry::Struct::Error, /Cannot specify both 'identifier' and 'identifier_prefix'/)
    end
    
    it "accepts different storage types" do
      storage_types = ["standard", "gp2", "gp3", "io1", "io2"]
      
      storage_types.each do |storage_type|
        attrs = Pangea::Resources::AWS::DbInstanceAttributes.new({
          engine: "mysql",
          instance_class: "db.t3.micro",
          allocated_storage: 100,
          storage_type: storage_type,
          iops: (storage_type.start_with?("io") ? 3000 : nil)
        }.compact)
        
        expect(attrs.storage_type).to eq(storage_type)
      end
    end
    
    it "accepts IOPS for io1 and io2 storage types" do
      attrs = Pangea::Resources::AWS::DbInstanceAttributes.new({
        engine: "mysql",
        instance_class: "db.t3.large",
        allocated_storage: 100,
        storage_type: "io2",
        iops: 10000
      })
      
      expect(attrs.iops).to eq(10000)
    end
    
    it "validates IOPS only allowed for io1/io2" do
      expect {
        Pangea::Resources::AWS::DbInstanceAttributes.new({
          engine: "mysql",
          instance_class: "db.t3.micro",
          allocated_storage: 100,
          storage_type: "gp3",
          iops: 3000
        })
      }.to raise_error(Dry::Struct::Error, /IOPS can only be specified for io1 or io2/)
    end
    
    it "accepts database configuration" do
      attrs = Pangea::Resources::AWS::DbInstanceAttributes.new({
        engine: "postgres",
        instance_class: "db.t3.medium",
        allocated_storage: 100,
        db_name: "myapp",
        username: "dbadmin"
      })
      
      expect(attrs.db_name).to eq("myapp")
      expect(attrs.username).to eq("dbadmin")
    end
    
    it "accepts password configuration" do
      attrs = Pangea::Resources::AWS::DbInstanceAttributes.new({
        engine: "mysql",
        instance_class: "db.t3.micro",
        allocated_storage: 20,
        password: "temporary-password",
        manage_master_user_password: false
      })
      
      expect(attrs.password).to eq("temporary-password")
      expect(attrs.manage_master_user_password).to eq(false)
    end
    
    it "validates password and manage_master_user_password are mutually exclusive" do
      expect {
        Pangea::Resources::AWS::DbInstanceAttributes.new({
          engine: "mysql",
          instance_class: "db.t3.micro",
          allocated_storage: 20,
          password: "mypassword",
          manage_master_user_password: true
        })
      }.to raise_error(Dry::Struct::Error, /Cannot specify both 'password' and 'manage_master_user_password'/)
    end
    
    it "accepts network configuration" do
      attrs = Pangea::Resources::AWS::DbInstanceAttributes.new({
        engine: "postgres",
        instance_class: "db.t3.medium",
        allocated_storage: 100,
        db_subnet_group_name: "my-db-subnet-group",
        vpc_security_group_ids: ["sg-12345", "sg-67890"],
        availability_zone: "us-east-1a",
        multi_az: true,
        publicly_accessible: false
      })
      
      expect(attrs.db_subnet_group_name).to eq("my-db-subnet-group")
      expect(attrs.vpc_security_group_ids).to eq(["sg-12345", "sg-67890"])
      expect(attrs.availability_zone).to eq("us-east-1a")
      expect(attrs.multi_az).to eq(true)
      expect(attrs.publicly_accessible).to eq(false)
    end
    
    it "accepts backup configuration" do
      attrs = Pangea::Resources::AWS::DbInstanceAttributes.new({
        engine: "mysql",
        instance_class: "db.t3.large",
        allocated_storage: 500,
        backup_retention_period: 14,
        backup_window: "03:00-04:00",
        maintenance_window: "sun:04:00-sun:05:00"
      })
      
      expect(attrs.backup_retention_period).to eq(14)
      expect(attrs.backup_window).to eq("03:00-04:00")
      expect(attrs.maintenance_window).to eq("sun:04:00-sun:05:00")
    end
    
    it "accepts performance monitoring configuration" do
      attrs = Pangea::Resources::AWS::DbInstanceAttributes.new({
        engine: "postgres",
        instance_class: "db.r5.large",
        allocated_storage: 1000,
        enabled_cloudwatch_logs_exports: ["postgresql"],
        performance_insights_enabled: true,
        performance_insights_retention_period: 31
      })
      
      expect(attrs.enabled_cloudwatch_logs_exports).to eq(["postgresql"])
      expect(attrs.performance_insights_enabled).to eq(true)
      expect(attrs.performance_insights_retention_period).to eq(31)
    end
    
    it "validates Aurora doesn't use allocated_storage" do
      expect {
        Pangea::Resources::AWS::DbInstanceAttributes.new({
          engine: "aurora-mysql",
          instance_class: "db.t3.small",
          allocated_storage: 100
        })
      }.to raise_error(Dry::Struct::Error, /Aurora engines do not support 'allocated_storage'/)
    end
    
    it "validates Aurora doesn't use multi_az at instance level" do
      expect {
        Pangea::Resources::AWS::DbInstanceAttributes.new({
          engine: "aurora-postgresql",
          instance_class: "db.r5.large",
          multi_az: true
        })
      }.to raise_error(Dry::Struct::Error, /Aurora engines handle multi-AZ at the cluster level/)
    end
    
    it "validates SQL Server doesn't support db_name" do
      expect {
        Pangea::Resources::AWS::DbInstanceAttributes.new({
          engine: "sqlserver-ex",
          instance_class: "db.t3.micro",
          allocated_storage: 20,
          db_name: "mydb"
        })
      }.to raise_error(Dry::Struct::Error, /SQL Server engines do not support 'db_name'/)
    end
    
    it "accepts encryption configuration" do
      attrs = Pangea::Resources::AWS::DbInstanceAttributes.new({
        engine: "mysql",
        instance_class: "db.t3.medium",
        allocated_storage: 200,
        storage_encrypted: true,
        kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678"
      })
      
      expect(attrs.storage_encrypted).to eq(true)
      expect(attrs.kms_key_id).to include("key/12345678")
    end
    
    it "accepts deletion protection settings" do
      attrs = Pangea::Resources::AWS::DbInstanceAttributes.new({
        engine: "postgres",
        instance_class: "db.t3.large",
        allocated_storage: 500,
        deletion_protection: true,
        skip_final_snapshot: false,
        final_snapshot_identifier: "final-backup-2023"
      })
      
      expect(attrs.deletion_protection).to eq(true)
      expect(attrs.skip_final_snapshot).to eq(false)
      expect(attrs.final_snapshot_identifier).to eq("final-backup-2023")
    end
    
    it "accepts tags" do
      attrs = Pangea::Resources::AWS::DbInstanceAttributes.new({
        engine: "mysql",
        instance_class: "db.t3.micro",
        allocated_storage: 20,
        tags: {
          Name: "production-database",
          Environment: "production",
          Application: "web-app"
        }
      })
      
      expect(attrs.tags[:Name]).to eq("production-database")
      expect(attrs.tags[:Environment]).to eq("production")
      expect(attrs.tags[:Application]).to eq("web-app")
    end
  end
  
  describe "aws_db_instance function behavior" do
    it "creates a resource reference with minimal attributes" do
      ref = test_instance.aws_db_instance(:test, {
        engine: "postgres",
        instance_class: "db.t3.micro",
        allocated_storage: 20
      })
      
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_db_instance')
      expect(ref.name).to eq(:test)
    end
    
    it "creates a database with custom identifier" do
      ref = test_instance.aws_db_instance(:my_db, {
        identifier: "production-postgres",
        engine: "postgres",
        instance_class: "db.t3.medium",
        allocated_storage: 100
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:identifier]).to eq("production-postgres")
    end
    
    it "creates a MySQL database with logging" do
      ref = test_instance.aws_db_instance(:mysql_db, {
        engine: "mysql",
        engine_version: "8.0.33",
        instance_class: "db.t3.large",
        allocated_storage: 500,
        enabled_cloudwatch_logs_exports: ["error", "general", "slowquery"]
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:engine]).to eq("mysql")
      expect(attrs[:engine_version]).to eq("8.0.33")
      expect(attrs[:enabled_cloudwatch_logs_exports]).to include("slowquery")
    end
    
    it "creates a high-performance database with provisioned IOPS" do
      ref = test_instance.aws_db_instance(:perf_db, {
        engine: "postgres",
        instance_class: "db.r5.2xlarge",
        allocated_storage: 1000,
        storage_type: "io2",
        iops: 20000,
        performance_insights_enabled: true
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:storage_type]).to eq("io2")
      expect(attrs[:iops]).to eq(20000)
      expect(attrs[:performance_insights_enabled]).to eq(true)
    end
    
    it "creates a multi-AZ database for high availability" do
      ref = test_instance.aws_db_instance(:ha_db, {
        engine: "mysql",
        instance_class: "db.m5.xlarge",
        allocated_storage: 500,
        multi_az: true,
        backup_retention_period: 14,
        deletion_protection: true
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:multi_az]).to eq(true)
      expect(attrs[:backup_retention_period]).to eq(14)
      expect(attrs[:deletion_protection]).to eq(true)
    end
    
    it "creates an Aurora instance" do
      ref = test_instance.aws_db_instance(:aurora_instance, {
        engine: "aurora-mysql",
        engine_version: "8.0.mysql_aurora.3.02.0",
        instance_class: "db.r5.large"
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:engine]).to eq("aurora-mysql")
      # Aurora doesn't have allocated_storage
      expect(attrs[:allocated_storage]).to be_nil
    end
    
    it "provides all expected outputs" do
      ref = test_instance.aws_db_instance(:test, {
        engine: "postgres",
        instance_class: "db.t3.micro",
        allocated_storage: 20
      })
      
      expected_outputs = [:id, :arn, :address, :endpoint, :hosted_zone_id, :resource_id, :status, :port]
      
      expected_outputs.each do |output|
        expect(ref.outputs).to have_key(output)
        expect(ref.outputs[output]).to include("${aws_db_instance.test.")
      end
    end
    
    it "provides computed properties" do
      ref = test_instance.aws_db_instance(:test, {
        engine: "mysql",
        instance_class: "db.t3.medium",
        allocated_storage: 100
      })
      
      expect(ref.engine_family).to eq("mysql")
      expect(ref.is_aurora?).to eq(false)
      expect(ref.is_serverless?).to eq(false)
      expect(ref.requires_subnet_group?).to eq(true)
      expect(ref.supports_encryption?).to eq(true)
      expect(ref.estimated_monthly_cost).to match(/~\$\d+\.\d+\/month/)
    end
    
    it "identifies Aurora engines correctly" do
      ref = test_instance.aws_db_instance(:aurora, {
        engine: "aurora-postgresql",
        instance_class: "db.r5.large"
      })
      
      expect(ref.is_aurora?).to eq(true)
      expect(ref.engine_family).to eq("postgresql")
    end
    
    it "identifies serverless instances" do
      ref = test_instance.aws_db_instance(:serverless, {
        engine: "aurora-mysql",
        instance_class: "db.serverless"
      })
      
      expect(ref.is_serverless?).to eq(true)
    end
  end
  
  describe "RdsEngineConfigs helper module" do
    it "provides MySQL configuration" do
      config = Pangea::Resources::AWS::RdsEngineConfigs.mysql(version: "8.0.35")
      
      expect(config[:engine]).to eq("mysql")
      expect(config[:engine_version]).to eq("8.0.35")
      expect(config[:enabled_cloudwatch_logs_exports]).to include("error", "general", "slowquery")
    end
    
    it "provides PostgreSQL configuration" do
      config = Pangea::Resources::AWS::RdsEngineConfigs.postgresql(version: "15.3")
      
      expect(config[:engine]).to eq("postgres")
      expect(config[:engine_version]).to eq("15.3")
      expect(config[:enabled_cloudwatch_logs_exports]).to eq(["postgresql"])
    end
    
    it "provides Aurora MySQL configuration" do
      config = Pangea::Resources::AWS::RdsEngineConfigs.aurora_mysql(version: "8.0.mysql_aurora.3.04.0")
      
      expect(config[:engine]).to eq("aurora-mysql")
      expect(config[:engine_version]).to eq("8.0.mysql_aurora.3.04.0")
    end
    
    it "provides Aurora PostgreSQL configuration" do
      config = Pangea::Resources::AWS::RdsEngineConfigs.aurora_postgresql(version: "15.3")
      
      expect(config[:engine]).to eq("aurora-postgresql")
      expect(config[:engine_version]).to eq("15.3")
    end
    
    it "provides MariaDB configuration" do
      config = Pangea::Resources::AWS::RdsEngineConfigs.mariadb(version: "10.11.4")
      
      expect(config[:engine]).to eq("mariadb")
      expect(config[:engine_version]).to eq("10.11.4")
      expect(config[:enabled_cloudwatch_logs_exports]).to include("error", "general", "slowquery")
    end
  end
  
  describe "common RDS patterns" do
    it "creates a production database with security best practices" do
      ref = test_instance.aws_db_instance(:prod_db, {
        identifier: "production-main-db",
        engine: "postgres",
        engine_version: "15.3",
        instance_class: "db.m5.xlarge",
        allocated_storage: 1000,
        storage_type: "gp3",
        storage_encrypted: true,
        kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/production",
        
        db_name: "mainapp",
        username: "dbadmin",
        manage_master_user_password: true,
        
        db_subnet_group_name: "production-db-subnet",
        vpc_security_group_ids: ["sg-prod-db"],
        multi_az: true,
        
        backup_retention_period: 30,
        backup_window: "03:00-04:00",
        maintenance_window: "sun:04:00-sun:05:00",
        
        performance_insights_enabled: true,
        performance_insights_retention_period: 7,
        enabled_cloudwatch_logs_exports: ["postgresql"],
        
        deletion_protection: true,
        auto_minor_version_upgrade: false,
        
        tags: {
          Name: "production-main-db",
          Environment: "production",
          DataClassification: "confidential"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:storage_encrypted]).to eq(true)
      expect(attrs[:multi_az]).to eq(true)
      expect(attrs[:backup_retention_period]).to eq(30)
      expect(attrs[:deletion_protection]).to eq(true)
      expect(attrs[:manage_master_user_password]).to eq(true)
    end
    
    it "creates a development database with cost optimization" do
      ref = test_instance.aws_db_instance(:dev_db, {
        identifier_prefix: "dev-db-",
        engine: "mysql",
        instance_class: "db.t3.micro",
        allocated_storage: 20,
        storage_type: "gp2",
        storage_encrypted: false,
        
        db_name: "devdb",
        username: "developer",
        password: "temp-dev-pass",
        manage_master_user_password: false,
        
        backup_retention_period: 1,
        skip_final_snapshot: true,
        deletion_protection: false,
        
        tags: {
          Environment: "development",
          AutoShutdown: "true",
          CostCenter: "engineering"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:instance_class]).to eq("db.t3.micro")
      expect(attrs[:allocated_storage]).to eq(20)
      expect(attrs[:storage_encrypted]).to eq(false)
      expect(attrs[:backup_retention_period]).to eq(1)
      expect(attrs[:deletion_protection]).to eq(false)
    end
    
    it "creates a data warehouse database" do
      ref = test_instance.aws_db_instance(:warehouse, {
        identifier: "data-warehouse",
        engine: "postgres",
        engine_version: "15.3",
        instance_class: "db.r5.4xlarge",
        allocated_storage: 5000,
        storage_type: "io2",
        iops: 50000,
        
        db_name: "warehouse",
        
        performance_insights_enabled: true,
        performance_insights_retention_period: 31,
        enabled_cloudwatch_logs_exports: ["postgresql"],
        
        backup_window: "05:00-06:00",
        maintenance_window: "sat:06:00-sat:07:00",
        
        tags: {
          Purpose: "data-warehouse",
          Type: "analytics"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:instance_class]).to include("r5")  # Memory optimized
      expect(attrs[:storage_type]).to eq("io2")
      expect(attrs[:iops]).to eq(50000)
      expect(attrs[:performance_insights_retention_period]).to eq(31)
    end
  end
  
  describe "resource reference integration" do
    it "provides terraform interpolation syntax for outputs" do
      ref = test_instance.aws_db_instance(:test_db, {
        engine: "mysql",
        instance_class: "db.t3.micro",
        allocated_storage: 20
      })
      
      expect(ref.outputs[:id]).to eq("${aws_db_instance.test_db.id}")
      expect(ref.outputs[:endpoint]).to eq("${aws_db_instance.test_db.endpoint}")
      expect(ref.outputs[:address]).to eq("${aws_db_instance.test_db.address}")
      expect(ref.outputs[:port]).to eq("${aws_db_instance.test_db.port}")
    end
    
    it "can be used with other AWS resources" do
      db_ref = test_instance.aws_db_instance(:app_db, {
        identifier: "application-database",
        engine: "postgres",
        instance_class: "db.t3.medium",
        allocated_storage: 100
      })
      
      # Simulate using database reference in application configuration
      db_endpoint = db_ref.outputs[:endpoint]
      db_port = db_ref.outputs[:port]
      
      expect(db_endpoint).to eq("${aws_db_instance.app_db.endpoint}")
      expect(db_port).to eq("${aws_db_instance.app_db.port}")
    end
    
    it "supports complex cross-resource references" do
      ref = test_instance.aws_db_instance(:cross_ref, {
        identifier: "${var.application}-${var.environment}-db",
        engine: "mysql",
        instance_class: "${var.db_instance_class}",
        allocated_storage: 100,
        
        db_subnet_group_name: "${aws_db_subnet_group.main.name}",
        vpc_security_group_ids: ["${aws_security_group.database.id}"],
        kms_key_id: "${aws_kms_key.database.arn}",
        
        tags: {
          Name: "${var.application}-database",
          Environment: "${var.environment}"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:identifier]).to include("var.application")
      expect(attrs[:db_subnet_group_name]).to include("aws_db_subnet_group")
      expect(attrs[:vpc_security_group_ids].first).to include("aws_security_group")
    end
  end
  
  describe "error conditions and edge cases" do
    it "handles default values correctly" do
      ref = test_instance.aws_db_instance(:defaults, {
        engine: "postgres",
        instance_class: "db.t3.micro",
        allocated_storage: 20
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:storage_type]).to eq("gp3")
      expect(attrs[:storage_encrypted]).to eq(true)
      expect(attrs[:manage_master_user_password]).to eq(true)
      expect(attrs[:multi_az]).to eq(false)
      expect(attrs[:publicly_accessible]).to eq(false)
      expect(attrs[:backup_retention_period]).to eq(7)
    end
    
    it "handles string keys in attributes" do
      ref = test_instance.aws_db_instance(:string_keys, {
        "identifier" => "string-key-db",
        "engine" => "mysql",
        "instance_class" => "db.t3.small",
        "allocated_storage" => 50,
        "tags" => {
          Name: "string-key-database"
        }
      })
      
      expect(ref.resource_attributes[:identifier]).to eq("string-key-db")
      expect(ref.resource_attributes[:engine]).to eq("mysql")
      expect(ref.resource_attributes[:tags][:Name]).to eq("string-key-database")
    end
    
    it "calculates cost estimates" do
      ref = test_instance.aws_db_instance(:cost_test, {
        engine: "postgres",
        instance_class: "db.m5.xlarge",
        allocated_storage: 500,
        multi_az: true
      })
      
      cost = ref.estimated_monthly_cost
      expect(cost).to match(/~\$/)
      expect(cost).to match(/month/)
      
      # Multi-AZ should roughly double the cost
      single_az_ref = test_instance.aws_db_instance(:single_az, {
        engine: "postgres",
        instance_class: "db.m5.xlarge",
        allocated_storage: 500,
        multi_az: false
      })
      
      multi_az_cost = cost.match(/~\$(\d+\.\d+)/)[1].to_f
      single_az_cost = single_az_ref.estimated_monthly_cost.match(/~\$(\d+\.\d+)/)[1].to_f
      
      expect(multi_az_cost).to be > single_az_cost
    end
    
    it "handles engine family detection correctly" do
      test_cases = {
        "mysql" => "mysql",
        "aurora-mysql" => "mysql",
        "postgres" => "postgresql",
        "aurora-postgresql" => "postgresql",
        "mariadb" => "mariadb",
        "oracle-ee" => "oracle",
        "sqlserver-ex" => "sqlserver"
      }
      
      test_cases.each do |engine, expected_family|
        ref = test_instance.aws_db_instance(:family_test, {
          engine: engine,
          instance_class: "db.t3.micro",
          allocated_storage: engine.start_with?("aurora") ? nil : 20
        }.compact)
        
        expect(ref.engine_family).to eq(expected_family)
      end
    end
  end
end