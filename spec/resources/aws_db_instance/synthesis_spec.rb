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
require 'pangea/resources/aws_db_instance/resource'

RSpec.describe "aws_db_instance synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON for MySQL instance" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_instance(:test, {
          engine: "mysql",
          instance_class: "db.t3.micro",
          allocated_storage: 20,
          tags: { Name: "test-db" }
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_db_instance")
      expect(result["resource"]["aws_db_instance"]).to have_key("test")

      db_config = result["resource"]["aws_db_instance"]["test"]
      expect(db_config["engine"]).to eq("mysql")
      expect(db_config["instance_class"]).to eq("db.t3.micro")
      expect(db_config["allocated_storage"]).to eq(20)
    end

    it "generates valid terraform JSON for PostgreSQL instance" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_instance(:postgres_db, {
          engine: "postgres",
          instance_class: "db.t3.small",
          allocated_storage: 50,
          tags: { Name: "postgres-db" }
        })
      end

      result = synthesizer.synthesis
      db_config = result["resource"]["aws_db_instance"]["postgres_db"]

      expect(db_config["engine"]).to eq("postgres")
      expect(db_config["instance_class"]).to eq("db.t3.small")
      expect(db_config["allocated_storage"]).to eq(50)
    end

    it "includes identifier when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_instance(:named_db, {
          identifier: "production-postgres",
          engine: "postgres",
          instance_class: "db.t3.medium",
          allocated_storage: 100
        })
      end

      result = synthesizer.synthesis
      db_config = result["resource"]["aws_db_instance"]["named_db"]

      expect(db_config["identifier"]).to eq("production-postgres")
    end

    it "includes engine version when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_instance(:versioned_db, {
          engine: "postgres",
          engine_version: "15.4",
          instance_class: "db.t3.micro",
          allocated_storage: 20
        })
      end

      result = synthesizer.synthesis
      db_config = result["resource"]["aws_db_instance"]["versioned_db"]

      expect(db_config["engine_version"]).to eq("15.4")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_instance(:tagged_db, {
          engine: "mysql",
          instance_class: "db.t3.micro",
          allocated_storage: 20,
          tags: { Name: "test-db", Environment: "test", Application: "myapp" }
        })
      end

      result = synthesizer.synthesis
      db_config = result["resource"]["aws_db_instance"]["tagged_db"]

      expect(db_config).to have_key("tags")
      expect(db_config["tags"]["Name"]).to eq("test-db")
      expect(db_config["tags"]["Environment"]).to eq("test")
      expect(db_config["tags"]["Application"]).to eq("myapp")
    end

    it "applies default values correctly" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_instance(:default_db, {
          engine: "mysql",
          instance_class: "db.t3.micro",
          allocated_storage: 20
        })
      end

      result = synthesizer.synthesis
      db_config = result["resource"]["aws_db_instance"]["default_db"]

      expect(db_config["storage_encrypted"]).to eq(true)
      expect(db_config["backup_retention_period"]).to eq(7)
      expect(db_config["multi_az"]).to eq(false)
      expect(db_config["publicly_accessible"]).to eq(false)
      expect(db_config["auto_minor_version_upgrade"]).to eq(true)
      expect(db_config["deletion_protection"]).to eq(false)
      expect(db_config["skip_final_snapshot"]).to eq(true)
    end

    it "supports database credentials configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_instance(:creds_db, {
          engine: "postgres",
          instance_class: "db.t3.micro",
          allocated_storage: 20,
          db_name: "myappdb",
          username: "admin",
          manage_master_user_password: true
        })
      end

      result = synthesizer.synthesis
      db_config = result["resource"]["aws_db_instance"]["creds_db"]

      expect(db_config["db_name"]).to eq("myappdb")
      expect(db_config["username"]).to eq("admin")
      expect(db_config["manage_master_user_password"]).to eq(true)
    end

    it "supports network configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_instance(:network_db, {
          engine: "mysql",
          instance_class: "db.t3.medium",
          allocated_storage: 100,
          db_subnet_group_name: "my-db-subnet-group",
          vpc_security_group_ids: ["sg-12345678", "sg-87654321"],
          availability_zone: "us-east-1a",
          multi_az: true
        })
      end

      result = synthesizer.synthesis
      db_config = result["resource"]["aws_db_instance"]["network_db"]

      expect(db_config["db_subnet_group_name"]).to eq("my-db-subnet-group")
      expect(db_config["vpc_security_group_ids"]).to eq(["sg-12345678", "sg-87654321"])
      expect(db_config["availability_zone"]).to eq("us-east-1a")
      expect(db_config["multi_az"]).to eq(true)
    end

    it "supports backup configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_instance(:backup_db, {
          engine: "postgres",
          instance_class: "db.t3.large",
          allocated_storage: 200,
          backup_retention_period: 14,
          backup_window: "03:00-04:00",
          maintenance_window: "sun:04:00-sun:05:00"
        })
      end

      result = synthesizer.synthesis
      db_config = result["resource"]["aws_db_instance"]["backup_db"]

      expect(db_config["backup_retention_period"]).to eq(14)
      expect(db_config["backup_window"]).to eq("03:00-04:00")
      expect(db_config["maintenance_window"]).to eq("sun:04:00-sun:05:00")
    end

    it "supports encryption configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_instance(:encrypted_db, {
          engine: "mysql",
          instance_class: "db.t3.medium",
          allocated_storage: 100,
          storage_encrypted: true,
          kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
        })
      end

      result = synthesizer.synthesis
      db_config = result["resource"]["aws_db_instance"]["encrypted_db"]

      expect(db_config["storage_encrypted"]).to eq(true)
      expect(db_config["kms_key_id"]).to eq("arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012")
    end

    it "supports io2 storage with IOPS" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_instance(:iops_db, {
          engine: "postgres",
          instance_class: "db.r5.large",
          allocated_storage: 500,
          storage_type: "io2",
          iops: 5000
        })
      end

      result = synthesizer.synthesis
      db_config = result["resource"]["aws_db_instance"]["iops_db"]

      expect(db_config["storage_type"]).to eq("io2")
      expect(db_config["iops"]).to eq(5000)
    end

    it "supports CloudWatch logs exports" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_instance(:logging_db, {
          engine: "postgres",
          instance_class: "db.t3.medium",
          allocated_storage: 100,
          enabled_cloudwatch_logs_exports: ["postgresql"]
        })
      end

      result = synthesizer.synthesis
      db_config = result["resource"]["aws_db_instance"]["logging_db"]

      expect(db_config["enabled_cloudwatch_logs_exports"]).to eq(["postgresql"])
    end

    it "supports Performance Insights" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_instance(:insights_db, {
          engine: "mysql",
          instance_class: "db.m5.large",
          allocated_storage: 200,
          performance_insights_enabled: true,
          performance_insights_retention_period: 31
        })
      end

      result = synthesizer.synthesis
      db_config = result["resource"]["aws_db_instance"]["insights_db"]

      expect(db_config["performance_insights_enabled"]).to eq(true)
      expect(db_config["performance_insights_retention_period"]).to eq(31)
    end

    it "supports deletion protection with final snapshot" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_instance(:protected_db, {
          engine: "postgres",
          instance_class: "db.t3.large",
          allocated_storage: 500,
          deletion_protection: true,
          skip_final_snapshot: false,
          final_snapshot_identifier: "final-backup-2025"
        })
      end

      result = synthesizer.synthesis
      db_config = result["resource"]["aws_db_instance"]["protected_db"]

      expect(db_config["deletion_protection"]).to eq(true)
      expect(db_config["skip_final_snapshot"]).to eq(false)
      expect(db_config["final_snapshot_identifier"]).to eq("final-backup-2025")
    end

    it "supports Aurora instance (no allocated_storage)" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_instance(:aurora_instance, {
          engine: "aurora-mysql",
          engine_version: "8.0.mysql_aurora.3.04.0",
          instance_class: "db.r5.large"
        })
      end

      result = synthesizer.synthesis
      db_config = result["resource"]["aws_db_instance"]["aurora_instance"]

      expect(db_config["engine"]).to eq("aurora-mysql")
      expect(db_config).not_to have_key("allocated_storage")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_instance(:validation_db, {
          engine: "mysql",
          instance_class: "db.t3.micro",
          allocated_storage: 20
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_db_instance"]).to be_a(Hash)
      expect(result["resource"]["aws_db_instance"]["validation_db"]).to be_a(Hash)

      # Validate required attributes are present
      db_config = result["resource"]["aws_db_instance"]["validation_db"]
      expect(db_config).to have_key("engine")
      expect(db_config["engine"]).to be_a(String)
      expect(db_config).to have_key("instance_class")
      expect(db_config["instance_class"]).to be_a(String)
    end
  end

  describe "resource references" do
    it "returns a ResourceReference with correct outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_db_instance(:ref_db, {
          engine: "postgres",
          instance_class: "db.t3.micro",
          allocated_storage: 20
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq("aws_db_instance")
      expect(ref.name).to eq(:ref_db)

      # Verify outputs
      expect(ref.outputs[:id]).to eq("${aws_db_instance.ref_db.id}")
      expect(ref.outputs[:arn]).to eq("${aws_db_instance.ref_db.arn}")
      expect(ref.outputs[:address]).to eq("${aws_db_instance.ref_db.address}")
      expect(ref.outputs[:endpoint]).to eq("${aws_db_instance.ref_db.endpoint}")
      expect(ref.outputs[:port]).to eq("${aws_db_instance.ref_db.port}")
    end

    it "can be used in other resource configurations" do
      db_ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        db_ref = aws_db_instance(:main_db, {
          engine: "mysql",
          instance_class: "db.t3.medium",
          allocated_storage: 100
        })
      end

      # Verify references can be used in other resources
      expect(db_ref.outputs[:endpoint]).to match(/\$\{aws_db_instance\.main_db\.endpoint\}/)
      expect(db_ref.outputs[:address]).to match(/\$\{aws_db_instance\.main_db\.address\}/)
    end
  end
end
