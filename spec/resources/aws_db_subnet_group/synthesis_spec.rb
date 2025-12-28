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
require 'pangea/resources/aws_db_subnet_group/resource'

RSpec.describe "aws_db_subnet_group synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON for basic subnet group" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_subnet_group(:test, {
          name: "test-subnet-group",
          subnet_ids: ["subnet-12345678", "subnet-87654321"],
          tags: { Name: "test-subnet-group" }
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_db_subnet_group")
      expect(result["resource"]["aws_db_subnet_group"]).to have_key("test")

      subnet_group_config = result["resource"]["aws_db_subnet_group"]["test"]
      expect(subnet_group_config["name"]).to eq("test-subnet-group")
      expect(subnet_group_config["subnet_ids"]).to eq(["subnet-12345678", "subnet-87654321"])
    end

    it "includes description when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_subnet_group(:described, {
          name: "described-subnet-group",
          subnet_ids: ["subnet-11111111", "subnet-22222222"],
          description: "Custom description for DB subnet group"
        })
      end

      result = synthesizer.synthesis
      subnet_group_config = result["resource"]["aws_db_subnet_group"]["described"]

      expect(subnet_group_config["description"]).to eq("Custom description for DB subnet group")
    end

    it "applies default description when not provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_subnet_group(:default_desc, {
          name: "default-desc-subnet-group",
          subnet_ids: ["subnet-aaaaaaaa", "subnet-bbbbbbbb"]
        })
      end

      result = synthesizer.synthesis
      subnet_group_config = result["resource"]["aws_db_subnet_group"]["default_desc"]

      expect(subnet_group_config["description"]).to eq("Managed by Pangea")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_subnet_group(:tagged, {
          name: "tagged-subnet-group",
          subnet_ids: ["subnet-cccccccc", "subnet-dddddddd"],
          tags: { Name: "tagged-subnet-group", Environment: "production", Application: "myapp" }
        })
      end

      result = synthesizer.synthesis
      subnet_group_config = result["resource"]["aws_db_subnet_group"]["tagged"]

      expect(subnet_group_config).to have_key("tags")
      expect(subnet_group_config["tags"]["Name"]).to eq("tagged-subnet-group")
      expect(subnet_group_config["tags"]["Environment"]).to eq("production")
      expect(subnet_group_config["tags"]["Application"]).to eq("myapp")
    end

    it "supports multiple subnets for high availability" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_subnet_group(:multi_az, {
          name: "multi-az-subnet-group",
          subnet_ids: ["subnet-11111111", "subnet-22222222", "subnet-33333333"],
          description: "Subnet group spanning 3 AZs"
        })
      end

      result = synthesizer.synthesis
      subnet_group_config = result["resource"]["aws_db_subnet_group"]["multi_az"]

      expect(subnet_group_config["subnet_ids"]).to eq(["subnet-11111111", "subnet-22222222", "subnet-33333333"])
      expect(subnet_group_config["subnet_ids"].length).to eq(3)
    end

    it "supports production configuration with all options" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_subnet_group(:production, {
          name: "production-db-subnet-group",
          subnet_ids: ["subnet-prod1111", "subnet-prod2222", "subnet-prod3333"],
          description: "Production database subnet group for Aurora cluster",
          tags: {
            Name: "production-db-subnet-group",
            Environment: "production",
            ManagedBy: "terraform",
            CostCenter: "engineering"
          }
        })
      end

      result = synthesizer.synthesis
      subnet_group_config = result["resource"]["aws_db_subnet_group"]["production"]

      expect(subnet_group_config["name"]).to eq("production-db-subnet-group")
      expect(subnet_group_config["subnet_ids"].length).to eq(3)
      expect(subnet_group_config["description"]).to eq("Production database subnet group for Aurora cluster")
      expect(subnet_group_config["tags"]["Environment"]).to eq("production")
      expect(subnet_group_config["tags"]["ManagedBy"]).to eq("terraform")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_subnet_group(:validation, {
          name: "validation-subnet-group",
          subnet_ids: ["subnet-val11111", "subnet-val22222"]
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_db_subnet_group"]).to be_a(Hash)
      expect(result["resource"]["aws_db_subnet_group"]["validation"]).to be_a(Hash)

      # Validate required attributes are present
      subnet_group_config = result["resource"]["aws_db_subnet_group"]["validation"]
      expect(subnet_group_config).to have_key("name")
      expect(subnet_group_config["name"]).to be_a(String)
      expect(subnet_group_config).to have_key("subnet_ids")
      expect(subnet_group_config["subnet_ids"]).to be_an(Array)
      expect(subnet_group_config["subnet_ids"].length).to be >= 2
    end
  end

  describe "resource references" do
    it "returns a ResourceReference with correct outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_db_subnet_group(:ref_subnet_group, {
          name: "ref-subnet-group",
          subnet_ids: ["subnet-ref11111", "subnet-ref22222"]
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq("aws_db_subnet_group")
      expect(ref.name).to eq(:ref_subnet_group)

      # Verify outputs
      expect(ref.outputs[:id]).to eq("${aws_db_subnet_group.ref_subnet_group.id}")
      expect(ref.outputs[:arn]).to eq("${aws_db_subnet_group.ref_subnet_group.arn}")
      expect(ref.outputs[:name]).to eq("${aws_db_subnet_group.ref_subnet_group.name}")
      expect(ref.outputs[:description]).to eq("${aws_db_subnet_group.ref_subnet_group.description}")
      expect(ref.outputs[:subnet_ids]).to eq("${aws_db_subnet_group.ref_subnet_group.subnet_ids}")
      expect(ref.outputs[:vpc_id]).to eq("${aws_db_subnet_group.ref_subnet_group.vpc_id}")
    end

    it "can be used in RDS instance configuration" do
      subnet_group_ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        subnet_group_ref = aws_db_subnet_group(:main_subnet_group, {
          name: "main-db-subnet-group",
          subnet_ids: ["subnet-main1111", "subnet-main2222"]
        })
      end

      # Verify the name output can be used in db_subnet_group_name
      expect(subnet_group_ref.outputs[:name]).to match(/\$\{aws_db_subnet_group\.main_subnet_group\.name\}/)
    end

    it "includes computed properties" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_db_subnet_group(:computed, {
          name: "computed-subnet-group",
          subnet_ids: ["subnet-comp1111", "subnet-comp2222", "subnet-comp3333"]
        })
      end

      # Verify computed properties
      expect(ref.computed_properties[:subnet_count]).to eq(3)
      expect(ref.computed_properties[:is_multi_az]).to eq(true)
    end
  end
end
