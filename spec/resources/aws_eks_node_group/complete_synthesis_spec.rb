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

# Load aws_eks_node_group resource and terraform-synthesizer for testing
require 'pangea/resources/aws_eks_node_group/resource'
require 'terraform-synthesizer'

RSpec.describe "aws_eks_node_group terraform synthesis" do
  let(:synthesizer) { TerraformSynthesizer.new }
  
  # Test IAM role ARN
  let(:node_role_arn) { "arn:aws:iam::123456789012:role/eks-node-role" }
  
  # Test basic node group synthesis
  it "synthesizes basic node group correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_node_group(:basic, {
        cluster_name: "my-cluster",
        node_role_arn: "arn:aws:iam::123456789012:role/eks-node-role",
        subnet_ids: ["subnet-12345", "subnet-67890"]
      })
    end
    
    json_output = synthesizer.synthesis
    node_group_config = json_output.dig(:resource, :aws_eks_node_group, :basic)
    
    expect(node_group_config[:cluster_name]).to eq("my-cluster")
    expect(node_group_config[:node_role_arn]).to eq(node_role_arn)
    expect(node_group_config[:subnet_ids]).to eq(["subnet-12345", "subnet-67890"])
    
    # Check defaults
    expect(node_group_config[:instance_types]).to eq(["t3.medium"])
    expect(node_group_config[:capacity_type]).to eq("ON_DEMAND")
    expect(node_group_config[:ami_type]).to eq("AL2_x86_64")
    expect(node_group_config[:disk_size]).to eq(20)
    
    # Check scaling config
    scaling = node_group_config[:scaling_config]
    expect(scaling[:desired_size]).to eq(2)
    expect(scaling[:min_size]).to eq(1)
    expect(scaling[:max_size]).to eq(4)
  end
  
  # Test node group with custom name synthesis
  it "synthesizes node group with custom name correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_node_group(:named, {
        cluster_name: "my-cluster",
        node_group_name: "production-workers",
        node_role_arn: "arn:aws:iam::123456789012:role/eks-node-role",
        subnet_ids: ["subnet-12345", "subnet-67890"]
      })
    end
    
    json_output = synthesizer.synthesis
    node_group_config = json_output.dig(:resource, :aws_eks_node_group, :named)
    
    expect(node_group_config[:node_group_name]).to eq("production-workers")
  end
  
  # Test spot instance node group synthesis
  it "synthesizes spot node group correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_node_group(:spot, {
        cluster_name: "my-cluster",
        node_role_arn: "arn:aws:iam::123456789012:role/eks-node-role",
        subnet_ids: ["subnet-12345", "subnet-67890"],
        capacity_type: "SPOT",
        instance_types: ["m5.large", "m5a.large", "m5n.large", "m5.xlarge"],
        scaling_config: {
          desired_size: 10,
          min_size: 5,
          max_size: 20
        }
      })
    end
    
    json_output = synthesizer.synthesis
    node_group_config = json_output.dig(:resource, :aws_eks_node_group, :spot)
    
    expect(node_group_config[:capacity_type]).to eq("SPOT")
    expect(node_group_config[:instance_types]).to eq(["m5.large", "m5a.large", "m5n.large", "m5.xlarge"])
    
    scaling = node_group_config[:scaling_config]
    expect(scaling[:desired_size]).to eq(10)
    expect(scaling[:min_size]).to eq(5)
    expect(scaling[:max_size]).to eq(20)
  end
  
  # Test GPU node group synthesis
  it "synthesizes GPU node group correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_node_group(:gpu, {
        cluster_name: "ml-cluster",
        node_role_arn: "arn:aws:iam::123456789012:role/eks-node-role",
        subnet_ids: ["subnet-12345", "subnet-67890"],
        ami_type: "AL2_x86_64_GPU",
        instance_types: ["g4dn.xlarge", "g4dn.2xlarge"],
        disk_size: 100,
        scaling_config: {
          desired_size: 2,
          min_size: 0,
          max_size: 10
        }
      })
    end
    
    json_output = synthesizer.synthesis
    node_group_config = json_output.dig(:resource, :aws_eks_node_group, :gpu)
    
    expect(node_group_config[:ami_type]).to eq("AL2_x86_64_GPU")
    expect(node_group_config[:instance_types]).to include("g4dn.xlarge")
    expect(node_group_config[:disk_size]).to eq(100)
    expect(node_group_config[:scaling_config][:min_size]).to eq(0)
  end
  
  # Test ARM node group synthesis
  it "synthesizes ARM node group correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_node_group(:arm, {
        cluster_name: "cost-optimized-cluster",
        node_role_arn: "arn:aws:iam::123456789012:role/eks-node-role",
        subnet_ids: ["subnet-12345", "subnet-67890"],
        ami_type: "AL2_ARM_64",
        instance_types: ["t4g.medium", "t4g.large", "m6g.large"],
        scaling_config: {
          desired_size: 3,
          min_size: 2,
          max_size: 6
        }
      })
    end
    
    json_output = synthesizer.synthesis
    node_group_config = json_output.dig(:resource, :aws_eks_node_group, :arm)
    
    expect(node_group_config[:ami_type]).to eq("AL2_ARM_64")
    expect(node_group_config[:instance_types]).to include("t4g.medium", "m6g.large")
  end
  
  # Test node group with labels and taints synthesis
  it "synthesizes node group with labels and taints correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_node_group(:labeled, {
        cluster_name: "my-cluster",
        node_role_arn: "arn:aws:iam::123456789012:role/eks-node-role",
        subnet_ids: ["subnet-12345", "subnet-67890"],
        labels: {
          workload: "batch",
          team: "data-engineering",
          environment: "production"
        },
        taints: [
          {
            key: "dedicated",
            value: "batch",
            effect: "NO_SCHEDULE"
          },
          {
            key: "workload",
            value: "cpu-intensive",
            effect: "PREFER_NO_SCHEDULE"
          }
        ]
      })
    end
    
    json_output = synthesizer.synthesis
    node_group_config = json_output.dig(:resource, :aws_eks_node_group, :labeled)
    
    expect(node_group_config[:labels]).to be_a(Hash)
    expect(node_group_config[:labels][:workload]).to eq("batch")
    expect(node_group_config[:labels][:team]).to eq("data-engineering")
    
    expect(node_group_config[:taint]).to be_an(Array)
    expect(node_group_config[:taint].size).to eq(2)
    
    first_taint = node_group_config[:taint].first
    expect(first_taint[:key]).to eq("dedicated")
    expect(first_taint[:value]).to eq("batch")
    expect(first_taint[:effect]).to eq("NO_SCHEDULE")
  end
  
  # Test node group with update config synthesis
  it "synthesizes node group with update config correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_node_group(:updatable, {
        cluster_name: "my-cluster",
        node_role_arn: "arn:aws:iam::123456789012:role/eks-node-role",
        subnet_ids: ["subnet-12345", "subnet-67890"],
        update_config: {
          max_unavailable_percentage: 33
        }
      })
    end
    
    json_output = synthesizer.synthesis
    node_group_config = json_output.dig(:resource, :aws_eks_node_group, :updatable)
    
    expect(node_group_config[:update_config]).to be_a(Hash)
    expect(node_group_config[:update_config][:max_unavailable_percentage]).to eq(33)
  end
  
  # Test node group with remote access synthesis
  it "synthesizes node group with remote access correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_node_group(:ssh_enabled, {
        cluster_name: "my-cluster",
        node_role_arn: "arn:aws:iam::123456789012:role/eks-node-role",
        subnet_ids: ["subnet-12345", "subnet-67890"],
        remote_access: {
          ec2_ssh_key: "my-key-pair",
          source_security_group_ids: ["sg-bastion", "sg-admin"]
        }
      })
    end
    
    json_output = synthesizer.synthesis
    node_group_config = json_output.dig(:resource, :aws_eks_node_group, :ssh_enabled)
    
    expect(node_group_config[:remote_access]).to be_a(Hash)
    expect(node_group_config[:remote_access][:ec2_ssh_key]).to eq("my-key-pair")
    expect(node_group_config[:remote_access][:source_security_group_ids]).to eq(["sg-bastion", "sg-admin"])
  end
  
  # Test node group with launch template synthesis
  it "synthesizes node group with launch template correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_node_group(:custom_launch, {
        cluster_name: "my-cluster",
        node_role_arn: "arn:aws:iam::123456789012:role/eks-node-role",
        subnet_ids: ["subnet-12345", "subnet-67890"],
        launch_template: {
          id: "lt-0123456789abcdef0",
          version: "$Latest"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    node_group_config = json_output.dig(:resource, :aws_eks_node_group, :custom_launch)
    
    expect(node_group_config[:launch_template]).to be_a(Hash)
    expect(node_group_config[:launch_template][:id]).to eq("lt-0123456789abcdef0")
    expect(node_group_config[:launch_template][:version]).to eq("$Latest")
  end
  
  # Test Bottlerocket node group synthesis
  it "synthesizes Bottlerocket node group correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_node_group(:bottlerocket, {
        cluster_name: "secure-cluster",
        node_role_arn: "arn:aws:iam::123456789012:role/eks-node-role",
        subnet_ids: ["subnet-12345", "subnet-67890"],
        ami_type: "BOTTLEROCKET_x86_64",
        instance_types: ["m5.large", "m5.xlarge"],
        scaling_config: {
          desired_size: 3,
          min_size: 3,
          max_size: 6
        }
      })
    end
    
    json_output = synthesizer.synthesis
    node_group_config = json_output.dig(:resource, :aws_eks_node_group, :bottlerocket)
    
    expect(node_group_config[:ami_type]).to eq("BOTTLEROCKET_x86_64")
    expect(node_group_config[:instance_types]).to include("m5.large", "m5.xlarge")
  end
  
  # Test production node group synthesis
  it "synthesizes production node group correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_node_group(:production, {
        cluster_name: "prod-cluster",
        node_group_name: "prod-workers",
        node_role_arn: "arn:aws:iam::123456789012:role/eks-prod-node-role",
        subnet_ids: ["subnet-prod-1a", "subnet-prod-1b", "subnet-prod-1c"],
        scaling_config: {
          desired_size: 6,
          min_size: 3,
          max_size: 12
        },
        update_config: {
          max_unavailable: 1
        },
        instance_types: ["m5.xlarge", "m5a.xlarge"],
        disk_size: 50,
        labels: {
          environment: "production",
          team: "platform"
        },
        tags: {
          Environment: "production",
          ManagedBy: "terraform",
          CostCenter: "engineering"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    node_group_config = json_output.dig(:resource, :aws_eks_node_group, :production)
    
    expect(node_group_config[:node_group_name]).to eq("prod-workers")
    expect(node_group_config[:scaling_config][:desired_size]).to eq(6)
    expect(node_group_config[:update_config][:max_unavailable]).to eq(1)
    expect(node_group_config[:disk_size]).to eq(50)
    expect(node_group_config[:tags][:Environment]).to eq("production")
  end
  
  # Test ML workload node group synthesis
  it "synthesizes ML workload node group correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_node_group(:ml_training, {
        cluster_name: "ml-cluster",
        node_group_name: "gpu-training-nodes",
        node_role_arn: "arn:aws:iam::123456789012:role/eks-ml-node-role",
        subnet_ids: ["subnet-ml-1", "subnet-ml-2"],
        ami_type: "AL2_x86_64_GPU",
        instance_types: ["p3.2xlarge", "p3.8xlarge"],
        scaling_config: {
          desired_size: 0,
          min_size: 0,
          max_size: 50
        },
        disk_size: 200,
        labels: {
          workload: "ml-training",
          gpu_type: "tesla-v100"
        },
        taints: [{
          key: "nvidia.com/gpu",
          effect: "NO_SCHEDULE"
        }],
        tags: {
          Workload: "machine-learning",
          GPUEnabled: "true"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    node_group_config = json_output.dig(:resource, :aws_eks_node_group, :ml_training)
    
    expect(node_group_config[:ami_type]).to eq("AL2_x86_64_GPU")
    expect(node_group_config[:instance_types]).to include("p3.2xlarge")
    expect(node_group_config[:disk_size]).to eq(200)
    expect(node_group_config[:scaling_config][:min_size]).to eq(0)
    expect(node_group_config[:labels][:gpu_type]).to eq("tesla-v100")
  end
  
  # Test minimal node group synthesis
  it "synthesizes minimal node group correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_node_group(:minimal, {
        cluster_name: "test-cluster",
        node_role_arn: "arn:aws:iam::123456789012:role/eks-node-role",
        subnet_ids: ["subnet-12345"]
      })
    end
    
    json_output = synthesizer.synthesis
    node_group_config = json_output.dig(:resource, :aws_eks_node_group, :minimal)
    
    expect(node_group_config[:cluster_name]).to eq("test-cluster")
    expect(node_group_config[:node_role_arn]).to eq(node_role_arn)
    expect(node_group_config[:subnet_ids]).to eq(["subnet-12345"])
    
    # Optional fields should not be present
    expect(node_group_config).not_to have_key(:node_group_name)
    expect(node_group_config).not_to have_key(:update_config)
    expect(node_group_config).not_to have_key(:release_version)
    expect(node_group_config).not_to have_key(:version)
    expect(node_group_config).not_to have_key(:remote_access)
    expect(node_group_config).not_to have_key(:launch_template)
    expect(node_group_config).not_to have_key(:labels)
    expect(node_group_config).not_to have_key(:taint)
    expect(node_group_config).not_to have_key(:tags)
  end
  
  # Test node group with tags synthesis
  it "synthesizes node group with comprehensive tags correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_node_group(:tagged, {
        cluster_name: "tagged-cluster",
        node_role_arn: "arn:aws:iam::123456789012:role/eks-node-role",
        subnet_ids: ["subnet-12345", "subnet-67890"],
        tags: {
          Application: "web-platform",
          Environment: "staging",
          Team: "platform",
          CostCenter: "engineering",
          Project: "modernization",
          ManagedBy: "terraform",
          Owner: "platform-team@example.com",
          InstanceType: "spot"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    node_group_config = json_output.dig(:resource, :aws_eks_node_group, :tagged)
    
    tags = node_group_config[:tags]
    expect(tags).to be_a(Hash)
    expect(tags[:Application]).to eq("web-platform")
    expect(tags[:Environment]).to eq("staging")
    expect(tags[:Team]).to eq("platform")
    expect(tags[:CostCenter]).to eq("engineering")
    expect(tags[:Project]).to eq("modernization")
    expect(tags[:ManagedBy]).to eq("terraform")
    expect(tags[:Owner]).to eq("platform-team@example.com")
    expect(tags[:InstanceType]).to eq("spot")
  end
  
  # Test multi-instance type diversification synthesis
  it "synthesizes diversified instance types correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_node_group(:diversified, {
        cluster_name: "resilient-cluster",
        node_role_arn: "arn:aws:iam::123456789012:role/eks-node-role",
        subnet_ids: ["subnet-12345", "subnet-67890", "subnet-13579"],
        capacity_type: "SPOT",
        instance_types: [
          "m5.large", "m5a.large", "m5n.large", "m5d.large",
          "m5.xlarge", "m5a.xlarge", "m5n.xlarge", "m5d.xlarge"
        ],
        scaling_config: {
          desired_size: 20,
          min_size: 10,
          max_size: 50
        }
      })
    end
    
    json_output = synthesizer.synthesis
    node_group_config = json_output.dig(:resource, :aws_eks_node_group, :diversified)
    
    expect(node_group_config[:capacity_type]).to eq("SPOT")
    expect(node_group_config[:instance_types].size).to eq(8)
    expect(node_group_config[:instance_types]).to include("m5.large", "m5a.large", "m5n.large", "m5d.large")
  end
end