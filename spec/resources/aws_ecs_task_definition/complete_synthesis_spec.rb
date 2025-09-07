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
require 'json'

# Load aws_ecs_task_definition resource and terraform-synthesizer for testing
require 'pangea/resources/aws_ecs_task_definition/resource'
require 'terraform-synthesizer'

RSpec.describe "aws_ecs_task_definition terraform synthesis" do
  let(:synthesizer) { TerraformSynthesizer.new }
  
  # Test ARN values for various resources
  let(:task_role_arn) { "arn:aws:iam::123456789012:role/task-role" }
  let(:execution_role_arn) { "arn:aws:iam::123456789012:role/execution-role" }
  let(:efs_file_system_id) { "fs-12345678" }
  let(:efs_access_point_id) { "fsap-12345678" }
  let(:kms_key_arn) { "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012" }
  
  # Test basic task definition synthesis
  it "synthesizes basic task definition correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_task_definition(:basic, {
        family: "basic-app",
        container_definitions: [
          {
            name: "app",
            image: "nginx:latest"
          }
        ]
      })
    end
    
    json_output = synthesizer.synthesis
    task_def_config = json_output.dig(:resource, :aws_ecs_task_definition, :basic)
    
    expect(task_def_config[:family]).to eq("basic-app")
    expect(task_def_config[:network_mode]).to eq("bridge")
    expect(task_def_config[:requires_compatibilities]).to eq(["EC2"])
    
    # Verify container definitions JSON
    container_defs = JSON.parse(task_def_config[:container_definitions])
    expect(container_defs).to be_an(Array)
    expect(container_defs.size).to eq(1)
    
    container = container_defs.first
    expect(container["name"]).to eq("app")
    expect(container["image"]).to eq("nginx:latest")
    expect(container["essential"]).to eq(true)
  end
  
  # Test Fargate task definition synthesis
  it "synthesizes Fargate task definition correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_task_definition(:fargate, {
        family: "fargate-web",
        container_definitions: [
          {
            name: "web",
            image: "nginx:latest",
            cpu: 128,
            memory: 256,
            port_mappings: [
              { container_port: 80, name: "web" }
            ]
          },
          {
            name: "app",
            image: "myapp:v1",
            cpu: 128,
            memory: 256,
            essential: false,
            port_mappings: [
              { container_port: 3000, name: "app" }
            ]
          }
        ],
        requires_compatibilities: ["FARGATE"],
        network_mode: "awsvpc",
        cpu: "256",
        memory: "512",
        execution_role_arn: execution_role_arn,
        task_role_arn: task_role_arn
      })
    end
    
    json_output = synthesizer.synthesis
    task_def_config = json_output.dig(:resource, :aws_ecs_task_definition, :fargate)
    
    expect(task_def_config[:family]).to eq("fargate-web")
    expect(task_def_config[:requires_compatibilities]).to eq(["FARGATE"])
    expect(task_def_config[:network_mode]).to eq("awsvpc")
    expect(task_def_config[:cpu]).to eq("256")
    expect(task_def_config[:memory]).to eq("512")
    expect(task_def_config[:execution_role_arn]).to eq(execution_role_arn)
    expect(task_def_config[:task_role_arn]).to eq(task_role_arn)
    
    # Verify container definitions
    container_defs = JSON.parse(task_def_config[:container_definitions])
    expect(container_defs.size).to eq(2)
    
    web_container = container_defs.find { |c| c["name"] == "web" }
    expect(web_container["cpu"]).to eq(128)
    expect(web_container["memory"]).to eq(256)
    expect(web_container["essential"]).to eq(true)
    expect(web_container["portMappings"]).to be_an(Array)
    expect(web_container["portMappings"].first["containerPort"]).to eq(80)
    expect(web_container["portMappings"].first["name"]).to eq("web")
    
    app_container = container_defs.find { |c| c["name"] == "app" }
    expect(app_container["essential"]).to eq(false)
    expect(app_container["portMappings"].first["containerPort"]).to eq(3000)
  end
  
  # Test task definition with environment variables and secrets
  it "synthesizes task definition with environment and secrets correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_task_definition(:with_env, {
        family: "app-with-secrets",
        container_definitions: [
          {
            name: "app",
            image: "myapp:v1",
            memory: 512,
            environment: [
              { name: "NODE_ENV", value: "production" },
              { name: "PORT", value: "3000" },
              { name: "LOG_LEVEL", value: "info" }
            ],
            secrets: [
              { name: "DB_PASSWORD", value_from: "arn:aws:secretsmanager:us-east-1:123456789012:secret:prod/db-abcdef" },
              { name: "API_KEY", value_from: "/prod/app/api-key" }
            ]
          }
        ],
        execution_role_arn: execution_role_arn
      })
    end
    
    json_output = synthesizer.synthesis
    task_def_config = json_output.dig(:resource, :aws_ecs_task_definition, :with_env)
    
    container_defs = JSON.parse(task_def_config[:container_definitions])
    container = container_defs.first
    
    # Verify environment variables
    expect(container["environment"]).to be_an(Array)
    expect(container["environment"].size).to eq(3)
    env_node_env = container["environment"].find { |e| e["name"] == "NODE_ENV" }
    expect(env_node_env["value"]).to eq("production")
    
    # Verify secrets
    expect(container["secrets"]).to be_an(Array)
    expect(container["secrets"].size).to eq(2)
    secret_db = container["secrets"].find { |s| s["name"] == "DB_PASSWORD" }
    expect(secret_db["valueFrom"]).to include("secretsmanager")
    secret_api = container["secrets"].find { |s| s["name"] == "API_KEY" }
    expect(secret_api["valueFrom"]).to eq("/prod/app/api-key")
  end
  
  # Test task definition with logging configuration
  it "synthesizes task definition with logging correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_task_definition(:with_logging, {
        family: "app-with-logs",
        container_definitions: [
          {
            name: "app",
            image: "myapp:v1",
            memory: 512,
            log_configuration: {
              log_driver: "awslogs",
              options: {
                "awslogs-group" => "/ecs/app",
                "awslogs-region" => "us-east-1",
                "awslogs-stream-prefix" => "app"
              },
              secret_options: [
                { name: "awslogs-endpoint", value_from: "/ecs/logging/endpoint" }
              ]
            }
          }
        ],
        execution_role_arn: execution_role_arn
      })
    end
    
    json_output = synthesizer.synthesis
    task_def_config = json_output.dig(:resource, :aws_ecs_task_definition, :with_logging)
    
    container_defs = JSON.parse(task_def_config[:container_definitions])
    container = container_defs.first
    
    expect(container["logConfiguration"]).to be_a(Hash)
    expect(container["logConfiguration"]["logDriver"]).to eq("awslogs")
    expect(container["logConfiguration"]["options"]).to be_a(Hash)
    expect(container["logConfiguration"]["options"]["awslogs-group"]).to eq("/ecs/app")
    expect(container["logConfiguration"]["options"]["awslogs-region"]).to eq("us-east-1")
    expect(container["logConfiguration"]["options"]["awslogs-stream-prefix"]).to eq("app")
    expect(container["logConfiguration"]["secretOptions"]).to be_an(Array)
    expect(container["logConfiguration"]["secretOptions"].first["name"]).to eq("awslogs-endpoint")
  end
  
  # Test task definition with health check
  it "synthesizes task definition with health check correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_task_definition(:with_health, {
        family: "app-with-health",
        container_definitions: [
          {
            name: "web",
            image: "nginx:latest",
            memory: 256,
            port_mappings: [
              { container_port: 80 }
            ],
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
    
    json_output = synthesizer.synthesis
    task_def_config = json_output.dig(:resource, :aws_ecs_task_definition, :with_health)
    
    container_defs = JSON.parse(task_def_config[:container_definitions])
    container = container_defs.first
    
    expect(container["healthCheck"]).to be_a(Hash)
    expect(container["healthCheck"]["command"]).to be_an(Array)
    expect(container["healthCheck"]["command"]).to include("CMD-SHELL")
    expect(container["healthCheck"]["interval"]).to eq(30)
    expect(container["healthCheck"]["timeout"]).to eq(5)
    expect(container["healthCheck"]["retries"]).to eq(3)
    expect(container["healthCheck"]["startPeriod"]).to eq(60)
  end
  
  # Test task definition with EFS volumes
  it "synthesizes task definition with EFS volumes correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_task_definition(:with_efs, {
        family: "app-with-efs",
        container_definitions: [
          {
            name: "app",
            image: "myapp:v1",
            memory: 512,
            mount_points: [
              { source_volume: "shared-storage", container_path: "/mnt/efs", read_only: false }
            ]
          }
        ],
        volumes: [
          {
            name: "shared-storage",
            efs_volume_configuration: {
              file_system_id: efs_file_system_id,
              root_directory: "/data",
              transit_encryption: "ENABLED",
              transit_encryption_port: 2999,
              authorization_config: {
                access_point_id: efs_access_point_id,
                iam: "ENABLED"
              }
            }
          }
        ]
      })
    end
    
    json_output = synthesizer.synthesis
    task_def_config = json_output.dig(:resource, :aws_ecs_task_definition, :with_efs)
    
    # Verify volume configuration
    expect(task_def_config[:volume]).to be_an(Array)
    expect(task_def_config[:volume].size).to eq(1)
    
    volume = task_def_config[:volume].first
    expect(volume[:name]).to eq("shared-storage")
    expect(volume[:efs_volume_configuration]).to be_a(Hash)
    
    efs_config = volume[:efs_volume_configuration]
    expect(efs_config[:file_system_id]).to eq(efs_file_system_id)
    expect(efs_config[:root_directory]).to eq("/data")
    expect(efs_config[:transit_encryption]).to eq("ENABLED")
    expect(efs_config[:transit_encryption_port]).to eq(2999)
    expect(efs_config[:authorization_config][:access_point_id]).to eq(efs_access_point_id)
    expect(efs_config[:authorization_config][:iam]).to eq("ENABLED")
    
    # Verify mount points in container
    container_defs = JSON.parse(task_def_config[:container_definitions])
    container = container_defs.first
    expect(container["mountPoints"]).to be_an(Array)
    expect(container["mountPoints"].first["sourceVolume"]).to eq("shared-storage")
    expect(container["mountPoints"].first["containerPath"]).to eq("/mnt/efs")
    expect(container["mountPoints"].first["readOnly"]).to eq(false)
  end
  
  # Test task definition with placement constraints
  it "synthesizes task definition with placement constraints correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_task_definition(:with_constraints, {
        family: "constrained-app",
        container_definitions: [
          {
            name: "app",
            image: "myapp:v1",
            memory: 1024
          }
        ],
        placement_constraints: [
          { type: "memberOf", expression: "attribute:instance-type =~ c5.*" },
          { type: "memberOf", expression: "attribute:ecs.availability-zone in [us-east-1a, us-east-1b]" }
        ]
      })
    end
    
    json_output = synthesizer.synthesis
    task_def_config = json_output.dig(:resource, :aws_ecs_task_definition, :with_constraints)
    
    expect(task_def_config[:placement_constraints]).to be_an(Array)
    expect(task_def_config[:placement_constraints].size).to eq(2)
    
    c5_constraint = task_def_config[:placement_constraints].find { |pc| pc[:expression].include?("c5") }
    expect(c5_constraint[:type]).to eq("memberOf")
    expect(c5_constraint[:expression]).to include("instance-type")
    
    az_constraint = task_def_config[:placement_constraints].find { |pc| pc[:expression].include?("availability-zone") }
    expect(az_constraint[:type]).to eq("memberOf")
    expect(az_constraint[:expression]).to include("us-east-1a")
  end
  
  # Test task definition with proxy configuration (App Mesh)
  it "synthesizes task definition with proxy configuration correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_task_definition(:with_proxy, {
        family: "mesh-app",
        container_definitions: [
          {
            name: "app",
            image: "myapp:v1",
            memory: 512,
            port_mappings: [
              { container_port: 3000 }
            ]
          },
          {
            name: "envoy",
            image: "public.ecr.aws/appmesh/aws-appmesh-envoy:v1.23.1.0-prod",
            memory: 256,
            essential: false,
            user: "1337"
          }
        ],
        proxy_configuration: {
          type: "APPMESH",
          container_name: "envoy",
          properties: [
            { name: "ProxyIngressPort", value: "15000" },
            { name: "ProxyEgressPort", value: "15001" },
            { name: "AppPorts", value: "3000" },
            { name: "EgressIgnoredIPs", value: "169.254.170.2,169.254.169.254" },
            { name: "IgnoredUID", value: "1337" },
            { name: "EgressIgnoredPorts", value: "22" }
          ]
        },
        requires_compatibilities: ["FARGATE"],
        network_mode: "awsvpc",
        cpu: "512",
        memory: "1024",
        execution_role_arn: execution_role_arn,
        task_role_arn: task_role_arn
      })
    end
    
    json_output = synthesizer.synthesis
    task_def_config = json_output.dig(:resource, :aws_ecs_task_definition, :with_proxy)
    
    expect(task_def_config[:proxy_configuration]).to be_a(Hash)
    expect(task_def_config[:proxy_configuration][:type]).to eq("APPMESH")
    expect(task_def_config[:proxy_configuration][:container_name]).to eq("envoy")
    expect(task_def_config[:proxy_configuration][:properties]).to be_a(Hash)
    
    # Properties should be a hash, not an array
    properties = task_def_config[:proxy_configuration][:properties]
    expect(properties["ProxyIngressPort"]).to eq("15000")
    expect(properties["ProxyEgressPort"]).to eq("15001")
    expect(properties["AppPorts"]).to eq("3000")
    expect(properties["IgnoredUID"]).to eq("1337")
  end
  
  # Test task definition with Linux parameters
  it "synthesizes task definition with Linux parameters correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_task_definition(:with_linux, {
        family: "secure-app",
        container_definitions: [
          {
            name: "app",
            image: "secure-app:v1",
            memory: 512,
            user: "1000:1000",
            privileged: false,
            readonly_root_filesystem: true,
            linux_parameters: {
              capabilities: {
                add: ["CHOWN", "SETUID", "SETGID"],
                drop: ["NET_ADMIN", "SYS_ADMIN"]
              },
              devices: [
                { host_path: "/dev/sda", container_path: "/dev/xvda", permissions: ["read", "write"] }
              ],
              init_process_enabled: true,
              shared_memory_size: 64,
              tmpfs: [
                { container_path: "/tmp", size: 100, mount_options: ["noexec", "nosuid", "nodev"] }
              ]
            },
            ulimits: [
              { name: "nofile", soft_limit: 1024, hard_limit: 4096 },
              { name: "memlock", soft_limit: 67108864, hard_limit: 67108864 }
            ]
          }
        ]
      })
    end
    
    json_output = synthesizer.synthesis
    task_def_config = json_output.dig(:resource, :aws_ecs_task_definition, :with_linux)
    
    container_defs = JSON.parse(task_def_config[:container_definitions])
    container = container_defs.first
    
    expect(container["user"]).to eq("1000:1000")
    expect(container["privileged"]).to eq(false)
    expect(container["readonlyRootFilesystem"]).to eq(true)
    
    # Linux parameters
    expect(container["linuxParameters"]).to be_a(Hash)
    expect(container["linuxParameters"]["capabilities"]["add"]).to include("CHOWN", "SETUID")
    expect(container["linuxParameters"]["capabilities"]["drop"]).to include("NET_ADMIN")
    expect(container["linuxParameters"]["initProcessEnabled"]).to eq(true)
    expect(container["linuxParameters"]["sharedMemorySize"]).to eq(64)
    
    # Ulimits
    expect(container["ulimits"]).to be_an(Array)
    nofile_ulimit = container["ulimits"].find { |u| u["name"] == "nofile" }
    expect(nofile_ulimit["softLimit"]).to eq(1024)
    expect(nofile_ulimit["hardLimit"]).to eq(4096)
  end
  
  # Test task definition with dependencies
  it "synthesizes task definition with container dependencies correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_task_definition(:with_deps, {
        family: "dependent-app",
        container_definitions: [
          {
            name: "database",
            image: "postgres:13",
            memory: 512,
            health_check: {
              command: ["CMD-SHELL", "pg_isready -U postgres"],
              interval: 30,
              timeout: 5,
              retries: 3
            }
          },
          {
            name: "app",
            image: "myapp:v1",
            memory: 512,
            depends_on: [
              { container_name: "database", condition: "HEALTHY" }
            ]
          },
          {
            name: "cache",
            image: "redis:6",
            memory: 256,
            essential: false
          },
          {
            name: "worker",
            image: "myapp:v1",
            memory: 512,
            command: ["worker"],
            depends_on: [
              { container_name: "database", condition: "HEALTHY" },
              { container_name: "cache", condition: "START" }
            ]
          }
        ]
      })
    end
    
    json_output = synthesizer.synthesis
    task_def_config = json_output.dig(:resource, :aws_ecs_task_definition, :with_deps)
    
    container_defs = JSON.parse(task_def_config[:container_definitions])
    
    app_container = container_defs.find { |c| c["name"] == "app" }
    expect(app_container["dependsOn"]).to be_an(Array)
    expect(app_container["dependsOn"].first["containerName"]).to eq("database")
    expect(app_container["dependsOn"].first["condition"]).to eq("HEALTHY")
    
    worker_container = container_defs.find { |c| c["name"] == "worker" }
    expect(worker_container["dependsOn"].size).to eq(2)
    expect(worker_container["command"]).to eq(["worker"])
  end
  
  # Test task definition with FireLens logging
  it "synthesizes task definition with FireLens correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_task_definition(:with_firelens, {
        family: "firelens-app",
        container_definitions: [
          {
            name: "log-router",
            image: "amazon/aws-for-fluent-bit:latest",
            memory: 128,
            essential: false,
            firelens_configuration: {
              type: "fluentbit",
              options: {
                "enable-ecs-log-metadata" => "true",
                "config-file-type" => "file",
                "config-file-value" => "/fluent-bit/configs/parse-json.conf"
              }
            }
          },
          {
            name: "app",
            image: "myapp:v1",
            memory: 512,
            log_configuration: {
              log_driver: "awsfirelens",
              options: {
                "Name" => "cloudwatch",
                "region" => "us-east-1",
                "log_group_name" => "/aws/ecs/app",
                "log_stream_prefix" => "firelens/"
              }
            }
          }
        ],
        execution_role_arn: execution_role_arn
      })
    end
    
    json_output = synthesizer.synthesis
    task_def_config = json_output.dig(:resource, :aws_ecs_task_definition, :with_firelens)
    
    container_defs = JSON.parse(task_def_config[:container_definitions])
    
    log_router = container_defs.find { |c| c["name"] == "log-router" }
    expect(log_router["firelensConfiguration"]).to be_a(Hash)
    expect(log_router["firelensConfiguration"]["type"]).to eq("fluentbit")
    expect(log_router["firelensConfiguration"]["options"]["enable-ecs-log-metadata"]).to eq("true")
    
    app_container = container_defs.find { |c| c["name"] == "app" }
    expect(app_container["logConfiguration"]["logDriver"]).to eq("awsfirelens")
    expect(app_container["logConfiguration"]["options"]["Name"]).to eq("cloudwatch")
  end
  
  # Test task definition with runtime platform
  it "synthesizes task definition with runtime platform correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_task_definition(:arm_task, {
        family: "arm-app",
        container_definitions: [
          {
            name: "app",
            image: "arm64v8/nginx:latest",
            memory: 512
          }
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
    end
    
    json_output = synthesizer.synthesis
    task_def_config = json_output.dig(:resource, :aws_ecs_task_definition, :arm_task)
    
    expect(task_def_config[:runtime_platform]).to be_a(Hash)
    expect(task_def_config[:runtime_platform][:operating_system_family]).to eq("LINUX")
    expect(task_def_config[:runtime_platform][:cpu_architecture]).to eq("ARM64")
  end
  
  # Test task definition with ephemeral storage
  it "synthesizes task definition with ephemeral storage correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_task_definition(:storage_task, {
        family: "storage-intensive",
        container_definitions: [
          {
            name: "processor",
            image: "data-processor:v1",
            memory: 1024
          }
        ],
        requires_compatibilities: ["FARGATE"],
        network_mode: "awsvpc",
        cpu: "512",
        memory: "1024",
        execution_role_arn: execution_role_arn,
        ephemeral_storage: {
          size_in_gib: 50
        }
      })
    end
    
    json_output = synthesizer.synthesis
    task_def_config = json_output.dig(:resource, :aws_ecs_task_definition, :storage_task)
    
    expect(task_def_config[:ephemeral_storage]).to be_a(Hash)
    expect(task_def_config[:ephemeral_storage][:size_in_gib]).to eq(50)
  end
  
  # Test comprehensive web application task definition
  it "synthesizes comprehensive web application task definition correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_task_definition(:web_app, {
        family: "production-web-app",
        container_definitions: [
          {
            name: "nginx",
            image: "nginx:alpine",
            memory: 128,
            port_mappings: [
              { container_port: 80, name: "web" }
            ],
            depends_on: [
              { container_name: "app", condition: "START" }
            ],
            log_configuration: {
              log_driver: "awslogs",
              options: {
                "awslogs-group" => "/ecs/production-web-app",
                "awslogs-region" => "us-east-1",
                "awslogs-stream-prefix" => "nginx"
              }
            }
          },
          {
            name: "app",
            image: "myapp:v2.3.1",
            memory: 512,
            port_mappings: [
              { container_port: 3000, name: "app" }
            ],
            environment: [
              { name: "NODE_ENV", value: "production" },
              { name: "PORT", value: "3000" },
              { name: "LOG_LEVEL", value: "info" }
            ],
            secrets: [
              { name: "DB_HOST", value_from: "/prod/db/host" },
              { name: "DB_PASSWORD", value_from: "arn:aws:secretsmanager:us-east-1:123456789012:secret:prod/db-password" }
            ],
            health_check: {
              command: ["CMD-SHELL", "curl -f http://localhost:3000/health || exit 1"],
              interval: 30,
              timeout: 5,
              retries: 3,
              start_period: 60
            },
            depends_on: [
              { container_name: "log-router", condition: "START" }
            ]
          },
          {
            name: "log-router",
            image: "amazon/aws-for-fluent-bit:latest",
            memory: 64,
            essential: false,
            firelens_configuration: {
              type: "fluentbit"
            }
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
          Version: "2.3.1"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    task_def_config = json_output.dig(:resource, :aws_ecs_task_definition, :web_app)
    
    expect(task_def_config[:family]).to eq("production-web-app")
    expect(task_def_config[:tags][:Application]).to eq("web-app")
    expect(task_def_config[:tags][:Environment]).to eq("production")
    
    container_defs = JSON.parse(task_def_config[:container_definitions])
    expect(container_defs.size).to eq(3)
    
    # Verify all containers are properly configured
    nginx = container_defs.find { |c| c["name"] == "nginx" }
    expect(nginx["memory"]).to eq(128)
    expect(nginx["dependsOn"]).to be_an(Array)
    
    app = container_defs.find { |c| c["name"] == "app" }
    expect(app["memory"]).to eq(512)
    expect(app["environment"]).to be_an(Array)
    expect(app["secrets"]).to be_an(Array)
    expect(app["healthCheck"]).to be_a(Hash)
    
    log_router = container_defs.find { |c| c["name"] == "log-router" }
    expect(log_router["essential"]).to eq(false)
    expect(log_router["firelensConfiguration"]).to be_a(Hash)
  end
  
  # Test task definition with tags
  it "synthesizes task definition with tags correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_task_definition(:tagged, {
        family: "tagged-app",
        container_definitions: [
          {
            name: "app",
            image: "myapp:v1",
            memory: 512
          }
        ],
        tags: {
          Application: "my-app",
          Environment: "production",
          Team: "backend",
          CostCenter: "engineering",
          ManagedBy: "terraform"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    task_def_config = json_output.dig(:resource, :aws_ecs_task_definition, :tagged)
    
    expect(task_def_config[:tags]).to be_a(Hash)
    expect(task_def_config[:tags][:Application]).to eq("my-app")
    expect(task_def_config[:tags][:Environment]).to eq("production")
    expect(task_def_config[:tags][:Team]).to eq("backend")
    expect(task_def_config[:tags][:CostCenter]).to eq("engineering")
    expect(task_def_config[:tags][:ManagedBy]).to eq("terraform")
  end
  
  # Test minimal task definition
  it "synthesizes minimal task definition correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_task_definition(:minimal, {
        family: "minimal-app",
        container_definitions: [
          {
            name: "app",
            image: "nginx:latest"
          }
        ]
      })
    end
    
    json_output = synthesizer.synthesis
    task_def_config = json_output.dig(:resource, :aws_ecs_task_definition, :minimal)
    
    expect(task_def_config[:family]).to eq("minimal-app")
    expect(task_def_config[:container_definitions]).to be_a(String) # JSON string
    expect(task_def_config[:network_mode]).to eq("bridge")
    expect(task_def_config[:requires_compatibilities]).to eq(["EC2"])
    
    # Optional fields should not be present
    expect(task_def_config).not_to have_key(:cpu)
    expect(task_def_config).not_to have_key(:memory)
    expect(task_def_config).not_to have_key(:task_role_arn)
    expect(task_def_config).not_to have_key(:execution_role_arn)
    expect(task_def_config).not_to have_key(:volume)
    expect(task_def_config).not_to have_key(:placement_constraints)
    expect(task_def_config).not_to have_key(:proxy_configuration)
    expect(task_def_config).not_to have_key(:runtime_platform)
    expect(task_def_config).not_to have_key(:ephemeral_storage)
  end
end