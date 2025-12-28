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
require 'pangea/resources/aws_ecs_task_definition/resource'
require 'json'

RSpec.describe "aws_ecs_task_definition synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON for EC2 launch type" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecs_task_definition(:test, {
          family: "test-task",
          container_definitions: [
            {
              name: "web",
              image: "nginx:latest",
              memory: 512,
              essential: true,
              port_mappings: [
                { container_port: 80 }
              ]
            }
          ]
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_ecs_task_definition")
      expect(result["resource"]["aws_ecs_task_definition"]).to have_key("test")

      task_config = result["resource"]["aws_ecs_task_definition"]["test"]
      expect(task_config["family"]).to eq("test-task")
      expect(task_config["network_mode"]).to eq("bridge")
      expect(task_config["requires_compatibilities"]).to eq(["EC2"])
      expect(task_config).to have_key("container_definitions")

      container_defs = JSON.parse(task_config["container_definitions"])
      expect(container_defs.length).to eq(1)
      expect(container_defs[0]["name"]).to eq("web")
      expect(container_defs[0]["image"]).to eq("nginx:latest")
    end

    it "generates valid terraform JSON for Fargate launch type" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecs_task_definition(:test, {
          family: "test-task",
          cpu: "256",
          memory: "512",
          network_mode: "awsvpc",
          requires_compatibilities: ["FARGATE"],
          execution_role_arn: "arn:aws:iam::123456789012:role/ecsTaskExecutionRole",
          container_definitions: [
            {
              name: "web",
              image: "nginx:latest",
              essential: true,
              port_mappings: [
                { container_port: 80 }
              ]
            }
          ]
        })
      end

      result = synthesizer.synthesis
      task_config = result["resource"]["aws_ecs_task_definition"]["test"]

      expect(task_config["cpu"]).to eq("256")
      expect(task_config["memory"]).to eq("512")
      expect(task_config["network_mode"]).to eq("awsvpc")
      expect(task_config["requires_compatibilities"]).to eq(["FARGATE"])
      expect(task_config["execution_role_arn"]).to eq("arn:aws:iam::123456789012:role/ecsTaskExecutionRole")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecs_task_definition(:test, {
          family: "test-task",
          container_definitions: [
            { name: "web", image: "nginx:latest", essential: true }
          ],
          tags: { Name: "test-task", Environment: "test" }
        })
      end

      result = synthesizer.synthesis
      task_config = result["resource"]["aws_ecs_task_definition"]["test"]

      expect(task_config).to have_key("tags")
      expect(task_config["tags"]["Name"]).to eq("test-task")
      expect(task_config["tags"]["Environment"]).to eq("test")
    end

    it "supports task and execution roles" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecs_task_definition(:test, {
          family: "test-task",
          cpu: "256",
          memory: "512",
          network_mode: "awsvpc",
          requires_compatibilities: ["FARGATE"],
          task_role_arn: "arn:aws:iam::123456789012:role/ecsTaskRole",
          execution_role_arn: "arn:aws:iam::123456789012:role/ecsTaskExecutionRole",
          container_definitions: [
            { name: "web", image: "nginx:latest", essential: true }
          ]
        })
      end

      result = synthesizer.synthesis
      task_config = result["resource"]["aws_ecs_task_definition"]["test"]

      expect(task_config["task_role_arn"]).to eq("arn:aws:iam::123456789012:role/ecsTaskRole")
      expect(task_config["execution_role_arn"]).to eq("arn:aws:iam::123456789012:role/ecsTaskExecutionRole")
    end

    it "supports container environment variables and secrets" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecs_task_definition(:test, {
          family: "test-task",
          container_definitions: [
            {
              name: "web",
              image: "nginx:latest",
              essential: true,
              environment: [
                { name: "NODE_ENV", value: "production" }
              ],
              secrets: [
                { name: "DB_PASSWORD", value_from: "arn:aws:secretsmanager:us-east-1:123456789012:secret:db-password" }
              ]
            }
          ]
        })
      end

      result = synthesizer.synthesis
      task_config = result["resource"]["aws_ecs_task_definition"]["test"]
      container_defs = JSON.parse(task_config["container_definitions"])

      expect(container_defs[0]["environment"]).to eq([{ "name" => "NODE_ENV", "value" => "production" }])
      expect(container_defs[0]["secrets"]).to eq([{ "name" => "DB_PASSWORD", "valueFrom" => "arn:aws:secretsmanager:us-east-1:123456789012:secret:db-password" }])
    end

    it "supports logging configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecs_task_definition(:test, {
          family: "test-task",
          container_definitions: [
            {
              name: "web",
              image: "nginx:latest",
              essential: true,
              log_configuration: {
                log_driver: "awslogs",
                options: {
                  "awslogs-group" => "/ecs/test-task",
                  "awslogs-region" => "us-east-1",
                  "awslogs-stream-prefix" => "web"
                }
              }
            }
          ]
        })
      end

      result = synthesizer.synthesis
      task_config = result["resource"]["aws_ecs_task_definition"]["test"]
      container_defs = JSON.parse(task_config["container_definitions"])

      expect(container_defs[0]).to have_key("logConfiguration")
      log_config = container_defs[0]["logConfiguration"]
      expect(log_config["logDriver"]).to eq("awslogs")
      expect(log_config["options"]["awslogs-group"]).to eq("/ecs/test-task")
    end

    it "supports container health checks" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecs_task_definition(:test, {
          family: "test-task",
          container_definitions: [
            {
              name: "web",
              image: "nginx:latest",
              essential: true,
              health_check: {
                command: ["CMD-SHELL", "curl -f http://localhost/ || exit 1"],
                interval: 30,
                timeout: 5,
                retries: 3,
                start_period: 60
              }
            }
          ]
        })
      end

      result = synthesizer.synthesis
      task_config = result["resource"]["aws_ecs_task_definition"]["test"]
      container_defs = JSON.parse(task_config["container_definitions"])

      expect(container_defs[0]).to have_key("healthCheck")
      health_check = container_defs[0]["healthCheck"]
      expect(health_check["command"]).to eq(["CMD-SHELL", "curl -f http://localhost/ || exit 1"])
      expect(health_check["interval"]).to eq(30)
      expect(health_check["timeout"]).to eq(5)
      expect(health_check["retries"]).to eq(3)
      expect(health_check["startPeriod"]).to eq(60)
    end

    it "supports volumes and mount points" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecs_task_definition(:test, {
          family: "test-task",
          volumes: [
            { name: "data-volume", host: { source_path: "/data" } }
          ],
          container_definitions: [
            {
              name: "web",
              image: "nginx:latest",
              essential: true,
              mount_points: [
                { source_volume: "data-volume", container_path: "/app/data", read_only: false }
              ]
            }
          ]
        })
      end

      result = synthesizer.synthesis
      task_config = result["resource"]["aws_ecs_task_definition"]["test"]

      expect(task_config).to have_key("volume")
      volume = task_config["volume"]
      expect(volume["name"]).to eq("data-volume")

      container_defs = JSON.parse(task_config["container_definitions"])
      expect(container_defs[0]).to have_key("mountPoints")
      mount_point = container_defs[0]["mountPoints"][0]
      expect(mount_point["sourceVolume"]).to eq("data-volume")
      expect(mount_point["containerPath"]).to eq("/app/data")
    end

    it "supports EFS volumes" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecs_task_definition(:test, {
          family: "test-task",
          cpu: "256",
          memory: "512",
          network_mode: "awsvpc",
          requires_compatibilities: ["FARGATE"],
          execution_role_arn: "arn:aws:iam::123456789012:role/ecsTaskExecutionRole",
          volumes: [
            {
              name: "efs-volume",
              efs_volume_configuration: {
                file_system_id: "fs-12345678",
                root_directory: "/",
                transit_encryption: "ENABLED"
              }
            }
          ],
          container_definitions: [
            {
              name: "web",
              image: "nginx:latest",
              essential: true,
              mount_points: [
                { source_volume: "efs-volume", container_path: "/mnt/efs" }
              ]
            }
          ]
        })
      end

      result = synthesizer.synthesis
      task_config = result["resource"]["aws_ecs_task_definition"]["test"]

      expect(task_config).to have_key("volume")
      volume = task_config["volume"]
      expect(volume).to have_key("efs_volume_configuration")
      efs_config = volume["efs_volume_configuration"]
      expect(efs_config["file_system_id"]).to eq("fs-12345678")
      expect(efs_config["transit_encryption"]).to eq("ENABLED")
    end

    it "supports runtime platform for Fargate" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecs_task_definition(:test, {
          family: "test-task",
          cpu: "256",
          memory: "512",
          network_mode: "awsvpc",
          requires_compatibilities: ["FARGATE"],
          execution_role_arn: "arn:aws:iam::123456789012:role/ecsTaskExecutionRole",
          runtime_platform: {
            operating_system_family: "LINUX",
            cpu_architecture: "ARM64"
          },
          container_definitions: [
            { name: "web", image: "nginx:latest", essential: true }
          ]
        })
      end

      result = synthesizer.synthesis
      task_config = result["resource"]["aws_ecs_task_definition"]["test"]

      expect(task_config).to have_key("runtime_platform")
      runtime_platform = task_config["runtime_platform"]
      expect(runtime_platform["operating_system_family"]).to eq("LINUX")
      expect(runtime_platform["cpu_architecture"]).to eq("ARM64")
    end

    it "supports ephemeral storage for Fargate" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecs_task_definition(:test, {
          family: "test-task",
          cpu: "256",
          memory: "512",
          network_mode: "awsvpc",
          requires_compatibilities: ["FARGATE"],
          execution_role_arn: "arn:aws:iam::123456789012:role/ecsTaskExecutionRole",
          ephemeral_storage: {
            size_in_gib: 30
          },
          container_definitions: [
            { name: "web", image: "nginx:latest", essential: true }
          ]
        })
      end

      result = synthesizer.synthesis
      task_config = result["resource"]["aws_ecs_task_definition"]["test"]

      expect(task_config).to have_key("ephemeral_storage")
      expect(task_config["ephemeral_storage"]["size_in_gib"]).to eq(30)
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecs_task_definition(:test, {
          family: "test-task",
          container_definitions: [
            { name: "web", image: "nginx:latest", essential: true }
          ]
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_ecs_task_definition"]).to be_a(Hash)
      expect(result["resource"]["aws_ecs_task_definition"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      task_config = result["resource"]["aws_ecs_task_definition"]["test"]
      expect(task_config).to have_key("family")
      expect(task_config).to have_key("container_definitions")
    end
  end

  describe "resource references" do
    it "returns a resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_ecs_task_definition(:test, {
          family: "test-task",
          container_definitions: [
            { name: "web", image: "nginx:latest", essential: true }
          ]
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.arn).to eq("${aws_ecs_task_definition.test.arn}")
      expect(ref.family).to eq("${aws_ecs_task_definition.test.family}")
      expect(ref.revision).to eq("${aws_ecs_task_definition.test.revision}")
    end

    it "provides computed properties" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_ecs_task_definition(:test, {
          family: "test-task",
          cpu: "256",
          memory: "512",
          network_mode: "awsvpc",
          requires_compatibilities: ["FARGATE"],
          execution_role_arn: "arn:aws:iam::123456789012:role/ecsTaskExecutionRole",
          volumes: [
            {
              name: "efs-volume",
              efs_volume_configuration: {
                file_system_id: "fs-12345678"
              }
            }
          ],
          container_definitions: [
            {
              name: "web",
              image: "nginx:latest",
              essential: true,
              mount_points: [
                { source_volume: "efs-volume", container_path: "/mnt/efs" }
              ]
            }
          ]
        })
      end

      expect(ref.fargate_compatible?).to eq(true)
      expect(ref.uses_efs?).to eq(true)
      expect(ref.main_container_name).to eq("web")
      expect(ref.container_names).to eq(["web"])
      expect(ref.essential_container_count).to eq(1)
    end
  end
end
