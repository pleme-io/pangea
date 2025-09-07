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

# Load aws_ecs_service resource and terraform-synthesizer for testing
require 'pangea/resources/aws_ecs_service/resource'
require 'terraform-synthesizer'

RSpec.describe "aws_ecs_service terraform synthesis" do
  let(:synthesizer) { TerraformSynthesizer.new }
  
  # Test ARN values for various resources
  let(:cluster_arn) { "arn:aws:ecs:us-east-1:123456789012:cluster/test-cluster" }
  let(:task_definition_arn) { "arn:aws:ecs:us-east-1:123456789012:task-definition/web:1" }
  let(:target_group_arn) { "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/web-tg/50dc6c495c0c9188" }
  let(:registry_arn) { "arn:aws:servicediscovery:us-east-1:123456789012:service/srv-utcrh6wavdkggqtk" }
  let(:service_connect_namespace) { "arn:aws:servicediscovery:us-east-1:123456789012:namespace/ns-12345" }
  
  # Test basic service synthesis
  it "synthesizes basic ECS service correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_service(:basic, {
        name: "basic-service",
        cluster: "test-cluster",
        task_definition: "web:1"
      })
    end
    
    json_output = synthesizer.synthesis
    service_config = json_output.dig(:resource, :aws_ecs_service, :basic)
    
    expect(service_config[:name]).to eq("basic-service")
    expect(service_config[:cluster]).to eq("test-cluster")
    expect(service_config[:task_definition]).to eq("web:1")
    expect(service_config[:desired_count]).to eq(1)
    expect(service_config[:enable_ecs_managed_tags]).to eq(true)
    expect(service_config[:enable_execute_command]).to eq(false)
  end
  
  # Test Fargate service synthesis
  it "synthesizes Fargate service correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_service(:fargate, {
        name: "fargate-service",
        cluster: cluster_arn,
        task_definition: task_definition_arn,
        launch_type: "FARGATE",
        platform_version: "1.4.0",
        desired_count: 3
      })
    end
    
    json_output = synthesizer.synthesis
    service_config = json_output.dig(:resource, :aws_ecs_service, :fargate)
    
    expect(service_config[:name]).to eq("fargate-service")
    expect(service_config[:cluster]).to eq(cluster_arn)
    expect(service_config[:task_definition]).to eq(task_definition_arn)
    expect(service_config[:launch_type]).to eq("FARGATE")
    expect(service_config[:platform_version]).to eq("1.4.0")
    expect(service_config[:desired_count]).to eq(3)
  end
  
  # Test service with capacity provider strategy
  it "synthesizes service with capacity provider strategy correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_service(:capacity_provider, {
        name: "cp-service",
        cluster: "batch-cluster",
        task_definition: "batch:1",
        desired_count: 5,
        capacity_provider_strategy: [
          { capacity_provider: "FARGATE_SPOT", weight: 3, base: 1 },
          { capacity_provider: "FARGATE", weight: 1, base: 0 }
        ]
      })
    end
    
    json_output = synthesizer.synthesis
    service_config = json_output.dig(:resource, :aws_ecs_service, :capacity_provider)
    
    expect(service_config[:name]).to eq("cp-service")
    expect(service_config[:desired_count]).to eq(5)
    expect(service_config[:capacity_provider_strategy]).to be_an(Array)
    expect(service_config[:capacity_provider_strategy].size).to eq(2)
    
    fargate_spot = service_config[:capacity_provider_strategy].find { |cp| cp[:capacity_provider] == "FARGATE_SPOT" }
    expect(fargate_spot[:weight]).to eq(3)
    expect(fargate_spot[:base]).to eq(1)
    
    fargate = service_config[:capacity_provider_strategy].find { |cp| cp[:capacity_provider] == "FARGATE" }
    expect(fargate[:weight]).to eq(1)
    expect(fargate[:base]).to eq(0)
    
    # Should not have launch_type when using capacity providers
    expect(service_config).not_to have_key(:launch_type)
  end
  
  # Test service with load balancer
  it "synthesizes load balanced service correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_service(:load_balanced, {
        name: "web-service",
        cluster: "web-cluster",
        task_definition: "web:1",
        launch_type: "FARGATE",
        desired_count: 3,
        load_balancer: [
          {
            target_group_arn: target_group_arn,
            container_name: "web",
            container_port: 80
          }
        ],
        health_check_grace_period_seconds: 60
      })
    end
    
    json_output = synthesizer.synthesis
    service_config = json_output.dig(:resource, :aws_ecs_service, :load_balanced)
    
    expect(service_config[:load_balancer]).to be_an(Array)
    expect(service_config[:load_balancer].size).to eq(1)
    
    lb_config = service_config[:load_balancer].first
    expect(lb_config[:target_group_arn]).to eq(target_group_arn)
    expect(lb_config[:container_name]).to eq("web")
    expect(lb_config[:container_port]).to eq(80)
    expect(service_config[:health_check_grace_period_seconds]).to eq(60)
  end
  
  # Test service with network configuration
  it "synthesizes service with network configuration correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_service(:network, {
        name: "network-service",
        cluster: "vpc-cluster",
        task_definition: "vpc-web:1",
        launch_type: "FARGATE",
        desired_count: 2,
        network_configuration: {
          subnets: ["subnet-12345", "subnet-67890"],
          security_groups: ["sg-web"],
          assign_public_ip: false
        }
      })
    end
    
    json_output = synthesizer.synthesis
    service_config = json_output.dig(:resource, :aws_ecs_service, :network)
    
    expect(service_config[:network_configuration]).to be_a(Hash)
    net_config = service_config[:network_configuration]
    
    expect(net_config[:subnets]).to eq(["subnet-12345", "subnet-67890"])
    expect(net_config[:security_groups]).to eq(["sg-web"])
    expect(net_config[:assign_public_ip]).to eq(false)
  end
  
  # Test service with service discovery
  it "synthesizes service with service discovery correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_service(:service_discovery, {
        name: "sd-service", 
        cluster: "sd-cluster",
        task_definition: "api:1",
        launch_type: "FARGATE",
        desired_count: 2,
        service_registries: [
          {
            registry_arn: registry_arn,
            port: 8080,
            container_name: "api"
          }
        ]
      })
    end
    
    json_output = synthesizer.synthesis
    service_config = json_output.dig(:resource, :aws_ecs_service, :service_discovery)
    
    expect(service_config[:service_registries]).to be_an(Array)
    expect(service_config[:service_registries].size).to eq(1)
    
    registry_config = service_config[:service_registries].first
    expect(registry_config[:registry_arn]).to eq(registry_arn)
    expect(registry_config[:port]).to eq(8080)
    expect(registry_config[:container_name]).to eq("api")
  end
  
  # Test service with Service Connect
  it "synthesizes service with Service Connect correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_service(:service_connect, {
        name: "sc-service",
        cluster: "microservices",
        task_definition: "user-api:1",
        launch_type: "FARGATE",
        desired_count: 2,
        service_connect_configuration: {
          enabled: true,
          namespace: service_connect_namespace,
          services: [
            {
              port_name: "api",
              discovery_name: "user-api",
              client_aliases: [
                { port: 8080, dns_name: "users" }
              ],
              timeout: {
                idle_timeout_seconds: 60,
                per_request_timeout_seconds: 30
              }
            }
          ],
          log_configuration: {
            log_driver: "awslogs",
            options: {
              "awslogs-group": "/ecs/service-connect",
              "awslogs-region": "us-east-1"
            }
          }
        }
      })
    end
    
    json_output = synthesizer.synthesis
    service_config = json_output.dig(:resource, :aws_ecs_service, :service_connect)
    
    expect(service_config[:service_connect_configuration]).to be_a(Hash)
    sc_config = service_config[:service_connect_configuration]
    
    expect(sc_config[:enabled]).to eq(true)
    expect(sc_config[:namespace]).to eq(service_connect_namespace)
    expect(sc_config[:service]).to be_an(Array)
    expect(sc_config[:service].size).to eq(1)
    
    service_def = sc_config[:service].first
    expect(service_def[:port_name]).to eq("api")
    expect(service_def[:discovery_name]).to eq("user-api")
    expect(service_def[:client_alias]).to be_an(Array)
    expect(service_def[:timeout][:idle_timeout_seconds]).to eq(60)
    expect(service_def[:timeout][:per_request_timeout_seconds]).to eq(30)
    
    expect(sc_config[:log_configuration][:log_driver]).to eq("awslogs")
    expect(sc_config[:log_configuration][:options]["awslogs-group"]).to eq("/ecs/service-connect")
  end
  
  # Test DAEMON service
  it "synthesizes DAEMON service correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_service(:daemon, {
        name: "monitoring-daemon",
        cluster: "monitoring-cluster",
        task_definition: "datadog-agent:1",
        scheduling_strategy: "DAEMON",
        launch_type: "EC2"
      })
    end
    
    json_output = synthesizer.synthesis
    service_config = json_output.dig(:resource, :aws_ecs_service, :daemon)
    
    expect(service_config[:name]).to eq("monitoring-daemon")
    expect(service_config[:scheduling_strategy]).to eq("DAEMON")
    expect(service_config[:launch_type]).to eq("EC2")
    
    # DAEMON services should not have desired_count
    expect(service_config).not_to have_key(:desired_count)
  end
  
  # Test service with placement constraints and strategies
  it "synthesizes service with placement configuration correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_service(:placement, {
        name: "placement-service",
        cluster: "ec2-cluster",
        task_definition: "web:1",
        launch_type: "EC2",
        desired_count: 4,
        placement_constraints: [
          { type: "distinctInstance" },
          { type: "memberOf", expression: "attribute:instance-type =~ m5.*" }
        ],
        placement_strategy: [
          { type: "spread", field: "attribute:ecs.availability-zone" },
          { type: "binpack", field: "memory" }
        ]
      })
    end
    
    json_output = synthesizer.synthesis
    service_config = json_output.dig(:resource, :aws_ecs_service, :placement)
    
    expect(service_config[:placement_constraints]).to be_an(Array)
    expect(service_config[:placement_constraints].size).to eq(2)
    
    distinct_constraint = service_config[:placement_constraints].find { |pc| pc[:type] == "distinctInstance" }
    expect(distinct_constraint[:type]).to eq("distinctInstance")
    expect(distinct_constraint).not_to have_key(:expression)
    
    member_constraint = service_config[:placement_constraints].find { |pc| pc[:type] == "memberOf" }
    expect(member_constraint[:type]).to eq("memberOf")
    expect(member_constraint[:expression]).to include("m5")
    
    expect(service_config[:placement_strategy]).to be_an(Array)
    expect(service_config[:placement_strategy].size).to eq(2)
    
    spread_strategy = service_config[:placement_strategy].find { |ps| ps[:type] == "spread" }
    expect(spread_strategy[:field]).to include("availability-zone")
    
    binpack_strategy = service_config[:placement_strategy].find { |ps| ps[:type] == "binpack" }
    expect(binpack_strategy[:field]).to eq("memory")
  end
  
  # Test service with deployment configuration
  it "synthesizes service with deployment configuration correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_service(:deployment, {
        name: "deploy-service",
        cluster: "prod-cluster",
        task_definition: "api:2",
        launch_type: "FARGATE",
        desired_count: 6,
        deployment_configuration: {
          deployment_circuit_breaker: { enable: true, rollback: true },
          maximum_percent: 150,
          minimum_healthy_percent: 75
        },
        deployment_controller: { type: "ECS" }
      })
    end
    
    json_output = synthesizer.synthesis
    service_config = json_output.dig(:resource, :aws_ecs_service, :deployment)
    
    expect(service_config[:deployment_configuration]).to be_a(Hash)
    deploy_config = service_config[:deployment_configuration]
    
    expect(deploy_config[:deployment_circuit_breaker][:enable]).to eq(true)
    expect(deploy_config[:deployment_circuit_breaker][:rollback]).to eq(true)
    expect(deploy_config[:maximum_percent]).to eq(150)
    expect(deploy_config[:minimum_healthy_percent]).to eq(75)
    
    expect(service_config[:deployment_controller][:type]).to eq("ECS")
  end
  
  # Test service with tags
  it "synthesizes service with tags correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_service(:tagged, {
        name: "tagged-service",
        cluster: "test-cluster",
        task_definition: "web:1",
        launch_type: "FARGATE",
        tags: {
          Environment: "production",
          Application: "web-app",
          Team: "backend",
          CostCenter: "engineering"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    service_config = json_output.dig(:resource, :aws_ecs_service, :tagged)
    
    expect(service_config[:tags]).to be_a(Hash)
    expect(service_config[:tags][:Environment]).to eq("production")
    expect(service_config[:tags][:Application]).to eq("web-app")
    expect(service_config[:tags][:Team]).to eq("backend")
    expect(service_config[:tags][:CostCenter]).to eq("engineering")
  end
  
  # Test web application service pattern
  it "synthesizes web application service pattern correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_service(:web_app, {
        name: "web-app-service",
        cluster: cluster_arn,
        task_definition: task_definition_arn,
        launch_type: "FARGATE",
        desired_count: 3,
        load_balancer: [
          { target_group_arn: target_group_arn, container_name: "web", container_port: 80 }
        ],
        network_configuration: {
          subnets: ["subnet-private-1", "subnet-private-2"],
          security_groups: ["sg-web-app"],
          assign_public_ip: false
        },
        health_check_grace_period_seconds: 60,
        deployment_configuration: {
          deployment_circuit_breaker: { enable: true, rollback: true },
          maximum_percent: 200,
          minimum_healthy_percent: 100
        },
        enable_execute_command: true,
        propagate_tags: "SERVICE",
        tags: {
          Environment: "production",
          Application: "web-app",
          Tier: "web"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    service_config = json_output.dig(:resource, :aws_ecs_service, :web_app)
    
    # Verify complete web application configuration
    expect(service_config[:name]).to eq("web-app-service")
    expect(service_config[:launch_type]).to eq("FARGATE")
    expect(service_config[:desired_count]).to eq(3)
    
    # Load balancer configuration
    expect(service_config[:load_balancer]).to be_an(Array)
    expect(service_config[:health_check_grace_period_seconds]).to eq(60)
    
    # Network configuration
    expect(service_config[:network_configuration][:assign_public_ip]).to eq(false)
    
    # Deployment safety
    expect(service_config[:deployment_configuration][:deployment_circuit_breaker][:enable]).to eq(true)
    expect(service_config[:deployment_configuration][:deployment_circuit_breaker][:rollback]).to eq(true)
    
    # Management features
    expect(service_config[:enable_execute_command]).to eq(true)
    expect(service_config[:propagate_tags]).to eq("SERVICE")
    
    # Tags
    expect(service_config[:tags][:Tier]).to eq("web")
  end
  
  # Test microservice pattern
  it "synthesizes microservice pattern correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_service(:microservice, {
        name: "user-service",
        cluster: "microservices-cluster",
        task_definition: "user-service:2",
        launch_type: "FARGATE",
        desired_count: 2,
        service_connect_configuration: {
          enabled: true,
          namespace: service_connect_namespace,
          services: [
            {
              port_name: "api",
              discovery_name: "user-api",
              client_aliases: [
                { port: 8080, dns_name: "users" }
              ]
            }
          ]
        },
        network_configuration: {
          subnets: ["subnet-private-1", "subnet-private-2"],
          security_groups: ["sg-microservice"]
        },
        tags: {
          Service: "user-service",
          Architecture: "microservices",
          Team: "user-team"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    service_config = json_output.dig(:resource, :aws_ecs_service, :microservice)
    
    # Service Connect configuration
    sc_config = service_config[:service_connect_configuration]
    expect(sc_config[:enabled]).to eq(true)
    expect(sc_config[:service]).to be_an(Array)
    
    service_def = sc_config[:service].first
    expect(service_def[:discovery_name]).to eq("user-api")
    expect(service_def[:client_alias]).to be_an(Array)
    
    # Microservice tags
    expect(service_config[:tags][:Architecture]).to eq("microservices")
    expect(service_config[:tags][:Service]).to eq("user-service")
  end
  
  # Test batch processing service pattern
  it "synthesizes batch processing service pattern correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_service(:batch, {
        name: "batch-processor",
        cluster: "batch-cluster",
        task_definition: "data-processor:1",
        desired_count: 10,
        capacity_provider_strategy: [
          { capacity_provider: "FARGATE_SPOT", weight: 4, base: 2 },
          { capacity_provider: "FARGATE", weight: 1, base: 0 }
        ],
        network_configuration: {
          subnets: ["subnet-private-1", "subnet-private-2"],
          security_groups: ["sg-batch"],
          assign_public_ip: false
        },
        deployment_configuration: {
          deployment_circuit_breaker: { enable: false, rollback: false },
          maximum_percent: 300,
          minimum_healthy_percent: 50
        },
        tags: {
          WorkloadType: "batch",
          CostOptimized: "true",
          Environment: "production"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    service_config = json_output.dig(:resource, :aws_ecs_service, :batch)
    
    # Capacity provider strategy for cost optimization
    expect(service_config[:capacity_provider_strategy]).to be_an(Array)
    spot_strategy = service_config[:capacity_provider_strategy].find { |cp| cp[:capacity_provider] == "FARGATE_SPOT" }
    expect(spot_strategy[:weight]).to eq(4)
    expect(spot_strategy[:base]).to eq(2)
    
    # Flexible deployment for batch workloads
    expect(service_config[:deployment_configuration][:maximum_percent]).to eq(300)
    expect(service_config[:deployment_configuration][:minimum_healthy_percent]).to eq(50)
    
    # No circuit breaker for batch workloads
    expect(service_config[:deployment_configuration][:deployment_circuit_breaker][:enable]).to eq(false)
    
    # Cost optimization tags
    expect(service_config[:tags][:CostOptimized]).to eq("true")
  end
  
  # Test highly available service pattern
  it "synthesizes highly available service pattern correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_service(:ha_service, {
        name: "critical-api",
        cluster: "production-cluster",
        task_definition: "critical-api:3",
        launch_type: "FARGATE",
        desired_count: 6,
        load_balancer: [
          { target_group_arn: target_group_arn, container_name: "api", container_port: 8080 }
        ],
        network_configuration: {
          subnets: ["subnet-private-1a", "subnet-private-1b", "subnet-private-1c"],
          security_groups: ["sg-critical-api"],
          assign_public_ip: false
        },
        health_check_grace_period_seconds: 120,
        deployment_configuration: {
          deployment_circuit_breaker: { enable: true, rollback: true },
          maximum_percent: 200,
          minimum_healthy_percent: 100
        },
        enable_execute_command: false, # Security hardening
        propagate_tags: "SERVICE",
        tags: {
          Environment: "production",
          Criticality: "high",
          SLA: "99.9",
          Security: "hardened"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    service_config = json_output.dig(:resource, :aws_ecs_service, :ha_service)
    
    # High availability configuration
    expect(service_config[:desired_count]).to eq(6)
    expect(service_config[:network_configuration][:subnets].size).to eq(3) # Multi-AZ
    
    # Conservative deployment for stability
    expect(service_config[:deployment_configuration][:minimum_healthy_percent]).to eq(100)
    expect(service_config[:health_check_grace_period_seconds]).to eq(120)
    
    # Security hardening
    expect(service_config[:enable_execute_command]).to eq(false)
    
    # High availability tags
    expect(service_config[:tags][:Criticality]).to eq("high")
    expect(service_config[:tags][:SLA]).to eq("99.9")
  end
  
  # Test service with Blue/Green deployment
  it "synthesizes Blue/Green deployment service correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_service(:blue_green, {
        name: "bg-service",
        cluster: "production-cluster",
        task_definition: "api-service:5",
        launch_type: "FARGATE",
        desired_count: 4,
        deployment_controller: { type: "CODE_DEPLOY" },
        load_balancer: [
          { target_group_arn: target_group_arn, container_name: "api", container_port: 8080 }
        ],
        network_configuration: {
          subnets: ["subnet-private-1", "subnet-private-2"],
          security_groups: ["sg-api"]
        },
        tags: {
          DeploymentStrategy: "blue-green",
          Environment: "production",
          Service: "api"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    service_config = json_output.dig(:resource, :aws_ecs_service, :blue_green)
    
    expect(service_config[:deployment_controller][:type]).to eq("CODE_DEPLOY")
    expect(service_config[:tags][:DeploymentStrategy]).to eq("blue-green")
    
    # Should have load balancer for traffic shifting
    expect(service_config[:load_balancer]).to be_an(Array)
  end
  
  # Test service with minimal configuration
  it "synthesizes minimal service configuration correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_service(:minimal, {
        name: "minimal-service",
        cluster: "test-cluster",
        task_definition: "simple:1"
      })
    end
    
    json_output = synthesizer.synthesis
    service_config = json_output.dig(:resource, :aws_ecs_service, :minimal)
    
    # Only required fields and defaults should be present
    expect(service_config[:name]).to eq("minimal-service")
    expect(service_config[:cluster]).to eq("test-cluster")
    expect(service_config[:task_definition]).to eq("simple:1")
    expect(service_config[:desired_count]).to eq(1)
    expect(service_config[:enable_ecs_managed_tags]).to eq(true)
    expect(service_config[:enable_execute_command]).to eq(false)
    
    # Optional fields should not be present when not specified
    expect(service_config).not_to have_key(:launch_type)
    expect(service_config).not_to have_key(:load_balancer)
    expect(service_config).not_to have_key(:network_configuration)
    expect(service_config).not_to have_key(:service_registries)
    expect(service_config).not_to have_key(:placement_constraints)
    expect(service_config).not_to have_key(:placement_strategy)
    expect(service_config).not_to have_key(:health_check_grace_period_seconds)
    expect(service_config).not_to have_key(:service_connect_configuration)
  end
end