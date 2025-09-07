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

# Load aws_eks_node_group resource and types for testing
require 'pangea/resources/aws_eks_node_group/resource'
require 'pangea/resources/aws_eks_node_group/types'

RSpec.describe "aws_eks_node_group resource function" do
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
  
  # Test IAM role ARN for nodes
  let(:node_role_arn) { "arn:aws:iam::123456789012:role/eks-node-role" }
  
  describe "ScalingConfig validation" do
    it "accepts valid scaling configuration" do
      scaling = Pangea::Resources::AWS::Types::ScalingConfig.new({
        desired_size: 3,
        min_size: 1,
        max_size: 5
      })
      
      expect(scaling.desired_size).to eq(3)
      expect(scaling.min_size).to eq(1)
      expect(scaling.max_size).to eq(5)
    end
    
    it "accepts scale-to-zero configuration" do
      scaling = Pangea::Resources::AWS::Types::ScalingConfig.new({
        desired_size: 0,
        min_size: 0,
        max_size: 10
      })
      
      expect(scaling.min_size).to eq(0)
      expect(scaling.desired_size).to eq(0)
    end
    
    it "uses defaults when not specified" do
      scaling = Pangea::Resources::AWS::Types::ScalingConfig.new({})
      
      expect(scaling.desired_size).to eq(2)
      expect(scaling.min_size).to eq(1)
      expect(scaling.max_size).to eq(4)
    end
    
    it "rejects min_size > max_size" do
      expect {
        Pangea::Resources::AWS::Types::ScalingConfig.new({
          min_size: 5,
          max_size: 3
        })
      }.to raise_error(Dry::Struct::Error, /min_size .* cannot be greater than max_size/)
    end
    
    it "rejects desired_size outside range" do
      expect {
        Pangea::Resources::AWS::Types::ScalingConfig.new({
          desired_size: 10,
          min_size: 1,
          max_size: 5
        })
      }.to raise_error(Dry::Struct::Error, /desired_size .* must be between min_size .* and max_size/)
    end
  end
  
  describe "UpdateConfig validation" do
    it "accepts max_unavailable absolute value" do
      update = Pangea::Resources::AWS::Types::UpdateConfig.new({
        max_unavailable: 2
      })
      
      expect(update.max_unavailable).to eq(2)
      expect(update.max_unavailable_percentage).to be_nil
    end
    
    it "accepts max_unavailable_percentage" do
      update = Pangea::Resources::AWS::Types::UpdateConfig.new({
        max_unavailable_percentage: 33
      })
      
      expect(update.max_unavailable_percentage).to eq(33)
      expect(update.max_unavailable).to be_nil
    end
    
    it "rejects both max_unavailable values" do
      expect {
        Pangea::Resources::AWS::Types::UpdateConfig.new({
          max_unavailable: 2,
          max_unavailable_percentage: 33
        })
      }.to raise_error(Dry::Struct::Error, /Cannot specify both max_unavailable and max_unavailable_percentage/)
    end
    
    it "validates percentage range" do
      expect {
        Pangea::Resources::AWS::Types::UpdateConfig.new({
          max_unavailable_percentage: 101
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
  end
  
  describe "RemoteAccess validation" do
    it "accepts SSH key configuration" do
      remote = Pangea::Resources::AWS::Types::RemoteAccess.new({
        ec2_ssh_key: "my-key-pair",
        source_security_group_ids: ["sg-12345", "sg-67890"]
      })
      
      expect(remote.ec2_ssh_key).to eq("my-key-pair")
      expect(remote.source_security_group_ids).to eq(["sg-12345", "sg-67890"])
    end
    
    it "accepts configuration without SSH key" do
      remote = Pangea::Resources::AWS::Types::RemoteAccess.new({
        source_security_group_ids: ["sg-12345"]
      })
      
      expect(remote.ec2_ssh_key).to be_nil
      expect(remote.source_security_group_ids).to eq(["sg-12345"])
    end
    
    it "defaults to empty security groups" do
      remote = Pangea::Resources::AWS::Types::RemoteAccess.new({})
      
      expect(remote.source_security_group_ids).to eq([])
    end
  end
  
  describe "LaunchTemplate validation" do
    it "accepts launch template with ID" do
      template = Pangea::Resources::AWS::Types::LaunchTemplate.new({
        id: "lt-12345",
        version: "$Latest"
      })
      
      expect(template.id).to eq("lt-12345")
      expect(template.version).to eq("$Latest")
      expect(template.name).to be_nil
    end
    
    it "accepts launch template with name" do
      template = Pangea::Resources::AWS::Types::LaunchTemplate.new({
        name: "my-template",
        version: "1"
      })
      
      expect(template.name).to eq("my-template")
      expect(template.version).to eq("1")
      expect(template.id).to be_nil
    end
    
    it "rejects template without ID or name" do
      expect {
        Pangea::Resources::AWS::Types::LaunchTemplate.new({
          version: "$Latest"
        })
      }.to raise_error(Dry::Struct::Error, /must specify either 'id' or 'name'/)
    end
    
    it "rejects template with both ID and name" do
      expect {
        Pangea::Resources::AWS::Types::LaunchTemplate.new({
          id: "lt-12345",
          name: "my-template"
        })
      }.to raise_error(Dry::Struct::Error, /cannot specify both 'id' and 'name'/)
    end
  end
  
  describe "Taint validation" do
    it "accepts valid taint configuration" do
      taint = Pangea::Resources::AWS::Types::Taint.new({
        key: "spot",
        value: "true",
        effect: "NO_SCHEDULE"
      })
      
      expect(taint.key).to eq("spot")
      expect(taint.value).to eq("true")
      expect(taint.effect).to eq("NO_SCHEDULE")
    end
    
    it "accepts taint without value" do
      taint = Pangea::Resources::AWS::Types::Taint.new({
        key: "nvidia.com/gpu",
        effect: "NO_EXECUTE"
      })
      
      expect(taint.key).to eq("nvidia.com/gpu")
      expect(taint.value).to be_nil
      expect(taint.effect).to eq("NO_EXECUTE")
    end
    
    it "validates effect values" do
      expect {
        Pangea::Resources::AWS::Types::Taint.new({
          key: "test",
          effect: "INVALID"
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
    
    it "accepts all valid effects" do
      effects = ["NO_SCHEDULE", "NO_EXECUTE", "PREFER_NO_SCHEDULE"]
      effects.each do |effect|
        taint = Pangea::Resources::AWS::Types::Taint.new({
          key: "test",
          effect: effect
        })
        expect(taint.effect).to eq(effect)
      end
    end
  end
  
  describe "EksNodeGroupAttributes validation" do
    it "accepts minimal valid configuration" do
      node_group = Pangea::Resources::AWS::Types::EksNodeGroupAttributes.new({
        cluster_name: "my-cluster",
        node_role_arn: node_role_arn,
        subnet_ids: ["subnet-12345", "subnet-67890"]
      })
      
      expect(node_group.cluster_name).to eq("my-cluster")
      expect(node_group.node_role_arn).to eq(node_role_arn)
      expect(node_group.subnet_ids.size).to eq(2)
      expect(node_group.instance_types).to eq(["t3.medium"])
      expect(node_group.capacity_type).to eq("ON_DEMAND")
      expect(node_group.ami_type).to eq("AL2_x86_64")
    end
    
    it "accepts full configuration" do
      node_group = Pangea::Resources::AWS::Types::EksNodeGroupAttributes.new({
        cluster_name: "my-cluster",
        node_group_name: "workers",
        node_role_arn: node_role_arn,
        subnet_ids: ["subnet-12345", "subnet-67890"],
        scaling_config: {
          desired_size: 5,
          min_size: 3,
          max_size: 10
        },
        update_config: {
          max_unavailable_percentage: 33
        },
        instance_types: ["m5.large", "m5a.large", "m5n.large"],
        capacity_type: "SPOT",
        ami_type: "AL2_x86_64",
        disk_size: 50,
        remote_access: {
          ec2_ssh_key: "my-key"
        },
        labels: {
          workload: "general",
          team: "platform"
        },
        taints: [{
          key: "spot",
          value: "true",
          effect: "NO_SCHEDULE"
        }],
        tags: {
          Environment: "production",
          CostCenter: "engineering"
        }
      })
      
      expect(node_group.node_group_name).to eq("workers")
      expect(node_group.scaling_config.desired_size).to eq(5)
      expect(node_group.instance_types.size).to eq(3)
      expect(node_group.capacity_type).to eq("SPOT")
      expect(node_group.disk_size).to eq(50)
      expect(node_group.labels[:workload]).to eq("general")
      expect(node_group.taints.size).to eq(1)
      expect(node_group.tags[:Environment]).to eq("production")
    end
    
    it "validates IAM role ARN format" do
      expect {
        Pangea::Resources::AWS::Types::EksNodeGroupAttributes.new({
          cluster_name: "my-cluster",
          node_role_arn: "invalid-arn",
          subnet_ids: ["subnet-12345"]
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
    
    it "requires at least one subnet" do
      expect {
        Pangea::Resources::AWS::Types::EksNodeGroupAttributes.new({
          cluster_name: "my-cluster",
          node_role_arn: node_role_arn,
          subnet_ids: []
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
    
    it "validates disk size range" do
      expect {
        Pangea::Resources::AWS::Types::EksNodeGroupAttributes.new({
          cluster_name: "my-cluster",
          node_role_arn: node_role_arn,
          subnet_ids: ["subnet-12345"],
          disk_size: 10
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
    
    it "validates ARM instance types with ARM AMI" do
      expect {
        Pangea::Resources::AWS::Types::EksNodeGroupAttributes.new({
          cluster_name: "my-cluster",
          node_role_arn: node_role_arn,
          subnet_ids: ["subnet-12345"],
          ami_type: "AL2_ARM_64",
          instance_types: ["t3.medium"]
        })
      }.to raise_error(Dry::Struct::Error, /ARM AMI types require ARM-compatible instance types/)
    end
    
    it "accepts ARM instance types with ARM AMI" do
      node_group = Pangea::Resources::AWS::Types::EksNodeGroupAttributes.new({
        cluster_name: "my-cluster",
        node_role_arn: node_role_arn,
        subnet_ids: ["subnet-12345"],
        ami_type: "AL2_ARM_64",
        instance_types: ["t4g.medium", "m6g.large", "a1.xlarge"]
      })
      
      expect(node_group.ami_type).to eq("AL2_ARM_64")
      expect(node_group.instance_types).to include("t4g.medium")
    end
    
    it "validates GPU instance types with GPU AMI" do
      expect {
        Pangea::Resources::AWS::Types::EksNodeGroupAttributes.new({
          cluster_name: "my-cluster",
          node_role_arn: node_role_arn,
          subnet_ids: ["subnet-12345"],
          ami_type: "AL2_x86_64_GPU",
          instance_types: ["t3.medium"]
        })
      }.to raise_error(Dry::Struct::Error, /GPU AMI types require GPU instance types/)
    end
    
    it "accepts GPU instance types with GPU AMI" do
      node_group = Pangea::Resources::AWS::Types::EksNodeGroupAttributes.new({
        cluster_name: "my-cluster",
        node_role_arn: node_role_arn,
        subnet_ids: ["subnet-12345"],
        ami_type: "AL2_x86_64_GPU",
        instance_types: ["p3.2xlarge", "g4dn.xlarge"]
      })
      
      expect(node_group.ami_type).to eq("AL2_x86_64_GPU")
      expect(node_group.instance_types).to include("g4dn.xlarge")
    end
  end
  
  describe "computed properties" do
    let(:spot_node_group) do
      Pangea::Resources::AWS::Types::EksNodeGroupAttributes.new({
        cluster_name: "my-cluster",
        node_role_arn: node_role_arn,
        subnet_ids: ["subnet-12345"],
        capacity_type: "SPOT"
      })
    end
    
    let(:custom_ami_node_group) do
      Pangea::Resources::AWS::Types::EksNodeGroupAttributes.new({
        cluster_name: "my-cluster",
        node_role_arn: node_role_arn,
        subnet_ids: ["subnet-12345"],
        ami_type: "CUSTOM"
      })
    end
    
    let(:labeled_node_group) do
      Pangea::Resources::AWS::Types::EksNodeGroupAttributes.new({
        cluster_name: "my-cluster",
        node_role_arn: node_role_arn,
        subnet_ids: ["subnet-12345"],
        labels: { workload: "batch" },
        taints: [{ key: "dedicated", effect: "NO_SCHEDULE" }],
        remote_access: { ec2_ssh_key: "my-key" }
      })
    end
    
    it "detects spot instances" do
      expect(spot_node_group.spot_instances?).to eq(true)
    end
    
    it "detects custom AMI" do
      expect(custom_ami_node_group.custom_ami?).to eq(true)
    end
    
    it "detects remote access" do
      expect(labeled_node_group.has_remote_access?).to eq(true)
    end
    
    it "detects taints" do
      expect(labeled_node_group.has_taints?).to eq(true)
    end
    
    it "detects labels" do
      expect(labeled_node_group.has_labels?).to eq(true)
    end
  end
  
  describe "aws_eks_node_group function" do
    it "creates basic node group" do
      result = test_instance.aws_eks_node_group(:workers, {
        cluster_name: "my-cluster",
        node_role_arn: node_role_arn,
        subnet_ids: ["subnet-12345", "subnet-67890"]
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.type).to eq('aws_eks_node_group')
      expect(result.name).to eq(:workers)
    end
    
    it "creates node group with custom name" do
      result = test_instance.aws_eks_node_group(:workers, {
        cluster_name: "my-cluster",
        node_group_name: "production-workers",
        node_role_arn: node_role_arn,
        subnet_ids: ["subnet-12345", "subnet-67890"]
      })
      
      expect(result.resource_attributes[:node_group_name]).to eq("production-workers")
    end
    
    it "creates spot instance node group" do
      result = test_instance.aws_eks_node_group(:spot_workers, {
        cluster_name: "my-cluster",
        node_role_arn: node_role_arn,
        subnet_ids: ["subnet-12345", "subnet-67890"],
        capacity_type: "SPOT",
        instance_types: ["m5.large", "m5a.large", "m5n.large"]
      })
      
      expect(result.spot_instances?).to eq(true)
      expect(result.resource_attributes[:instance_types].size).to eq(3)
    end
    
    it "creates GPU node group" do
      result = test_instance.aws_eks_node_group(:gpu_workers, {
        cluster_name: "my-cluster",
        node_role_arn: node_role_arn,
        subnet_ids: ["subnet-12345", "subnet-67890"],
        ami_type: "AL2_x86_64_GPU",
        instance_types: ["g4dn.xlarge", "g4dn.2xlarge"],
        disk_size: 100
      })
      
      expect(result.ami_type).to eq("AL2_x86_64_GPU")
      expect(result.resource_attributes[:disk_size]).to eq(100)
    end
    
    it "creates node group with labels and taints" do
      result = test_instance.aws_eks_node_group(:specialized, {
        cluster_name: "my-cluster",
        node_role_arn: node_role_arn,
        subnet_ids: ["subnet-12345", "subnet-67890"],
        labels: {
          workload: "batch",
          team: "data"
        },
        taints: [{
          key: "dedicated",
          value: "batch",
          effect: "NO_SCHEDULE"
        }]
      })
      
      expect(result.has_labels?).to eq(true)
      expect(result.has_taints?).to eq(true)
    end
    
    it "creates node group with launch template" do
      result = test_instance.aws_eks_node_group(:custom, {
        cluster_name: "my-cluster",
        node_role_arn: node_role_arn,
        subnet_ids: ["subnet-12345", "subnet-67890"],
        launch_template: {
          id: "lt-12345",
          version: "$Latest"
        }
      })
      
      launch_template = result.resource_attributes[:launch_template]
      expect(launch_template[:id]).to eq("lt-12345")
      expect(launch_template[:version]).to eq("$Latest")
    end
    
    it "provides correct outputs" do
      result = test_instance.aws_eks_node_group(:test, {
        cluster_name: "my-cluster",
        node_role_arn: node_role_arn,
        subnet_ids: ["subnet-12345"]
      })
      
      expect(result.id).to eq("${aws_eks_node_group.test.id}")
      expect(result.arn).to eq("${aws_eks_node_group.test.arn}")
      expect(result.cluster_name).to eq("${aws_eks_node_group.test.cluster_name}")
      expect(result.node_group_name).to eq("${aws_eks_node_group.test.node_group_name}")
      expect(result.node_role_arn).to eq("${aws_eks_node_group.test.node_role_arn}")
      expect(result.subnet_ids).to eq("${aws_eks_node_group.test.subnet_ids}")
      expect(result.status).to eq("${aws_eks_node_group.test.status}")
      expect(result.capacity_type).to eq("${aws_eks_node_group.test.capacity_type}")
      expect(result.instance_types).to eq("${aws_eks_node_group.test.instance_types}")
      expect(result.disk_size).to eq("${aws_eks_node_group.test.disk_size}")
      expect(result.remote_access).to eq("${aws_eks_node_group.test.remote_access}")
      expect(result.scaling_config).to eq("${aws_eks_node_group.test.scaling_config}")
      expect(result.update_config).to eq("${aws_eks_node_group.test.update_config}")
      expect(result.launch_template).to eq("${aws_eks_node_group.test.launch_template}")
      expect(result.version).to eq("${aws_eks_node_group.test.version}")
      expect(result.release_version).to eq("${aws_eks_node_group.test.release_version}")
      expect(result.resources).to eq("${aws_eks_node_group.test.resources}")
      expect(result.tags_all).to eq("${aws_eks_node_group.test.tags_all}")
    end
    
    it "provides computed properties" do
      result = test_instance.aws_eks_node_group(:test, {
        cluster_name: "my-cluster",
        node_role_arn: node_role_arn,
        subnet_ids: ["subnet-12345"],
        capacity_type: "SPOT",
        scaling_config: {
          desired_size: 5,
          min_size: 2,
          max_size: 10
        },
        labels: { workload: "batch" },
        taints: [{ key: "spot", effect: "NO_SCHEDULE" }]
      })
      
      expect(result.spot_instances?).to eq(true)
      expect(result.custom_ami?).to eq(false)
      expect(result.has_remote_access?).to eq(false)
      expect(result.has_taints?).to eq(true)
      expect(result.has_labels?).to eq(true)
      expect(result.ami_type).to eq("AL2_x86_64")
      expect(result.desired_size).to eq(5)
    end
  end
  
  describe "node group deployment patterns" do
    it "creates general purpose node group" do
      result = test_instance.aws_eks_node_group(:general, {
        cluster_name: "production-cluster",
        node_role_arn: node_role_arn,
        subnet_ids: ["subnet-private-1a", "subnet-private-1b", "subnet-private-1c"],
        scaling_config: {
          desired_size: 3,
          min_size: 2,
          max_size: 6
        },
        instance_types: ["m5.large"],
        tags: {
          Purpose: "general-workloads",
          Environment: "production"
        }
      })
      
      expect(result.resource_attributes[:scaling_config][:desired_size]).to eq(3)
      expect(result.resource_attributes[:tags][:Purpose]).to eq("general-workloads")
    end
    
    it "creates spot fleet node group" do
      result = test_instance.aws_eks_node_group(:spot_fleet, {
        cluster_name: "cost-optimized-cluster",
        node_role_arn: node_role_arn,
        subnet_ids: ["subnet-12345", "subnet-67890"],
        capacity_type: "SPOT",
        instance_types: ["t3.large", "t3a.large", "t3.xlarge", "t3a.xlarge"],
        scaling_config: {
          desired_size: 10,
          min_size: 5,
          max_size: 20
        },
        labels: {
          lifecycle: "spot",
          workload: "batch"
        },
        taints: [{
          key: "spot-instance",
          value: "true",
          effect: "NO_SCHEDULE"
        }],
        tags: {
          CostOptimization: "aggressive"
        }
      })
      
      expect(result.spot_instances?).to eq(true)
      expect(result.resource_attributes[:instance_types].size).to eq(4)
      expect(result.has_taints?).to eq(true)
    end
    
    it "creates ARM-based node group" do
      result = test_instance.aws_eks_node_group(:arm_workers, {
        cluster_name: "arm-cluster",
        node_role_arn: node_role_arn,
        subnet_ids: ["subnet-12345", "subnet-67890"],
        ami_type: "AL2_ARM_64",
        instance_types: ["t4g.medium", "t4g.large", "m6g.large"],
        scaling_config: {
          desired_size: 4,
          min_size: 2,
          max_size: 8
        },
        labels: {
          architecture: "arm64",
          cost_optimized: "true"
        },
        tags: {
          Architecture: "graviton"
        }
      })
      
      expect(result.ami_type).to eq("AL2_ARM_64")
      expect(result.resource_attributes[:labels][:architecture]).to eq("arm64")
    end
    
    it "creates ML/GPU node group" do
      result = test_instance.aws_eks_node_group(:ml_workers, {
        cluster_name: "ml-cluster",
        node_role_arn: node_role_arn,
        subnet_ids: ["subnet-12345", "subnet-67890"],
        ami_type: "AL2_x86_64_GPU",
        instance_types: ["g4dn.xlarge", "g4dn.2xlarge"],
        scaling_config: {
          desired_size: 2,
          min_size: 0,
          max_size: 10
        },
        disk_size: 200,
        labels: {
          workload: "ml-training",
          gpu: "nvidia-tesla-t4"
        },
        taints: [{
          key: "nvidia.com/gpu",
          effect: "NO_SCHEDULE"
        }],
        tags: {
          Workload: "machine-learning",
          GPUType: "T4"
        }
      })
      
      expect(result.resource_attributes[:ami_type]).to eq("AL2_x86_64_GPU")
      expect(result.resource_attributes[:disk_size]).to eq(200)
      expect(result.has_taints?).to eq(true)
    end
    
    it "creates Bottlerocket node group" do
      result = test_instance.aws_eks_node_group(:bottlerocket, {
        cluster_name: "secure-cluster",
        node_role_arn: node_role_arn,
        subnet_ids: ["subnet-12345", "subnet-67890"],
        ami_type: "BOTTLEROCKET_x86_64",
        instance_types: ["m5.large", "m5.xlarge"],
        scaling_config: {
          desired_size: 3,
          min_size: 3,
          max_size: 6
        },
        labels: {
          os: "bottlerocket",
          security: "hardened"
        },
        tags: {
          OS: "bottlerocket",
          SecurityLevel: "high"
        }
      })
      
      expect(result.resource_attributes[:ami_type]).to eq("BOTTLEROCKET_x86_64")
      expect(result.resource_attributes[:labels][:security]).to eq("hardened")
    end
    
    it "creates node group with custom launch template" do
      result = test_instance.aws_eks_node_group(:custom_launch, {
        cluster_name: "custom-cluster",
        node_role_arn: node_role_arn,
        subnet_ids: ["subnet-12345", "subnet-67890"],
        launch_template: {
          name: "eks-custom-template",
          version: "$Latest"
        },
        scaling_config: {
          desired_size: 3,
          min_size: 1,
          max_size: 5
        }
      })
      
      template = result.resource_attributes[:launch_template]
      expect(template[:name]).to eq("eks-custom-template")
      expect(template[:version]).to eq("$Latest")
    end
  end
  
  describe "update configuration patterns" do
    it "creates node group with percentage-based updates" do
      result = test_instance.aws_eks_node_group(:percentage_update, {
        cluster_name: "my-cluster",
        node_role_arn: node_role_arn,
        subnet_ids: ["subnet-12345", "subnet-67890"],
        update_config: {
          max_unavailable_percentage: 33
        }
      })
      
      update_config = result.resource_attributes[:update_config]
      expect(update_config[:max_unavailable_percentage]).to eq(33)
    end
    
    it "creates node group with absolute update limit" do
      result = test_instance.aws_eks_node_group(:absolute_update, {
        cluster_name: "my-cluster",
        node_role_arn: node_role_arn,
        subnet_ids: ["subnet-12345", "subnet-67890"],
        update_config: {
          max_unavailable: 1
        }
      })
      
      update_config = result.resource_attributes[:update_config]
      expect(update_config[:max_unavailable]).to eq(1)
    end
  end
  
  describe "remote access patterns" do
    it "creates node group with SSH access" do
      result = test_instance.aws_eks_node_group(:ssh_enabled, {
        cluster_name: "my-cluster",
        node_role_arn: node_role_arn,
        subnet_ids: ["subnet-12345", "subnet-67890"],
        remote_access: {
          ec2_ssh_key: "my-key-pair",
          source_security_group_ids: ["sg-bastion"]
        }
      })
      
      expect(result.has_remote_access?).to eq(true)
      remote = result.resource_attributes[:remote_access]
      expect(remote[:ec2_ssh_key]).to eq("my-key-pair")
      expect(remote[:source_security_group_ids]).to include("sg-bastion")
    end
  end
end