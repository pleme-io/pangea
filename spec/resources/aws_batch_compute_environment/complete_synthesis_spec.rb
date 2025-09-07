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

# Load aws_batch_compute_environment resource and terraform-synthesizer for testing
require 'pangea/resources/aws_batch_compute_environment/resource'
require 'terraform-synthesizer'

RSpec.describe "aws_batch_compute_environment terraform synthesis" do
  let(:synthesizer) { TerraformSynthesizer.new }
  
  # Test ARN values and IDs for various resources
  let(:service_role_arn) { "arn:aws:iam::123456789012:role/aws-batch-service-role" }
  let(:instance_role_arn) { "arn:aws:iam::123456789012:role/ecsInstanceRole" }
  let(:spot_fleet_role_arn) { "arn:aws:iam::123456789012:role/aws-ec2-spot-fleet-role" }
  let(:subnet_ids) { ["subnet-12345678", "subnet-87654321"] }
  let(:security_group_ids) { ["sg-12345678", "sg-87654321"] }
  let(:launch_template_id) { "lt-12345678" }
  let(:launch_template_name) { "batch-launch-template" }

  # Test basic MANAGED compute environment with EC2
  it "synthesizes basic MANAGED EC2 compute environment correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_batch_compute_environment(:basic_ec2_env, {
        compute_environment_name: "basic-ec2-environment",
        type: "MANAGED",
        service_role: "arn:aws:iam::123456789012:role/aws-batch-service-role",
        compute_resources: {
          type: "EC2",
          allocation_strategy: "BEST_FIT_PROGRESSIVE",
          min_vcpus: 0,
          max_vcpus: 100,
          desired_vcpus: 10,
          instance_types: ["optimal"],
          instance_role: "arn:aws:iam::123456789012:role/ecsInstanceRole",
          subnets: ["subnet-12345678", "subnet-87654321"],
          security_group_ids: ["sg-12345678"]
        }
      })
    end
    
    json_output = synthesizer.synthesis
    env_config = json_output.dig(:resource, :aws_batch_compute_environment, :basic_ec2_env)
    
    expect(env_config[:compute_environment_name]).to eq("basic-ec2-environment")
    expect(env_config[:type]).to eq("MANAGED")
    expect(env_config[:service_role]).to eq("arn:aws:iam::123456789012:role/aws-batch-service-role")
    
    # Verify compute resources structure
    compute_resources = env_config[:compute_resources]
    expect(compute_resources).to be_a(Hash)
    expect(compute_resources[:type]).to eq("EC2")
    expect(compute_resources[:allocation_strategy]).to eq("BEST_FIT_PROGRESSIVE")
    expect(compute_resources[:min_vcpus]).to eq(0)
    expect(compute_resources[:max_vcpus]).to eq(100)
    expect(compute_resources[:desired_vcpus]).to eq(10)
    expect(compute_resources[:instance_types]).to eq(["optimal"])
    expect(compute_resources[:instance_role]).to eq("arn:aws:iam::123456789012:role/ecsInstanceRole")
    expect(compute_resources[:subnets]).to eq(["subnet-12345678", "subnet-87654321"])
    expect(compute_resources[:security_group_ids]).to eq(["sg-12345678"])
  end

  # Test SPOT compute environment synthesis
  it "synthesizes MANAGED SPOT compute environment with required configuration" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_batch_compute_environment(:spot_env, {
        compute_environment_name: "spot-compute-environment",
        type: "MANAGED",
        state: "ENABLED",
        service_role: service_role_arn,
        compute_resources: {
          type: "SPOT",
          allocation_strategy: "SPOT_CAPACITY_OPTIMIZED",
          min_vcpus: 0,
          max_vcpus: 500,
          desired_vcpus: 0,
          instance_types: ["m5.large", "m5.xlarge", "c5.large"],
          spot_iam_fleet_request_role: spot_fleet_role_arn,
          bid_percentage: 40,
          instance_role: instance_role_arn,
          subnets: subnet_ids,
          security_group_ids: security_group_ids
        }
      })
    end
    
    json_output = synthesizer.synthesis
    env_config = json_output.dig(:resource, :aws_batch_compute_environment, :spot_env)
    
    expect(env_config[:type]).to eq("MANAGED")
    expect(env_config[:state]).to eq("ENABLED")
    
    compute_resources = env_config[:compute_resources]
    expect(compute_resources[:type]).to eq("SPOT")
    expect(compute_resources[:allocation_strategy]).to eq("SPOT_CAPACITY_OPTIMIZED")
    expect(compute_resources[:spot_iam_fleet_request_role]).to eq(spot_fleet_role_arn)
    expect(compute_resources[:bid_percentage]).to eq(40)
    expect(compute_resources[:instance_types]).to eq(["m5.large", "m5.xlarge", "c5.large"])
  end

  # Test FARGATE compute environment synthesis
  it "synthesizes MANAGED FARGATE compute environment with platform capabilities" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_batch_compute_environment(:fargate_env, {
        compute_environment_name: "fargate-compute-environment",
        type: "MANAGED",
        service_role: service_role_arn,
        compute_resources: {
          type: "FARGATE",
          max_vcpus: 200,
          subnets: subnet_ids,
          security_group_ids: security_group_ids,
          platform_capabilities: ["FARGATE"]
        }
      })
    end
    
    json_output = synthesizer.synthesis
    env_config = json_output.dig(:resource, :aws_batch_compute_environment, :fargate_env)
    
    compute_resources = env_config[:compute_resources]
    expect(compute_resources[:type]).to eq("FARGATE")
    expect(compute_resources[:max_vcpus]).to eq(200)
    expect(compute_resources[:platform_capabilities]).to eq(["FARGATE"])
    expect(compute_resources).not_to have_key(:min_vcpus)
    expect(compute_resources).not_to have_key(:desired_vcpus)
    expect(compute_resources).not_to have_key(:instance_role)
  end

  # Test FARGATE_SPOT compute environment synthesis
  it "synthesizes MANAGED FARGATE_SPOT compute environment" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_batch_compute_environment(:fargate_spot_env, {
        compute_environment_name: "fargate-spot-environment",
        type: "MANAGED",
        service_role: service_role_arn,
        compute_resources: {
          type: "FARGATE_SPOT",
          max_vcpus: 300,
          subnets: subnet_ids,
          security_group_ids: security_group_ids,
          platform_capabilities: ["FARGATE"]
        }
      })
    end
    
    json_output = synthesizer.synthesis
    env_config = json_output.dig(:resource, :aws_batch_compute_environment, :fargate_spot_env)
    
    compute_resources = env_config[:compute_resources]
    expect(compute_resources[:type]).to eq("FARGATE_SPOT")
    expect(compute_resources[:max_vcpus]).to eq(300)
    expect(compute_resources[:platform_capabilities]).to eq(["FARGATE"])
  end

  # Test UNMANAGED compute environment synthesis
  it "synthesizes UNMANAGED compute environment without compute resources" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_batch_compute_environment(:unmanaged_env, {
        compute_environment_name: "unmanaged-environment",
        type: "UNMANAGED",
        state: "DISABLED",
        service_role: service_role_arn
      })
    end
    
    json_output = synthesizer.synthesis
    env_config = json_output.dig(:resource, :aws_batch_compute_environment, :unmanaged_env)
    
    expect(env_config[:compute_environment_name]).to eq("unmanaged-environment")
    expect(env_config[:type]).to eq("UNMANAGED")
    expect(env_config[:state]).to eq("DISABLED")
    expect(env_config[:service_role]).to eq(service_role_arn)
    expect(env_config).not_to have_key(:compute_resources)
  end

  # Test compute environment with launch template
  it "synthesizes compute environment with launch template configuration" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_batch_compute_environment(:launch_template_env, {
        compute_environment_name: "launch-template-environment",
        type: "MANAGED",
        service_role: service_role_arn,
        compute_resources: {
          type: "EC2",
          allocation_strategy: "BEST_FIT",
          min_vcpus: 5,
          max_vcpus: 200,
          instance_types: ["m5.large", "m5.xlarge"],
          instance_role: instance_role_arn,
          subnets: subnet_ids,
          security_group_ids: security_group_ids,
          launch_template: {
            launch_template_id: launch_template_id,
            version: "$Latest"
          }
        }
      })
    end
    
    json_output = synthesizer.synthesis
    env_config = json_output.dig(:resource, :aws_batch_compute_environment, :launch_template_env)
    
    compute_resources = env_config[:compute_resources]
    launch_template = compute_resources[:launch_template]
    expect(launch_template[:launch_template_id]).to eq(launch_template_id)
    expect(launch_template[:version]).to eq("$Latest")
  end

  # Test compute environment with launch template name instead of ID
  it "synthesizes compute environment with launch template name" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_batch_compute_environment(:launch_template_name_env, {
        compute_environment_name: "launch-template-name-env",
        type: "MANAGED",
        service_role: service_role_arn,
        compute_resources: {
          type: "EC2",
          max_vcpus: 150,
          instance_role: instance_role_arn,
          subnets: subnet_ids,
          security_group_ids: security_group_ids,
          launch_template: {
            launch_template_name: launch_template_name,
            version: "1"
          }
        }
      })
    end
    
    json_output = synthesizer.synthesis
    env_config = json_output.dig(:resource, :aws_batch_compute_environment, :launch_template_name_env)
    
    launch_template = env_config[:compute_resources][:launch_template]
    expect(launch_template[:launch_template_name]).to eq(launch_template_name)
    expect(launch_template[:version]).to eq("1")
    expect(launch_template).not_to have_key(:launch_template_id)
  end

  # Test compute environment with custom AMI and EC2 key pair
  it "synthesizes compute environment with custom AMI and key pair" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_batch_compute_environment(:custom_ami_env, {
        compute_environment_name: "custom-ami-environment",
        type: "MANAGED",
        service_role: service_role_arn,
        compute_resources: {
          type: "EC2",
          max_vcpus: 100,
          instance_types: ["m5.large"],
          instance_role: instance_role_arn,
          image_id: "ami-12345678",
          ec2_key_pair: "my-batch-key-pair",
          subnets: subnet_ids,
          security_group_ids: security_group_ids
        }
      })
    end
    
    json_output = synthesizer.synthesis
    env_config = json_output.dig(:resource, :aws_batch_compute_environment, :custom_ami_env)
    
    compute_resources = env_config[:compute_resources]
    expect(compute_resources[:image_id]).to eq("ami-12345678")
    expect(compute_resources[:ec2_key_pair]).to eq("my-batch-key-pair")
  end

  # Test compute environment with comprehensive tags
  it "synthesizes compute environment with tags at multiple levels" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_batch_compute_environment(:tagged_env, {
        compute_environment_name: "tagged-environment",
        type: "MANAGED",
        service_role: service_role_arn,
        compute_resources: {
          type: "EC2",
          max_vcpus: 100,
          instance_role: instance_role_arn,
          subnets: subnet_ids,
          security_group_ids: security_group_ids,
          tags: {
            "ComputeType" => "EC2",
            "Team" => "data-engineering",
            "Environment" => "production"
          }
        },
        tags: {
          "Project" => "batch-processing",
          "CostCenter" => "engineering",
          "Owner" => "data-team"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    env_config = json_output.dig(:resource, :aws_batch_compute_environment, :tagged_env)
    
    # Environment-level tags
    expect(env_config[:tags]["Project"]).to eq("batch-processing")
    expect(env_config[:tags]["CostCenter"]).to eq("engineering")
    expect(env_config[:tags]["Owner"]).to eq("data-team")
    
    # Compute resource-level tags
    compute_tags = env_config[:compute_resources][:tags]
    expect(compute_tags["ComputeType"]).to eq("EC2")
    expect(compute_tags["Team"]).to eq("data-engineering")
    expect(compute_tags["Environment"]).to eq("production")
  end

  # Test compute environment using ec2_managed_environment template
  it "synthesizes compute environment from ec2_managed_environment template" do
    template_config = Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.ec2_managed_environment(
      "template-ec2-env",
      {
        subnets: subnet_ids,
        security_group_ids: security_group_ids
      },
      {
        min_vcpus: 20,
        max_vcpus: 800,
        desired_vcpus: 100,
        instance_types: ["c5.large", "c5.xlarge"],
        instance_role: instance_role_arn,
        tags: { "Source" => "template" }
      }
    )
    
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_batch_compute_environment(:template_ec2_env, template_config)
    end
    
    json_output = synthesizer.synthesis
    env_config = json_output.dig(:resource, :aws_batch_compute_environment, :template_ec2_env)
    
    expect(env_config[:compute_environment_name]).to eq("template-ec2-env")
    expect(env_config[:type]).to eq("MANAGED")
    expect(env_config[:state]).to eq("ENABLED")
    
    compute_resources = env_config[:compute_resources]
    expect(compute_resources[:type]).to eq("EC2")
    expect(compute_resources[:allocation_strategy]).to eq("BEST_FIT_PROGRESSIVE")
    expect(compute_resources[:min_vcpus]).to eq(20)
    expect(compute_resources[:max_vcpus]).to eq(800)
    expect(compute_resources[:desired_vcpus]).to eq(100)
    expect(compute_resources[:instance_types]).to eq(["c5.large", "c5.xlarge"])
    expect(compute_resources[:tags]["Source"]).to eq("template")
  end

  # Test compute environment using spot_managed_environment template
  it "synthesizes compute environment from spot_managed_environment template" do
    template_config = Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.spot_managed_environment(
      "template-spot-env",
      {
        subnets: subnet_ids,
        security_group_ids: security_group_ids
      },
      {
        min_vcpus: 0,
        max_vcpus: 1500,
        desired_vcpus: 0,
        instance_types: ["m5.large", "r5.large"],
        spot_iam_fleet_request_role: spot_fleet_role_arn,
        bid_percentage: 25,
        instance_role: instance_role_arn,
        tags: { "CostOptimized" => "true" }
      }
    )
    
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_batch_compute_environment(:template_spot_env, template_config)
    end
    
    json_output = synthesizer.synthesis
    env_config = json_output.dig(:resource, :aws_batch_compute_environment, :template_spot_env)
    
    compute_resources = env_config[:compute_resources]
    expect(compute_resources[:type]).to eq("SPOT")
    expect(compute_resources[:allocation_strategy]).to eq("SPOT_CAPACITY_OPTIMIZED")
    expect(compute_resources[:bid_percentage]).to eq(25)
    expect(compute_resources[:spot_iam_fleet_request_role]).to eq(spot_fleet_role_arn)
    expect(compute_resources[:instance_types]).to eq(["m5.large", "r5.large"])
    expect(compute_resources[:tags]["CostOptimized"]).to eq("true")
  end

  # Test compute environment using fargate_managed_environment template
  it "synthesizes compute environment from fargate_managed_environment template" do
    template_config = Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.fargate_managed_environment(
      "template-fargate-env",
      {
        subnets: subnet_ids,
        security_group_ids: security_group_ids
      },
      {
        max_vcpus: 400,
        tags: { "Platform" => "serverless" }
      }
    )
    
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_batch_compute_environment(:template_fargate_env, template_config)
    end
    
    json_output = synthesizer.synthesis
    env_config = json_output.dig(:resource, :aws_batch_compute_environment, :template_fargate_env)
    
    compute_resources = env_config[:compute_resources]
    expect(compute_resources[:type]).to eq("FARGATE")
    expect(compute_resources[:max_vcpus]).to eq(400)
    expect(compute_resources[:platform_capabilities]).to eq(["FARGATE"])
    expect(compute_resources[:tags]["Platform"]).to eq("serverless")
  end

  # Test compute environment using fargate_spot_managed_environment template
  it "synthesizes compute environment from fargate_spot_managed_environment template" do
    template_config = Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.fargate_spot_managed_environment(
      "template-fargate-spot-env",
      {
        subnets: subnet_ids,
        security_group_ids: security_group_ids
      },
      {
        max_vcpus: 600,
        tags: { "CostModel" => "spot-serverless" }
      }
    )
    
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_batch_compute_environment(:template_fargate_spot_env, template_config)
    end
    
    json_output = synthesizer.synthesis
    env_config = json_output.dig(:resource, :aws_batch_compute_environment, :template_fargate_spot_env)
    
    compute_resources = env_config[:compute_resources]
    expect(compute_resources[:type]).to eq("FARGATE_SPOT")
    expect(compute_resources[:max_vcpus]).to eq(600)
    expect(compute_resources[:platform_capabilities]).to eq(["FARGATE"])
    expect(compute_resources[:tags]["CostModel"]).to eq("spot-serverless")
  end

  # Test compute environment using unmanaged_environment template
  it "synthesizes compute environment from unmanaged_environment template" do
    template_config = Pangea::Resources::AWS::Types::BatchComputeEnvironmentAttributes.unmanaged_environment(
      "template-unmanaged-env",
      {
        service_role: service_role_arn,
        state: "ENABLED",
        tags: { "Management" => "custom" }
      }
    )
    
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_batch_compute_environment(:template_unmanaged_env, template_config)
    end
    
    json_output = synthesizer.synthesis
    env_config = json_output.dig(:resource, :aws_batch_compute_environment, :template_unmanaged_env)
    
    expect(env_config[:compute_environment_name]).to eq("template-unmanaged-env")
    expect(env_config[:type]).to eq("UNMANAGED")
    expect(env_config[:state]).to eq("ENABLED")
    expect(env_config[:service_role]).to eq(service_role_arn)
    expect(env_config[:tags]["Management"]).to eq("custom")
    expect(env_config).not_to have_key(:compute_resources)
  end

  # Test multiple compute environments in single synthesis
  it "synthesizes multiple compute environments correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      # EC2 environment
      aws_batch_compute_environment(:multi_ec2_env, {
        compute_environment_name: "multi-ec2-env",
        type: "MANAGED",
        service_role: service_role_arn,
        compute_resources: {
          type: "EC2",
          max_vcpus: 100,
          instance_role: instance_role_arn,
          subnets: subnet_ids,
          security_group_ids: security_group_ids
        }
      })
      
      # SPOT environment
      aws_batch_compute_environment(:multi_spot_env, {
        compute_environment_name: "multi-spot-env",
        type: "MANAGED",
        service_role: service_role_arn,
        compute_resources: {
          type: "SPOT",
          max_vcpus: 200,
          spot_iam_fleet_request_role: spot_fleet_role_arn,
          instance_role: instance_role_arn,
          subnets: subnet_ids,
          security_group_ids: security_group_ids
        }
      })
      
      # Fargate environment
      aws_batch_compute_environment(:multi_fargate_env, {
        compute_environment_name: "multi-fargate-env",
        type: "MANAGED",
        service_role: service_role_arn,
        compute_resources: {
          type: "FARGATE",
          max_vcpus: 150,
          subnets: subnet_ids,
          security_group_ids: security_group_ids,
          platform_capabilities: ["FARGATE"]
        }
      })
      
      # Unmanaged environment
      aws_batch_compute_environment(:multi_unmanaged_env, {
        compute_environment_name: "multi-unmanaged-env",
        type: "UNMANAGED",
        service_role: service_role_arn
      })
    end
    
    json_output = synthesizer.synthesis
    compute_environments = json_output.dig(:resource, :aws_batch_compute_environment)
    
    expect(compute_environments.keys).to contain_exactly(
      :multi_ec2_env, :multi_spot_env, :multi_fargate_env, :multi_unmanaged_env
    )
    
    # Verify each environment has correct type and properties
    expect(compute_environments[:multi_ec2_env][:compute_resources][:type]).to eq("EC2")
    expect(compute_environments[:multi_spot_env][:compute_resources][:type]).to eq("SPOT")
    expect(compute_environments[:multi_fargate_env][:compute_resources][:type]).to eq("FARGATE")
    expect(compute_environments[:multi_unmanaged_env][:type]).to eq("UNMANAGED")
    expect(compute_environments[:multi_unmanaged_env]).not_to have_key(:compute_resources)
  end

  # Test synthesis with comprehensive configuration including all optional properties
  it "synthesizes compute environment with comprehensive configuration" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_batch_compute_environment(:comprehensive_env, {
        compute_environment_name: "comprehensive-batch-environment",
        type: "MANAGED",
        state: "ENABLED",
        service_role: service_role_arn,
        compute_resources: {
          type: "EC2",
          allocation_strategy: "BEST_FIT_PROGRESSIVE",
          min_vcpus: 10,
          max_vcpus: 1000,
          desired_vcpus: 100,
          instance_types: ["m5.large", "m5.xlarge", "c5.large", "c5.xlarge"],
          instance_role: instance_role_arn,
          subnets: subnet_ids,
          security_group_ids: security_group_ids,
          ec2_key_pair: "comprehensive-key-pair",
          image_id: "ami-comprehensive",
          launch_template: {
            launch_template_id: launch_template_id,
            version: "$Latest"
          },
          platform_capabilities: ["EC2"],
          tags: {
            "Team" => "infrastructure",
            "Environment" => "production",
            "Project" => "batch-compute",
            "CostCenter" => "engineering"
          }
        },
        tags: {
          "Service" => "aws-batch",
          "Owner" => "platform-team",
          "Compliance" => "required"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    env_config = json_output.dig(:resource, :aws_batch_compute_environment, :comprehensive_env)
    
    # Verify top-level properties
    expect(env_config[:compute_environment_name]).to eq("comprehensive-batch-environment")
    expect(env_config[:type]).to eq("MANAGED")
    expect(env_config[:state]).to eq("ENABLED")
    expect(env_config[:service_role]).to eq(service_role_arn)
    
    # Verify compute resources
    compute_resources = env_config[:compute_resources]
    expect(compute_resources[:type]).to eq("EC2")
    expect(compute_resources[:allocation_strategy]).to eq("BEST_FIT_PROGRESSIVE")
    expect(compute_resources[:min_vcpus]).to eq(10)
    expect(compute_resources[:max_vcpus]).to eq(1000)
    expect(compute_resources[:desired_vcpus]).to eq(100)
    expect(compute_resources[:instance_types]).to eq(["m5.large", "m5.xlarge", "c5.large", "c5.xlarge"])
    expect(compute_resources[:instance_role]).to eq(instance_role_arn)
    expect(compute_resources[:subnets]).to eq(subnet_ids)
    expect(compute_resources[:security_group_ids]).to eq(security_group_ids)
    expect(compute_resources[:ec2_key_pair]).to eq("comprehensive-key-pair")
    expect(compute_resources[:image_id]).to eq("ami-comprehensive")
    expect(compute_resources[:platform_capabilities]).to eq(["EC2"])
    
    # Verify launch template
    launch_template = compute_resources[:launch_template]
    expect(launch_template[:launch_template_id]).to eq(launch_template_id)
    expect(launch_template[:version]).to eq("$Latest")
    
    # Verify tags at both levels
    expect(env_config[:tags]["Service"]).to eq("aws-batch")
    expect(env_config[:tags]["Owner"]).to eq("platform-team")
    expect(compute_resources[:tags]["Team"]).to eq("infrastructure")
    expect(compute_resources[:tags]["Environment"]).to eq("production")
  end

  # Test synthesis with minimal configuration
  it "synthesizes compute environment with minimal required configuration" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_batch_compute_environment(:minimal_env, {
        compute_environment_name: "minimal-environment",
        type: "UNMANAGED"
      })
    end
    
    json_output = synthesizer.synthesis
    env_config = json_output.dig(:resource, :aws_batch_compute_environment, :minimal_env)
    
    expect(env_config[:compute_environment_name]).to eq("minimal-environment")
    expect(env_config[:type]).to eq("UNMANAGED")
    expect(env_config).not_to have_key(:state)  # Not provided, so not synthesized
    expect(env_config).not_to have_key(:service_role)  # Not provided
    expect(env_config).not_to have_key(:compute_resources)  # UNMANAGED type
    expect(env_config).not_to have_key(:tags)  # Not provided
  end
end