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

# Load aws_ecs_cluster resource and types for testing
require 'pangea/resources/aws_ecs_cluster/resource'
require 'pangea/resources/aws_ecs_cluster/types'

RSpec.describe "aws_ecs_cluster resource function" do
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
  let(:kms_key_arn) { "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012" }
  let(:custom_provider_arn) { "arn:aws:ecs:us-east-1:123456789012:capacity-provider/custom-provider" }
  
  describe "EcsClusterAttributes validation" do
    it "accepts basic cluster configuration" do
      attrs = Pangea::Resources::AWS::Types::EcsClusterAttributes.new({
        name: "test-cluster"
      })
      
      expect(attrs.name).to eq("test-cluster")
      expect(attrs.capacity_providers).to eq([])
      expect(attrs.container_insights_enabled).to be_nil
      expect(attrs.setting).to eq([])
    end
    
    it "accepts cluster with FARGATE capacity provider" do
      attrs = Pangea::Resources::AWS::Types::EcsClusterAttributes.new({
        name: "fargate-cluster",
        capacity_providers: ["FARGATE"]
      })
      
      expect(attrs.name).to eq("fargate-cluster")
      expect(attrs.capacity_providers).to eq(["FARGATE"])
      expect(attrs.using_fargate?).to eq(true)
      expect(attrs.using_ec2?).to eq(false)
    end
    
    it "accepts cluster with FARGATE_SPOT capacity provider" do
      attrs = Pangea::Resources::AWS::Types::EcsClusterAttributes.new({
        name: "spot-cluster",
        capacity_providers: ["FARGATE_SPOT"]
      })
      
      expect(attrs.name).to eq("spot-cluster")
      expect(attrs.capacity_providers).to eq(["FARGATE_SPOT"])
      expect(attrs.using_fargate?).to eq(true)
      expect(attrs.using_ec2?).to eq(false)
    end
    
    it "accepts cluster with custom capacity provider ARN" do
      attrs = Pangea::Resources::AWS::Types::EcsClusterAttributes.new({
        name: "custom-cluster",
        capacity_providers: [custom_provider_arn]
      })
      
      expect(attrs.name).to eq("custom-cluster")
      expect(attrs.capacity_providers).to eq([custom_provider_arn])
      expect(attrs.using_fargate?).to eq(false)
      expect(attrs.using_ec2?).to eq(true)
    end
    
    it "accepts cluster with mixed capacity providers" do
      attrs = Pangea::Resources::AWS::Types::EcsClusterAttributes.new({
        name: "mixed-cluster",
        capacity_providers: ["FARGATE", "FARGATE_SPOT", custom_provider_arn]
      })
      
      expect(attrs.capacity_providers).to eq(["FARGATE", "FARGATE_SPOT", custom_provider_arn])
      expect(attrs.using_fargate?).to eq(true)
      expect(attrs.using_ec2?).to eq(true)
    end
    
    it "accepts cluster with Container Insights enabled (shorthand)" do
      attrs = Pangea::Resources::AWS::Types::EcsClusterAttributes.new({
        name: "insights-cluster",
        container_insights_enabled: true
      })
      
      expect(attrs.container_insights_enabled).to eq(true)
      expect(attrs.insights_enabled?).to eq(true)
    end
    
    it "accepts cluster with Container Insights via settings" do
      attrs = Pangea::Resources::AWS::Types::EcsClusterAttributes.new({
        name: "settings-cluster",
        setting: [
          { name: "containerInsights", value: "enabled" }
        ]
      })
      
      expect(attrs.insights_enabled?).to eq(true)
    end
    
    it "accepts cluster with execute command configuration" do
      attrs = Pangea::Resources::AWS::Types::EcsClusterAttributes.new({
        name: "exec-cluster",
        configuration: {
          execute_command_configuration: {
            kms_key_id: kms_key_arn,
            logging: "OVERRIDE",
            log_configuration: {
              cloud_watch_encryption_enabled: true,
              cloud_watch_log_group_name: "/ecs/exec",
              s3_bucket_name: "exec-logs",
              s3_bucket_encryption_enabled: true,
              s3_key_prefix: "logs/"
            }
          }
        }
      })
      
      exec_config = attrs.configuration[:execute_command_configuration]
      expect(exec_config[:kms_key_id]).to eq(kms_key_arn)
      expect(exec_config[:logging]).to eq("OVERRIDE")
      expect(exec_config[:log_configuration][:cloud_watch_encryption_enabled]).to eq(true)
    end
    
    it "accepts cluster with Service Connect defaults" do
      attrs = Pangea::Resources::AWS::Types::EcsClusterAttributes.new({
        name: "service-connect-cluster",
        service_connect_defaults: {
          namespace: "arn:aws:servicediscovery:us-east-1:123456789012:namespace/ns-12345"
        }
      })
      
      expect(attrs.service_connect_defaults[:namespace]).to include("servicediscovery")
    end
    
    it "accepts cluster with comprehensive configuration" do
      attrs = Pangea::Resources::AWS::Types::EcsClusterAttributes.new({
        name: "comprehensive-cluster",
        capacity_providers: ["FARGATE", "FARGATE_SPOT"],
        container_insights_enabled: true,
        configuration: {
          execute_command_configuration: {
            kms_key_id: kms_key_arn,
            logging: "OVERRIDE"
          }
        },
        service_connect_defaults: {
          namespace: "arn:aws:servicediscovery:us-east-1:123456789012:namespace/ns-12345"
        },
        tags: {
          Environment: "production",
          Team: "platform",
          Project: "containers"
        }
      })
      
      expect(attrs.name).to eq("comprehensive-cluster")
      expect(attrs.using_fargate?).to eq(true)
      expect(attrs.insights_enabled?).to eq(true)
      expect(attrs.tags[:Environment]).to eq("production")
    end
  end
  
  describe "capacity provider validation" do
    it "accepts FARGATE provider" do
      expect {
        Pangea::Resources::AWS::Types::EcsClusterAttributes.new({
          name: "test",
          capacity_providers: ["FARGATE"]
        })
      }.not_to raise_error
    end
    
    it "accepts FARGATE_SPOT provider" do
      expect {
        Pangea::Resources::AWS::Types::EcsClusterAttributes.new({
          name: "test",
          capacity_providers: ["FARGATE_SPOT"]
        })
      }.not_to raise_error
    end
    
    it "accepts valid capacity provider ARN" do
      expect {
        Pangea::Resources::AWS::Types::EcsClusterAttributes.new({
          name: "test",
          capacity_providers: ["arn:aws:ecs:us-east-1:123456789012:capacity-provider/custom"]
        })
      }.not_to raise_error
    end
    
    it "rejects invalid capacity provider" do
      expect {
        Pangea::Resources::AWS::Types::EcsClusterAttributes.new({
          name: "test",
          capacity_providers: ["INVALID_PROVIDER"]
        })
      }.to raise_error(Dry::Struct::Error, /Invalid capacity provider/)
    end
    
    it "rejects malformed ARN" do
      expect {
        Pangea::Resources::AWS::Types::EcsClusterAttributes.new({
          name: "test",
          capacity_providers: ["arn:aws:invalid:provider"]
        })
      }.to raise_error(Dry::Struct::Error, /Invalid capacity provider/)
    end
  end
  
  describe "container insights validation" do
    it "allows both shorthand and setting when consistent" do
      expect {
        Pangea::Resources::AWS::Types::EcsClusterAttributes.new({
          name: "test",
          container_insights_enabled: true,
          setting: [
            { name: "containerInsights", value: "enabled" }
          ]
        })
      }.not_to raise_error
    end
    
    it "rejects conflicting insights configuration" do
      expect {
        Pangea::Resources::AWS::Types::EcsClusterAttributes.new({
          name: "test",
          container_insights_enabled: true,
          setting: [
            { name: "containerInsights", value: "disabled" }
          ]
        })
      }.to raise_error(Dry::Struct::Error, /conflicts with setting value/)
    end
  end
  
  describe "logging configuration validation" do
    it "accepts DEFAULT logging" do
      attrs = Pangea::Resources::AWS::Types::EcsClusterAttributes.new({
        name: "test",
        configuration: {
          execute_command_configuration: {
            logging: "DEFAULT"
          }
        }
      })
      
      expect(attrs.configuration[:execute_command_configuration][:logging]).to eq("DEFAULT")
    end
    
    it "accepts NONE logging" do
      attrs = Pangea::Resources::AWS::Types::EcsClusterAttributes.new({
        name: "test",
        configuration: {
          execute_command_configuration: {
            logging: "NONE"
          }
        }
      })
      
      expect(attrs.configuration[:execute_command_configuration][:logging]).to eq("NONE")
    end
    
    it "accepts OVERRIDE logging" do
      attrs = Pangea::Resources::AWS::Types::EcsClusterAttributes.new({
        name: "test",
        configuration: {
          execute_command_configuration: {
            logging: "OVERRIDE"
          }
        }
      })
      
      expect(attrs.configuration[:execute_command_configuration][:logging]).to eq("OVERRIDE")
    end
    
    it "rejects invalid logging value" do
      expect {
        Pangea::Resources::AWS::Types::EcsClusterAttributes.new({
          name: "test",
          configuration: {
            execute_command_configuration: {
              logging: "INVALID"
            }
          }
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
  end
  
  describe "computed properties" do
    let(:fargate_attrs) do
      Pangea::Resources::AWS::Types::EcsClusterAttributes.new({
        name: "fargate-cluster",
        capacity_providers: ["FARGATE", "FARGATE_SPOT"],
        container_insights_enabled: true,
        service_connect_defaults: {
          namespace: "arn:aws:servicediscovery:us-east-1:123456789012:namespace/ns-12345"
        }
      })
    end
    
    it "detects Fargate usage" do
      expect(fargate_attrs.using_fargate?).to eq(true)
      expect(fargate_attrs.using_ec2?).to eq(false)
    end
    
    it "detects Container Insights enabled" do
      expect(fargate_attrs.insights_enabled?).to eq(true)
    end
    
    it "estimates monthly cost" do
      cost = fargate_attrs.estimated_monthly_cost
      expect(cost).to be > 0
      expect(cost).to eq(7.0) # Insights (5) + Service Connect (2)
    end
    
    it "generates ARN pattern" do
      arn = fargate_attrs.arn_pattern("us-east-1", "123456789012")
      expect(arn).to eq("arn:aws:ecs:us-east-1:123456789012:cluster/fargate-cluster")
    end
    
    it "generates ARN pattern with wildcards" do
      arn = fargate_attrs.arn_pattern
      expect(arn).to eq("arn:aws:ecs:*:*:cluster/fargate-cluster")
    end
  end
  
  describe "EcsCapacityProviderStrategy validation" do
    it "accepts valid strategy configuration" do
      strategy = Pangea::Resources::AWS::Types::EcsCapacityProviderStrategy.new({
        capacity_provider: "FARGATE",
        weight: 100,
        base: 2
      })
      
      expect(strategy.capacity_provider).to eq("FARGATE")
      expect(strategy.weight).to eq(100)
      expect(strategy.base).to eq(2)
    end
    
    it "accepts strategy with defaults" do
      strategy = Pangea::Resources::AWS::Types::EcsCapacityProviderStrategy.new({
        capacity_provider: "FARGATE_SPOT"
      })
      
      expect(strategy.capacity_provider).to eq("FARGATE_SPOT")
      expect(strategy.weight).to eq(1) # Default
      expect(strategy.base).to eq(0)    # Default
    end
    
    it "accepts zero weight with zero base" do
      expect {
        Pangea::Resources::AWS::Types::EcsCapacityProviderStrategy.new({
          capacity_provider: "FARGATE",
          weight: 0,
          base: 0
        })
      }.not_to raise_error
    end
    
    it "rejects base > 0 with weight = 0" do
      expect {
        Pangea::Resources::AWS::Types::EcsCapacityProviderStrategy.new({
          capacity_provider: "FARGATE",
          weight: 0,
          base: 1
        })
      }.to raise_error(Dry::Struct::Error, /Cannot have base > 0 with weight = 0/)
    end
    
    it "validates weight range" do
      expect {
        Pangea::Resources::AWS::Types::EcsCapacityProviderStrategy.new({
          capacity_provider: "FARGATE",
          weight: 1001
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
    
    it "validates base range" do
      expect {
        Pangea::Resources::AWS::Types::EcsCapacityProviderStrategy.new({
          capacity_provider: "FARGATE",
          base: 100001
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
  end
  
  describe "aws_ecs_cluster function" do
    it "creates basic ECS cluster" do
      result = test_instance.aws_ecs_cluster(:basic, {
        name: "basic-cluster"
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.type).to eq('aws_ecs_cluster')
      expect(result.name).to eq(:basic)
    end
    
    it "creates cluster with Fargate" do
      result = test_instance.aws_ecs_cluster(:fargate, {
        name: "fargate-cluster",
        capacity_providers: ["FARGATE"]
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.using_fargate?).to eq(true)
      expect(result.using_ec2?).to eq(false)
    end
    
    it "creates cluster with Container Insights" do
      result = test_instance.aws_ecs_cluster(:insights, {
        name: "insights-cluster",
        container_insights_enabled: true
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.insights_enabled?).to eq(true)
    end
    
    it "creates cluster with execute command configuration" do
      result = test_instance.aws_ecs_cluster(:exec, {
        name: "exec-cluster",
        configuration: {
          execute_command_configuration: {
            kms_key_id: kms_key_arn,
            logging: "OVERRIDE"
          }
        }
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
    end
    
    it "provides correct outputs" do
      result = test_instance.aws_ecs_cluster(:test, {
        name: "test-cluster"
      })
      
      expect(result.id).to eq("${aws_ecs_cluster.test.id}")
      expect(result.arn).to eq("${aws_ecs_cluster.test.arn}")
      expect(result.name).to eq("${aws_ecs_cluster.test.name}")
      expect(result.capacity_providers).to eq("${aws_ecs_cluster.test.capacity_providers}")
      expect(result.tags_all).to eq("${aws_ecs_cluster.test.tags_all}")
    end
    
    it "provides computed properties" do
      result = test_instance.aws_ecs_cluster(:test, {
        name: "test-cluster",
        capacity_providers: ["FARGATE"],
        container_insights_enabled: true
      })
      
      expect(result.using_fargate?).to eq(true)
      expect(result.using_ec2?).to eq(false)
      expect(result.insights_enabled?).to eq(true)
      expect(result.estimated_monthly_cost).to be > 0
      expect(result.arn_pattern("us-east-1", "123456789012")).to include("test-cluster")
    end
  end
  
  describe "cluster deployment patterns" do
    it "creates development cluster" do
      result = test_instance.aws_ecs_cluster(:dev, {
        name: "dev-cluster",
        capacity_providers: ["FARGATE"],
        container_insights_enabled: false,
        tags: {
          Environment: "development",
          Purpose: "testing"
        }
      })
      
      expect(result.using_fargate?).to eq(true)
      expect(result.insights_enabled?).to eq(false)
    end
    
    it "creates production cluster with full monitoring" do
      result = test_instance.aws_ecs_cluster(:prod, {
        name: "production-cluster",
        capacity_providers: ["FARGATE", "FARGATE_SPOT"],
        container_insights_enabled: true,
        configuration: {
          execute_command_configuration: {
            kms_key_id: kms_key_arn,
            logging: "OVERRIDE",
            log_configuration: {
              cloud_watch_encryption_enabled: true,
              cloud_watch_log_group_name: "/ecs/production"
            }
          }
        },
        service_connect_defaults: {
          namespace: "arn:aws:servicediscovery:us-east-1:123456789012:namespace/production"
        },
        tags: {
          Environment: "production",
          Security: "high",
          Monitoring: "enabled"
        }
      })
      
      expect(result.using_fargate?).to eq(true)
      expect(result.insights_enabled?).to eq(true)
      expect(result.estimated_monthly_cost).to eq(7.0)
    end
    
    it "creates hybrid cluster with EC2 and Fargate" do
      result = test_instance.aws_ecs_cluster(:hybrid, {
        name: "hybrid-cluster",
        capacity_providers: ["FARGATE", custom_provider_arn],
        container_insights_enabled: true,
        tags: {
          Environment: "production",
          Type: "hybrid",
          CostOptimized: "true"
        }
      })
      
      expect(result.using_fargate?).to eq(true)
      expect(result.using_ec2?).to eq(true)
      expect(result.insights_enabled?).to eq(true)
    end
  end
  
  describe "microservices platform patterns" do
    it "creates platform cluster for microservices" do
      result = test_instance.aws_ecs_cluster(:platform, {
        name: "microservices-platform",
        capacity_providers: ["FARGATE", "FARGATE_SPOT"],
        container_insights_enabled: true,
        configuration: {
          execute_command_configuration: {
            logging: "OVERRIDE",
            log_configuration: {
              cloud_watch_encryption_enabled: true,
              cloud_watch_log_group_name: "/ecs/microservices"
            }
          }
        },
        service_connect_defaults: {
          namespace: "arn:aws:servicediscovery:us-east-1:123456789012:namespace/microservices"
        },
        tags: {
          Environment: "production",
          Architecture: "microservices",
          ServiceMesh: "enabled",
          Platform: "ecs"
        }
      })
      
      expect(result.using_fargate?).to eq(true)
      expect(result.insights_enabled?).to eq(true)
      expect(result.estimated_monthly_cost).to eq(7.0) # Insights + Service Connect
    end
  end
  
  describe "security-focused patterns" do
    it "creates high-security cluster" do
      result = test_instance.aws_ecs_cluster(:secure, {
        name: "secure-cluster",
        capacity_providers: ["FARGATE"], # No Spot for security
        container_insights_enabled: true,
        configuration: {
          execute_command_configuration: {
            kms_key_id: kms_key_arn,
            logging: "OVERRIDE",
            log_configuration: {
              cloud_watch_encryption_enabled: true,
              cloud_watch_log_group_name: "/ecs/secure",
              s3_bucket_name: "secure-exec-logs",
              s3_bucket_encryption_enabled: true,
              s3_key_prefix: "cluster-logs/"
            }
          }
        },
        tags: {
          Environment: "production",
          Security: "high",
          Compliance: "required",
          Encryption: "enabled"
        }
      })
      
      expect(result.using_fargate?).to eq(true)
      expect(result.using_ec2?).to eq(false)
      expect(result.insights_enabled?).to eq(true)
    end
  end
  
  describe "cost optimization patterns" do
    it "creates cost-optimized cluster" do
      result = test_instance.aws_ecs_cluster(:cost_optimized, {
        name: "cost-optimized-cluster",
        capacity_providers: ["FARGATE_SPOT"], # Spot for cost savings
        container_insights_enabled: false,     # Disable for cost savings
        tags: {
          Environment: "development",
          CostOptimized: "true",
          Purpose: "testing"
        }
      })
      
      expect(result.using_fargate?).to eq(true)
      expect(result.insights_enabled?).to eq(false)
      expect(result.estimated_monthly_cost).to eq(0.0) # No additional services
    end
  end
end