# frozen_string_literal: true
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

# Load aws_ecs_task_definition resource and types for testing
require 'pangea/resources/aws_ecs_task_definition/resource'
require 'pangea/resources/aws_ecs_task_definition/types'

RSpec.describe "aws_ecs_task_definition resource function" do
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
  
  # Test ARN values for various resources
  let(:task_role_arn) { "arn:aws:iam::123456789012:role/task-role" }
  let(:execution_role_arn) { "arn:aws:iam::123456789012:role/execution-role" }
  let(:efs_file_system_id) { "fs-12345678" }
  let(:efs_access_point_id) { "fsap-12345678" }
  
  describe "EcsContainerDefinition validation" do
    it "accepts basic container configuration" do
      container = Pangea::Resources::AWS::Types::EcsContainerDefinition.new({
        name: "web",
        image: "nginx:latest"
      })
      
      expect(container.name).to eq("web")
      expect(container.image).to eq("nginx:latest")
      expect(container.essential).to eq(true)
      expect(container.port_mappings).to eq([])
      expect(container.environment).to eq([])
    end
    
    it "accepts container with resource allocation" do
      container = Pangea::Resources::AWS::Types::EcsContainerDefinition.new({
        name: "app",
        image: "myapp:v1",
        cpu: 512,
        memory: 1024,
        memory_reservation: 512
      })
      
      expect(container.cpu).to eq(512)
      expect(container.memory).to eq(1024)
      expect(container.memory_reservation).to eq(512)
      expect(container.estimated_memory_mb).to eq(1024)
    end
    
    it "accepts container with port mappings" do
      container = Pangea::Resources::AWS::Types::EcsContainerDefinition.new({
        name: "web",
        image: "nginx:latest",
        port_mappings: [
          { container_port: 80, host_port: 8080, protocol: "tcp", name: "web" },
          { container_port: 443, protocol: "tcp", app_protocol: "http2" }
        ]
      })
      
      expect(container.port_mappings.size).to eq(2)
      expect(container.port_mappings.first[:container_port]).to eq(80)
      expect(container.port_mappings.first[:host_port]).to eq(8080)
      expect(container.port_mappings.first[:protocol]).to eq("tcp")
      expect(container.port_mappings.first[:name]).to eq("web")
      expect(container.port_mappings.last[:app_protocol]).to eq("http2")
    end
    
    it "accepts container with environment variables and secrets" do
      container = Pangea::Resources::AWS::Types::EcsContainerDefinition.new({
        name: "app",
        image: "myapp:v1",
        environment: [
          { name: "NODE_ENV", value: "production" },
          { name: "PORT", value: "3000" }
        ],
        secrets: [
          { name: "DB_PASSWORD", value_from: "arn:aws:secretsmanager:us-east-1:123456789012:secret:prod/db" },
          { name: "API_KEY", value_from: "/prod/app/api-key" }
        ]
      })
      
      expect(container.environment.size).to eq(2)
      expect(container.environment.first[:name]).to eq("NODE_ENV")
      expect(container.environment.first[:value]).to eq("production")
      
      expect(container.secrets.size).to eq(2)
      expect(container.secrets.first[:name]).to eq("DB_PASSWORD")
      expect(container.secrets.first[:value_from]).to include("secretsmanager")
    end
    
    it "accepts container with logging configuration" do
      container = Pangea::Resources::AWS::Types::EcsContainerDefinition.new({
        name: "app",
        image: "myapp:v1",
        log_configuration: {
          log_driver: "awslogs",
          options: {
            "awslogs-group" => "/ecs/myapp",
            "awslogs-region" => "us-east-1",
            "awslogs-stream-prefix" => "ecs"
          }
        }
      })
      
      expect(container.log_configuration[:log_driver]).to eq("awslogs")
      expect(container.log_configuration[:options]["awslogs-group"]).to eq("/ecs/myapp")
      expect(container.using_awslogs?).to eq(true)
    end
    
    it "accepts container with health check" do
      container = Pangea::Resources::AWS::Types::EcsContainerDefinition.new({
        name: "app",
        image: "myapp:v1",
        health_check: {
          command: ["CMD-SHELL", "curl -f http://localhost/ || exit 1"],
          interval: 30,
          timeout: 5,
          retries: 3,
          start_period: 60
        }
      })
      
      hc = container.health_check
      expect(hc[:command]).to include("curl")
      expect(hc[:interval]).to eq(30)
      expect(hc[:timeout]).to eq(5)
      expect(hc[:retries]).to eq(3)
      expect(hc[:start_period]).to eq(60)
    end
    
    it "accepts container with mount points and volumes from" do
      container = Pangea::Resources::AWS::Types::EcsContainerDefinition.new({
        name: "app",
        image: "myapp:v1",
        mount_points: [
          { source_volume: "shared-data", container_path: "/data", read_only: false },
          { source_volume: "config", container_path: "/etc/app", read_only: true }
        ],
        volumes_from: [
          { source_container: "data-container", read_only: true }
        ]
      })
      
      expect(container.mount_points.size).to eq(2)
      expect(container.mount_points.first[:source_volume]).to eq("shared-data")
      expect(container.mount_points.first[:container_path]).to eq("/data")
      expect(container.mount_points.first[:read_only]).to eq(false)
      
      expect(container.volumes_from.size).to eq(1)
      expect(container.volumes_from.first[:source_container]).to eq("data-container")
    end
    
    it "accepts container with dependencies" do
      container = Pangea::Resources::AWS::Types::EcsContainerDefinition.new({
        name: "app",
        image: "myapp:v1",
        depends_on: [
          { container_name: "database", condition: "HEALTHY" },
          { container_name: "cache", condition: "START" }
        ]
      })
      
      expect(container.depends_on.size).to eq(2)
      expect(container.depends_on.first[:container_name]).to eq("database")
      expect(container.depends_on.first[:condition]).to eq("HEALTHY")
    end
    
    it "accepts container with Linux parameters" do
      container = Pangea::Resources::AWS::Types::EcsContainerDefinition.new({
        name: "privileged-app",
        image: "myapp:v1",
        privileged: true,
        linux_parameters: {
          capabilities: {
            add: ["SYS_ADMIN", "NET_ADMIN"],
            drop: ["MKNOD"]
          },
          devices: [
            { host_path: "/dev/sda", container_path: "/dev/xvda", permissions: ["read", "write"] }
          ],
          init_process_enabled: true,
          shared_memory_size: 256,
          tmpfs: [
            { container_path: "/tmp", size: 100, mount_options: ["noexec", "nosuid"] }
          ]
        }
      })
      
      expect(container.privileged).to eq(true)
      lp = container.linux_parameters
      expect(lp[:capabilities][:add]).to include("SYS_ADMIN")
      expect(lp[:capabilities][:drop]).to include("MKNOD")
      expect(lp[:init_process_enabled]).to eq(true)
      expect(lp[:shared_memory_size]).to eq(256)
    end
    
    it "accepts container with ulimits" do
      container = Pangea::Resources::AWS::Types::EcsContainerDefinition.new({
        name: "app",
        image: "myapp:v1",
        ulimits: [
          { name: "nofile", soft_limit: 1024, hard_limit: 2048 },
          { name: "nproc", soft_limit: 512, hard_limit: 1024 }
        ]
      })
      
      expect(container.ulimits.size).to eq(2)
      expect(container.ulimits.first[:name]).to eq("nofile")
      expect(container.ulimits.first[:soft_limit]).to eq(1024)
      expect(container.ulimits.first[:hard_limit]).to eq(2048)
    end
    
    it "accepts container with FireLens configuration" do
      container = Pangea::Resources::AWS::Types::EcsContainerDefinition.new({
        name: "log-router",
        image: "fluent/fluent-bit:latest",
        firelens_configuration: {
          type: "fluentbit",
          options: {
            "enable-ecs-log-metadata" => "true",
            "config-file-type" => "file",
            "config-file-value" => "/fluent-bit/configs/parse-json.conf"
          }
        }
      })
      
      fc = container.firelens_configuration
      expect(fc[:type]).to eq("fluentbit")
      expect(fc[:options]["enable-ecs-log-metadata"]).to eq("true")
    end
  end
  
  describe "container validation rules" do
    it "rejects memory reservation > memory" do
      expect {
        Pangea::Resources::AWS::Types::EcsContainerDefinition.new({
          name: "app",
          image: "myapp:v1",
          memory: 512,
          memory_reservation: 1024
        })
      }.to raise_error(Dry::Struct::Error, /memory_reservation cannot be greater than memory/)
    end
    
    it "rejects invalid image URI format" do
      expect {
        Pangea::Resources::AWS::Types::EcsContainerDefinition.new({
          name: "app",
          image: "invalid image name with spaces"
        })
      }.to raise_error(Dry::Struct::Error, /Invalid image URI format/)
    end
    
    it "rejects invalid port range" do
      expect {
        Pangea::Resources::AWS::Types::EcsContainerDefinition.new({
          name: "app",
          image: "myapp:v1",
          port_mappings: [
            { container_port: 70000 }
          ]
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
    
    it "rejects invalid protocol" do
      expect {
        Pangea::Resources::AWS::Types::EcsContainerDefinition.new({
          name: "app",
          image: "myapp:v1",
          port_mappings: [
            { container_port: 80, protocol: "invalid" }
          ]
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
    
    it "rejects invalid health check interval" do
      expect {
        Pangea::Resources::AWS::Types::EcsContainerDefinition.new({
          name: "app",
          image: "myapp:v1",
          health_check: {
            command: ["CMD", "echo", "ok"],
            interval: 400
          }
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
  end
  
  describe "EcsTaskDefinitionAttributes validation" do
    it "accepts basic task definition" do
      task_def = Pangea::Resources::AWS::Types::EcsTaskDefinitionAttributes.new({
        family: "web-app",
        container_definitions: [
          { name: "web", image: "nginx:latest" }
        ]
      })
      
      expect(task_def.family).to eq("web-app")
      expect(task_def.container_definitions.size).to eq(1)
      expect(task_def.network_mode).to eq("bridge")
      expect(task_def.requires_compatibilities).to eq(["EC2"])
    end
    
    it "accepts Fargate task definition" do
      task_def = Pangea::Resources::AWS::Types::EcsTaskDefinitionAttributes.new({
        family: "fargate-app",
        container_definitions: [
          { name: "app", image: "myapp:v1" }
        ],
        requires_compatibilities: ["FARGATE"],
        network_mode: "awsvpc",
        cpu: "256",
        memory: "512",
        execution_role_arn: execution_role_arn,
        task_role_arn: task_role_arn
      })
      
      expect(task_def.requires_compatibilities).to include("FARGATE")
      expect(task_def.network_mode).to eq("awsvpc")
      expect(task_def.cpu).to eq("256")
      expect(task_def.memory).to eq("512")
      expect(task_def.fargate_compatible?).to eq(true)
    end
    
    it "accepts task definition with EFS volumes" do
      task_def = Pangea::Resources::AWS::Types::EcsTaskDefinitionAttributes.new({
        family: "efs-app",
        container_definitions: [
          { 
            name: "app", 
            image: "myapp:v1",
            mount_points: [
              { source_volume: "shared-storage", container_path: "/mnt/efs" }
            ]
          }
        ],
        volumes: [
          {
            name: "shared-storage",
            efs_volume_configuration: {
              file_system_id: efs_file_system_id,
              transit_encryption: "ENABLED",
              authorization_config: {
                access_point_id: efs_access_point_id,
                iam: "ENABLED"
              }
            }
          }
        ]
      })
      
      expect(task_def.uses_efs?).to eq(true)
      efs_vol = task_def.volumes.first[:efs_volume_configuration]
      expect(efs_vol[:file_system_id]).to eq(efs_file_system_id)
      expect(efs_vol[:transit_encryption]).to eq("ENABLED")
    end
    
    it "accepts task definition with placement constraints" do
      task_def = Pangea::Resources::AWS::Types::EcsTaskDefinitionAttributes.new({
        family: "constrained-app",
        container_definitions: [
          { name: "app", image: "myapp:v1" }
        ],
        placement_constraints: [
          { type: "memberOf", expression: "attribute:instance-type =~ t3.*" }
        ]
      })
      
      expect(task_def.placement_constraints.size).to eq(1)
      expect(task_def.placement_constraints.first[:type]).to eq("memberOf")
      expect(task_def.placement_constraints.first[:expression]).to include("t3")
    end
    
    it "accepts task definition with proxy configuration" do
      task_def = Pangea::Resources::AWS::Types::EcsTaskDefinitionAttributes.new({
        family: "mesh-app",
        container_definitions: [
          { name: "app", image: "myapp:v1" },
          { name: "envoy", image: "envoyproxy/envoy:latest", essential: false }
        ],
        proxy_configuration: {
          type: "APPMESH",
          container_name: "envoy",
          properties: [
            { name: "ProxyIngressPort", value: "15000" },
            { name: "ProxyEgressPort", value: "15001" },
            { name: "AppPorts", value: "3000" }
          ]
        }
      })
      
      proxy = task_def.proxy_configuration
      expect(proxy[:type]).to eq("APPMESH")
      expect(proxy[:container_name]).to eq("envoy")
      expect(proxy[:properties].size).to eq(3)
    end
    
    it "accepts task definition with runtime platform" do
      task_def = Pangea::Resources::AWS::Types::EcsTaskDefinitionAttributes.new({
        family: "arm-app",
        container_definitions: [
          { name: "app", image: "myapp:v1" }
        ],
        requires_compatibilities: ["FARGATE"],
        network_mode: "awsvpc",
        cpu: "256",
        memory: "512",
        execution_role_arn: execution_role_arn,
        runtime_platform: {
          operating_system_family: "LINUX",
          cpu_architecture: "ARM64"
        }
      })
      
      runtime = task_def.runtime_platform
      expect(runtime[:operating_system_family]).to eq("LINUX")
      expect(runtime[:cpu_architecture]).to eq("ARM64")
    end
    
    it "accepts task definition with ephemeral storage" do
      task_def = Pangea::Resources::AWS::Types::EcsTaskDefinitionAttributes.new({
        family: "storage-app",
        container_definitions: [
          { name: "app", image: "myapp:v1" }
        ],
        requires_compatibilities: ["FARGATE"],
        network_mode: "awsvpc",
        cpu: "256",
        memory: "512",
        execution_role_arn: execution_role_arn,
        ephemeral_storage: {
          size_in_gib: 30
        }
      })
      
      expect(task_def.ephemeral_storage[:size_in_gib]).to eq(30)
    end
  end
  
  describe "task definition validation rules" do
    it "rejects Fargate without CPU/memory" do
      expect {
        Pangea::Resources::AWS::Types::EcsTaskDefinitionAttributes.new({
          family: "fargate-app",
          container_definitions: [
            { name: "app", image: "myapp:v1" }
          ],
          requires_compatibilities: ["FARGATE"],
          network_mode: "awsvpc",
          execution_role_arn: execution_role_arn
        })
      }.to raise_error(Dry::Struct::Error, /CPU and memory must be specified for Fargate compatibility/)
    end
    
    it "rejects Fargate without awsvpc network mode" do
      expect {
        Pangea::Resources::AWS::Types::EcsTaskDefinitionAttributes.new({
          family: "fargate-app",
          container_definitions: [
            { name: "app", image: "myapp:v1" }
          ],
          requires_compatibilities: ["FARGATE"],
          network_mode: "bridge",
          cpu: "256",
          memory: "512",
          execution_role_arn: execution_role_arn
        })
      }.to raise_error(Dry::Struct::Error, /Network mode must be 'awsvpc' for Fargate compatibility/)
    end
    
    it "rejects Fargate without execution role" do
      expect {
        Pangea::Resources::AWS::Types::EcsTaskDefinitionAttributes.new({
          family: "fargate-app",
          container_definitions: [
            { name: "app", image: "myapp:v1" }
          ],
          requires_compatibilities: ["FARGATE"],
          network_mode: "awsvpc",
          cpu: "256",
          memory: "512"
        })
      }.to raise_error(Dry::Struct::Error, /Execution role ARN is required for Fargate compatibility/)
    end
    
    it "rejects invalid Fargate CPU/memory combinations" do
      expect {
        Pangea::Resources::AWS::Types::EcsTaskDefinitionAttributes.new({
          family: "fargate-app",
          container_definitions: [
            { name: "app", image: "myapp:v1" }
          ],
          requires_compatibilities: ["FARGATE"],
          network_mode: "awsvpc",
          cpu: "256",
          memory: "128",
          execution_role_arn: execution_role_arn
        })
      }.to raise_error(Dry::Struct::Error, /Invalid CPU\/memory combination for Fargate/)
    end
    
    it "rejects awsvpc with mismatched host/container ports" do
      expect {
        Pangea::Resources::AWS::Types::EcsTaskDefinitionAttributes.new({
          family: "awsvpc-app",
          container_definitions: [
            { 
              name: "app", 
              image: "myapp:v1",
              port_mappings: [
                { container_port: 80, host_port: 8080 }
              ]
            }
          ],
          network_mode: "awsvpc"
        })
      }.to raise_error(Dry::Struct::Error, /host_port must equal container_port or be omitted/)
    end
    
    it "rejects task definition without essential containers" do
      expect {
        Pangea::Resources::AWS::Types::EcsTaskDefinitionAttributes.new({
          family: "no-essential",
          container_definitions: [
            { name: "app", image: "myapp:v1", essential: false }
          ]
        })
      }.to raise_error(Dry::Struct::Error, /At least one container must be marked as essential/)
    end
    
    it "rejects undefined volume references" do
      expect {
        Pangea::Resources::AWS::Types::EcsTaskDefinitionAttributes.new({
          family: "undefined-volume",
          container_definitions: [
            { 
              name: "app", 
              image: "myapp:v1",
              mount_points: [
                { source_volume: "nonexistent", container_path: "/data" }
              ]
            }
          ]
        })
      }.to raise_error(Dry::Struct::Error, /references undefined volume/)
    end
    
    it "rejects invalid ephemeral storage size" do
      expect {
        Pangea::Resources::AWS::Types::EcsTaskDefinitionAttributes.new({
          family: "large-storage",
          container_definitions: [
            { name: "app", image: "myapp:v1" }
          ],
          ephemeral_storage: {
            size_in_gib: 300
          }
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
  end
  
  describe "computed properties" do
    let(:fargate_task_attrs) do
      Pangea::Resources::AWS::Types::EcsTaskDefinitionAttributes.new({
        family: "fargate-web",
        container_definitions: [
          { name: "web", image: "nginx:latest", cpu: 128, memory: 256 },
          { name: "app", image: "myapp:v1", cpu: 128, memory: 256, essential: false }
        ],
        requires_compatibilities: ["FARGATE"],
        network_mode: "awsvpc",
        cpu: "256",
        memory: "512",
        execution_role_arn: execution_role_arn,
        volumes: [
          {
            name: "shared-data",
            efs_volume_configuration: {
              file_system_id: efs_file_system_id
            }
          }
        ]
      })
    end
    
    it "detects Fargate compatibility" do
      expect(fargate_task_attrs.fargate_compatible?).to eq(true)
    end
    
    it "detects EFS usage" do
      expect(fargate_task_attrs.uses_efs?).to eq(true)
    end
    
    it "calculates total memory from task level" do
      expect(fargate_task_attrs.total_memory_mb).to eq(512)
    end
    
    it "estimates hourly cost for Fargate" do
      cost = fargate_task_attrs.estimated_hourly_cost
      expect(cost).to be > 0
      expect(cost).to be_a(Float)
    end
    
    it "identifies main container" do
      main = fargate_task_attrs.main_container
      expect(main.name).to eq("web")
      expect(main.is_essential?).to eq(true)
    end
    
    let(:ec2_task_attrs) do
      Pangea::Resources::AWS::Types::EcsTaskDefinitionAttributes.new({
        family: "ec2-web",
        container_definitions: [
          { name: "web", image: "nginx:latest", memory: 512 },
          { name: "sidecar", image: "sidecar:v1", memory_reservation: 128, essential: false }
        ],
        requires_compatibilities: ["EC2"]
      })
    end
    
    it "calculates total memory from containers for EC2" do
      expect(ec2_task_attrs.total_memory_mb).to eq(640) # 512 + 128
    end
    
    it "returns zero cost for EC2 tasks" do
      expect(ec2_task_attrs.estimated_hourly_cost).to eq(0.0)
    end
  end
  
  describe "aws_ecs_task_definition function" do
    it "creates basic task definition" do
      result = test_instance.aws_ecs_task_definition(:basic, {
        family: "basic-app",
        container_definitions: [
          { name: "app", image: "myapp:v1" }
        ]
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.type).to eq('aws_ecs_task_definition')
      expect(result.name).to eq(:basic)
    end
    
    it "creates Fargate task definition" do
      result = test_instance.aws_ecs_task_definition(:fargate, {
        family: "fargate-web",
        container_definitions: [
          { name: "web", image: "nginx:latest" }
        ],
        requires_compatibilities: ["FARGATE"],
        network_mode: "awsvpc",
        cpu: "256",
        memory: "512",
        execution_role_arn: execution_role_arn,
        task_role_arn: task_role_arn
      })
      
      expect(result.fargate_compatible?).to eq(true)
    end
    
    it "creates task definition with EFS volumes" do
      result = test_instance.aws_ecs_task_definition(:efs, {
        family: "efs-app",
        container_definitions: [
          { 
            name: "app", 
            image: "myapp:v1",
            mount_points: [
              { source_volume: "shared-data", container_path: "/data" }
            ]
          }
        ],
        volumes: [
          {
            name: "shared-data",
            efs_volume_configuration: {
              file_system_id: efs_file_system_id,
              transit_encryption: "ENABLED"
            }
          }
        ]
      })
      
      expect(result.uses_efs?).to eq(true)
    end
    
    it "provides correct outputs" do
      result = test_instance.aws_ecs_task_definition(:test, {
        family: "test-app",
        container_definitions: [
          { name: "app", image: "myapp:v1" }
        ]
      })
      
      expect(result.arn).to eq("${aws_ecs_task_definition.test.arn}")
      expect(result.arn_without_revision).to eq("${aws_ecs_task_definition.test.arn_without_revision}")
      expect(result.family).to eq("${aws_ecs_task_definition.test.family}")
      expect(result.revision).to eq("${aws_ecs_task_definition.test.revision}")
      expect(result.tags_all).to eq("${aws_ecs_task_definition.test.tags_all}")
      expect(result.id).to eq("${aws_ecs_task_definition.test.id}")
    end
    
    it "provides computed properties" do
      result = test_instance.aws_ecs_task_definition(:computed, {
        family: "computed-app",
        container_definitions: [
          { name: "web", image: "nginx:latest", memory: 256 },
          { name: "app", image: "myapp:v1", memory: 512, essential: false }
        ],
        requires_compatibilities: ["FARGATE"],
        network_mode: "awsvpc",
        cpu: "512",
        memory: "1024",
        execution_role_arn: execution_role_arn
      })
      
      expect(result.fargate_compatible?).to eq(true)
      expect(result.uses_efs?).to eq(false)
      expect(result.total_memory_mb).to eq(1024)
      expect(result.estimated_hourly_cost).to be > 0
      expect(result.main_container_name).to eq("web")
      expect(result.container_names).to eq(["web", "app"])
      expect(result.essential_container_count).to eq(1)
    end
  end
  
  describe "task definition deployment patterns" do
    it "creates web application task definition" do
      result = test_instance.aws_ecs_task_definition(:web_app, {
        family: "web-application",
        container_definitions: [
          {
            name: "web",
            image: "nginx:latest",
            memory: 256,
            port_mappings: [
              { container_port: 80, name: "web" }
            ],
            log_configuration: {
              log_driver: "awslogs",
              options: {
                "awslogs-group" => "/ecs/web-app",
                "awslogs-region" => "us-east-1",
                "awslogs-stream-prefix" => "web"
              }
            }
          },
          {
            name: "app",
            image: "myapp:v1",
            memory: 512,
            port_mappings: [
              { container_port: 3000, name: "app" }
            ],
            environment: [
              { name: "NODE_ENV", value: "production" },
              { name: "PORT", value: "3000" }
            ],
            secrets: [
              { name: "DB_PASSWORD", value_from: "arn:aws:secretsmanager:us-east-1:123456789012:secret:prod/db" }
            ],
            depends_on: [
              { container_name: "web", condition: "START" }
            ]
          }
        ],
        requires_compatibilities: ["FARGATE"],
        network_mode: "awsvpc",
        cpu: "512",
        memory: "1024",
        execution_role_arn: execution_role_arn,
        task_role_arn: task_role_arn,
        tags: {
          Application: "web-app",
          Environment: "production",
          Tier: "web"
        }
      })
      
      expect(result.fargate_compatible?).to eq(true)
      expect(result.container_names).to include("web", "app")
      expect(result.essential_container_count).to eq(2)
    end
    
    it "creates microservice task definition with sidecar" do
      result = test_instance.aws_ecs_task_definition(:microservice, {
        family: "user-service",
        container_definitions: [
          {
            name: "app",
            image: "user-service:v2",
            memory: 512,
            port_mappings: [
              { container_port: 8080, name: "api" }
            ],
            health_check: {
              command: ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"],
              interval: 30,
              timeout: 5,
              retries: 3,
              start_period: 60
            }
          },
          {
            name: "envoy",
            image: "envoyproxy/envoy:latest",
            memory: 128,
            essential: false,
            port_mappings: [
              { container_port: 9901, name: "envoy-admin" }
            ]
          }
        ],
        requires_compatibilities: ["FARGATE"],
        network_mode: "awsvpc",
        cpu: "512",
        memory: "1024",
        execution_role_arn: execution_role_arn,
        task_role_arn: task_role_arn,
        proxy_configuration: {
          type: "APPMESH",
          container_name: "envoy",
          properties: [
            { name: "ProxyIngressPort", value: "15000" },
            { name: "ProxyEgressPort", value: "15001" },
            { name: "AppPorts", value: "8080" }
          ]
        }
      })
      
      expect(result.container_names).to include("app", "envoy")
      expect(result.essential_container_count).to eq(1)
    end
    
    it "creates data processing task definition" do
      result = test_instance.aws_ecs_task_definition(:data_processor, {
        family: "batch-processor",
        container_definitions: [
          {
            name: "processor",
            image: "batch-processor:v1",
            memory: 2048,
            environment: [
              { name: "BATCH_SIZE", value: "1000" },
              { name: "PARALLEL_WORKERS", value: "4" }
            ],
            mount_points: [
              { source_volume: "scratch", container_path: "/tmp/scratch" }
            ],
            ulimits: [
              { name: "nofile", soft_limit: 4096, hard_limit: 8192 }
            ]
          }
        ],
        requires_compatibilities: ["EC2"],
        volumes: [
          {
            name: "scratch",
            host: {
              source_path: "/tmp/batch-scratch"
            }
          }
        ],
        placement_constraints: [
          { type: "memberOf", expression: "attribute:instance-type =~ c5.*" }
        ],
        tags: {
          WorkloadType: "batch",
          CostOptimized: "true"
        }
      })
      
      expect(result.fargate_compatible?).to eq(false)
      expect(result.container_names).to eq(["processor"])
    end
    
    it "creates logging sidecar task definition" do
      result = test_instance.aws_ecs_task_definition(:with_logging, {
        family: "app-with-logging",
        container_definitions: [
          {
            name: "app",
            image: "myapp:v1",
            memory: 512,
            log_configuration: {
              log_driver: "awsfirelens",
              options: {
                "Name" => "cloudwatch",
                "region" => "us-east-1",
                "log_group_name" => "/aws/ecs/app"
              }
            }
          },
          {
            name: "log-router",
            image: "fluent/fluent-bit:latest",
            memory: 128,
            essential: false,
            firelens_configuration: {
              type: "fluentbit",
              options: {
                "enable-ecs-log-metadata" => "true"
              }
            }
          }
        ],
        requires_compatibilities: ["FARGATE"],
        network_mode: "awsvpc",
        cpu: "512",
        memory: "1024",
        execution_role_arn: execution_role_arn
      })
      
      expect(result.container_names).to include("app", "log-router")
      expect(result.essential_container_count).to eq(1)
    end
  end
  
  describe "complex container configurations" do
    it "creates container with comprehensive Linux parameters" do
      container = Pangea::Resources::AWS::Types::EcsContainerDefinition.new({
        name: "secure-app",
        image: "secure-app:v1",
        user: "1000:1000",
        readonly_root_filesystem: true,
        linux_parameters: {
          capabilities: {
            drop: ["ALL"],
            add: ["CHOWN", "SETUID", "SETGID"]
          },
          init_process_enabled: true,
          max_swap: 0,
          shared_memory_size: 64
        },
        ulimits: [
          { name: "memlock", soft_limit: 67108864, hard_limit: 67108864 },
          { name: "nofile", soft_limit: 1024, hard_limit: 4096 }
        ]
      })
      
      expect(container.user).to eq("1000:1000")
      expect(container.readonly_root_filesystem).to eq(true)
      lp = container.linux_parameters
      expect(lp[:capabilities][:drop]).to include("ALL")
      expect(lp[:capabilities][:add]).to include("CHOWN")
      expect(lp[:init_process_enabled]).to eq(true)
      expect(lp[:max_swap]).to eq(0)
    end
  end
end