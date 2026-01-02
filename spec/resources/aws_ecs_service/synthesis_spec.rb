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
require 'pangea/resources/aws_ecs_service/resource'

RSpec.describe "aws_ecs_service synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecs_service(:test, {
          name: "test-service",
          cluster: "arn:aws:ecs:us-east-1:123456789012:cluster/test-cluster",
          task_definition: "arn:aws:ecs:us-east-1:123456789012:task-definition/test-task:1",
          desired_count: 2
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_ecs_service")
      expect(result["resource"]["aws_ecs_service"]).to have_key("test")

      service_config = result["resource"]["aws_ecs_service"]["test"]
      expect(service_config["name"]).to eq("test-service")
      expect(service_config["cluster"]).to eq("arn:aws:ecs:us-east-1:123456789012:cluster/test-cluster")
      expect(service_config["task_definition"]).to eq("arn:aws:ecs:us-east-1:123456789012:task-definition/test-task:1")
      expect(service_config["desired_count"]).to eq(2)
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecs_service(:test, {
          name: "test-service",
          cluster: "arn:aws:ecs:us-east-1:123456789012:cluster/test-cluster",
          task_definition: "arn:aws:ecs:us-east-1:123456789012:task-definition/test-task:1",
          tags: { Name: "test-service", Environment: "test" }
        })
      end

      result = synthesizer.synthesis
      service_config = result["resource"]["aws_ecs_service"]["test"]

      expect(service_config).to have_key("tags")
      expect(service_config["tags"]["Name"]).to eq("test-service")
      expect(service_config["tags"]["Environment"]).to eq("test")
    end

    it "supports Fargate launch type" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecs_service(:test, {
          name: "test-service",
          cluster: "arn:aws:ecs:us-east-1:123456789012:cluster/test-cluster",
          task_definition: "arn:aws:ecs:us-east-1:123456789012:task-definition/test-task:1",
          launch_type: "FARGATE",
          platform_version: "1.4.0",
          network_configuration: {
            subnets: ["subnet-12345678", "subnet-87654321"],
            security_groups: ["sg-12345678"],
            assign_public_ip: true
          }
        })
      end

      result = synthesizer.synthesis
      service_config = result["resource"]["aws_ecs_service"]["test"]

      expect(service_config["launch_type"]).to eq("FARGATE")
      expect(service_config["platform_version"]).to eq("1.4.0")
      expect(service_config).to have_key("network_configuration")
      network_config = service_config["network_configuration"]
      expect(network_config["subnets"]).to eq(["subnet-12345678", "subnet-87654321"])
      expect(network_config["security_groups"]).to eq(["sg-12345678"])
      expect(network_config["assign_public_ip"]).to eq(true)
    end

    it "supports load balancer configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecs_service(:test, {
          name: "test-service",
          cluster: "arn:aws:ecs:us-east-1:123456789012:cluster/test-cluster",
          task_definition: "arn:aws:ecs:us-east-1:123456789012:task-definition/test-task:1",
          launch_type: "FARGATE",
          network_configuration: {
            subnets: ["subnet-12345678"]
          },
          load_balancer: [
            {
              target_group_arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/test-tg/1234567890",
              container_name: "web",
              container_port: 8080
            }
          ],
          health_check_grace_period_seconds: 60
        })
      end

      result = synthesizer.synthesis
      service_config = result["resource"]["aws_ecs_service"]["test"]

      expect(service_config).to have_key("load_balancer")
      lb_config = service_config["load_balancer"]
      expect(lb_config["target_group_arn"]).to eq("arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/test-tg/1234567890")
      expect(lb_config["container_name"]).to eq("web")
      expect(lb_config["container_port"]).to eq(8080)
      expect(service_config["health_check_grace_period_seconds"]).to eq(60)
    end

    it "supports deployment configuration with circuit breaker" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecs_service(:test, {
          name: "test-service",
          cluster: "arn:aws:ecs:us-east-1:123456789012:cluster/test-cluster",
          task_definition: "arn:aws:ecs:us-east-1:123456789012:task-definition/test-task:1",
          deployment_configuration: {
            deployment_circuit_breaker: {
              enable: true,
              rollback: true
            },
            maximum_percent: 200,
            minimum_healthy_percent: 100
          }
        })
      end

      result = synthesizer.synthesis
      service_config = result["resource"]["aws_ecs_service"]["test"]

      expect(service_config).to have_key("deployment_configuration")
      deploy_config = service_config["deployment_configuration"]
      expect(deploy_config["deployment_circuit_breaker"]["enable"]).to eq(true)
      expect(deploy_config["deployment_circuit_breaker"]["rollback"]).to eq(true)
      expect(deploy_config["maximum_percent"]).to eq(200)
      expect(deploy_config["minimum_healthy_percent"]).to eq(100)
    end

    it "supports deployment controller type" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecs_service(:test, {
          name: "test-service",
          cluster: "arn:aws:ecs:us-east-1:123456789012:cluster/test-cluster",
          task_definition: "arn:aws:ecs:us-east-1:123456789012:task-definition/test-task:1",
          deployment_controller: {
            type: "ECS"
          }
        })
      end

      result = synthesizer.synthesis
      service_config = result["resource"]["aws_ecs_service"]["test"]

      expect(service_config).to have_key("deployment_controller")
      expect(service_config["deployment_controller"]["type"]).to eq("ECS")
    end

    it "supports enable execute command" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecs_service(:test, {
          name: "test-service",
          cluster: "arn:aws:ecs:us-east-1:123456789012:cluster/test-cluster",
          task_definition: "arn:aws:ecs:us-east-1:123456789012:task-definition/test-task:1",
          enable_execute_command: true
        })
      end

      result = synthesizer.synthesis
      service_config = result["resource"]["aws_ecs_service"]["test"]

      expect(service_config["enable_execute_command"]).to eq(true)
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecs_service(:test, {
          name: "test-service",
          cluster: "arn:aws:ecs:us-east-1:123456789012:cluster/test-cluster",
          task_definition: "arn:aws:ecs:us-east-1:123456789012:task-definition/test-task:1"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_ecs_service"]).to be_a(Hash)
      expect(result["resource"]["aws_ecs_service"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      service_config = result["resource"]["aws_ecs_service"]["test"]
      expect(service_config).to have_key("name")
      expect(service_config).to have_key("cluster")
      expect(service_config).to have_key("task_definition")
    end
  end

  describe "resource references" do
    it "returns a resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_ecs_service(:test, {
          name: "test-service",
          cluster: "arn:aws:ecs:us-east-1:123456789012:cluster/test-cluster",
          task_definition: "arn:aws:ecs:us-east-1:123456789012:task-definition/test-task:1"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.id).to eq("${aws_ecs_service.test.id}")
      expect(ref.name).to eq("${aws_ecs_service.test.name}")
      expect(ref.cluster).to eq("${aws_ecs_service.test.cluster}")
    end

    it "provides computed properties" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_ecs_service(:test, {
          name: "test-service",
          cluster: "arn:aws:ecs:us-east-1:123456789012:cluster/test-cluster",
          task_definition: "arn:aws:ecs:us-east-1:123456789012:task-definition/test-task:1",
          launch_type: "FARGATE",
          network_configuration: {
            subnets: ["subnet-12345678"]
          },
          load_balancer: [
            {
              target_group_arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/test-tg/1234567890",
              container_name: "web",
              container_port: 8080
            }
          ],
          deployment_configuration: {
            deployment_circuit_breaker: {
              enable: true,
              rollback: true
            }
          }
        })
      end

      expect(ref.using_fargate?).to eq(true)
      expect(ref.load_balanced?).to eq(true)
      expect(ref.deployment_safe?).to eq(true)
    end
  end
end
