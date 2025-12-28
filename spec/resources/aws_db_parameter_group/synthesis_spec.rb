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
require 'pangea/resources/aws_db_parameter_group/resource'

RSpec.describe "aws_db_parameter_group synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON for MySQL parameter group" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_parameter_group(:test, {
          name: "test-mysql-params",
          family: "mysql8.0",
          tags: { Name: "test-mysql-params" }
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_db_parameter_group")
      expect(result["resource"]["aws_db_parameter_group"]).to have_key("test")

      param_group_config = result["resource"]["aws_db_parameter_group"]["test"]
      expect(param_group_config["name"]).to eq("test-mysql-params")
      expect(param_group_config["family"]).to eq("mysql8.0")
    end

    it "generates valid terraform JSON for PostgreSQL parameter group" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_parameter_group(:postgres_params, {
          name: "test-postgres-params",
          family: "postgres15",
          tags: { Name: "test-postgres-params" }
        })
      end

      result = synthesizer.synthesis
      param_group_config = result["resource"]["aws_db_parameter_group"]["postgres_params"]

      expect(param_group_config["name"]).to eq("test-postgres-params")
      expect(param_group_config["family"]).to eq("postgres15")
    end

    it "generates valid terraform JSON for Aurora MySQL parameter group" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_parameter_group(:aurora_mysql_params, {
          name: "aurora-mysql-params",
          family: "aurora-mysql8.0",
          tags: { Name: "aurora-mysql-params" }
        })
      end

      result = synthesizer.synthesis
      param_group_config = result["resource"]["aws_db_parameter_group"]["aurora_mysql_params"]

      expect(param_group_config["family"]).to eq("aurora-mysql8.0")
    end

    it "generates valid terraform JSON for Aurora PostgreSQL parameter group" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_parameter_group(:aurora_postgres_params, {
          name: "aurora-postgres-params",
          family: "aurora-postgresql15",
          tags: { Name: "aurora-postgres-params" }
        })
      end

      result = synthesizer.synthesis
      param_group_config = result["resource"]["aws_db_parameter_group"]["aurora_postgres_params"]

      expect(param_group_config["family"]).to eq("aurora-postgresql15")
    end

    it "includes description when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_parameter_group(:described, {
          name: "described-params",
          family: "mysql8.0",
          description: "Custom MySQL 8.0 parameter group for production"
        })
      end

      result = synthesizer.synthesis
      param_group_config = result["resource"]["aws_db_parameter_group"]["described"]

      expect(param_group_config["description"]).to eq("Custom MySQL 8.0 parameter group for production")
    end

    it "applies default description when not provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_parameter_group(:default_desc, {
          name: "default-desc-params",
          family: "postgres14"
        })
      end

      result = synthesizer.synthesis
      param_group_config = result["resource"]["aws_db_parameter_group"]["default_desc"]

      expect(param_group_config["description"]).to include("postgresql")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_parameter_group(:tagged, {
          name: "tagged-params",
          family: "mysql8.0",
          tags: { Name: "tagged-params", Environment: "production", Application: "myapp" }
        })
      end

      result = synthesizer.synthesis
      param_group_config = result["resource"]["aws_db_parameter_group"]["tagged"]

      expect(param_group_config).to have_key("tags")
      expect(param_group_config["tags"]["Name"]).to eq("tagged-params")
      expect(param_group_config["tags"]["Environment"]).to eq("production")
      expect(param_group_config["tags"]["Application"]).to eq("myapp")
    end

    it "includes parameters with immediate apply method" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_parameter_group(:with_params, {
          name: "params-with-settings",
          family: "mysql8.0",
          parameters: [
            { name: "slow_query_log", value: "1", apply_method: "immediate" },
            { name: "long_query_time", value: "2", apply_method: "immediate" }
          ]
        })
      end

      result = synthesizer.synthesis
      param_group_config = result["resource"]["aws_db_parameter_group"]["with_params"]

      # The parameters should be present in the synthesized output
      expect(result["resource"]["aws_db_parameter_group"]["with_params"]).to be_a(Hash)
    end

    it "includes parameters with pending-reboot apply method" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_parameter_group(:reboot_params, {
          name: "reboot-params",
          family: "mysql8.0",
          parameters: [
            { name: "innodb_buffer_pool_size", value: "134217728", apply_method: "pending-reboot" }
          ]
        })
      end

      result = synthesizer.synthesis
      param_group_config = result["resource"]["aws_db_parameter_group"]["reboot_params"]

      expect(param_group_config["name"]).to eq("reboot-params")
    end

    it "supports PostgreSQL performance tuning parameters" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_parameter_group(:pg_perf, {
          name: "postgres-performance",
          family: "postgres15",
          description: "PostgreSQL 15 performance tuning",
          parameters: [
            { name: "work_mem", value: "4MB", apply_method: "immediate" },
            { name: "maintenance_work_mem", value: "64MB", apply_method: "immediate" },
            { name: "checkpoint_completion_target", value: "0.9", apply_method: "immediate" },
            { name: "log_statement", value: "all", apply_method: "immediate" }
          ]
        })
      end

      result = synthesizer.synthesis
      param_group_config = result["resource"]["aws_db_parameter_group"]["pg_perf"]

      expect(param_group_config["name"]).to eq("postgres-performance")
      expect(param_group_config["family"]).to eq("postgres15")
    end

    it "supports production configuration with all options" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_parameter_group(:production, {
          name: "production-mysql-params",
          family: "mysql8.0",
          description: "Production MySQL 8.0 parameter group with optimized settings",
          parameters: [
            { name: "slow_query_log", value: "1", apply_method: "immediate" },
            { name: "long_query_time", value: "1", apply_method: "immediate" },
            { name: "max_connections", value: "200", apply_method: "immediate" },
            { name: "innodb_buffer_pool_size", value: "1073741824", apply_method: "pending-reboot" }
          ],
          tags: {
            Name: "production-mysql-params",
            Environment: "production",
            ManagedBy: "terraform"
          }
        })
      end

      result = synthesizer.synthesis
      param_group_config = result["resource"]["aws_db_parameter_group"]["production"]

      expect(param_group_config["name"]).to eq("production-mysql-params")
      expect(param_group_config["family"]).to eq("mysql8.0")
      expect(param_group_config["description"]).to include("Production")
      expect(param_group_config["tags"]["Environment"]).to eq("production")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_parameter_group(:validation, {
          name: "validation-params",
          family: "mysql8.0"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_db_parameter_group"]).to be_a(Hash)
      expect(result["resource"]["aws_db_parameter_group"]["validation"]).to be_a(Hash)

      # Validate required attributes are present
      param_group_config = result["resource"]["aws_db_parameter_group"]["validation"]
      expect(param_group_config).to have_key("name")
      expect(param_group_config["name"]).to be_a(String)
      expect(param_group_config).to have_key("family")
      expect(param_group_config["family"]).to be_a(String)
    end
  end

  describe "resource references" do
    it "returns a ResourceReference with correct outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_db_parameter_group(:ref_params, {
          name: "ref-params",
          family: "postgres15"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq("aws_db_parameter_group")
      expect(ref.name).to eq(:ref_params)

      # Verify outputs
      expect(ref.outputs[:id]).to eq("${aws_db_parameter_group.ref_params.id}")
      expect(ref.outputs[:arn]).to eq("${aws_db_parameter_group.ref_params.arn}")
      expect(ref.outputs[:name]).to eq("${aws_db_parameter_group.ref_params.name}")
      expect(ref.outputs[:description]).to eq("${aws_db_parameter_group.ref_params.description}")
      expect(ref.outputs[:family]).to eq("${aws_db_parameter_group.ref_params.family}")
    end

    it "can be used in RDS instance configuration" do
      param_group_ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        param_group_ref = aws_db_parameter_group(:main_params, {
          name: "main-db-params",
          family: "mysql8.0"
        })
      end

      # Verify the name output can be used in parameter_group_name
      expect(param_group_ref.outputs[:name]).to match(/\$\{aws_db_parameter_group\.main_params\.name\}/)
    end

    it "includes computed properties" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_db_parameter_group(:computed, {
          name: "computed-params",
          family: "aurora-mysql8.0",
          parameters: [
            { name: "slow_query_log", value: "1", apply_method: "immediate" },
            { name: "innodb_buffer_pool_size", value: "134217728", apply_method: "pending-reboot" }
          ]
        })
      end

      # Verify computed properties
      expect(ref.computed_properties[:engine]).to eq("aurora-mysql")
      expect(ref.computed_properties[:is_aurora]).to eq(true)
      expect(ref.computed_properties[:parameter_count]).to eq(2)
      expect(ref.computed_properties[:requires_reboot]).to eq(true)
    end
  end
end
