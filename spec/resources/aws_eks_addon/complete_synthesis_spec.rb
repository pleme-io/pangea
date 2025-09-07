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

# Load aws_eks_addon resource and terraform-synthesizer for testing
require 'pangea/resources/aws_eks_addon/resource'
require 'terraform-synthesizer'

RSpec.describe "aws_eks_addon terraform synthesis" do
  let(:synthesizer) { TerraformSynthesizer.new }
  
  # Test IAM role ARNs
  let(:vpc_cni_role_arn) { "arn:aws:iam::123456789012:role/vpc-cni-role" }
  let(:ebs_csi_role_arn) { "arn:aws:iam::123456789012:role/ebs-csi-role" }
  
  # Test basic addon synthesis
  it "synthesizes basic addon correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_addon(:basic, {
        cluster_name: "my-cluster",
        addon_name: "vpc-cni"
      })
    end
    
    json_output = synthesizer.synthesis
    addon_config = json_output.dig(:resource, :aws_eks_addon, :basic)
    
    expect(addon_config[:cluster_name]).to eq("my-cluster")
    expect(addon_config[:addon_name]).to eq("vpc-cni")
    
    # Should not include default values
    expect(addon_config).not_to have_key(:resolve_conflicts)
    expect(addon_config).not_to have_key(:preserve)
  end
  
  # Test addon with version synthesis
  it "synthesizes addon with version correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_addon(:versioned, {
        cluster_name: "my-cluster",
        addon_name: "vpc-cni",
        addon_version: "v1.12.6-eksbuild.2"
      })
    end
    
    json_output = synthesizer.synthesis
    addon_config = json_output.dig(:resource, :aws_eks_addon, :versioned)
    
    expect(addon_config[:addon_version]).to eq("v1.12.6-eksbuild.2")
  end
  
  # Test addon with IAM role synthesis
  it "synthesizes addon with IAM role correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_addon(:with_iam, {
        cluster_name: "my-cluster",
        addon_name: "aws-ebs-csi-driver",
        addon_version: "v1.28.0-eksbuild.1",
        service_account_role_arn: "arn:aws:iam::123456789012:role/ebs-csi-role"
      })
    end
    
    json_output = synthesizer.synthesis
    addon_config = json_output.dig(:resource, :aws_eks_addon, :with_iam)
    
    expect(addon_config[:addon_name]).to eq("aws-ebs-csi-driver")
    expect(addon_config[:service_account_role_arn]).to eq(ebs_csi_role_arn)
  end
  
  # Test addon with resolve_conflicts synthesis
  it "synthesizes addon with resolve_conflicts correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_addon(:with_conflicts, {
        cluster_name: "my-cluster",
        addon_name: "coredns",
        resolve_conflicts: "OVERWRITE"
      })
    end
    
    json_output = synthesizer.synthesis
    addon_config = json_output.dig(:resource, :aws_eks_addon, :with_conflicts)
    
    expect(addon_config[:resolve_conflicts]).to eq("OVERWRITE")
  end
  
  # Test addon with separate conflict resolution synthesis
  it "synthesizes addon with separate conflict resolution correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_addon(:granular_conflicts, {
        cluster_name: "my-cluster",
        addon_name: "kube-proxy",
        resolve_conflicts_on_create: "OVERWRITE",
        resolve_conflicts_on_update: "PRESERVE"
      })
    end
    
    json_output = synthesizer.synthesis
    addon_config = json_output.dig(:resource, :aws_eks_addon, :granular_conflicts)
    
    expect(addon_config[:resolve_conflicts_on_create]).to eq("OVERWRITE")
    expect(addon_config[:resolve_conflicts_on_update]).to eq("PRESERVE")
    expect(addon_config).not_to have_key(:resolve_conflicts)
  end
  
  # Test addon with configuration values synthesis
  it "synthesizes addon with configuration correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      config_json = JSON.generate({
        computeType: "Fargate",
        replicaCount: 3,
        resources: {
          limits: {
            cpu: "100m",
            memory: "150Mi"
          }
        }
      })
      
      aws_eks_addon(:with_config, {
        cluster_name: "my-cluster",
        addon_name: "coredns",
        configuration_values: config_json
      })
    end
    
    json_output = synthesizer.synthesis
    addon_config = json_output.dig(:resource, :aws_eks_addon, :with_config)
    
    expect(addon_config[:configuration_values]).to be_a(String)
    parsed_config = JSON.parse(addon_config[:configuration_values])
    expect(parsed_config["computeType"]).to eq("Fargate")
    expect(parsed_config["replicaCount"]).to eq(3)
  end
  
  # Test addon with preserve false synthesis
  it "synthesizes addon with preserve false correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_addon(:no_preserve, {
        cluster_name: "my-cluster",
        addon_name: "snapshot-controller",
        preserve: false
      })
    end
    
    json_output = synthesizer.synthesis
    addon_config = json_output.dig(:resource, :aws_eks_addon, :no_preserve)
    
    expect(addon_config[:preserve]).to eq(false)
  end
  
  # Test VPC CNI addon synthesis
  it "synthesizes VPC CNI addon correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_addon(:vpc_cni, {
        cluster_name: "production-cluster",
        addon_name: "vpc-cni",
        addon_version: "v1.12.6-eksbuild.2",
        service_account_role_arn: "arn:aws:iam::123456789012:role/vpc-cni-role",
        configuration_values: JSON.generate({
          env: {
            ENABLE_PREFIX_DELEGATION: "true",
            WARM_PREFIX_TARGET: "1"
          }
        }),
        tags: {
          Component: "networking",
          Critical: "true"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    addon_config = json_output.dig(:resource, :aws_eks_addon, :vpc_cni)
    
    expect(addon_config[:addon_name]).to eq("vpc-cni")
    expect(addon_config[:service_account_role_arn]).to eq(vpc_cni_role_arn)
    expect(addon_config[:tags][:Component]).to eq("networking")
  end
  
  # Test EBS CSI driver addon synthesis
  it "synthesizes EBS CSI driver addon correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_addon(:ebs_csi, {
        cluster_name: "stateful-cluster",
        addon_name: "aws-ebs-csi-driver",
        addon_version: "v1.28.0-eksbuild.1",
        service_account_role_arn: "arn:aws:iam::123456789012:role/ebs-csi-role",
        resolve_conflicts_on_create: "OVERWRITE",
        configuration_values: JSON.generate({
          controller: {
            replicaCount: 2
          }
        })
      })
    end
    
    json_output = synthesizer.synthesis
    addon_config = json_output.dig(:resource, :aws_eks_addon, :ebs_csi)
    
    expect(addon_config[:addon_name]).to eq("aws-ebs-csi-driver")
    expect(addon_config[:resolve_conflicts_on_create]).to eq("OVERWRITE")
    expect(addon_config).not_to have_key(:resolve_conflicts)
  end
  
  # Test GuardDuty agent addon synthesis
  it "synthesizes GuardDuty agent addon correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_addon(:guardduty, {
        cluster_name: "secure-cluster",
        addon_name: "aws-guardduty-agent",
        addon_version: "v1.4.0-eksbuild.1",
        service_account_role_arn: "arn:aws:iam::123456789012:role/guardduty-agent-role",
        resolve_conflicts: "OVERWRITE",
        preserve: false,
        tags: {
          SecurityCompliance: "required"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    addon_config = json_output.dig(:resource, :aws_eks_addon, :guardduty)
    
    expect(addon_config[:addon_name]).to eq("aws-guardduty-agent")
    expect(addon_config[:resolve_conflicts]).to eq("OVERWRITE")
    expect(addon_config[:preserve]).to eq(false)
    expect(addon_config[:tags][:SecurityCompliance]).to eq("required")
  end
  
  # Test CoreDNS addon for Fargate synthesis
  it "synthesizes CoreDNS for Fargate correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_addon(:coredns_fargate, {
        cluster_name: "fargate-cluster",
        addon_name: "coredns",
        addon_version: "v1.10.1-eksbuild.7",
        configuration_values: JSON.generate({
          computeType: "Fargate",
          replicaCount: 3,
          resources: {
            limits: {
              cpu: "100m",
              memory: "150Mi"
            }
          }
        })
      })
    end
    
    json_output = synthesizer.synthesis
    addon_config = json_output.dig(:resource, :aws_eks_addon, :coredns_fargate)
    
    expect(addon_config[:addon_name]).to eq("coredns")
    config = JSON.parse(addon_config[:configuration_values])
    expect(config["computeType"]).to eq("Fargate")
  end
  
  # Test ADOT addon synthesis
  it "synthesizes ADOT addon correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_addon(:adot, {
        cluster_name: "observability-cluster",
        addon_name: "adot",
        addon_version: "v0.90.0-eksbuild.1",
        service_account_role_arn: "arn:aws:iam::123456789012:role/adot-collector-role",
        configuration_values: JSON.generate({
          collector: {
            resources: {
              limits: {
                cpu: "200m",
                memory: "256Mi"
              }
            }
          }
        })
      })
    end
    
    json_output = synthesizer.synthesis
    addon_config = json_output.dig(:resource, :aws_eks_addon, :adot)
    
    expect(addon_config[:addon_name]).to eq("adot")
    expect(addon_config[:addon_version]).to eq("v0.90.0-eksbuild.1")
  end
  
  # Test minimal addon synthesis
  it "synthesizes minimal addon correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_addon(:minimal, {
        cluster_name: "test-cluster",
        addon_name: "kube-proxy"
      })
    end
    
    json_output = synthesizer.synthesis
    addon_config = json_output.dig(:resource, :aws_eks_addon, :minimal)
    
    expect(addon_config[:cluster_name]).to eq("test-cluster")
    expect(addon_config[:addon_name]).to eq("kube-proxy")
    
    # Optional fields should not be present
    expect(addon_config).not_to have_key(:addon_version)
    expect(addon_config).not_to have_key(:service_account_role_arn)
    expect(addon_config).not_to have_key(:resolve_conflicts)
    expect(addon_config).not_to have_key(:resolve_conflicts_on_create)
    expect(addon_config).not_to have_key(:resolve_conflicts_on_update)
    expect(addon_config).not_to have_key(:configuration_values)
    expect(addon_config).not_to have_key(:preserve)
    expect(addon_config).not_to have_key(:tags)
  end
  
  # Test addon with comprehensive tags synthesis
  it "synthesizes addon with comprehensive tags correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_eks_addon(:tagged, {
        cluster_name: "tagged-cluster",
        addon_name: "vpc-cni",
        tags: {
          Application: "kubernetes-platform",
          Environment: "production",
          Team: "platform",
          CostCenter: "engineering",
          Project: "eks-migration",
          ManagedBy: "terraform",
          Owner: "platform-team@example.com",
          Critical: "true"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    addon_config = json_output.dig(:resource, :aws_eks_addon, :tagged)
    
    tags = addon_config[:tags]
    expect(tags).to be_a(Hash)
    expect(tags[:Application]).to eq("kubernetes-platform")
    expect(tags[:Environment]).to eq("production")
    expect(tags[:Team]).to eq("platform")
    expect(tags[:CostCenter]).to eq("engineering")
    expect(tags[:Project]).to eq("eks-migration")
    expect(tags[:ManagedBy]).to eq("terraform")
    expect(tags[:Owner]).to eq("platform-team@example.com")
    expect(tags[:Critical]).to eq("true")
  end
  
  # Test multiple storage addons synthesis
  it "synthesizes multiple storage addons correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      # EBS CSI Driver
      aws_eks_addon(:ebs_csi, {
        cluster_name: "storage-cluster",
        addon_name: "aws-ebs-csi-driver",
        service_account_role_arn: "arn:aws:iam::123456789012:role/ebs-csi-role"
      })
      
      # EFS CSI Driver
      aws_eks_addon(:efs_csi, {
        cluster_name: "storage-cluster",
        addon_name: "aws-efs-csi-driver",
        service_account_role_arn: "arn:aws:iam::123456789012:role/efs-csi-role"
      })
      
      # S3 CSI Driver
      aws_eks_addon(:s3_csi, {
        cluster_name: "storage-cluster",
        addon_name: "aws-mountpoint-s3-csi-driver",
        service_account_role_arn: "arn:aws:iam::123456789012:role/s3-csi-role"
      })
    end
    
    json_output = synthesizer.synthesis
    
    ebs_config = json_output.dig(:resource, :aws_eks_addon, :ebs_csi)
    expect(ebs_config[:addon_name]).to eq("aws-ebs-csi-driver")
    
    efs_config = json_output.dig(:resource, :aws_eks_addon, :efs_csi)
    expect(efs_config[:addon_name]).to eq("aws-efs-csi-driver")
    
    s3_config = json_output.dig(:resource, :aws_eks_addon, :s3_csi)
    expect(s3_config[:addon_name]).to eq("aws-mountpoint-s3-csi-driver")
  end
end