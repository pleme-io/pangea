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

RSpec.describe "aws_rds_cluster synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON for Aurora MySQL cluster" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_rds_cluster(:test, {
          engine: "aurora-mysql",
          skip_final_snapshot: true,
          tags: { Name: "test-cluster" }
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_rds_cluster")
      expect(result["resource"]["aws_rds_cluster"]).to have_key("test")

      cluster_config = result["resource"]["aws_rds_cluster"]["test"]
      expect(cluster_config["engine"]).to eq("aurora-mysql")
      expect(cluster_config["skip_final_snapshot"]).to eq(true)
    end

    it "generates valid terraform JSON for Aurora PostgreSQL cluster" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_rds_cluster(:postgres_cluster, {
          engine: "aurora-postgresql",
          skip_final_snapshot: true,
          tags: { Name: "postgres-cluster" }
        })
      end

      result = synthesizer.synthesis
      cluster_config = result["resource"]["aws_rds_cluster"]["postgres_cluster"]

      expect(cluster_config["engine"]).to eq("aurora-postgresql")
    end

    it "includes cluster identifier when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_rds_cluster(:named_cluster, {
          cluster_identifier: "production-aurora",
          engine: "aurora-mysql",
          skip_final_snapshot: true
        })
      end

      result = synthesizer.synthesis
      cluster_config = result["resource"]["aws_rds_cluster"]["named_cluster"]

      expect(cluster_config["cluster_identifier"]).to eq("production-aurora")
    end

    it "includes engine version when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_rds_cluster(:versioned_cluster, {
          engine: "aurora-mysql",
          engine_version: "8.0.mysql_aurora.3.04.0",
          skip_final_snapshot: true
        })
      end

      result = synthesizer.synthesis
      cluster_config = result["resource"]["aws_rds_cluster"]["versioned_cluster"]

      expect(cluster_config["engine_version"]).to eq("8.0.mysql_aurora.3.04.0")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_rds_cluster(:tagged_cluster, {
          engine: "aurora-mysql",
          skip_final_snapshot: true,
          tags: { Name: "test-cluster", Environment: "test", Application: "myapp" }
        })
      end

      result = synthesizer.synthesis
      cluster_config = result["resource"]["aws_rds_cluster"]["tagged_cluster"]

      expect(cluster_config).to have_key("tags")
      expect(cluster_config["tags"]["Name"]).to eq("test-cluster")
      expect(cluster_config["tags"]["Environment"]).to eq("test")
      expect(cluster_config["tags"]["Application"]).to eq("myapp")
    end

    it "applies default values correctly" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_rds_cluster(:default_cluster, {
          engine: "aurora-mysql",
          skip_final_snapshot: true
        })
      end

      result = synthesizer.synthesis
      cluster_config = result["resource"]["aws_rds_cluster"]["default_cluster"]

      expect(cluster_config["storage_encrypted"]).to eq(true)
      expect(cluster_config["backup_retention_period"]).to eq(7)
      expect(cluster_config["copy_tags_to_snapshot"]).to eq(true)
      expect(cluster_config["deletion_protection"]).to eq(false)
      expect(cluster_config["auto_minor_version_upgrade"]).to eq(true)
    end

    it "supports database configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_rds_cluster(:db_config_cluster, {
          engine: "aurora-mysql",
          database_name: "myappdb",
          master_username: "admin",
          manage_master_user_password: true,
          skip_final_snapshot: true
        })
      end

      result = synthesizer.synthesis
      cluster_config = result["resource"]["aws_rds_cluster"]["db_config_cluster"]

      expect(cluster_config["database_name"]).to eq("myappdb")
      expect(cluster_config["master_username"]).to eq("admin")
      expect(cluster_config["manage_master_user_password"]).to eq(true)
    end

    it "supports network configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_rds_cluster(:network_cluster, {
          engine: "aurora-mysql",
          db_subnet_group_name: "my-db-subnet-group",
          vpc_security_group_ids: ["sg-12345678", "sg-87654321"],
          availability_zones: ["us-east-1a", "us-east-1b", "us-east-1c"],
          port: 3306,
          skip_final_snapshot: true
        })
      end

      result = synthesizer.synthesis
      cluster_config = result["resource"]["aws_rds_cluster"]["network_cluster"]

      expect(cluster_config["db_subnet_group_name"]).to eq("my-db-subnet-group")
      expect(cluster_config["vpc_security_group_ids"]).to eq(["sg-12345678", "sg-87654321"])
      expect(cluster_config["availability_zones"]).to eq(["us-east-1a", "us-east-1b", "us-east-1c"])
      expect(cluster_config["port"]).to eq(3306)
    end

    it "supports backup configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_rds_cluster(:backup_cluster, {
          engine: "aurora-mysql",
          backup_retention_period: 14,
          preferred_backup_window: "03:00-04:00",
          preferred_maintenance_window: "sun:04:00-sun:05:00",
          skip_final_snapshot: true
        })
      end

      result = synthesizer.synthesis
      cluster_config = result["resource"]["aws_rds_cluster"]["backup_cluster"]

      expect(cluster_config["backup_retention_period"]).to eq(14)
      expect(cluster_config["preferred_backup_window"]).to eq("03:00-04:00")
      expect(cluster_config["preferred_maintenance_window"]).to eq("sun:04:00-sun:05:00")
    end

    it "supports encryption configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_rds_cluster(:encrypted_cluster, {
          engine: "aurora-mysql",
          storage_encrypted: true,
          kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012",
          skip_final_snapshot: true
        })
      end

      result = synthesizer.synthesis
      cluster_config = result["resource"]["aws_rds_cluster"]["encrypted_cluster"]

      expect(cluster_config["storage_encrypted"]).to eq(true)
      expect(cluster_config["kms_key_id"]).to eq("arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012")
    end

    it "supports CloudWatch logs exports" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_rds_cluster(:logging_cluster, {
          engine: "aurora-mysql",
          enabled_cloudwatch_logs_exports: ["audit", "error", "general", "slowquery"],
          skip_final_snapshot: true
        })
      end

      result = synthesizer.synthesis
      cluster_config = result["resource"]["aws_rds_cluster"]["logging_cluster"]

      expect(cluster_config["enabled_cloudwatch_logs_exports"]).to eq(["audit", "error", "general", "slowquery"])
    end

    it "supports deletion protection with final snapshot" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_rds_cluster(:protected_cluster, {
          engine: "aurora-mysql",
          deletion_protection: true,
          skip_final_snapshot: false,
          final_snapshot_identifier: "final-snapshot-2025"
        })
      end

      result = synthesizer.synthesis
      cluster_config = result["resource"]["aws_rds_cluster"]["protected_cluster"]

      expect(cluster_config["deletion_protection"]).to eq(true)
      expect(cluster_config["skip_final_snapshot"]).to eq(false)
      expect(cluster_config["final_snapshot_identifier"]).to eq("final-snapshot-2025")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_rds_cluster(:validation_cluster, {
          engine: "aurora-mysql",
          skip_final_snapshot: true
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_rds_cluster"]).to be_a(Hash)
      expect(result["resource"]["aws_rds_cluster"]["validation_cluster"]).to be_a(Hash)

      # Validate required attributes are present
      cluster_config = result["resource"]["aws_rds_cluster"]["validation_cluster"]
      expect(cluster_config).to have_key("engine")
      expect(cluster_config["engine"]).to be_a(String)
    end
  end

  describe "resource references" do
    it "returns a ResourceReference with correct outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_rds_cluster(:ref_cluster, {
          engine: "aurora-mysql",
          skip_final_snapshot: true
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq("aws_rds_cluster")
      expect(ref.name).to eq(:ref_cluster)

      # Verify outputs
      expect(ref.outputs[:id]).to eq("${aws_rds_cluster.ref_cluster.id}")
      expect(ref.outputs[:arn]).to eq("${aws_rds_cluster.ref_cluster.arn}")
      expect(ref.outputs[:endpoint]).to eq("${aws_rds_cluster.ref_cluster.endpoint}")
      expect(ref.outputs[:reader_endpoint]).to eq("${aws_rds_cluster.ref_cluster.reader_endpoint}")
      expect(ref.outputs[:cluster_identifier]).to eq("${aws_rds_cluster.ref_cluster.cluster_identifier}")
      expect(ref.outputs[:port]).to eq("${aws_rds_cluster.ref_cluster.port}")
    end

    it "can be used in other resource configurations" do
      cluster_ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        cluster_ref = aws_rds_cluster(:main_cluster, {
          engine: "aurora-mysql",
          skip_final_snapshot: true
        })
      end

      # Verify references can be used in other resources
      expect(cluster_ref.outputs[:endpoint]).to match(/\$\{aws_rds_cluster\.main_cluster\.endpoint\}/)
      expect(cluster_ref.outputs[:reader_endpoint]).to match(/\$\{aws_rds_cluster\.main_cluster\.reader_endpoint\}/)
    end
  end
end
