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

# Load aws_eks_addon resource and types for testing
require 'pangea/resources/aws_eks_addon/resource'
require 'pangea/resources/aws_eks_addon/types'

RSpec.describe "aws_eks_addon resource function" do
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
  
  # Test IAM role ARN for service accounts
  let(:vpc_cni_role_arn) { "arn:aws:iam::123456789012:role/vpc-cni-role" }
  let(:ebs_csi_role_arn) { "arn:aws:iam::123456789012:role/ebs-csi-role" }
  
  describe "EksAddonAttributes validation" do
    it "accepts minimal valid configuration" do
      addon = Pangea::Resources::AWS::Types::EksAddonAttributes.new({
        cluster_name: "my-cluster",
        addon_name: "vpc-cni"
      })
      
      expect(addon.cluster_name).to eq("my-cluster")
      expect(addon.addon_name).to eq("vpc-cni")
      expect(addon.resolve_conflicts).to eq("NONE")
      expect(addon.preserve).to eq(true)
      expect(addon.tags).to eq({})
    end
    
    it "accepts full configuration" do
      addon = Pangea::Resources::AWS::Types::EksAddonAttributes.new({
        cluster_name: "my-cluster",
        addon_name: "aws-ebs-csi-driver",
        addon_version: "v1.28.0-eksbuild.1",
        service_account_role_arn: ebs_csi_role_arn,
        resolve_conflicts_on_create: "OVERWRITE",
        resolve_conflicts_on_update: "PRESERVE",
        configuration_values: JSON.generate({ 
          controller: { 
            replicaCount: 2 
          }
        }),
        preserve: false,
        tags: {
          Environment: "production",
          Team: "platform"
        }
      })
      
      expect(addon.addon_version).to eq("v1.28.0-eksbuild.1")
      expect(addon.service_account_role_arn).to eq(ebs_csi_role_arn)
      expect(addon.resolve_conflicts_on_create).to eq("OVERWRITE")
      expect(addon.resolve_conflicts_on_update).to eq("PRESERVE")
      expect(addon.configuration_values).to include("replicaCount")
      expect(addon.preserve).to eq(false)
      expect(addon.tags[:Environment]).to eq("production")
    end
    
    it "validates addon name from supported list" do
      expect {
        Pangea::Resources::AWS::Types::EksAddonAttributes.new({
          cluster_name: "my-cluster",
          addon_name: "invalid-addon"
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
    
    it "accepts all supported addon names" do
      addon_names = [
        "vpc-cni", "coredns", "kube-proxy", "aws-ebs-csi-driver",
        "aws-efs-csi-driver", "aws-guardduty-agent", 
        "aws-mountpoint-s3-csi-driver", "snapshot-controller", "adot"
      ]
      
      addon_names.each do |name|
        addon = Pangea::Resources::AWS::Types::EksAddonAttributes.new({
          cluster_name: "my-cluster",
          addon_name: name
        })
        expect(addon.addon_name).to eq(name)
      end
    end
    
    it "validates addon version for specific addon" do
      expect {
        Pangea::Resources::AWS::Types::EksAddonAttributes.new({
          cluster_name: "my-cluster",
          addon_name: "vpc-cni",
          addon_version: "v99.99.99"
        })
      }.to raise_error(Dry::Struct::Error, /Invalid version .* for addon/)
    end
    
    it "accepts valid addon version" do
      addon = Pangea::Resources::AWS::Types::EksAddonAttributes.new({
        cluster_name: "my-cluster",
        addon_name: "vpc-cni",
        addon_version: "v1.12.6-eksbuild.2"
      })
      
      expect(addon.addon_version).to eq("v1.12.6-eksbuild.2")
    end
    
    it "validates IAM role ARN format" do
      expect {
        Pangea::Resources::AWS::Types::EksAddonAttributes.new({
          cluster_name: "my-cluster",
          addon_name: "vpc-cni",
          service_account_role_arn: "invalid-arn"
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
    
    it "validates resolve_conflicts options" do
      expect {
        Pangea::Resources::AWS::Types::EksAddonAttributes.new({
          cluster_name: "my-cluster",
          addon_name: "vpc-cni",
          resolve_conflicts: "INVALID"
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
    
    it "accepts valid resolve_conflicts options" do
      ["OVERWRITE", "NONE", "PRESERVE"].each do |option|
        addon = Pangea::Resources::AWS::Types::EksAddonAttributes.new({
          cluster_name: "my-cluster",
          addon_name: "vpc-cni",
          resolve_conflicts: option
        })
        expect(addon.resolve_conflicts).to eq(option)
      end
    end
    
    it "rejects both resolve_conflicts and resolve_conflicts_on_create" do
      expect {
        Pangea::Resources::AWS::Types::EksAddonAttributes.new({
          cluster_name: "my-cluster",
          addon_name: "vpc-cni",
          resolve_conflicts: "OVERWRITE",
          resolve_conflicts_on_create: "PRESERVE"
        })
      }.to raise_error(Dry::Struct::Error, /Cannot specify both resolve_conflicts and resolve_conflicts_on_create/)
    end
    
    it "rejects both resolve_conflicts and resolve_conflicts_on_update" do
      expect {
        Pangea::Resources::AWS::Types::EksAddonAttributes.new({
          cluster_name: "my-cluster",
          addon_name: "vpc-cni",
          resolve_conflicts: "OVERWRITE",
          resolve_conflicts_on_update: "PRESERVE"
        })
      }.to raise_error(Dry::Struct::Error, /Cannot specify both resolve_conflicts and resolve_conflicts_on_update/)
    end
    
    it "accepts separate create and update conflict resolution" do
      addon = Pangea::Resources::AWS::Types::EksAddonAttributes.new({
        cluster_name: "my-cluster",
        addon_name: "vpc-cni",
        resolve_conflicts_on_create: "OVERWRITE",
        resolve_conflicts_on_update: "PRESERVE"
      })
      
      expect(addon.resolve_conflicts_on_create).to eq("OVERWRITE")
      expect(addon.resolve_conflicts_on_update).to eq("PRESERVE")
    end
    
    it "validates configuration_values is valid JSON" do
      expect {
        Pangea::Resources::AWS::Types::EksAddonAttributes.new({
          cluster_name: "my-cluster",
          addon_name: "coredns",
          configuration_values: "invalid json {"
        })
      }.to raise_error(Dry::Struct::Error, /configuration_values must be valid JSON/)
    end
    
    it "accepts valid JSON configuration" do
      config = JSON.generate({
        replicaCount: 3,
        resources: {
          limits: {
            cpu: "100m",
            memory: "150Mi"
          }
        }
      })
      
      addon = Pangea::Resources::AWS::Types::EksAddonAttributes.new({
        cluster_name: "my-cluster",
        addon_name: "coredns",
        configuration_values: config
      })
      
      expect(addon.configuration_values).to eq(config)
    end
  end
  
  describe "computed properties" do
    let(:vpc_cni_addon) do
      Pangea::Resources::AWS::Types::EksAddonAttributes.new({
        cluster_name: "my-cluster",
        addon_name: "vpc-cni"
      })
    end
    
    let(:ebs_csi_addon) do
      Pangea::Resources::AWS::Types::EksAddonAttributes.new({
        cluster_name: "my-cluster",
        addon_name: "aws-ebs-csi-driver"
      })
    end
    
    let(:coredns_addon) do
      Pangea::Resources::AWS::Types::EksAddonAttributes.new({
        cluster_name: "my-cluster",
        addon_name: "coredns"
      })
    end
    
    let(:guardduty_addon) do
      Pangea::Resources::AWS::Types::EksAddonAttributes.new({
        cluster_name: "my-cluster",
        addon_name: "aws-guardduty-agent"
      })
    end
    
    it "provides addon info" do
      info = vpc_cni_addon.addon_info
      expect(info[:service_account]).to eq("aws-node")
      expect(info[:namespace]).to eq("kube-system")
      expect(info[:description]).to include("VPC CNI")
    end
    
    it "provides service account name" do
      expect(vpc_cni_addon.service_account_name).to eq("aws-node")
      expect(ebs_csi_addon.service_account_name).to eq("ebs-csi-controller-sa")
      expect(coredns_addon.service_account_name).to eq("coredns")
    end
    
    it "provides namespace" do
      expect(vpc_cni_addon.namespace).to eq("kube-system")
      expect(guardduty_addon.namespace).to eq("amazon-guardduty")
    end
    
    it "detects IAM role requirement" do
      expect(vpc_cni_addon.requires_iam_role?).to eq(true)
      expect(ebs_csi_addon.requires_iam_role?).to eq(true)
      expect(coredns_addon.requires_iam_role?).to eq(false)
    end
    
    it "categorizes compute addons" do
      expect(vpc_cni_addon.is_compute_addon?).to eq(true)
      expect(Pangea::Resources::AWS::Types::EksAddonAttributes.new({
        cluster_name: "my-cluster",
        addon_name: "kube-proxy"
      }).is_compute_addon?).to eq(true)
      expect(ebs_csi_addon.is_compute_addon?).to eq(false)
    end
    
    it "categorizes storage addons" do
      expect(ebs_csi_addon.is_storage_addon?).to eq(true)
      expect(Pangea::Resources::AWS::Types::EksAddonAttributes.new({
        cluster_name: "my-cluster",
        addon_name: "aws-efs-csi-driver"
      }).is_storage_addon?).to eq(true)
      expect(vpc_cni_addon.is_storage_addon?).to eq(false)
    end
    
    it "categorizes networking addons" do
      expect(vpc_cni_addon.is_networking_addon?).to eq(true)
      expect(coredns_addon.is_networking_addon?).to eq(true)
      expect(ebs_csi_addon.is_networking_addon?).to eq(false)
    end
    
    it "categorizes observability addons" do
      expect(guardduty_addon.is_observability_addon?).to eq(true)
      expect(Pangea::Resources::AWS::Types::EksAddonAttributes.new({
        cluster_name: "my-cluster",
        addon_name: "adot"
      }).is_observability_addon?).to eq(true)
      expect(vpc_cni_addon.is_observability_addon?).to eq(false)
    end
  end
  
  describe "aws_eks_addon function" do
    it "creates basic addon" do
      result = test_instance.aws_eks_addon(:vpc_cni, {
        cluster_name: "my-cluster",
        addon_name: "vpc-cni"
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.type).to eq('aws_eks_addon')
      expect(result.name).to eq(:vpc_cni)
      expect(result.addon_name).to eq("vpc-cni")
    end
    
    it "creates addon with version" do
      result = test_instance.aws_eks_addon(:vpc_cni, {
        cluster_name: "my-cluster",
        addon_name: "vpc-cni",
        addon_version: "v1.12.6-eksbuild.2"
      })
      
      expect(result.resource_attributes[:addon_version]).to eq("v1.12.6-eksbuild.2")
    end
    
    it "creates addon with IAM role" do
      result = test_instance.aws_eks_addon(:ebs_csi, {
        cluster_name: "my-cluster",
        addon_name: "aws-ebs-csi-driver",
        service_account_role_arn: ebs_csi_role_arn
      })
      
      expect(result.resource_attributes[:service_account_role_arn]).to eq(ebs_csi_role_arn)
      expect(result.requires_iam_role?).to eq(true)
    end
    
    it "creates addon with conflict resolution" do
      result = test_instance.aws_eks_addon(:coredns, {
        cluster_name: "my-cluster",
        addon_name: "coredns",
        resolve_conflicts: "OVERWRITE"
      })
      
      expect(result.resource_attributes[:resolve_conflicts]).to eq("OVERWRITE")
    end
    
    it "creates addon with separate conflict resolution" do
      result = test_instance.aws_eks_addon(:kube_proxy, {
        cluster_name: "my-cluster",
        addon_name: "kube-proxy",
        resolve_conflicts_on_create: "OVERWRITE",
        resolve_conflicts_on_update: "PRESERVE"
      })
      
      expect(result.resource_attributes[:resolve_conflicts_on_create]).to eq("OVERWRITE")
      expect(result.resource_attributes[:resolve_conflicts_on_update]).to eq("PRESERVE")
    end
    
    it "creates addon with configuration" do
      config = JSON.generate({
        computeType: "Fargate",
        replicaCount: 3
      })
      
      result = test_instance.aws_eks_addon(:coredns_fargate, {
        cluster_name: "my-cluster",
        addon_name: "coredns",
        configuration_values: config
      })
      
      expect(result.resource_attributes[:configuration_values]).to eq(config)
    end
    
    it "creates addon without preservation" do
      result = test_instance.aws_eks_addon(:temp_addon, {
        cluster_name: "my-cluster",
        addon_name: "snapshot-controller",
        preserve: false
      })
      
      expect(result.resource_attributes[:preserve]).to eq(false)
    end
    
    it "provides correct outputs" do
      result = test_instance.aws_eks_addon(:test, {
        cluster_name: "my-cluster",
        addon_name: "vpc-cni"
      })
      
      expect(result.id).to eq("${aws_eks_addon.test.id}")
      expect(result.arn).to eq("${aws_eks_addon.test.arn}")
      expect(result.addon_version).to eq("${aws_eks_addon.test.addon_version}")
      expect(result.created_at).to eq("${aws_eks_addon.test.created_at}")
      expect(result.modified_at).to eq("${aws_eks_addon.test.modified_at}")
      expect(result.status).to eq("${aws_eks_addon.test.status}")
      expect(result.configuration_values).to eq("${aws_eks_addon.test.configuration_values}")
      expect(result.tags_all).to eq("${aws_eks_addon.test.tags_all}")
    end
    
    it "provides computed properties" do
      result = test_instance.aws_eks_addon(:test, {
        cluster_name: "my-cluster",
        addon_name: "aws-ebs-csi-driver"
      })
      
      expect(result.addon_name).to eq("aws-ebs-csi-driver")
      expect(result.service_account).to eq("ebs-csi-controller-sa")
      expect(result.namespace).to eq("kube-system")
      expect(result.requires_iam_role?).to eq(true)
      expect(result.is_compute_addon?).to eq(false)
      expect(result.is_storage_addon?).to eq(true)
      expect(result.is_networking_addon?).to eq(false)
      expect(result.is_observability_addon?).to eq(false)
      expect(result.addon_description).to include("EBS CSI")
    end
  end
  
  describe "addon deployment patterns" do
    it "creates VPC CNI addon with custom configuration" do
      result = test_instance.aws_eks_addon(:vpc_cni_custom, {
        cluster_name: "production-cluster",
        addon_name: "vpc-cni",
        addon_version: "v1.12.6-eksbuild.2",
        service_account_role_arn: vpc_cni_role_arn,
        configuration_values: JSON.generate({
          env: {
            ENABLE_PREFIX_DELEGATION: "true",
            WARM_PREFIX_TARGET: "1",
            MINIMUM_IP_TARGET: "10"
          }
        }),
        tags: {
          Component: "networking",
          Critical: "true"
        }
      })
      
      expect(result.addon_name).to eq("vpc-cni")
      expect(result.requires_iam_role?).to eq(true)
      expect(result.is_networking_addon?).to eq(true)
    end
    
    it "creates EBS CSI driver for persistent volumes" do
      result = test_instance.aws_eks_addon(:ebs_csi, {
        cluster_name: "stateful-cluster",
        addon_name: "aws-ebs-csi-driver",
        addon_version: "v1.28.0-eksbuild.1",
        service_account_role_arn: ebs_csi_role_arn,
        resolve_conflicts_on_create: "OVERWRITE",
        configuration_values: JSON.generate({
          controller: {
            replicaCount: 2,
            resources: {
              requests: {
                cpu: "100m",
                memory: "128Mi"
              }
            }
          }
        })
      })
      
      expect(result.is_storage_addon?).to eq(true)
      expect(result.service_account).to eq("ebs-csi-controller-sa")
    end
    
    it "creates CoreDNS for Fargate" do
      result = test_instance.aws_eks_addon(:coredns_fargate, {
        cluster_name: "fargate-cluster",
        addon_name: "coredns",
        configuration_values: JSON.generate({
          computeType: "Fargate",
          replicaCount: 3,
          resources: {
            limits: {
              cpu: "100m",
              memory: "150Mi"
            },
            requests: {
              cpu: "50m",
              memory: "100Mi"
            }
          }
        })
      })
      
      expect(result.is_networking_addon?).to eq(true)
      expect(result.namespace).to eq("kube-system")
    end
    
    it "creates GuardDuty agent for security monitoring" do
      result = test_instance.aws_eks_addon(:guardduty, {
        cluster_name: "secure-cluster",
        addon_name: "aws-guardduty-agent",
        service_account_role_arn: "arn:aws:iam::123456789012:role/guardduty-agent-role",
        resolve_conflicts: "OVERWRITE",
        preserve: false,
        tags: {
          SecurityCompliance: "required",
          MonitoringLevel: "enhanced"
        }
      })
      
      expect(result.is_observability_addon?).to eq(true)
      expect(result.namespace).to eq("amazon-guardduty")
      expect(result.requires_iam_role?).to eq(true)
    end
    
    it "creates OpenTelemetry addon" do
      result = test_instance.aws_eks_addon(:otel, {
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
      
      expect(result.is_observability_addon?).to eq(true)
      expect(result.service_account).to eq("aws-otel-sa")
    end
    
    it "creates snapshot controller addon" do
      result = test_instance.aws_eks_addon(:snapshots, {
        cluster_name: "backup-enabled-cluster",
        addon_name: "snapshot-controller",
        addon_version: "v6.3.2-eksbuild.1"
      })
      
      expect(result.is_storage_addon?).to eq(true)
      expect(result.requires_iam_role?).to eq(false)
    end
  end
  
  describe "addon version management" do
    it "creates addon with specific version" do
      versions = {
        "vpc-cni" => "v1.12.6-eksbuild.2",
        "coredns" => "v1.10.1-eksbuild.7",
        "kube-proxy" => "v1.29.0-eksbuild.3",
        "aws-ebs-csi-driver" => "v1.28.0-eksbuild.1"
      }
      
      versions.each do |addon_name, version|
        result = test_instance.aws_eks_addon(addon_name.gsub("-", "_").to_sym, {
          cluster_name: "version-test-cluster",
          addon_name: addon_name,
          addon_version: version
        })
        
        expect(result.resource_attributes[:addon_version]).to eq(version)
      end
    end
  end
  
  describe "addon conflict resolution strategies" do
    it "uses NONE by default" do
      result = test_instance.aws_eks_addon(:default_conflicts, {
        cluster_name: "my-cluster",
        addon_name: "vpc-cni"
      })
      
      expect(result.resource_attributes[:resolve_conflicts]).to eq("NONE")
    end
    
    it "uses OVERWRITE for aggressive updates" do
      result = test_instance.aws_eks_addon(:overwrite_conflicts, {
        cluster_name: "my-cluster",
        addon_name: "vpc-cni",
        resolve_conflicts: "OVERWRITE"
      })
      
      expect(result.resource_attributes[:resolve_conflicts]).to eq("OVERWRITE")
    end
    
    it "uses different strategies for create and update" do
      result = test_instance.aws_eks_addon(:granular_conflicts, {
        cluster_name: "my-cluster",
        addon_name: "vpc-cni",
        resolve_conflicts_on_create: "OVERWRITE",
        resolve_conflicts_on_update: "NONE"
      })
      
      expect(result.resource_attributes[:resolve_conflicts_on_create]).to eq("OVERWRITE")
      expect(result.resource_attributes[:resolve_conflicts_on_update]).to eq("NONE")
    end
  end
end