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

# Load aws_batch_compute_environment resource and types for testing
require 'pangea/resources/aws_batch_compute_environment/resource'
require 'pangea/resources/aws_batch_compute_environment/types'

RSpec.describe "aws_batch_compute_environment resource function" do
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
  
  # Test ARN values and IDs for various resources
  let(:service_role_arn) { "arn:aws:iam::123456789012:role/aws-batch-service-role" }
  let(:instance_role_arn) { "arn:aws:iam::123456789012:role/ecsInstanceRole" }
  let(:spot_fleet_role_arn) { "arn:aws:iam::123456789012:role/aws-ec2-spot-fleet-role" }
  let(:subnet_ids) { ["subnet-12345678", "subnet-87654321"] }
  let(:security_group_ids) { ["sg-12345678", "sg-87654321"] }
  let(:launch_template_id) { "lt-12345678" }
  let(:vpc_config) do
    {
      subnets: subnet_ids,
      security_group_ids: security_group_ids
    }
  end

  describe "BatchComputeEnvironmentAttributes validation" do
    it "accepts basic MANAGED environment with EC2 compute resources" do
      env = Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
        compute_environment_name: "basic-managed-env",
        type: "MANAGED",
        service_role: service_role_arn,
        compute_resources: {
          type: "EC2",
          min_vcpus: 0,
          max_vcpus: 100,
          instance_types: ["optimal"],
          subnets: subnet_ids,
          security_group_ids: security_group_ids,
          instance_role: instance_role_arn
        }
      })
      
      expect(env.compute_environment_name).to eq("basic-managed-env")
      expect(env.type).to eq("MANAGED")
      expect(env.is_managed?).to be true
      expect(env.is_unmanaged?).to be false
      expect(env.supports_ec2?).to be true
      expect(env.supports_fargate?).to be false
      expect(env.is_spot_based?).to be false
    end
    
    it "accepts MANAGED environment with SPOT compute resources" do
      env = Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
        compute_environment_name: "spot-managed-env",
        type: "MANAGED",
        service_role: service_role_arn,
        compute_resources: {
          type: "SPOT",
          allocation_strategy: "SPOT_CAPACITY_OPTIMIZED",
          min_vcpus: 0,
          max_vcpus: 200,
          bid_percentage: 50,
          instance_types: ["m5.large", "m5.xlarge"],
          spot_iam_fleet_request_role: spot_fleet_role_arn,
          subnets: subnet_ids,
          security_group_ids: security_group_ids,
          instance_role: instance_role_arn
        }
      })
      
      expect(env.supports_ec2?).to be true
      expect(env.is_spot_based?).to be true
      expect(env.compute_resources[:type]).to eq("SPOT")
      expect(env.compute_resources[:bid_percentage]).to eq(50)
    end
    
    it "accepts MANAGED environment with FARGATE compute resources" do
      env = Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
        compute_environment_name: "fargate-env",
        type: "MANAGED",
        service_role: service_role_arn,
        compute_resources: {
          type: "FARGATE",
          max_vcpus: 100,
          subnets: subnet_ids,
          security_group_ids: security_group_ids,
          platform_capabilities: ["FARGATE"]
        }
      })
      
      expect(env.supports_fargate?).to be true
      expect(env.supports_ec2?).to be false
      expect(env.compute_resources[:platform_capabilities]).to include("FARGATE")
    end
    
    it "accepts MANAGED environment with FARGATE_SPOT compute resources" do
      env = Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
        compute_environment_name: "fargate-spot-env",
        type: "MANAGED",
        service_role: service_role_arn,
        compute_resources: {
          type: "FARGATE_SPOT",
          max_vcpus: 150,
          subnets: subnet_ids,
          security_group_ids: security_group_ids,
          platform_capabilities: ["FARGATE"]
        }
      })
      
      expect(env.supports_fargate?).to be true
      expect(env.is_spot_based?).to be true
      expect(env.compute_resources[:type]).to eq("FARGATE_SPOT")
    end
    
    it "accepts UNMANAGED environment without compute resources" do
      env = Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
        compute_environment_name: "unmanaged-env",
        type: "UNMANAGED",
        service_role: service_role_arn
      })
      
      expect(env.is_unmanaged?).to be true
      expect(env.is_managed?).to be false
      expect(env.compute_resources).to be_nil
    end
    
    it "accepts environment with DISABLED state" do
      env = Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
        compute_environment_name: "disabled-env",
        type: "MANAGED",
        state: "DISABLED",
        service_role: service_role_arn,
        compute_resources: {
          type: "EC2",
          max_vcpus: 50,
          subnets: subnet_ids,
          security_group_ids: security_group_ids,
          instance_role: instance_role_arn
        }
      })
      
      expect(env.state).to eq("DISABLED")
      expect(env.is_disabled?).to be true
      expect(env.is_enabled?).to be false
    end
    
    it "defaults state to ENABLED when not specified" do
      env = Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
        compute_environment_name: "default-enabled-env",
        type: "MANAGED",
        service_role: service_role_arn,
        compute_resources: {
          type: "EC2",
          max_vcpus: 50,
          subnets: subnet_ids,
          security_group_ids: security_group_ids,
          instance_role: instance_role_arn
        }
      })
      
      expect(env.state).to eq("ENABLED")
      expect(env.is_enabled?).to be true
    end
    
    it "accepts environment with tags" do
      env = Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
        compute_environment_name: "tagged-env",
        type: "MANAGED",
        service_role: service_role_arn,
        compute_resources: {
          type: "EC2",
          max_vcpus: 100,
          subnets: subnet_ids,
          security_group_ids: security_group_ids,
          instance_role: instance_role_arn,
          tags: {
            "Team" => "backend",
            "Environment" => "production"
          }
        },
        tags: {
          "Project" => "batch-processing",
          "CostCenter" => "engineering"
        }
      })
      
      expect(env.compute_resources[:tags]["Team"]).to eq("backend")
      expect(env.tags["Project"]).to eq("batch-processing")
    end
    
    it "accepts environment with launch template configuration" do
      env = Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
        compute_environment_name: "launch-template-env",
        type: "MANAGED",
        service_role: service_role_arn,
        compute_resources: {
          type: "EC2",
          max_vcpus: 100,
          subnets: subnet_ids,
          security_group_ids: security_group_ids,
          instance_role: instance_role_arn,
          launch_template: {
            launch_template_id: launch_template_id,
            version: "$Latest"
          }
        }
      })
      
      lt = env.compute_resources[:launch_template]
      expect(lt[:launch_template_id]).to eq(launch_template_id)
      expect(lt[:version]).to eq("$Latest")
    end
    
    it "accepts environment with custom AMI and key pair" do
      env = Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
        compute_environment_name: "custom-ami-env",
        type: "MANAGED",
        service_role: service_role_arn,
        compute_resources: {
          type: "EC2",
          max_vcpus: 100,
          subnets: subnet_ids,
          security_group_ids: security_group_ids,
          instance_role: instance_role_arn,
          image_id: "ami-12345678",
          ec2_key_pair: "my-key-pair"
        }
      })
      
      expect(env.compute_resources[:image_id]).to eq("ami-12345678")
      expect(env.compute_resources[:ec2_key_pair]).to eq("my-key-pair")
    end
  end

  describe "compute environment name validation" do
    it "accepts valid compute environment names" do
      valid_names = [
        "basic-env",
        "my_env_123",
        "ComputeEnvironment",
        "a",
        "a" * 128  # Exactly 128 characters
      ]
      
      valid_names.each do |name|
        expect {
          Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
            compute_environment_name: name,
            type: "UNMANAGED"
          })
        }.not_to raise_error, "Failed for name: #{name}"
      end
    end
    
    it "rejects invalid compute environment names" do
      invalid_names = [
        "",                    # Empty string
        "a" * 129,            # Too long (129 characters)
        "invalid@name",       # Invalid character @
        "invalid.name",       # Invalid character .
        "invalid name",       # Space not allowed
        "invalid/name",       # Invalid character /
        "invalid#name"        # Invalid character #
      ]
      
      invalid_names.each do |name|
        expect {
          Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
            compute_environment_name: name,
            type: "UNMANAGED"
          })
        }.to raise_error(Dry::Struct::Error), "Should have failed for name: #{name}"
      end
    end
  end

  describe "compute environment type validation" do
    it "accepts valid environment types" do
      ["MANAGED", "UNMANAGED"].each do |type|
        expect {
          Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
            compute_environment_name: "test-env",
            type: type
          })
        }.not_to raise_error, "Failed for type: #{type}"
      end
    end
    
    it "rejects invalid environment types" do
      ["managed", "unmanaged", "INVALID", "AUTO", ""].each do |type|
        expect {
          Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
            compute_environment_name: "test-env",
            type: type
          })
        }.to raise_error(Dry::Struct::Error), "Should have failed for type: #{type}"
      end
    end
  end

  describe "state validation" do
    it "accepts valid states" do
      ["ENABLED", "DISABLED"].each do |state|
        expect {
          Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
            compute_environment_name: "test-env",
            type: "UNMANAGED",
            state: state
          })
        }.not_to raise_error, "Failed for state: #{state}"
      end
    end
    
    it "rejects invalid states" do
      ["enabled", "disabled", "ACTIVE", "INACTIVE", ""].each do |state|
        expect {
          Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
            compute_environment_name: "test-env",
            type: "UNMANAGED",
            state: state
          })
        }.to raise_error(Dry::Struct::Error), "Should have failed for state: #{state}"
      end
    end
  end

  describe "compute resources validation" do
    it "rejects UNMANAGED environment with compute resources" do
      expect {
        Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
          compute_environment_name: "invalid-unmanaged",
          type: "UNMANAGED",
          compute_resources: {
            type: "EC2",
            max_vcpus: 100
          }
        })
      }.to raise_error(Dry::Struct::Error, /UNMANAGED compute environments cannot have compute_resources/)
    end
    
    it "validates compute resource types" do
      ["EC2", "SPOT", "FARGATE", "FARGATE_SPOT"].each do |resource_type|
        expect {
          Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
            compute_environment_name: "test-env",
            type: "MANAGED",
            service_role: service_role_arn,
            compute_resources: {
              type: resource_type,
              max_vcpus: 100,
              subnets: subnet_ids,
              security_group_ids: security_group_ids,
              instance_role: resource_type.include?("FARGATE") ? nil : instance_role_arn,
              spot_iam_fleet_request_role: resource_type == "SPOT" ? spot_fleet_role_arn : nil,
              platform_capabilities: resource_type.include?("FARGATE") ? ["FARGATE"] : nil
            }
          })
        }.not_to raise_error, "Failed for resource type: #{resource_type}"
      end
    end
    
    it "rejects invalid compute resource types" do
      ["ec2", "spot", "fargate", "INVALID", "LAMBDA", ""].each do |resource_type|
        expect {
          Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
            compute_environment_name: "test-env",
            type: "MANAGED",
            service_role: service_role_arn,
            compute_resources: {
              type: resource_type,
              max_vcpus: 100,
              subnets: subnet_ids,
              security_group_ids: security_group_ids
            }
          })
        }.to raise_error(Dry::Struct::Error), "Should have failed for resource type: #{resource_type}"
      end
    end
    
    it "validates allocation strategies for EC2 compute resources" do
      ["BEST_FIT", "BEST_FIT_PROGRESSIVE", "SPOT_CAPACITY_OPTIMIZED"].each do |strategy|
        expect {
          Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
            compute_environment_name: "test-env",
            type: "MANAGED",
            service_role: service_role_arn,
            compute_resources: {
              type: "EC2",
              allocation_strategy: strategy,
              max_vcpus: 100,
              subnets: subnet_ids,
              security_group_ids: security_group_ids,
              instance_role: instance_role_arn
            }
          })
        }.not_to raise_error, "Failed for EC2 allocation strategy: #{strategy}"
      end
    end
    
    it "validates allocation strategies for SPOT compute resources" do
      ["BEST_FIT", "BEST_FIT_PROGRESSIVE", "SPOT_CAPACITY_OPTIMIZED"].each do |strategy|
        expect {
          Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
            compute_environment_name: "test-env",
            type: "MANAGED",
            service_role: service_role_arn,
            compute_resources: {
              type: "SPOT",
              allocation_strategy: strategy,
              max_vcpus: 100,
              subnets: subnet_ids,
              security_group_ids: security_group_ids,
              instance_role: instance_role_arn,
              spot_iam_fleet_request_role: spot_fleet_role_arn
            }
          })
        }.not_to raise_error, "Failed for SPOT allocation strategy: #{strategy}"
      end
    end
    
    it "validates allocation strategies for FARGATE compute resources" do
      expect {
        Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
          compute_environment_name: "test-env",
          type: "MANAGED",
          service_role: service_role_arn,
          compute_resources: {
            type: "FARGATE",
            allocation_strategy: "SPOT_CAPACITY_OPTIMIZED",
            max_vcpus: 100,
            subnets: subnet_ids,
            security_group_ids: security_group_ids,
            platform_capabilities: ["FARGATE"]
          }
        })
      }.not_to raise_error
    end
    
    it "rejects invalid allocation strategies for compute resource types" do
      expect {
        Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
          compute_environment_name: "test-env",
          type: "MANAGED",
          service_role: service_role_arn,
          compute_resources: {
            type: "FARGATE",
            allocation_strategy: "BEST_FIT",  # Invalid for FARGATE
            max_vcpus: 100,
            subnets: subnet_ids,
            security_group_ids: security_group_ids
          }
        })
      }.to raise_error(Dry::Struct::Error, /Invalid allocation strategy/)
    end
  end

  describe "vCPU validation" do
    it "validates min_vcpus must be non-negative" do
      expect {
        Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
          compute_environment_name: "test-env",
          type: "MANAGED",
          service_role: service_role_arn,
          compute_resources: {
            type: "EC2",
            min_vcpus: -1,
            max_vcpus: 100,
            subnets: subnet_ids,
            security_group_ids: security_group_ids,
            instance_role: instance_role_arn
          }
        })
      }.to raise_error(Dry::Struct::Error, /min_vcpus must be non-negative/)
    end
    
    it "validates max_vcpus must be non-negative" do
      expect {
        Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
          compute_environment_name: "test-env",
          type: "MANAGED",
          service_role: service_role_arn,
          compute_resources: {
            type: "EC2",
            max_vcpus: -1,
            subnets: subnet_ids,
            security_group_ids: security_group_ids,
            instance_role: instance_role_arn
          }
        })
      }.to raise_error(Dry::Struct::Error, /max_vcpus must be non-negative/)
    end
    
    it "validates desired_vcpus must be non-negative" do
      expect {
        Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
          compute_environment_name: "test-env",
          type: "MANAGED",
          service_role: service_role_arn,
          compute_resources: {
            type: "EC2",
            desired_vcpus: -1,
            max_vcpus: 100,
            subnets: subnet_ids,
            security_group_ids: security_group_ids,
            instance_role: instance_role_arn
          }
        })
      }.to raise_error(Dry::Struct::Error, /desired_vcpus must be non-negative/)
    end
    
    it "validates min_vcpus cannot be greater than max_vcpus" do
      expect {
        Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
          compute_environment_name: "test-env",
          type: "MANAGED",
          service_role: service_role_arn,
          compute_resources: {
            type: "EC2",
            min_vcpus: 100,
            max_vcpus: 50,
            subnets: subnet_ids,
            security_group_ids: security_group_ids,
            instance_role: instance_role_arn
          }
        })
      }.to raise_error(Dry::Struct::Error, /min_vcpus cannot be greater than max_vcpus/)
    end
    
    it "validates desired_vcpus cannot be greater than max_vcpus" do
      expect {
        Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
          compute_environment_name: "test-env",
          type: "MANAGED",
          service_role: service_role_arn,
          compute_resources: {
            type: "EC2",
            desired_vcpus: 150,
            max_vcpus: 100,
            subnets: subnet_ids,
            security_group_ids: security_group_ids,
            instance_role: instance_role_arn
          }
        })
      }.to raise_error(Dry::Struct::Error, /desired_vcpus cannot be greater than max_vcpus/)
    end
    
    it "accepts zero min_vcpus for cost optimization" do
      expect {
        Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
          compute_environment_name: "cost-optimized-env",
          type: "MANAGED",
          service_role: service_role_arn,
          compute_resources: {
            type: "EC2",
            min_vcpus: 0,
            max_vcpus: 100,
            desired_vcpus: 0,
            subnets: subnet_ids,
            security_group_ids: security_group_ids,
            instance_role: instance_role_arn
          }
        })
      }.not_to raise_error
    end
  end

  describe "instance type validation" do
    it "accepts 'optimal' instance type selection" do
      expect {
        Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
          compute_environment_name: "optimal-env",
          type: "MANAGED",
          service_role: service_role_arn,
          compute_resources: {
            type: "EC2",
            instance_types: ["optimal"],
            max_vcpus: 100,
            subnets: subnet_ids,
            security_group_ids: security_group_ids,
            instance_role: instance_role_arn
          }
        })
      }.not_to raise_error
    end
    
    it "accepts specific instance types" do
      instance_types = ["m5.large", "m5.xlarge", "c5.xlarge", "r5.large"]
      expect {
        Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
          compute_environment_name: "specific-instances-env",
          type: "MANAGED",
          service_role: service_role_arn,
          compute_resources: {
            type: "EC2",
            instance_types: instance_types,
            max_vcpus: 100,
            subnets: subnet_ids,
            security_group_ids: security_group_ids,
            instance_role: instance_role_arn
          }
        })
      }.not_to raise_error
    end
    
    it "rejects invalid instance type format" do
      expect {
        Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
          compute_environment_name: "invalid-instances-env",
          type: "MANAGED",
          service_role: service_role_arn,
          compute_resources: {
            type: "EC2",
            instance_types: ["invalid-format"],
            max_vcpus: 100,
            subnets: subnet_ids,
            security_group_ids: security_group_ids,
            instance_role: instance_role_arn
          }
        })
      }.to raise_error(Dry::Struct::Error, /Invalid instance type format/)
    end
    
    it "rejects non-array instance types" do
      expect {
        Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
          compute_environment_name: "invalid-instances-env",
          type: "MANAGED",
          service_role: service_role_arn,
          compute_resources: {
            type: "EC2",
            instance_types: "m5.large",  # Should be array
            max_vcpus: 100,
            subnets: subnet_ids,
            security_group_ids: security_group_ids,
            instance_role: instance_role_arn
          }
        })
      }.to raise_error(Dry::Struct::Error, /Instance types must be an array/)
    end
  end

  describe "spot configuration validation" do
    it "requires spot_iam_fleet_request_role for SPOT compute resources" do
      expect {
        Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
          compute_environment_name: "spot-env",
          type: "MANAGED",
          service_role: service_role_arn,
          compute_resources: {
            type: "SPOT",
            max_vcpus: 100,
            subnets: subnet_ids,
            security_group_ids: security_group_ids,
            instance_role: instance_role_arn
            # Missing spot_iam_fleet_request_role
          }
        })
      }.to raise_error(Dry::Struct::Error, /SPOT compute resources require spot_iam_fleet_request_role/)
    end
    
    it "accepts spot configuration with bid percentage" do
      expect {
        Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
          compute_environment_name: "spot-bid-env",
          type: "MANAGED",
          service_role: service_role_arn,
          compute_resources: {
            type: "SPOT",
            max_vcpus: 100,
            bid_percentage: 75,
            spot_iam_fleet_request_role: spot_fleet_role_arn,
            subnets: subnet_ids,
            security_group_ids: security_group_ids,
            instance_role: instance_role_arn
          }
        })
      }.not_to raise_error
    end
  end

  describe "Fargate configuration validation" do
    it "requires FARGATE platform capability for Fargate compute resources" do
      expect {
        Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
          compute_environment_name: "fargate-env",
          type: "MANAGED",
          service_role: service_role_arn,
          compute_resources: {
            type: "FARGATE",
            max_vcpus: 100,
            subnets: subnet_ids,
            security_group_ids: security_group_ids,
            platform_capabilities: ["EC2"]  # Should be FARGATE
          }
        })
      }.to raise_error(Dry::Struct::Error, /Fargate compute resources must include FARGATE platform capability/)
    end
    
    it "accepts valid Fargate configuration" do
      expect {
        Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
          compute_environment_name: "fargate-env",
          type: "MANAGED",
          service_role: service_role_arn,
          compute_resources: {
            type: "FARGATE",
            max_vcpus: 100,
            subnets: subnet_ids,
            security_group_ids: security_group_ids,
            platform_capabilities: ["FARGATE"]
          }
        })
      }.not_to raise_error
    end
  end

  describe "template system" do
    describe "ec2_managed_environment template" do
      it "creates valid EC2 managed environment configuration" do
        config = Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.ec2_managed_environment(
          "ec2-batch-env",
          vpc_config,
          {
            min_vcpus: 10,
            max_vcpus: 500,
            desired_vcpus: 50,
            instance_types: ["m5.large", "m5.xlarge"],
            instance_role: instance_role_arn
          }
        )
        
        expect(config[:compute_environment_name]).to eq("ec2-batch-env")
        expect(config[:type]).to eq("MANAGED")
        expect(config[:state]).to eq("ENABLED")
        expect(config[:compute_resources][:type]).to eq("EC2")
        expect(config[:compute_resources][:allocation_strategy]).to eq("BEST_FIT_PROGRESSIVE")
        expect(config[:compute_resources][:min_vcpus]).to eq(10)
        expect(config[:compute_resources][:max_vcpus]).to eq(500)
        expect(config[:compute_resources][:instance_types]).to eq(["m5.large", "m5.xlarge"])
      end
      
      it "uses defaults when options not provided" do
        config = Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.ec2_managed_environment(
          "default-ec2-env",
          vpc_config
        )
        
        expect(config[:compute_resources][:min_vcpus]).to eq(0)
        expect(config[:compute_resources][:max_vcpus]).to eq(100)
        expect(config[:compute_resources][:desired_vcpus]).to eq(0)
        expect(config[:compute_resources][:instance_types]).to eq(["optimal"])
      end
    end
    
    describe "spot_managed_environment template" do
      it "creates valid SPOT managed environment configuration" do
        config = Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.spot_managed_environment(
          "spot-batch-env",
          vpc_config,
          {
            min_vcpus: 0,
            max_vcpus: 1000,
            desired_vcpus: 0,
            instance_types: ["m5.large", "c5.large"],
            spot_iam_fleet_request_role: spot_fleet_role_arn,
            bid_percentage: 30,
            instance_role: instance_role_arn
          }
        )
        
        expect(config[:compute_resources][:type]).to eq("SPOT")
        expect(config[:compute_resources][:allocation_strategy]).to eq("SPOT_CAPACITY_OPTIMIZED")
        expect(config[:compute_resources][:bid_percentage]).to eq(30)
        expect(config[:compute_resources][:spot_iam_fleet_request_role]).to eq(spot_fleet_role_arn)
      end
      
      it "uses default bid percentage when not provided" do
        config = Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.spot_managed_environment(
          "default-spot-env",
          vpc_config,
          {
            spot_iam_fleet_request_role: spot_fleet_role_arn,
            instance_role: instance_role_arn
          }
        )
        
        expect(config[:compute_resources][:bid_percentage]).to eq(50)
      end
    end
    
    describe "fargate_managed_environment template" do
      it "creates valid Fargate managed environment configuration" do
        config = Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.fargate_managed_environment(
          "fargate-batch-env",
          vpc_config,
          {
            max_vcpus: 200,
            tags: { "Platform" => "serverless" }
          }
        )
        
        expect(config[:compute_resources][:type]).to eq("FARGATE")
        expect(config[:compute_resources][:max_vcpus]).to eq(200)
        expect(config[:compute_resources][:platform_capabilities]).to eq(["FARGATE"])
        expect(config[:compute_resources][:tags]["Platform"]).to eq("serverless")
      end
    end
    
    describe "fargate_spot_managed_environment template" do
      it "creates valid Fargate Spot managed environment configuration" do
        config = Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.fargate_spot_managed_environment(
          "fargate-spot-env",
          vpc_config,
          {
            max_vcpus: 300,
            tags: { "Cost" => "optimized" }
          }
        )
        
        expect(config[:compute_resources][:type]).to eq("FARGATE_SPOT")
        expect(config[:compute_resources][:max_vcpus]).to eq(300)
        expect(config[:compute_resources][:platform_capabilities]).to eq(["FARGATE"])
        expect(config[:compute_resources][:tags]["Cost"]).to eq("optimized")
      end
    end
    
    describe "unmanaged_environment template" do
      it "creates valid unmanaged environment configuration" do
        config = Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.unmanaged_environment(
          "unmanaged-env",
          {
            service_role: service_role_arn,
            state: "DISABLED",
            tags: { "Type" => "custom" }
          }
        )
        
        expect(config[:compute_environment_name]).to eq("unmanaged-env")
        expect(config[:type]).to eq("UNMANAGED")
        expect(config[:state]).to eq("DISABLED")
        expect(config[:service_role]).to eq(service_role_arn)
        expect(config[:tags]["Type"]).to eq("custom")
      end
      
      it "uses defaults when options not provided" do
        config = Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.unmanaged_environment(
          "default-unmanaged"
        )
        
        expect(config[:state]).to eq("ENABLED")
        expect(config[:tags]).to eq({})
      end
    end
  end

  describe "instance type helpers" do
    describe "compute_optimized_instances" do
      it "returns array of compute optimized instance types" do
        instances = Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.compute_optimized_instances
        
        expect(instances).to be_an(Array)
        expect(instances).to include("c5.large", "c5.xlarge", "c6i.large")
        expect(instances.all? { |i| i.match?(/^c[0-9]/) }).to be true
      end
    end
    
    describe "memory_optimized_instances" do
      it "returns array of memory optimized instance types" do
        instances = Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.memory_optimized_instances
        
        expect(instances).to be_an(Array)
        expect(instances).to include("r5.large", "r5.xlarge", "r6i.large")
        expect(instances.all? { |i| i.match?(/^r[0-9]/) }).to be true
      end
    end
    
    describe "general_purpose_instances" do
      it "returns array of general purpose instance types" do
        instances = Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.general_purpose_instances
        
        expect(instances).to be_an(Array)
        expect(instances).to include("m5.large", "m5.xlarge", "m6i.large")
        expect(instances.all? { |i| i.match?(/^m[0-9]/) }).to be true
      end
    end
    
    describe "gpu_instances" do
      it "returns array of GPU instance types" do
        instances = Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.gpu_instances
        
        expect(instances).to be_an(Array)
        expect(instances).to include("p3.2xlarge", "g4dn.xlarge")
        expect(instances.any? { |i| i.match?(/^[pg][0-9]/) }).to be true
      end
    end
  end

  describe "VPC configuration validation" do
    it "validates VPC configuration structure" do
      expect {
        Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.validate_vpc_configuration("not-a-hash")
      }.to raise_error(Dry::Struct::Error, /VPC configuration must be a hash/)
    end
    
    it "validates subnets array is present and non-empty" do
      expect {
        Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.validate_vpc_configuration({
          security_group_ids: security_group_ids
          # Missing subnets
        })
      }.to raise_error(Dry::Struct::Error, /must include non-empty subnets array/)
      
      expect {
        Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.validate_vpc_configuration({
          subnets: [],  # Empty array
          security_group_ids: security_group_ids
        })
      }.to raise_error(Dry::Struct::Error, /must include non-empty subnets array/)
    end
    
    it "validates security_group_ids array is present and non-empty" do
      expect {
        Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.validate_vpc_configuration({
          subnets: subnet_ids
          # Missing security_group_ids
        })
      }.to raise_error(Dry::Struct::Error, /must include non-empty security_group_ids array/)
      
      expect {
        Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.validate_vpc_configuration({
          subnets: subnet_ids,
          security_group_ids: []  # Empty array
        })
      }.to raise_error(Dry::Struct::Error, /must include non-empty security_group_ids array/)
    end
    
    it "accepts valid VPC configuration" do
      expect {
        Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.validate_vpc_configuration(vpc_config)
      }.not_to raise_error
    end
  end

  describe "computed properties" do
    let(:managed_ec2_env) do
      Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
        compute_environment_name: "managed-ec2",
        type: "MANAGED",
        state: "ENABLED",
        service_role: service_role_arn,
        compute_resources: {
          type: "EC2",
          max_vcpus: 100,
          subnets: subnet_ids,
          security_group_ids: security_group_ids,
          instance_role: instance_role_arn
        }
      })
    end
    
    let(:managed_spot_env) do
      Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
        compute_environment_name: "managed-spot",
        type: "MANAGED",
        compute_resources: {
          type: "SPOT",
          max_vcpus: 200,
          spot_iam_fleet_request_role: spot_fleet_role_arn,
          subnets: subnet_ids,
          security_group_ids: security_group_ids,
          instance_role: instance_role_arn
        }
      })
    end
    
    let(:managed_fargate_env) do
      Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
        compute_environment_name: "managed-fargate",
        type: "MANAGED",
        compute_resources: {
          type: "FARGATE",
          max_vcpus: 150,
          subnets: subnet_ids,
          security_group_ids: security_group_ids,
          platform_capabilities: ["FARGATE"]
        }
      })
    end
    
    let(:unmanaged_env) do
      Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.new({
        compute_environment_name: "unmanaged",
        type: "UNMANAGED",
        state: "DISABLED"
      })
    end
    
    it "correctly identifies managed vs unmanaged environments" do
      expect(managed_ec2_env.is_managed?).to be true
      expect(managed_ec2_env.is_unmanaged?).to be false
      
      expect(unmanaged_env.is_managed?).to be false
      expect(unmanaged_env.is_unmanaged?).to be true
    end
    
    it "correctly identifies enabled vs disabled environments" do
      expect(managed_ec2_env.is_enabled?).to be true
      expect(managed_ec2_env.is_disabled?).to be false
      
      expect(unmanaged_env.is_enabled?).to be false
      expect(unmanaged_env.is_disabled?).to be true
    end
    
    it "correctly identifies EC2 support" do
      expect(managed_ec2_env.supports_ec2?).to be true
      expect(managed_spot_env.supports_ec2?).to be true
      expect(managed_fargate_env.supports_ec2?).to be false
      expect(unmanaged_env.supports_ec2?).to be false
    end
    
    it "correctly identifies Fargate support" do
      expect(managed_ec2_env.supports_fargate?).to be false
      expect(managed_spot_env.supports_fargate?).to be false
      expect(managed_fargate_env.supports_fargate?).to be true
      expect(unmanaged_env.supports_fargate?).to be false
    end
    
    it "correctly identifies spot-based environments" do
      expect(managed_ec2_env.is_spot_based?).to be false
      expect(managed_spot_env.is_spot_based?).to be true
      expect(managed_fargate_env.is_spot_based?).to be false
      expect(unmanaged_env.is_spot_based?).to be false
    end
  end

  describe "resource function integration" do
    it "returns ResourceReference" do
      ref = test_instance.aws_batch_compute_environment(:test_env, {
        compute_environment_name: "test-environment",
        type: "MANAGED",
        service_role: service_role_arn,
        compute_resources: {
          type: "EC2",
          max_vcpus: 100,
          subnets: subnet_ids,
          security_group_ids: security_group_ids,
          instance_role: instance_role_arn
        }
      })
      
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.name).to eq(:test_env)
      expect(ref.resource_type).to eq(:aws_batch_compute_environment)
    end
    
    it "handles comprehensive EC2 managed environment" do
      expect {
        test_instance.aws_batch_compute_environment(:comprehensive_ec2, {
          compute_environment_name: "comprehensive-ec2-env",
          type: "MANAGED",
          state: "ENABLED",
          service_role: service_role_arn,
          compute_resources: {
            type: "EC2",
            allocation_strategy: "BEST_FIT_PROGRESSIVE",
            min_vcpus: 10,
            max_vcpus: 500,
            desired_vcpus: 50,
            instance_types: ["m5.large", "m5.xlarge", "c5.large"],
            instance_role: instance_role_arn,
            subnets: subnet_ids,
            security_group_ids: security_group_ids,
            ec2_key_pair: "my-batch-key",
            image_id: "ami-12345678",
            launch_template: {
              launch_template_id: launch_template_id,
              version: "$Latest"
            },
            tags: {
              "Team" => "data-engineering",
              "Environment" => "production"
            }
          },
          tags: {
            "Project" => "batch-compute",
            "CostCenter" => "engineering"
          }
        })
      }.not_to raise_error
    end
    
    it "handles SPOT environment with all configuration options" do
      expect {
        test_instance.aws_batch_compute_environment(:spot_env, {
          compute_environment_name: "spot-compute-env",
          type: "MANAGED",
          service_role: service_role_arn,
          compute_resources: {
            type: "SPOT",
            allocation_strategy: "SPOT_CAPACITY_OPTIMIZED",
            min_vcpus: 0,
            max_vcpus: 1000,
            desired_vcpus: 0,
            instance_types: ["m5.large", "c5.large", "r5.large"],
            spot_iam_fleet_request_role: spot_fleet_role_arn,
            bid_percentage: 40,
            instance_role: instance_role_arn,
            subnets: subnet_ids,
            security_group_ids: security_group_ids,
            tags: {
              "SpotOptimized" => "true",
              "CostSavings" => "high"
            }
          }
        })
      }.not_to raise_error
    end
    
    it "handles Fargate environment configuration" do
      expect {
        test_instance.aws_batch_compute_environment(:fargate_env, {
          compute_environment_name: "fargate-serverless-env",
          type: "MANAGED",
          service_role: service_role_arn,
          compute_resources: {
            type: "FARGATE",
            max_vcpus: 200,
            subnets: subnet_ids,
            security_group_ids: security_group_ids,
            platform_capabilities: ["FARGATE"],
            tags: {
              "Platform" => "serverless",
              "Scaling" => "automatic"
            }
          }
        })
      }.not_to raise_error
    end
    
    it "handles Fargate Spot environment configuration" do
      expect {
        test_instance.aws_batch_compute_environment(:fargate_spot_env, {
          compute_environment_name: "fargate-spot-env",
          type: "MANAGED",
          service_role: service_role_arn,
          compute_resources: {
            type: "FARGATE_SPOT",
            max_vcpus: 300,
            subnets: subnet_ids,
            security_group_ids: security_group_ids,
            platform_capabilities: ["FARGATE"],
            tags: {
              "Platform" => "serverless-spot",
              "CostOptimization" => "maximum"
            }
          }
        })
      }.not_to raise_error
    end
    
    it "handles UNMANAGED environment configuration" do
      expect {
        test_instance.aws_batch_compute_environment(:unmanaged_env, {
          compute_environment_name: "custom-ecs-cluster",
          type: "UNMANAGED",
          service_role: service_role_arn,
          tags: {
            "Management" => "manual",
            "Integration" => "ecs-cluster"
          }
        })
      }.not_to raise_error
    end
  end

  describe "edge cases and error handling" do
    it "handles validation errors gracefully" do
      expect {
        test_instance.aws_batch_compute_environment(:invalid_env, {
          compute_environment_name: "invalid@environment",
          type: "MANAGED",
          service_role: service_role_arn,
          compute_resources: {
            type: "EC2",
            max_vcpus: 100
          }
        })
      }.to raise_error(Dry::Struct::Error, /can only contain letters, numbers, hyphens, and underscores/)
    end
    
    it "handles missing required fields for managed environments" do
      expect {
        test_instance.aws_batch_compute_environment(:incomplete_managed, {
          compute_environment_name: "incomplete-managed",
          type: "MANAGED"
          # Missing compute_resources
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "handles invalid compute resource configuration" do
      expect {
        test_instance.aws_batch_compute_environment(:invalid_compute, {
          compute_environment_name: "invalid-compute",
          type: "MANAGED",
          service_role: service_role_arn,
          compute_resources: {
            type: "INVALID_TYPE",
            max_vcpus: 100
          }
        })
      }.to raise_error(Dry::Struct::Error, /must be one of: EC2, SPOT, FARGATE, FARGATE_SPOT/)
    end
    
    it "handles empty attributes hash" do
      expect {
        test_instance.aws_batch_compute_environment(:empty_env, {})
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "handles nil attributes" do
      expect {
        test_instance.aws_batch_compute_environment(:nil_env, nil)
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "handles invalid vCPU relationships" do
      expect {
        test_instance.aws_batch_compute_environment(:invalid_vcpu, {
          compute_environment_name: "invalid-vcpu-env",
          type: "MANAGED",
          service_role: service_role_arn,
          compute_resources: {
            type: "EC2",
            min_vcpus: 100,
            max_vcpus: 50,  # Invalid: min > max
            subnets: subnet_ids,
            security_group_ids: security_group_ids,
            instance_role: instance_role_arn
          }
        })
      }.to raise_error(Dry::Struct::Error, /min_vcpus cannot be greater than max_vcpus/)
    end
    
    it "handles configuration conflicts" do
      expect {
        test_instance.aws_batch_compute_environment(:conflict_env, {
          compute_environment_name: "conflict-env",
          type: "UNMANAGED",
          compute_resources: {
            type: "EC2",
            max_vcpus: 100
          }
        })
      }.to raise_error(Dry::Struct::Error, /UNMANAGED compute environments cannot have compute_resources/)
    end
  end
end