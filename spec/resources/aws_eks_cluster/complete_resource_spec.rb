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

# Load aws_eks_cluster resource and types for testing
require 'pangea/resources/aws_eks_cluster/resource'
require 'pangea/resources/aws_eks_cluster/types'

RSpec.describe "aws_eks_cluster resource function" do
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
  
  # Test IAM role ARN for EKS
  let(:cluster_role_arn) { "arn:aws:iam::123456789012:role/eks-cluster-role" }
  let(:kms_key_arn) { "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012" }
  
  describe "VpcConfig validation" do
    it "accepts valid VPC configuration" do
      vpc_config = Pangea::Resources::AWS::Types::VpcConfig.new({
        subnet_ids: ["subnet-12345", "subnet-67890"],
        endpoint_private_access: true,
        endpoint_public_access: true
      })
      
      expect(vpc_config.subnet_ids.size).to eq(2)
      expect(vpc_config.endpoint_private_access).to eq(true)
      expect(vpc_config.endpoint_public_access).to eq(true)
      expect(vpc_config.public_access_cidrs).to eq(["0.0.0.0/0"])
    end
    
    it "accepts VPC config with security groups" do
      vpc_config = Pangea::Resources::AWS::Types::VpcConfig.new({
        subnet_ids: ["subnet-12345", "subnet-67890"],
        security_group_ids: ["sg-12345", "sg-67890"],
        endpoint_private_access: true,
        endpoint_public_access: false
      })
      
      expect(vpc_config.security_group_ids).to eq(["sg-12345", "sg-67890"])
      expect(vpc_config.endpoint_public_access).to eq(false)
    end
    
    it "accepts custom public access CIDRs" do
      vpc_config = Pangea::Resources::AWS::Types::VpcConfig.new({
        subnet_ids: ["subnet-12345", "subnet-67890"],
        endpoint_public_access: true,
        public_access_cidrs: ["10.0.0.0/8", "172.16.0.0/12"]
      })
      
      expect(vpc_config.public_access_cidrs).to eq(["10.0.0.0/8", "172.16.0.0/12"])
    end
    
    it "rejects VPC config with fewer than 2 subnets" do
      expect {
        Pangea::Resources::AWS::Types::VpcConfig.new({
          subnet_ids: ["subnet-12345"]
        })
      }.to raise_error(Dry::Struct::Error, /requires at least 2 subnets/)
    end
    
    it "rejects VPC config with both endpoints disabled" do
      expect {
        Pangea::Resources::AWS::Types::VpcConfig.new({
          subnet_ids: ["subnet-12345", "subnet-67890"],
          endpoint_private_access: false,
          endpoint_public_access: false
        })
      }.to raise_error(Dry::Struct::Error, /At least one of endpoint_public_access or endpoint_private_access must be true/)
    end
    
    it "validates CIDR format for public access" do
      expect {
        Pangea::Resources::AWS::Types::VpcConfig.new({
          subnet_ids: ["subnet-12345", "subnet-67890"],
          public_access_cidrs: ["invalid-cidr"]
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
  end
  
  describe "EncryptionConfig validation" do
    it "accepts valid encryption configuration" do
      encryption = Pangea::Resources::AWS::Types::EncryptionConfig.new({
        resources: ["secrets"],
        provider: { key_arn: kms_key_arn }
      })
      
      expect(encryption.resources).to eq(["secrets"])
      expect(encryption.provider.key_arn).to eq(kms_key_arn)
    end
    
    it "validates KMS key ARN format" do
      expect {
        Pangea::Resources::AWS::Types::EncryptionConfig.new({
          resources: ["secrets"],
          provider: { key_arn: "invalid-arn" }
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
    
    it "defaults to secrets resource" do
      encryption = Pangea::Resources::AWS::Types::EncryptionConfig.new({
        provider: { key_arn: kms_key_arn }
      })
      
      expect(encryption.resources).to eq(["secrets"])
    end
  end
  
  describe "KubernetesNetworkConfig validation" do
    it "accepts valid network configuration" do
      network_config = Pangea::Resources::AWS::Types::KubernetesNetworkConfig.new({
        service_ipv4_cidr: "10.100.0.0/16",
        ip_family: "ipv4"
      })
      
      expect(network_config.service_ipv4_cidr).to eq("10.100.0.0/16")
      expect(network_config.ip_family).to eq("ipv4")
    end
    
    it "accepts IPv6 configuration" do
      network_config = Pangea::Resources::AWS::Types::KubernetesNetworkConfig.new({
        ip_family: "ipv6"
      })
      
      expect(network_config.ip_family).to eq("ipv6")
      expect(network_config.service_ipv4_cidr).to be_nil
    end
    
    it "validates service CIDR is private" do
      expect {
        Pangea::Resources::AWS::Types::KubernetesNetworkConfig.new({
          service_ipv4_cidr: "8.8.8.0/24"
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
    
    it "validates IP family values" do
      expect {
        Pangea::Resources::AWS::Types::KubernetesNetworkConfig.new({
          ip_family: "invalid"
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
  end
  
  describe "ClusterLogging validation" do
    it "accepts valid log types" do
      logging = Pangea::Resources::AWS::Types::ClusterLogging.new({
        enabled_types: ["api", "audit", "authenticator"]
      })
      
      expect(logging.enabled_types).to eq(["api", "audit", "authenticator"])
    end
    
    it "accepts all log types" do
      logging = Pangea::Resources::AWS::Types::ClusterLogging.new({
        enabled_types: ["api", "audit", "authenticator", "controllerManager", "scheduler"]
      })
      
      expect(logging.enabled_types.size).to eq(5)
    end
    
    it "defaults to empty log types" do
      logging = Pangea::Resources::AWS::Types::ClusterLogging.new({})
      
      expect(logging.enabled_types).to eq([])
    end
    
    it "rejects invalid log types" do
      expect {
        Pangea::Resources::AWS::Types::ClusterLogging.new({
          enabled_types: ["api", "invalid"]
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
    
    it "formats output correctly" do
      logging = Pangea::Resources::AWS::Types::ClusterLogging.new({
        enabled_types: ["api", "audit"]
      })
      
      output = logging.to_h
      expect(output[:enabled_cluster_log_types]).to be_an(Array)
      expect(output[:enabled_cluster_log_types].size).to eq(2)
      expect(output[:enabled_cluster_log_types].first).to eq({ types: ["api"], enabled: true })
    end
  end
  
  describe "EksClusterAttributes validation" do
    it "accepts minimal valid configuration" do
      cluster = Pangea::Resources::AWS::Types::EksClusterAttributes.new({
        role_arn: cluster_role_arn,
        vpc_config: {
          subnet_ids: ["subnet-12345", "subnet-67890"]
        }
      })
      
      expect(cluster.role_arn).to eq(cluster_role_arn)
      expect(cluster.version).to eq("1.28")
      expect(cluster.vpc_config.subnet_ids.size).to eq(2)
      expect(cluster.tags).to eq({})
    end
    
    it "accepts full configuration" do
      cluster = Pangea::Resources::AWS::Types::EksClusterAttributes.new({
        name: "my-cluster",
        role_arn: cluster_role_arn,
        version: "1.29",
        vpc_config: {
          subnet_ids: ["subnet-12345", "subnet-67890"],
          security_group_ids: ["sg-12345"],
          endpoint_private_access: true,
          endpoint_public_access: false
        },
        enabled_cluster_log_types: ["api", "audit"],
        encryption_config: [{
          resources: ["secrets"],
          provider: { key_arn: kms_key_arn }
        }],
        kubernetes_network_config: {
          service_ipv4_cidr: "172.20.0.0/16"
        },
        tags: {
          Environment: "production",
          Team: "platform"
        }
      })
      
      expect(cluster.name).to eq("my-cluster")
      expect(cluster.version).to eq("1.29")
      expect(cluster.enabled_cluster_log_types).to eq(["api", "audit"])
      expect(cluster.encryption_config.size).to eq(1)
      expect(cluster.kubernetes_network_config.service_ipv4_cidr).to eq("172.20.0.0/16")
      expect(cluster.tags[:Environment]).to eq("production")
    end
    
    it "validates Kubernetes version" do
      expect {
        Pangea::Resources::AWS::Types::EksClusterAttributes.new({
          role_arn: cluster_role_arn,
          version: "1.20",
          vpc_config: {
            subnet_ids: ["subnet-12345", "subnet-67890"]
          }
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
    
    it "validates IAM role ARN format" do
      expect {
        Pangea::Resources::AWS::Types::EksClusterAttributes.new({
          role_arn: "invalid-arn",
          vpc_config: {
            subnet_ids: ["subnet-12345", "subnet-67890"]
          }
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
    
    it "validates log types" do
      expect {
        Pangea::Resources::AWS::Types::EksClusterAttributes.new({
          role_arn: cluster_role_arn,
          vpc_config: {
            subnet_ids: ["subnet-12345", "subnet-67890"]
          },
          enabled_cluster_log_types: ["api", "invalid"]
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
  end
  
  describe "computed properties" do
    let(:cluster_attrs) do
      Pangea::Resources::AWS::Types::EksClusterAttributes.new({
        role_arn: cluster_role_arn,
        vpc_config: {
          subnet_ids: ["subnet-12345", "subnet-67890"],
          endpoint_private_access: true,
          endpoint_public_access: false
        },
        enabled_cluster_log_types: ["api", "audit"],
        encryption_config: [{
          resources: ["secrets"],
          provider: { key_arn: kms_key_arn }
        }]
      })
    end
    
    it "detects encryption enabled" do
      expect(cluster_attrs.encryption_enabled?).to eq(true)
    end
    
    it "detects logging enabled" do
      expect(cluster_attrs.logging_enabled?).to eq(true)
    end
    
    it "detects private endpoint" do
      expect(cluster_attrs.private_endpoint?).to eq(true)
    end
    
    it "detects public endpoint" do
      expect(cluster_attrs.public_endpoint?).to eq(false)
    end
    
    let(:minimal_cluster_attrs) do
      Pangea::Resources::AWS::Types::EksClusterAttributes.new({
        role_arn: cluster_role_arn,
        vpc_config: {
          subnet_ids: ["subnet-12345", "subnet-67890"]
        }
      })
    end
    
    it "detects no encryption" do
      expect(minimal_cluster_attrs.encryption_enabled?).to eq(false)
    end
    
    it "detects no logging" do
      expect(minimal_cluster_attrs.logging_enabled?).to eq(false)
    end
  end
  
  describe "aws_eks_cluster function" do
    it "creates basic EKS cluster" do
      result = test_instance.aws_eks_cluster(:main, {
        role_arn: cluster_role_arn,
        vpc_config: {
          subnet_ids: ["subnet-12345", "subnet-67890"]
        }
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.type).to eq('aws_eks_cluster')
      expect(result.name).to eq(:main)
    end
    
    it "creates EKS cluster with custom name" do
      result = test_instance.aws_eks_cluster(:main, {
        name: "production-cluster",
        role_arn: cluster_role_arn,
        vpc_config: {
          subnet_ids: ["subnet-12345", "subnet-67890"]
        }
      })
      
      expect(result.resource_attributes[:name]).to eq("production-cluster")
    end
    
    it "creates EKS cluster with logging" do
      result = test_instance.aws_eks_cluster(:main, {
        role_arn: cluster_role_arn,
        vpc_config: {
          subnet_ids: ["subnet-12345", "subnet-67890"]
        },
        enabled_cluster_log_types: ["api", "audit", "authenticator"]
      })
      
      expect(result.logging_enabled?).to eq(true)
      expect(result.log_types).to eq(["api", "audit", "authenticator"])
    end
    
    it "creates EKS cluster with encryption" do
      result = test_instance.aws_eks_cluster(:secure, {
        role_arn: cluster_role_arn,
        vpc_config: {
          subnet_ids: ["subnet-12345", "subnet-67890"]
        },
        encryption_config: [{
          resources: ["secrets"],
          provider: { key_arn: kms_key_arn }
        }]
      })
      
      expect(result.encryption_enabled?).to eq(true)
    end
    
    it "creates EKS cluster with private endpoint only" do
      result = test_instance.aws_eks_cluster(:private, {
        role_arn: cluster_role_arn,
        vpc_config: {
          subnet_ids: ["subnet-12345", "subnet-67890"],
          endpoint_private_access: true,
          endpoint_public_access: false
        }
      })
      
      expect(result.private_endpoint?).to eq(true)
      expect(result.public_endpoint?).to eq(false)
    end
    
    it "creates EKS cluster with custom networking" do
      result = test_instance.aws_eks_cluster(:custom_net, {
        role_arn: cluster_role_arn,
        vpc_config: {
          subnet_ids: ["subnet-12345", "subnet-67890"]
        },
        kubernetes_network_config: {
          service_ipv4_cidr: "172.20.0.0/16",
          ip_family: "ipv4"
        }
      })
      
      network_config = result.resource_attributes[:kubernetes_network_config]
      expect(network_config[:service_ipv4_cidr]).to eq("172.20.0.0/16")
    end
    
    it "provides correct outputs" do
      result = test_instance.aws_eks_cluster(:test, {
        role_arn: cluster_role_arn,
        vpc_config: {
          subnet_ids: ["subnet-12345", "subnet-67890"]
        }
      })
      
      expect(result.id).to eq("${aws_eks_cluster.test.id}")
      expect(result.arn).to eq("${aws_eks_cluster.test.arn}")
      expect(result.name).to eq("${aws_eks_cluster.test.name}")
      expect(result.endpoint).to eq("${aws_eks_cluster.test.endpoint}")
      expect(result.platform_version).to eq("${aws_eks_cluster.test.platform_version}")
      expect(result.version).to eq("${aws_eks_cluster.test.version}")
      expect(result.status).to eq("${aws_eks_cluster.test.status}")
      expect(result.role_arn).to eq("${aws_eks_cluster.test.role_arn}")
      expect(result.vpc_config).to eq("${aws_eks_cluster.test.vpc_config}")
      expect(result.identity).to eq("${aws_eks_cluster.test.identity}")
      expect(result.certificate_authority).to eq("${aws_eks_cluster.test.certificate_authority}")
      expect(result.certificate_authority_data).to eq("${aws_eks_cluster.test.certificate_authority[0].data}")
      expect(result.created_at).to eq("${aws_eks_cluster.test.created_at}")
    end
    
    it "provides computed properties" do
      result = test_instance.aws_eks_cluster(:test, {
        role_arn: cluster_role_arn,
        vpc_config: {
          subnet_ids: ["subnet-12345", "subnet-67890"],
          endpoint_private_access: true,
          endpoint_public_access: false
        },
        enabled_cluster_log_types: ["api", "audit"],
        encryption_config: [{
          resources: ["secrets"],
          provider: { key_arn: kms_key_arn }
        }]
      })
      
      expect(result.encryption_enabled?).to eq(true)
      expect(result.logging_enabled?).to eq(true)
      expect(result.private_endpoint?).to eq(true)
      expect(result.public_endpoint?).to eq(false)
      expect(result.log_types).to eq(["api", "audit"])
    end
  end
  
  describe "EKS cluster deployment patterns" do
    it "creates development EKS cluster" do
      result = test_instance.aws_eks_cluster(:dev_cluster, {
        name: "dev-cluster",
        role_arn: cluster_role_arn,
        version: "1.28",
        vpc_config: {
          subnet_ids: ["subnet-dev1", "subnet-dev2"],
          endpoint_public_access: true,
          endpoint_private_access: false
        },
        tags: {
          Environment: "development",
          ManagedBy: "terraform"
        }
      })
      
      expect(result.resource_attributes[:version]).to eq("1.28")
      expect(result.public_endpoint?).to eq(true)
      expect(result.resource_attributes[:tags][:Environment]).to eq("development")
    end
    
    it "creates production EKS cluster" do
      result = test_instance.aws_eks_cluster(:prod_cluster, {
        name: "production-cluster",
        role_arn: cluster_role_arn,
        version: "1.29",
        vpc_config: {
          subnet_ids: ["subnet-prod1", "subnet-prod2", "subnet-prod3"],
          security_group_ids: ["sg-prod-cluster"],
          endpoint_private_access: true,
          endpoint_public_access: true,
          public_access_cidrs: ["10.0.0.0/8"]
        },
        enabled_cluster_log_types: ["api", "audit", "authenticator", "controllerManager", "scheduler"],
        encryption_config: [{
          resources: ["secrets"],
          provider: { key_arn: kms_key_arn }
        }],
        kubernetes_network_config: {
          service_ipv4_cidr: "172.20.0.0/16"
        },
        tags: {
          Environment: "production",
          CostCenter: "engineering",
          Compliance: "pci"
        }
      })
      
      expect(result.encryption_enabled?).to eq(true)
      expect(result.logging_enabled?).to eq(true)
      expect(result.private_endpoint?).to eq(true)
      expect(result.log_types.size).to eq(5)
    end
    
    it "creates multi-region EKS cluster" do
      result = test_instance.aws_eks_cluster(:multi_region, {
        name: "global-cluster-us-east-1",
        role_arn: cluster_role_arn,
        version: "1.29",
        vpc_config: {
          subnet_ids: ["subnet-use1-az1", "subnet-use1-az2", "subnet-use1-az3"],
          endpoint_private_access: true,
          endpoint_public_access: false
        },
        enabled_cluster_log_types: ["api", "audit"],
        tags: {
          Region: "us-east-1",
          GlobalCluster: "true",
          ReplicationGroup: "global-cluster"
        }
      })
      
      expect(result.resource_attributes[:tags][:Region]).to eq("us-east-1")
      expect(result.resource_attributes[:tags][:GlobalCluster]).to eq("true")
    end
    
    it "creates EKS cluster for microservices" do
      result = test_instance.aws_eks_cluster(:microservices, {
        name: "microservices-platform",
        role_arn: cluster_role_arn,
        version: "1.29",
        vpc_config: {
          subnet_ids: ["subnet-ms1", "subnet-ms2", "subnet-ms3"],
          endpoint_private_access: true,
          endpoint_public_access: true,
          public_access_cidrs: ["10.0.0.0/8", "172.16.0.0/12"]
        },
        enabled_cluster_log_types: ["api", "audit", "authenticator"],
        kubernetes_network_config: {
          service_ipv4_cidr: "172.20.0.0/14",
          ip_family: "ipv4"
        },
        tags: {
          Platform: "microservices",
          ServiceMesh: "istio",
          Monitoring: "prometheus"
        }
      })
      
      expect(result.resource_attributes[:kubernetes_network_config][:service_ipv4_cidr]).to eq("172.20.0.0/14")
      expect(result.resource_attributes[:tags][:ServiceMesh]).to eq("istio")
    end
    
    it "creates EKS cluster for data processing" do
      result = test_instance.aws_eks_cluster(:data_platform, {
        name: "data-processing-cluster",
        role_arn: cluster_role_arn,
        version: "1.28",
        vpc_config: {
          subnet_ids: ["subnet-data1", "subnet-data2"],
          endpoint_private_access: true,
          endpoint_public_access: false
        },
        encryption_config: [{
          resources: ["secrets"],
          provider: { key_arn: kms_key_arn }
        }],
        tags: {
          Platform: "data-processing",
          Framework: "spark",
          DataClassification: "sensitive"
        }
      })
      
      expect(result.encryption_enabled?).to eq(true)
      expect(result.private_endpoint?).to eq(true)
      expect(result.public_endpoint?).to eq(false)
    end
  end
  
  describe "VPC configuration patterns" do
    it "creates cluster with restrictive public access" do
      result = test_instance.aws_eks_cluster(:restricted, {
        role_arn: cluster_role_arn,
        vpc_config: {
          subnet_ids: ["subnet-12345", "subnet-67890"],
          endpoint_public_access: true,
          endpoint_private_access: true,
          public_access_cidrs: ["203.0.113.0/24", "198.51.100.0/24"]
        }
      })
      
      vpc_config = result.resource_attributes[:vpc_config]
      expect(vpc_config[:public_access_cidrs]).to include("203.0.113.0/24")
      expect(vpc_config[:public_access_cidrs]).not_to include("0.0.0.0/0")
    end
    
    it "creates cluster with custom security groups" do
      result = test_instance.aws_eks_cluster(:custom_sg, {
        role_arn: cluster_role_arn,
        vpc_config: {
          subnet_ids: ["subnet-12345", "subnet-67890"],
          security_group_ids: ["sg-cluster", "sg-nodes", "sg-pods"]
        }
      })
      
      sg_ids = result.resource_attributes[:vpc_config][:security_group_ids]
      expect(sg_ids.size).to eq(3)
      expect(sg_ids).to include("sg-cluster", "sg-nodes", "sg-pods")
    end
  end
  
  describe "logging configuration patterns" do
    it "enables minimal logging" do
      result = test_instance.aws_eks_cluster(:minimal_logs, {
        role_arn: cluster_role_arn,
        vpc_config: {
          subnet_ids: ["subnet-12345", "subnet-67890"]
        },
        enabled_cluster_log_types: ["api"]
      })
      
      expect(result.log_types).to eq(["api"])
    end
    
    it "enables security-focused logging" do
      result = test_instance.aws_eks_cluster(:security_logs, {
        role_arn: cluster_role_arn,
        vpc_config: {
          subnet_ids: ["subnet-12345", "subnet-67890"]
        },
        enabled_cluster_log_types: ["api", "audit", "authenticator"]
      })
      
      expect(result.log_types).to include("audit", "authenticator")
    end
    
    it "enables full logging" do
      result = test_instance.aws_eks_cluster(:full_logs, {
        role_arn: cluster_role_arn,
        vpc_config: {
          subnet_ids: ["subnet-12345", "subnet-67890"]
        },
        enabled_cluster_log_types: ["api", "audit", "authenticator", "controllerManager", "scheduler"]
      })
      
      expect(result.log_types.size).to eq(5)
    end
  end
end