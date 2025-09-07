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

# Load aws_ecs_service resource and types for testing
require 'pangea/resources/aws_ecs_service/resource'
require 'pangea/resources/aws_ecs_service/types'

RSpec.describe "aws_ecs_service resource function" do
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
  let(:cluster_arn) { "arn:aws:ecs:us-east-1:123456789012:cluster/test-cluster" }
  let(:task_definition_arn) { "arn:aws:ecs:us-east-1:123456789012:task-definition/web:1" }
  let(:target_group_arn) { "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/web-tg/50dc6c495c0c9188" }
  let(:registry_arn) { "arn:aws:servicediscovery:us-east-1:123456789012:service/srv-utcrh6wavdkggqtk" }
  let(:service_connect_namespace) { "arn:aws:servicediscovery:us-east-1:123456789012:namespace/ns-12345" }
  
  describe "EcsServiceAttributes validation" do
    it "accepts basic service configuration" do
      attrs = Pangea::Resources::AWS::Types::EcsServiceAttributes.new({
        name: "web-service",
        cluster: "test-cluster",
        task_definition: "web:1"
      })
      
      expect(attrs.name).to eq("web-service")
      expect(attrs.cluster).to eq("test-cluster") 
      expect(attrs.task_definition).to eq("web:1")
      expect(attrs.desired_count).to eq(1)
      expect(attrs.scheduling_strategy).to eq("REPLICA")
      expect(attrs.enable_ecs_managed_tags).to eq(true)
      expect(attrs.enable_execute_command).to eq(false)
    end
    
    it "accepts service with Fargate launch type" do
      attrs = Pangea::Resources::AWS::Types::EcsServiceAttributes.new({
        name: "fargate-service",
        cluster: cluster_arn,
        task_definition: task_definition_arn,
        launch_type: "FARGATE",
        platform_version: "1.4.0"
      })
      
      expect(attrs.launch_type).to eq("FARGATE")
      expect(attrs.platform_version).to eq("1.4.0")
      expect(attrs.using_fargate?).to eq(true)
    end
    
    it "accepts service with capacity provider strategy" do
      attrs = Pangea::Resources::AWS::Types::EcsServiceAttributes.new({
        name: "cp-service",
        cluster: "test-cluster",
        task_definition: "web:1",
        capacity_provider_strategy: [
          { capacity_provider: "FARGATE", weight: 2, base: 1 },
          { capacity_provider: "FARGATE_SPOT", weight: 1, base: 0 }
        ]
      })
      
      expect(attrs.capacity_provider_strategy.size).to eq(2)
      expect(attrs.capacity_provider_strategy.first.capacity_provider).to eq("FARGATE")
      expect(attrs.capacity_provider_strategy.first.weight).to eq(2)
      expect(attrs.capacity_provider_strategy.first.base).to eq(1)
      expect(attrs.using_fargate?).to eq(true)
    end
    
    it "accepts service with load balancer configuration" do
      attrs = Pangea::Resources::AWS::Types::EcsServiceAttributes.new({
        name: "lb-service",
        cluster: "test-cluster",
        task_definition: "web:1",
        load_balancer: [
          {
            target_group_arn: target_group_arn,
            container_name: "web",
            container_port: 80
          }
        ]
      })
      
      expect(attrs.load_balancer.size).to eq(1)
      expect(attrs.load_balancer.first.target_group_arn).to eq(target_group_arn)
      expect(attrs.load_balancer.first.container_name).to eq("web")
      expect(attrs.load_balancer.first.container_port).to eq(80)
      expect(attrs.load_balanced?).to eq(true)
    end
    
    it "accepts service with network configuration" do
      attrs = Pangea::Resources::AWS::Types::EcsServiceAttributes.new({
        name: "network-service",
        cluster: "test-cluster",
        task_definition: "web:1",
        network_configuration: {
          subnets: ["subnet-12345", "subnet-67890"],
          security_groups: ["sg-12345"],
          assign_public_ip: true
        }
      })
      
      expect(attrs.network_configuration.subnets).to eq(["subnet-12345", "subnet-67890"])
      expect(attrs.network_configuration.security_groups).to eq(["sg-12345"])
      expect(attrs.network_configuration.assign_public_ip).to eq(true)
    end
    
    it "accepts service with service discovery" do
      attrs = Pangea::Resources::AWS::Types::EcsServiceAttributes.new({
        name: "sd-service",
        cluster: "test-cluster",
        task_definition: "web:1",
        service_registries: [
          {
            registry_arn: registry_arn,
            port: 80,
            container_name: "web"
          }
        ]
      })
      
      expect(attrs.service_registries.size).to eq(1)
      expect(attrs.service_registries.first.registry_arn).to eq(registry_arn)
      expect(attrs.service_registries.first.port).to eq(80)
      expect(attrs.service_discovery_enabled?).to eq(true)
    end
    
    it "accepts service with Service Connect configuration" do
      attrs = Pangea::Resources::AWS::Types::EcsServiceAttributes.new({
        name: "sc-service",
        cluster: "test-cluster",
        task_definition: "web:1",
        service_connect_configuration: {
          enabled: true,
          namespace: service_connect_namespace,
          services: [
            {
              port_name: "web",
              discovery_name: "web-api",
              client_aliases: [
                { port: 80, dns_name: "api" }
              ]
            }
          ]
        }
      })
      
      sc_config = attrs.service_connect_configuration
      expect(sc_config[:enabled]).to eq(true)
      expect(sc_config[:namespace]).to eq(service_connect_namespace)
      expect(sc_config[:services].size).to eq(1)
      expect(attrs.service_connect_enabled?).to eq(true)
    end
    
    it "accepts DAEMON scheduling strategy" do
      attrs = Pangea::Resources::AWS::Types::EcsServiceAttributes.new({
        name: "daemon-service",
        cluster: "test-cluster",
        task_definition: "daemon:1",
        scheduling_strategy: "DAEMON",
        desired_count: 0
      })
      
      expect(attrs.scheduling_strategy).to eq("DAEMON")
      expect(attrs.desired_count).to eq(0)
    end
    
    it "accepts placement constraints" do
      attrs = Pangea::Resources::AWS::Types::EcsServiceAttributes.new({
        name: "constrained-service",
        cluster: "test-cluster", 
        task_definition: "web:1",
        placement_constraints: [
          { type: "distinctInstance" },
          { type: "memberOf", expression: "attribute:instance-type =~ t3.*" }
        ]
      })
      
      expect(attrs.placement_constraints.size).to eq(2)
      expect(attrs.placement_constraints.first.type).to eq("distinctInstance")
      expect(attrs.placement_constraints.last.type).to eq("memberOf")
      expect(attrs.placement_constraints.last.expression).to include("t3")
    end
    
    it "accepts placement strategies" do
      attrs = Pangea::Resources::AWS::Types::EcsServiceAttributes.new({
        name: "strategy-service",
        cluster: "test-cluster",
        task_definition: "web:1",
        placement_strategy: [
          { type: "spread", field: "instanceId" },
          { type: "binpack", field: "memory" }
        ]
      })
      
      expect(attrs.placement_strategy.size).to eq(2)
      expect(attrs.placement_strategy.first.type).to eq("spread")
      expect(attrs.placement_strategy.last.type).to eq("binpack")
    end
    
    it "accepts deployment configuration" do
      attrs = Pangea::Resources::AWS::Types::EcsServiceAttributes.new({
        name: "deploy-service",
        cluster: "test-cluster",
        task_definition: "web:1",
        deployment_configuration: {
          deployment_circuit_breaker: { enable: true, rollback: true },
          maximum_percent: 150,
          minimum_healthy_percent: 50
        }
      })
      
      deploy_config = attrs.deployment_configuration
      expect(deploy_config.deployment_circuit_breaker[:enable]).to eq(true)
      expect(deploy_config.deployment_circuit_breaker[:rollback]).to eq(true)
      expect(deploy_config.maximum_percent).to eq(150)
      expect(deploy_config.minimum_healthy_percent).to eq(50)
      expect(attrs.deployment_safe?).to eq(true)
    end
  end
  
  describe "validation rules" do
    it "rejects invalid task definition format" do
      expect {
        Pangea::Resources::AWS::Types::EcsServiceAttributes.new({
          name: "test",
          cluster: "cluster",
          task_definition: "invalid-format"
        })
      }.to raise_error(Dry::Struct::Error, /Invalid task definition format/)
    end
    
    it "rejects both launch_type and capacity_provider_strategy" do
      expect {
        Pangea::Resources::AWS::Types::EcsServiceAttributes.new({
          name: "test",
          cluster: "cluster", 
          task_definition: "web:1",
          launch_type: "FARGATE",
          capacity_provider_strategy: [{ capacity_provider: "FARGATE" }]
        })
      }.to raise_error(Dry::Struct::Error, /Cannot specify both launch_type and capacity_provider_strategy/)
    end
    
    it "rejects DAEMON with non-zero desired_count" do
      expect {
        Pangea::Resources::AWS::Types::EcsServiceAttributes.new({
          name: "test",
          cluster: "cluster",
          task_definition: "daemon:1",
          scheduling_strategy: "DAEMON",
          desired_count: 2
        })
      }.to raise_error(Dry::Struct::Error, /desired_count must be 0 or omitted for DAEMON scheduling/)
    end
    
    it "rejects DAEMON with placement strategies" do
      expect {
        Pangea::Resources::AWS::Types::EcsServiceAttributes.new({
          name: "test",
          cluster: "cluster",
          task_definition: "daemon:1",
          scheduling_strategy: "DAEMON",
          placement_strategy: [{ type: "spread", field: "instanceId" }]
        })
      }.to raise_error(Dry::Struct::Error, /placement_strategy cannot be used with DAEMON scheduling/)
    end
    
    it "rejects health check grace period without load balancer" do
      expect {
        Pangea::Resources::AWS::Types::EcsServiceAttributes.new({
          name: "test",
          cluster: "cluster",
          task_definition: "web:1",
          health_check_grace_period_seconds: 30
        })
      }.to raise_error(Dry::Struct::Error, /health_check_grace_period_seconds requires load_balancer configuration/)
    end
    
    it "rejects Service Connect without service configuration" do
      expect {
        Pangea::Resources::AWS::Types::EcsServiceAttributes.new({
          name: "test",
          cluster: "cluster",
          task_definition: "web:1",
          service_connect_configuration: {
            enabled: true,
            namespace: service_connect_namespace
          }
        })
      }.to raise_error(Dry::Struct::Error, /Service Connect requires at least one service configuration/)
    end
  end
  
  describe "placement constraint validation" do
    it "accepts distinctInstance without expression" do
      expect {
        Pangea::Resources::AWS::Types::EcsPlacementConstraint.new({
          type: "distinctInstance"
        })
      }.not_to raise_error
    end
    
    it "rejects memberOf without expression" do
      expect {
        Pangea::Resources::AWS::Types::EcsPlacementConstraint.new({
          type: "memberOf"
        })
      }.to raise_error(Dry::Struct::Error, /Expression is required for memberOf constraint type/)
    end
  end
  
  describe "placement strategy validation" do
    it "accepts random without field" do
      expect {
        Pangea::Resources::AWS::Types::EcsPlacementStrategy.new({
          type: "random"
        })
      }.not_to raise_error
    end
    
    it "rejects spread without field" do
      expect {
        Pangea::Resources::AWS::Types::EcsPlacementStrategy.new({
          type: "spread"
        })
      }.to raise_error(Dry::Struct::Error, /Field is required for spread strategy/)
    end
    
    it "rejects binpack without field" do
      expect {
        Pangea::Resources::AWS::Types::EcsPlacementStrategy.new({
          type: "binpack"
        })
      }.to raise_error(Dry::Struct::Error, /Field is required for binpack strategy/)
    end
  end
  
  describe "load balancer validation" do
    it "validates target group ARN format" do
      expect {
        Pangea::Resources::AWS::Types::EcsLoadBalancer.new({
          target_group_arn: "invalid-arn",
          container_name: "web",
          container_port: 80
        })
      }.to raise_error(Dry::Struct::Error, /Invalid target group ARN format/)
    end
    
    it "validates container port range" do
      expect {
        Pangea::Resources::AWS::Types::EcsLoadBalancer.new({
          target_group_arn: target_group_arn,
          container_name: "web",
          container_port: 70000
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
  end
  
  describe "computed properties" do
    let(:fargate_service_attrs) do
      Pangea::Resources::AWS::Types::EcsServiceAttributes.new({
        name: "fargate-service",
        cluster: "test-cluster",
        task_definition: "web:1",
        launch_type: "FARGATE",
        desired_count: 3,
        load_balancer: [
          { target_group_arn: target_group_arn, container_name: "web", container_port: 80 }
        ],
        service_registries: [
          { registry_arn: registry_arn }
        ],
        service_connect_configuration: {
          enabled: true,
          namespace: service_connect_namespace,
          services: [{ port_name: "web" }]
        }
      })
    end
    
    it "detects Fargate usage" do
      expect(fargate_service_attrs.using_fargate?).to eq(true)
    end
    
    it "detects load balancer usage" do
      expect(fargate_service_attrs.load_balanced?).to eq(true)
    end
    
    it "detects service discovery usage" do
      expect(fargate_service_attrs.service_discovery_enabled?).to eq(true)
    end
    
    it "detects Service Connect usage" do
      expect(fargate_service_attrs.service_connect_enabled?).to eq(true)
    end
    
    it "calculates estimated monthly cost" do
      cost = fargate_service_attrs.estimated_monthly_cost
      expect(cost).to be > 0
      expect(cost).to eq(163.0) # Fargate (150) + Service Connect (5) + Load balancer targets (8)
    end
    
    it "determines deployment safety" do
      safe_attrs = Pangea::Resources::AWS::Types::EcsServiceAttributes.new({
        name: "safe-service",
        cluster: "test-cluster",
        task_definition: "web:1",
        deployment_configuration: {
          deployment_circuit_breaker: { enable: true, rollback: true }
        }
      })
      
      expect(safe_attrs.deployment_safe?).to eq(true)
    end
  end
  
  describe "aws_ecs_service function" do
    it "creates basic ECS service" do
      result = test_instance.aws_ecs_service(:basic, {
        name: "basic-service",
        cluster: "test-cluster",
        task_definition: "web:1"
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.type).to eq('aws_ecs_service')
      expect(result.name).to eq(:basic)
    end
    
    it "creates Fargate service" do
      result = test_instance.aws_ecs_service(:fargate, {
        name: "fargate-service",
        cluster: cluster_arn,
        task_definition: task_definition_arn,
        launch_type: "FARGATE",
        platform_version: "1.4.0"
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.using_fargate?).to eq(true)
    end
    
    it "creates load balanced service" do
      result = test_instance.aws_ecs_service(:load_balanced, {
        name: "lb-service",
        cluster: "test-cluster",
        task_definition: "web:1",
        load_balancer: [
          {
            target_group_arn: target_group_arn,
            container_name: "web",
            container_port: 80
          }
        ]
      })
      
      expect(result.load_balanced?).to eq(true)
    end
    
    it "creates service with Service Connect" do
      result = test_instance.aws_ecs_service(:service_connect, {
        name: "sc-service",
        cluster: "test-cluster",
        task_definition: "web:1",
        service_connect_configuration: {
          enabled: true,
          namespace: service_connect_namespace,
          services: [
            { port_name: "web", discovery_name: "web-api" }
          ]
        }
      })
      
      expect(result.service_connect_enabled?).to eq(true)
    end
    
    it "provides correct outputs" do
      result = test_instance.aws_ecs_service(:test, {
        name: "test-service",
        cluster: "test-cluster",
        task_definition: "web:1"
      })
      
      expect(result.id).to eq("${aws_ecs_service.test.id}")
      expect(result.name).to eq("${aws_ecs_service.test.name}")
      expect(result.cluster).to eq("${aws_ecs_service.test.cluster}")
      expect(result.iam_role).to eq("${aws_ecs_service.test.iam_role}")
      expect(result.desired_count).to eq("${aws_ecs_service.test.desired_count}")
      expect(result.launch_type).to eq("${aws_ecs_service.test.launch_type}")
      expect(result.platform_version).to eq("${aws_ecs_service.test.platform_version}")
      expect(result.task_definition).to eq("${aws_ecs_service.test.task_definition}")
      expect(result.tags_all).to eq("${aws_ecs_service.test.tags_all}")
    end
    
    it "provides computed properties" do
      result = test_instance.aws_ecs_service(:computed, {
        name: "computed-service",
        cluster: "test-cluster",
        task_definition: "web:1",
        launch_type: "FARGATE",
        desired_count: 3,
        deployment_configuration: {
          deployment_circuit_breaker: { enable: true, rollback: true }
        },
        scheduling_strategy: "DAEMON"
      })
      
      expect(result.using_fargate?).to eq(true)
      expect(result.load_balanced?).to eq(false)
      expect(result.service_discovery_enabled?).to eq(false)
      expect(result.service_connect_enabled?).to eq(false)
      expect(result.deployment_safe?).to eq(true)
      expect(result.is_daemon_service?).to eq(true)
      expect(result.estimated_monthly_cost).to be > 0
    end
  end
  
  describe "service deployment patterns" do
    it "creates web application service" do
      result = test_instance.aws_ecs_service(:web_app, {
        name: "web-app-service",
        cluster: cluster_arn,
        task_definition: task_definition_arn,
        launch_type: "FARGATE",
        desired_count: 3,
        load_balancer: [
          { target_group_arn: target_group_arn, container_name: "web", container_port: 80 }
        ],
        network_configuration: {
          subnets: ["subnet-12345", "subnet-67890"],
          security_groups: ["sg-12345"],
          assign_public_ip: false
        },
        health_check_grace_period_seconds: 60,
        deployment_configuration: {
          deployment_circuit_breaker: { enable: true, rollback: true },
          maximum_percent: 200,
          minimum_healthy_percent: 100
        },
        tags: {
          Application: "web-app",
          Environment: "production",
          Tier: "web"
        }
      })
      
      expect(result.using_fargate?).to eq(true)
      expect(result.load_balanced?).to eq(true)
      expect(result.deployment_safe?).to eq(true)
    end
    
    it "creates microservice with Service Connect" do
      result = test_instance.aws_ecs_service(:microservice, {
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
      
      expect(result.using_fargate?).to eq(true)
      expect(result.service_connect_enabled?).to eq(true)
      expect(result.load_balanced?).to eq(false)
    end
    
    it "creates daemon service for monitoring" do
      result = test_instance.aws_ecs_service(:daemon, {
        name: "monitoring-daemon",
        cluster: "monitoring-cluster",
        task_definition: "datadog-agent:1",
        scheduling_strategy: "DAEMON",
        launch_type: "EC2",
        placement_constraints: [
          { type: "memberOf", expression: "attribute:instance-type =~ c5.*" }
        ],
        tags: {
          Purpose: "monitoring",
          DaemonType: "agent"
        }
      })
      
      expect(result.is_daemon_service?).to eq(true)
      expect(result.using_fargate?).to eq(false)
    end
    
    it "creates service with capacity providers" do
      result = test_instance.aws_ecs_service(:capacity_provider, {
        name: "batch-service",
        cluster: "batch-cluster",
        task_definition: "batch-processor:1",
        desired_count: 5,
        capacity_provider_strategy: [
          { capacity_provider: "FARGATE_SPOT", weight: 3, base: 1 },
          { capacity_provider: "FARGATE", weight: 1, base: 0 }
        ],
        network_configuration: {
          subnets: ["subnet-private-1", "subnet-private-2"],
          security_groups: ["sg-batch"]
        },
        tags: {
          WorkloadType: "batch",
          CostOptimized: "true"
        }
      })
      
      expect(result.using_fargate?).to eq(true)
    end
  end
  
  describe "service deployment strategies" do
    it "creates service with blue-green deployment" do
      result = test_instance.aws_ecs_service(:blue_green, {
        name: "blue-green-service",
        cluster: "production-cluster",
        task_definition: "api-service:3",
        launch_type: "FARGATE",
        desired_count: 4,
        deployment_controller: {
          type: "CODE_DEPLOY"
        },
        load_balancer: [
          { target_group_arn: target_group_arn, container_name: "api", container_port: 8080 }
        ],
        tags: {
          DeploymentStrategy: "blue-green",
          CriticalService: "true"
        }
      })
      
      expect(result.load_balanced?).to eq(true)
    end
    
    it "creates service with external deployment controller" do
      result = test_instance.aws_ecs_service(:external, {
        name: "external-service",
        cluster: "external-cluster",
        task_definition: "external-app:1",
        launch_type: "FARGATE",
        desired_count: 2,
        deployment_controller: {
          type: "EXTERNAL"
        },
        tags: {
          DeploymentController: "external",
          ManagedBy: "custom-controller"
        }
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
    end
  end
  
  describe "service scaling and placement" do
    it "creates service with placement strategies" do
      result = test_instance.aws_ecs_service(:placement, {
        name: "placement-service",
        cluster: "ec2-cluster",
        task_definition: "web:1",
        launch_type: "EC2",
        desired_count: 6,
        placement_strategy: [
          { type: "spread", field: "attribute:ecs.availability-zone" },
          { type: "spread", field: "instanceId" },
          { type: "binpack", field: "memory" }
        ],
        placement_constraints: [
          { type: "memberOf", expression: "attribute:instance-type =~ m5.*" }
        ],
        tags: {
          PlacementOptimized: "true",
          LaunchType: "EC2"
        }
      })
      
      expect(result.using_fargate?).to eq(false)
    end
  end
  
  describe "service networking patterns" do
    it "creates service in awsvpc mode with public IPs" do
      result = test_instance.aws_ecs_service(:public_service, {
        name: "public-service",
        cluster: "public-cluster",
        task_definition: "public-web:1",
        launch_type: "FARGATE",
        desired_count: 2,
        network_configuration: {
          subnets: ["subnet-public-1", "subnet-public-2"],
          security_groups: ["sg-public"],
          assign_public_ip: true
        },
        tags: {
          NetworkMode: "awsvpc",
          PublicAccess: "true"
        }
      })
      
      expect(result.using_fargate?).to eq(true)
    end
  end
end