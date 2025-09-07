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

# Load aws_eks_cluster resource and terraform-synthesizer for testing
require 'pangea/resources/aws_eks_cluster/resource'
require 'terraform-synthesizer'

RSpec.describe "aws_eks_cluster terraform synthesis" do
  let(:synthesizer) { TerraformSynthesizer.new }
  
  # Test IAM role and KMS key ARNs
  let(:cluster_role_arn) { "arn:aws:iam::123456789012:role/eks-cluster-role" }
  let(:kms_key_arn) { "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012" }
  
  # Test basic EKS cluster synthesis
  it "synthesizes basic EKS cluster correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_cluster(:basic, {
        role_arn: "arn:aws:iam::123456789012:role/eks-cluster-role",
        vpc_config: {
          subnet_ids: ["subnet-12345", "subnet-67890"]
        }
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_eks_cluster, :basic)
    
    expect(cluster_config[:role_arn]).to eq(cluster_role_arn)
    expect(cluster_config[:version]).to eq("1.28")
    
    vpc_config = cluster_config[:vpc_config]
    expect(vpc_config[:subnet_ids]).to eq(["subnet-12345", "subnet-67890"])
    expect(vpc_config[:endpoint_private_access]).to eq(false)
    expect(vpc_config[:endpoint_public_access]).to eq(true)
    expect(vpc_config[:public_access_cidrs]).to eq(["0.0.0.0/0"])
  end
  
  # Test EKS cluster with custom name synthesis
  it "synthesizes EKS cluster with custom name correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_cluster(:prod, {
        name: "production-cluster",
        role_arn: "arn:aws:iam::123456789012:role/eks-cluster-role",
        version: "1.29",
        vpc_config: {
          subnet_ids: ["subnet-prod1", "subnet-prod2", "subnet-prod3"]
        }
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_eks_cluster, :prod)
    
    expect(cluster_config[:name]).to eq("production-cluster")
    expect(cluster_config[:version]).to eq("1.29")
    expect(cluster_config[:vpc_config][:subnet_ids].size).to eq(3)
  end
  
  # Test EKS cluster with private endpoint synthesis
  it "synthesizes EKS cluster with private endpoint correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_cluster(:private, {
        role_arn: "arn:aws:iam::123456789012:role/eks-cluster-role",
        vpc_config: {
          subnet_ids: ["subnet-private1", "subnet-private2"],
          security_group_ids: ["sg-cluster"],
          endpoint_private_access: true,
          endpoint_public_access: false
        }
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_eks_cluster, :private)
    
    vpc_config = cluster_config[:vpc_config]
    expect(vpc_config[:endpoint_private_access]).to eq(true)
    expect(vpc_config[:endpoint_public_access]).to eq(false)
    expect(vpc_config[:security_group_ids]).to eq(["sg-cluster"])
    expect(vpc_config).not_to have_key(:public_access_cidrs)
  end
  
  # Test EKS cluster with logging enabled synthesis
  it "synthesizes EKS cluster with logging correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_cluster(:logged, {
        role_arn: "arn:aws:iam::123456789012:role/eks-cluster-role",
        vpc_config: {
          subnet_ids: ["subnet-12345", "subnet-67890"]
        },
        enabled_cluster_log_types: ["api", "audit", "authenticator", "controllerManager", "scheduler"]
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_eks_cluster, :logged)
    
    expect(cluster_config[:enabled_cluster_log_types]).to be_an(Array)
    expect(cluster_config[:enabled_cluster_log_types].size).to eq(5)
    expect(cluster_config[:enabled_cluster_log_types]).to include("api", "audit", "authenticator")
  end
  
  # Test EKS cluster with encryption synthesis
  it "synthesizes EKS cluster with encryption correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_cluster(:encrypted, {
        role_arn: "arn:aws:iam::123456789012:role/eks-cluster-role",
        vpc_config: {
          subnet_ids: ["subnet-12345", "subnet-67890"]
        },
        encryption_config: [{
          resources: ["secrets"],
          provider: { 
            key_arn: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012" 
          }
        }]
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_eks_cluster, :encrypted)
    
    expect(cluster_config[:encryption_config]).to be_an(Array)
    expect(cluster_config[:encryption_config].size).to eq(1)
    
    encryption = cluster_config[:encryption_config].first
    expect(encryption[:resources]).to eq(["secrets"])
    expect(encryption[:provider]).to be_a(Hash)
    expect(encryption[:provider][:key_arn]).to eq(kms_key_arn)
  end
  
  # Test EKS cluster with Kubernetes network config synthesis
  it "synthesizes EKS cluster with network config correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_cluster(:custom_net, {
        role_arn: "arn:aws:iam::123456789012:role/eks-cluster-role",
        vpc_config: {
          subnet_ids: ["subnet-12345", "subnet-67890"]
        },
        kubernetes_network_config: {
          service_ipv4_cidr: "172.20.0.0/16",
          ip_family: "ipv4"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_eks_cluster, :custom_net)
    
    k8s_network = cluster_config[:kubernetes_network_config]
    expect(k8s_network).to be_a(Hash)
    expect(k8s_network[:service_ipv4_cidr]).to eq("172.20.0.0/16")
    expect(k8s_network[:ip_family]).to eq("ipv4")
  end
  
  # Test production-ready EKS cluster synthesis
  it "synthesizes production EKS cluster correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_cluster(:production, {
        name: "prod-cluster",
        role_arn: "arn:aws:iam::123456789012:role/eks-cluster-role",
        version: "1.29",
        vpc_config: {
          subnet_ids: ["subnet-prod-1a", "subnet-prod-1b", "subnet-prod-1c"],
          security_group_ids: ["sg-cluster-prod"],
          endpoint_private_access: true,
          endpoint_public_access: true,
          public_access_cidrs: ["10.0.0.0/8", "172.16.0.0/12"]
        },
        enabled_cluster_log_types: ["api", "audit", "authenticator"],
        encryption_config: [{
          resources: ["secrets"],
          provider: { key_arn: "arn:aws:kms:us-east-1:123456789012:key/prod-key" }
        }],
        kubernetes_network_config: {
          service_ipv4_cidr: "172.20.0.0/16"
        },
        tags: {
          Environment: "production",
          CostCenter: "engineering",
          ManagedBy: "terraform"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_eks_cluster, :production)
    
    expect(cluster_config[:name]).to eq("prod-cluster")
    expect(cluster_config[:version]).to eq("1.29")
    expect(cluster_config[:enabled_cluster_log_types].size).to eq(3)
    expect(cluster_config[:encryption_config]).to be_an(Array)
    expect(cluster_config[:tags][:Environment]).to eq("production")
    
    vpc_config = cluster_config[:vpc_config]
    expect(vpc_config[:subnet_ids].size).to eq(3)
    expect(vpc_config[:public_access_cidrs]).not_to include("0.0.0.0/0")
  end
  
  # Test microservices platform EKS cluster synthesis
  it "synthesizes microservices EKS cluster correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_cluster(:microservices, {
        name: "microservices-platform",
        role_arn: "arn:aws:iam::123456789012:role/eks-microservices-role",
        version: "1.29",
        vpc_config: {
          subnet_ids: ["subnet-ms-1a", "subnet-ms-1b", "subnet-ms-1c"],
          endpoint_private_access: true,
          endpoint_public_access: true
        },
        enabled_cluster_log_types: ["api", "audit"],
        kubernetes_network_config: {
          service_ipv4_cidr: "172.20.0.0/14"
        },
        tags: {
          Platform: "microservices",
          ServiceMesh: "istio",
          Monitoring: "prometheus"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_eks_cluster, :microservices)
    
    expect(cluster_config[:name]).to eq("microservices-platform")
    expect(cluster_config[:kubernetes_network_config][:service_ipv4_cidr]).to eq("172.20.0.0/14")
    expect(cluster_config[:tags][:ServiceMesh]).to eq("istio")
    expect(cluster_config[:tags][:Monitoring]).to eq("prometheus")
  end
  
  # Test data processing EKS cluster synthesis
  it "synthesizes data processing EKS cluster correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_cluster(:data_processing, {
        name: "data-platform",
        role_arn: "arn:aws:iam::123456789012:role/eks-data-role",
        version: "1.28",
        vpc_config: {
          subnet_ids: ["subnet-data-1", "subnet-data-2"],
          endpoint_private_access: true,
          endpoint_public_access: false
        },
        encryption_config: [{
          resources: ["secrets"],
          provider: { key_arn: "arn:aws:kms:us-east-1:123456789012:key/data-key" }
        }],
        tags: {
          Platform: "data-processing",
          Framework: "spark",
          DataClassification: "sensitive"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_eks_cluster, :data_processing)
    
    expect(cluster_config[:name]).to eq("data-platform")
    expect(cluster_config[:vpc_config][:endpoint_public_access]).to eq(false)
    expect(cluster_config[:encryption_config]).to be_an(Array)
    expect(cluster_config[:tags][:DataClassification]).to eq("sensitive")
  end
  
  # Test multi-region EKS cluster synthesis
  it "synthesizes multi-region EKS cluster correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_cluster(:multi_region, {
        name: "global-cluster-us-east-1",
        role_arn: "arn:aws:iam::123456789012:role/eks-global-role",
        version: "1.29",
        vpc_config: {
          subnet_ids: ["subnet-use1-az1", "subnet-use1-az2", "subnet-use1-az3"],
          endpoint_private_access: true,
          endpoint_public_access: true,
          public_access_cidrs: ["10.0.0.0/8"]
        },
        enabled_cluster_log_types: ["api", "audit"],
        tags: {
          Region: "us-east-1",
          GlobalCluster: "true",
          ReplicationGroup: "global-cluster"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_eks_cluster, :multi_region)
    
    expect(cluster_config[:name]).to include("global-cluster")
    expect(cluster_config[:tags][:GlobalCluster]).to eq("true")
    expect(cluster_config[:tags][:ReplicationGroup]).to eq("global-cluster")
  end
  
  # Test development EKS cluster synthesis
  it "synthesizes development EKS cluster correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_cluster(:dev, {
        name: "dev-cluster",
        role_arn: "arn:aws:iam::123456789012:role/eks-dev-role",
        version: "1.28",
        vpc_config: {
          subnet_ids: ["subnet-dev1", "subnet-dev2"],
          endpoint_public_access: true,
          endpoint_private_access: false
        },
        tags: {
          Environment: "development",
          AutoShutdown: "true",
          CostOptimized: "true"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_eks_cluster, :dev)
    
    expect(cluster_config[:name]).to eq("dev-cluster")
    expect(cluster_config[:vpc_config][:endpoint_private_access]).to eq(false)
    expect(cluster_config[:tags][:AutoShutdown]).to eq("true")
    expect(cluster_config[:tags][:CostOptimized]).to eq("true")
  end
  
  # Test EKS cluster with restricted public access synthesis
  it "synthesizes EKS cluster with restricted access correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_cluster(:restricted, {
        role_arn: "arn:aws:iam::123456789012:role/eks-cluster-role",
        vpc_config: {
          subnet_ids: ["subnet-12345", "subnet-67890"],
          endpoint_private_access: true,
          endpoint_public_access: true,
          public_access_cidrs: ["203.0.113.0/24", "198.51.100.0/24", "192.0.2.0/24"]
        }
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_eks_cluster, :restricted)
    
    public_cidrs = cluster_config[:vpc_config][:public_access_cidrs]
    expect(public_cidrs).to be_an(Array)
    expect(public_cidrs).not_to include("0.0.0.0/0")
    expect(public_cidrs).to include("203.0.113.0/24")
  end
  
  # Test minimal EKS cluster synthesis
  it "synthesizes minimal EKS cluster correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_cluster(:minimal, {
        role_arn: "arn:aws:iam::123456789012:role/eks-cluster-role",
        vpc_config: {
          subnet_ids: ["subnet-12345", "subnet-67890"]
        }
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_eks_cluster, :minimal)
    
    expect(cluster_config[:role_arn]).to eq(cluster_role_arn)
    expect(cluster_config[:version]).to eq("1.28")
    
    # Optional fields should not be present
    expect(cluster_config).not_to have_key(:name)
    expect(cluster_config).not_to have_key(:enabled_cluster_log_types)
    expect(cluster_config).not_to have_key(:encryption_config)
    expect(cluster_config).not_to have_key(:kubernetes_network_config)
    expect(cluster_config).not_to have_key(:tags)
    
    # VPC config should have minimal fields
    vpc_config = cluster_config[:vpc_config]
    expect(vpc_config).not_to have_key(:security_group_ids)
  end
  
  # Test EKS cluster with tags synthesis
  it "synthesizes EKS cluster with comprehensive tags correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_cluster(:tagged, {
        role_arn: "arn:aws:iam::123456789012:role/eks-cluster-role",
        vpc_config: {
          subnet_ids: ["subnet-12345", "subnet-67890"]
        },
        tags: {
          Application: "web-platform",
          Environment: "staging",
          Team: "platform",
          CostCenter: "engineering",
          Project: "modernization",
          ManagedBy: "terraform",
          Owner: "platform-team@example.com"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_eks_cluster, :tagged)
    
    tags = cluster_config[:tags]
    expect(tags).to be_a(Hash)
    expect(tags[:Application]).to eq("web-platform")
    expect(tags[:Environment]).to eq("staging")
    expect(tags[:Team]).to eq("platform")
    expect(tags[:CostCenter]).to eq("engineering")
    expect(tags[:Project]).to eq("modernization")
    expect(tags[:ManagedBy]).to eq("terraform")
    expect(tags[:Owner]).to eq("platform-team@example.com")
  end
  
  # Test EKS cluster for ML/AI workloads synthesis
  it "synthesizes ML/AI EKS cluster correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_cluster(:ml_platform, {
        name: "ml-ai-cluster",
        role_arn: "arn:aws:iam::123456789012:role/eks-ml-role",
        version: "1.29",
        vpc_config: {
          subnet_ids: ["subnet-ml-1a", "subnet-ml-1b", "subnet-ml-1c"],
          endpoint_private_access: true,
          endpoint_public_access: true
        },
        enabled_cluster_log_types: ["api", "audit", "scheduler"],
        tags: {
          Platform: "machine-learning",
          GPUEnabled: "true",
          Framework: "kubeflow",
          CostTracking: "ml-experiments"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_eks_cluster, :ml_platform)
    
    expect(cluster_config[:name]).to eq("ml-ai-cluster")
    expect(cluster_config[:tags][:Platform]).to eq("machine-learning")
    expect(cluster_config[:tags][:GPUEnabled]).to eq("true")
    expect(cluster_config[:tags][:Framework]).to eq("kubeflow")
    expect(cluster_config[:enabled_cluster_log_types]).to include("scheduler")
  end
end