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
require 'pangea/resources/aws_ecs_cluster/resource'

RSpec.describe "aws_ecs_cluster synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecs_cluster(:test, {
          name: "test-cluster"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_ecs_cluster")
      expect(result["resource"]["aws_ecs_cluster"]).to have_key("test")

      cluster_config = result["resource"]["aws_ecs_cluster"]["test"]
      expect(cluster_config["name"]).to eq("test-cluster")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecs_cluster(:test, {
          name: "test-cluster",
          tags: { Name: "test-cluster", Environment: "test" }
        })
      end

      result = synthesizer.synthesis
      cluster_config = result["resource"]["aws_ecs_cluster"]["test"]

      expect(cluster_config).to have_key("tags")
      expect(cluster_config["tags"]["Name"]).to eq("test-cluster")
      expect(cluster_config["tags"]["Environment"]).to eq("test")
    end

    it "supports container insights enabled" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecs_cluster(:test, {
          name: "test-cluster",
          container_insights_enabled: true
        })
      end

      result = synthesizer.synthesis
      cluster_config = result["resource"]["aws_ecs_cluster"]["test"]

      expect(cluster_config).to have_key("setting")
      setting = cluster_config["setting"]
      expect(setting["name"]).to eq("containerInsights")
      expect(setting["value"]).to eq("enabled")
    end

    it "supports Fargate capacity providers" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecs_cluster(:test, {
          name: "test-cluster",
          capacity_providers: ["FARGATE", "FARGATE_SPOT"]
        })
      end

      result = synthesizer.synthesis
      cluster_config = result["resource"]["aws_ecs_cluster"]["test"]

      expect(cluster_config["capacity_providers"]).to eq(["FARGATE", "FARGATE_SPOT"])
    end

    it "supports execute command configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecs_cluster(:test, {
          name: "test-cluster",
          configuration: {
            execute_command_configuration: {
              logging: "OVERRIDE",
              log_configuration: {
                cloud_watch_log_group_name: "/ecs/exec-logs",
                cloud_watch_encryption_enabled: true
              }
            }
          }
        })
      end

      result = synthesizer.synthesis
      cluster_config = result["resource"]["aws_ecs_cluster"]["test"]

      expect(cluster_config).to have_key("configuration")
      config = cluster_config["configuration"]
      expect(config).to have_key("execute_command_configuration")
      exec_config = config["execute_command_configuration"]
      expect(exec_config["logging"]).to eq("OVERRIDE")
      expect(exec_config["log_configuration"]["cloud_watch_log_group_name"]).to eq("/ecs/exec-logs")
    end

    it "supports service connect defaults" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecs_cluster(:test, {
          name: "test-cluster",
          service_connect_defaults: {
            namespace: "arn:aws:servicediscovery:us-east-1:123456789012:namespace/ns-example"
          }
        })
      end

      result = synthesizer.synthesis
      cluster_config = result["resource"]["aws_ecs_cluster"]["test"]

      expect(cluster_config).to have_key("service_connect_defaults")
      expect(cluster_config["service_connect_defaults"]["namespace"]).to eq("arn:aws:servicediscovery:us-east-1:123456789012:namespace/ns-example")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecs_cluster(:test, { name: "test-cluster" })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_ecs_cluster"]).to be_a(Hash)
      expect(result["resource"]["aws_ecs_cluster"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      cluster_config = result["resource"]["aws_ecs_cluster"]["test"]
      expect(cluster_config).to have_key("name")
      expect(cluster_config["name"]).to be_a(String)
    end
  end

  describe "resource references" do
    it "returns a resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_ecs_cluster(:test, { name: "test-cluster" })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.id).to eq("${aws_ecs_cluster.test.id}")
      expect(ref.arn).to eq("${aws_ecs_cluster.test.arn}")
      expect(ref.name).to eq("${aws_ecs_cluster.test.name}")
    end

    it "provides computed properties" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_ecs_cluster(:test, {
          name: "test-cluster",
          capacity_providers: ["FARGATE"],
          container_insights_enabled: true
        })
      end

      expect(ref.using_fargate?).to eq(true)
      expect(ref.using_ec2?).to eq(false)
      expect(ref.insights_enabled?).to eq(true)
    end
  end
end
