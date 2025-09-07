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

# Load aws_vpc_endpoint resource and types for testing
require 'pangea/resources/aws_vpc_endpoint/resource'
require 'pangea/resources/aws_vpc_endpoint/types'

RSpec.describe "aws_vpc_endpoint resource function" do
  # Create a test class that includes the AwsVpcEndpoint module and mocks terraform-synthesizer
  let(:test_class) do
    Class.new do
      include Pangea::Resources::AwsVpcEndpoint
      
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
  
  describe "VpcEndpointAttributes validation" do
    it "accepts Gateway endpoint configuration" do
      endpoint = Pangea::Resources::AwsVpcEndpoint::Types::VpcEndpointAttributes.new({
        vpc_id: "vpc-12345678",
        service_name: "com.amazonaws.us-east-1.s3",
        vpc_endpoint_type: "Gateway",
        route_table_ids: ["rtb-12345678", "rtb-87654321"],
        policy: '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":"*","Action":"*","Resource":"*"}]}',
        tags: {
          Name: "s3-endpoint",
          Environment: "production"
        }
      })
      
      expect(endpoint.vpc_id).to eq("vpc-12345678")
      expect(endpoint.service_name).to eq("com.amazonaws.us-east-1.s3")
      expect(endpoint.vpc_endpoint_type).to eq("Gateway")
      expect(endpoint.route_table_ids).to have(2).items
      expect(endpoint.is_gateway_endpoint?).to eq(true)
      expect(endpoint.is_interface_endpoint?).to eq(false)
    end
    
    it "accepts Interface endpoint configuration" do
      endpoint = Pangea::Resources::AwsVpcEndpoint::Types::VpcEndpointAttributes.new({
        vpc_id: "vpc-12345678",
        service_name: "com.amazonaws.us-east-1.ec2",
        vpc_endpoint_type: "Interface",
        subnet_ids: ["subnet-12345678", "subnet-87654321"],
        security_group_ids: ["sg-12345678"],
        private_dns_enabled: true,
        dns_options: {
          dns_record_ip_type: "ipv4"
        },
        tags: {
          Name: "ec2-endpoint",
          Environment: "production"
        }
      })
      
      expect(endpoint.vpc_endpoint_type).to eq("Interface")
      expect(endpoint.subnet_ids).to have(2).items
      expect(endpoint.security_group_ids).to have(1).item
      expect(endpoint.private_dns_enabled).to eq(true)
      expect(endpoint.dns_options).to eq({ dns_record_ip_type: "ipv4" })
      expect(endpoint.is_interface_endpoint?).to eq(true)
      expect(endpoint.is_gateway_endpoint?).to eq(false)
    end
    
    it "validates Gateway endpoints require route_table_ids" do
      expect {
        Pangea::Resources::AwsVpcEndpoint::Types::VpcEndpointAttributes.new({
          vpc_id: "vpc-12345678",
          service_name: "com.amazonaws.us-east-1.s3",
          vpc_endpoint_type: "Gateway"
        })
      }.to raise_error(Dry::Struct::Error, /Gateway endpoints require route_table_ids/)
    end
    
    it "validates Gateway endpoints cannot have subnet_ids" do
      expect {
        Pangea::Resources::AwsVpcEndpoint::Types::VpcEndpointAttributes.new({
          vpc_id: "vpc-12345678",
          service_name: "com.amazonaws.us-east-1.s3",
          vpc_endpoint_type: "Gateway",
          route_table_ids: ["rtb-12345678"],
          subnet_ids: ["subnet-12345678"]
        })
      }.to raise_error(Dry::Struct::Error, /Gateway endpoints cannot have subnet_ids or security_group_ids/)
    end
    
    it "validates Interface endpoints require subnet_ids" do
      expect {
        Pangea::Resources::AwsVpcEndpoint::Types::VpcEndpointAttributes.new({
          vpc_id: "vpc-12345678",
          service_name: "com.amazonaws.us-east-1.ec2",
          vpc_endpoint_type: "Interface"
        })
      }.to raise_error(Dry::Struct::Error, /Interface endpoints require subnet_ids/)
    end
    
    it "validates Interface endpoints cannot have route_table_ids" do
      expect {
        Pangea::Resources::AwsVpcEndpoint::Types::VpcEndpointAttributes.new({
          vpc_id: "vpc-12345678",
          service_name: "com.amazonaws.us-east-1.ec2",
          vpc_endpoint_type: "Interface",
          subnet_ids: ["subnet-12345678"],
          route_table_ids: ["rtb-12345678"]
        })
      }.to raise_error(Dry::Struct::Error, /Interface endpoints cannot have route_table_ids/)
    end
    
    it "validates service name format" do
      expect {
        Pangea::Resources::AwsVpcEndpoint::Types::VpcEndpointAttributes.new({
          vpc_id: "vpc-12345678",
          service_name: "invalid-service",
          vpc_endpoint_type: "Gateway",
          route_table_ids: ["rtb-12345678"]
        })
      }.to raise_error(Dry::Struct::Error, /Service name must match AWS service pattern/)
    end
    
    it "validates policy is valid JSON when provided" do
      expect {
        Pangea::Resources::AwsVpcEndpoint::Types::VpcEndpointAttributes.new({
          vpc_id: "vpc-12345678",
          service_name: "com.amazonaws.us-east-1.s3",
          vpc_endpoint_type: "Gateway",
          route_table_ids: ["rtb-12345678"],
          policy: "invalid json"
        })
      }.to raise_error(Dry::Struct::Error, /Policy must be valid JSON/)
    end
    
    it "validates DNS options format for Interface endpoints" do
      expect {
        Pangea::Resources::AwsVpcEndpoint::Types::VpcEndpointAttributes.new({
          vpc_id: "vpc-12345678",
          service_name: "com.amazonaws.us-east-1.ec2",
          vpc_endpoint_type: "Interface",
          subnet_ids: ["subnet-12345678"],
          dns_options: {
            dns_record_ip_type: "invalid"
          }
        })
      }.to raise_error(Dry::Struct::Error, /dns_record_ip_type must be/)
    end
    
    it "detects service type from service name" do
      s3_endpoint = Pangea::Resources::AwsVpcEndpoint::Types::VpcEndpointAttributes.new({
        vpc_id: "vpc-12345678",
        service_name: "com.amazonaws.us-east-1.s3",
        vpc_endpoint_type: "Gateway",
        route_table_ids: ["rtb-12345678"]
      })
      expect(s3_endpoint.service_type).to eq("s3")
      
      ec2_endpoint = Pangea::Resources::AwsVpcEndpoint::Types::VpcEndpointAttributes.new({
        vpc_id: "vpc-12345678",
        service_name: "com.amazonaws.us-east-1.ec2",
        vpc_endpoint_type: "Interface",
        subnet_ids: ["subnet-12345678"]
      })
      expect(ec2_endpoint.service_type).to eq("ec2")
    end
    
    it "provides configuration warnings" do
      # Interface endpoint without security groups
      endpoint = Pangea::Resources::AwsVpcEndpoint::Types::VpcEndpointAttributes.new({
        vpc_id: "vpc-12345678",
        service_name: "com.amazonaws.us-east-1.ec2",
        vpc_endpoint_type: "Interface",
        subnet_ids: ["subnet-12345678"]
      })
      warnings = endpoint.validate_configuration
      expect(warnings).to include("Interface endpoint has no security groups - will use VPC default security group")
      
      # Interface endpoint without private DNS
      endpoint_no_dns = Pangea::Resources::AwsVpcEndpoint::Types::VpcEndpointAttributes.new({
        vpc_id: "vpc-12345678",
        service_name: "com.amazonaws.us-east-1.ec2",
        vpc_endpoint_type: "Interface",
        subnet_ids: ["subnet-12345678"],
        private_dns_enabled: false
      })
      warnings = endpoint_no_dns.validate_configuration
      expect(warnings).to include("Interface endpoint has private DNS disabled - applications must use endpoint DNS names")
    end
  end
  
  describe "VpcEndpointConfigs module" do
    it "creates S3 Gateway endpoint configuration" do
      config = Pangea::Resources::AwsVpcEndpoint::Types::VpcEndpointConfigs.s3_gateway("vpc-12345678", ["rtb-12345678"])
      
      expect(config[:vpc_id]).to eq("vpc-12345678")
      expect(config[:service_name]).to eq("com.amazonaws.${data.aws_region.current.name}.s3")
      expect(config[:vpc_endpoint_type]).to eq("Gateway")
      expect(config[:route_table_ids]).to eq(["rtb-12345678"])
    end
    
    it "creates DynamoDB Gateway endpoint configuration" do
      config = Pangea::Resources::AwsVpcEndpoint::Types::VpcEndpointConfigs.dynamodb_gateway("vpc-12345678", ["rtb-12345678"])
      
      expect(config[:vpc_id]).to eq("vpc-12345678")
      expect(config[:service_name]).to eq("com.amazonaws.${data.aws_region.current.name}.dynamodb")
      expect(config[:vpc_endpoint_type]).to eq("Gateway")
      expect(config[:route_table_ids]).to eq(["rtb-12345678"])
    end
    
    it "creates Interface endpoint configuration" do
      config = Pangea::Resources::AwsVpcEndpoint::Types::VpcEndpointConfigs.interface_endpoint(
        "vpc-12345678",
        "ec2",
        ["subnet-12345678"],
        security_group_ids: ["sg-12345678"],
        private_dns: true
      )
      
      expect(config[:vpc_id]).to eq("vpc-12345678")
      expect(config[:service_name]).to eq("com.amazonaws.${data.aws_region.current.name}.ec2")
      expect(config[:vpc_endpoint_type]).to eq("Interface")
      expect(config[:subnet_ids]).to eq(["subnet-12345678"])
      expect(config[:security_group_ids]).to eq(["sg-12345678"])
      expect(config[:private_dns_enabled]).to eq(true)
    end
    
    it "creates PrivateLink endpoint configuration" do
      config = Pangea::Resources::AwsVpcEndpoint::Types::VpcEndpointConfigs.privatelink_endpoint(
        "vpc-12345678",
        "com.example.vpce-svc-123456",
        ["subnet-12345678", "subnet-87654321"],
        security_group_ids: ["sg-12345678"]
      )
      
      expect(config[:vpc_id]).to eq("vpc-12345678")
      expect(config[:service_name]).to eq("com.example.vpce-svc-123456")
      expect(config[:vpc_endpoint_type]).to eq("Interface")
      expect(config[:subnet_ids]).to have(2).items
      expect(config[:private_dns_enabled]).to eq(true)
    end
  end
  
  describe "aws_vpc_endpoint function" do
    it "creates basic Gateway endpoint for S3" do
      result = test_instance.aws_vpc_endpoint(:s3_endpoint, {
        vpc_id: "vpc-12345678",
        service_name: "com.amazonaws.us-east-1.s3",
        vpc_endpoint_type: "Gateway",
        route_table_ids: ["rtb-12345678", "rtb-87654321"],
        tags: {
          Name: "s3-endpoint",
          Environment: "production"
        }
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.type).to eq('aws_vpc_endpoint')
      expect(result.name).to eq(:s3_endpoint)
      expect(result.id).to eq("${aws_vpc_endpoint.s3_endpoint.id}")
    end
    
    it "creates Interface endpoint with private DNS" do
      result = test_instance.aws_vpc_endpoint(:ec2_endpoint, {
        vpc_id: "vpc-12345678",
        service_name: "com.amazonaws.us-east-1.ec2",
        vpc_endpoint_type: "Interface",
        subnet_ids: ["subnet-12345678", "subnet-87654321"],
        security_group_ids: ["sg-12345678"],
        private_dns_enabled: true,
        dns_options: {
          dns_record_ip_type: "ipv4"
        }
      })
      
      expect(result.resource_attributes[:vpc_endpoint_type]).to eq("Interface")
      expect(result.resource_attributes[:private_dns_enabled]).to eq(true)
      expect(result.resource_attributes[:dns_options]).to have_key(:dns_record_ip_type)
    end
    
    it "creates endpoint with custom policy" do
      policy = {
        Version: "2012-10-17",
        Statement: [{
          Effect: "Allow",
          Principal: { AWS: "*" },
          Action: "s3:GetObject",
          Resource: "arn:aws:s3:::my-bucket/*"
        }]
      }
      
      result = test_instance.aws_vpc_endpoint(:s3_restricted, {
        vpc_id: "vpc-12345678",
        service_name: "com.amazonaws.us-east-1.s3",
        vpc_endpoint_type: "Gateway",
        route_table_ids: ["rtb-12345678"],
        policy: policy.to_json
      })
      
      expect(result.resource_attributes[:policy]).to be_a(String)
      expect(JSON.parse(result.resource_attributes[:policy])).to have_key("Statement")
    end
    
    it "provides correct outputs" do
      result = test_instance.aws_vpc_endpoint(:test, {
        vpc_id: "vpc-12345678",
        service_name: "com.amazonaws.us-east-1.s3",
        vpc_endpoint_type: "Gateway",
        route_table_ids: ["rtb-12345678"]
      })
      
      expect(result.id).to eq("${aws_vpc_endpoint.test.id}")
      expect(result.arn).to eq("${aws_vpc_endpoint.test.arn}")
      expect(result.prefix_list_id).to eq("${aws_vpc_endpoint.test.prefix_list_id}")
      expect(result.state).to eq("${aws_vpc_endpoint.test.state}")
      expect(result.network_interface_ids).to eq("${aws_vpc_endpoint.test.network_interface_ids}")
      expect(result.dns_entry).to eq("${aws_vpc_endpoint.test.dns_entry}")
    end
    
    it "provides computed properties" do
      result = test_instance.aws_vpc_endpoint(:computed_test, {
        vpc_id: "vpc-12345678",
        service_name: "com.amazonaws.us-east-1.ec2",
        vpc_endpoint_type: "Interface",
        subnet_ids: ["subnet-12345678"],
        private_dns_enabled: true
      })
      
      expect(result.is_gateway_endpoint?).to eq(false)
      expect(result.is_interface_endpoint?).to eq(true)
      expect(result.service_type).to eq("ec2")
      expect(result.requires_route_tables?).to eq(false)
      expect(result.requires_subnets?).to eq(true)
    end
  end
  
  describe "endpoint patterns" do
    it "creates S3 Gateway endpoint with multiple route tables" do
      result = test_instance.aws_vpc_endpoint(:s3_gateway, {
        vpc_id: "vpc-12345678",
        service_name: "com.amazonaws.us-east-1.s3",
        vpc_endpoint_type: "Gateway",
        route_table_ids: ["rtb-public-1a", "rtb-public-1b", "rtb-private-1a", "rtb-private-1b"],
        tags: {
          Name: "s3-gateway-endpoint",
          Purpose: "S3 access without internet gateway"
        }
      })
      
      expect(result.resource_attributes[:route_table_ids]).to have(4).items
      expect(result.service_type).to eq("s3")
    end
    
    it "creates multi-AZ Interface endpoint" do
      result = test_instance.aws_vpc_endpoint(:ec2_multi_az, {
        vpc_id: "vpc-12345678",
        service_name: "com.amazonaws.us-east-1.ec2",
        vpc_endpoint_type: "Interface",
        subnet_ids: ["subnet-1a", "subnet-1b", "subnet-1c"],
        security_group_ids: ["sg-ec2-endpoint"],
        private_dns_enabled: true,
        dns_options: {
          dns_record_ip_type: "ipv4"
        },
        tags: {
          Name: "ec2-interface-endpoint",
          Pattern: "multi-az"
        }
      })
      
      expect(result.resource_attributes[:subnet_ids]).to have(3).items
      expect(result.is_interface_endpoint?).to eq(true)
    end
    
    it "creates PrivateLink endpoint for custom service" do
      result = test_instance.aws_vpc_endpoint(:custom_service, {
        vpc_id: "vpc-12345678",
        service_name: "com.example.vpce-svc-123456789abcdef0",
        vpc_endpoint_type: "Interface",
        subnet_ids: ["subnet-12345678"],
        security_group_ids: ["sg-privatelink"],
        private_dns_enabled: true,
        tags: {
          Name: "custom-privatelink-endpoint",
          Service: "partner-api"
        }
      })
      
      expect(result.resource_attributes[:service_name]).to include("vpce-svc")
      expect(result.service_type).to eq("vpce-svc-123456789abcdef0")
    end
    
    it "creates multiple service endpoints pattern" do
      # S3 Gateway
      s3_endpoint = test_instance.aws_vpc_endpoint(:s3, {
        vpc_id: "vpc-12345678",
        service_name: "com.amazonaws.us-east-1.s3",
        vpc_endpoint_type: "Gateway",
        route_table_ids: ["rtb-12345678"]
      })
      
      # DynamoDB Gateway
      dynamodb_endpoint = test_instance.aws_vpc_endpoint(:dynamodb, {
        vpc_id: "vpc-12345678",
        service_name: "com.amazonaws.us-east-1.dynamodb",
        vpc_endpoint_type: "Gateway",
        route_table_ids: ["rtb-12345678"]
      })
      
      # EC2 Interface
      ec2_endpoint = test_instance.aws_vpc_endpoint(:ec2, {
        vpc_id: "vpc-12345678",
        service_name: "com.amazonaws.us-east-1.ec2",
        vpc_endpoint_type: "Interface",
        subnet_ids: ["subnet-12345678"],
        private_dns_enabled: true
      })
      
      # Systems Manager Interface
      ssm_endpoint = test_instance.aws_vpc_endpoint(:ssm, {
        vpc_id: "vpc-12345678",
        service_name: "com.amazonaws.us-east-1.ssm",
        vpc_endpoint_type: "Interface",
        subnet_ids: ["subnet-12345678"],
        private_dns_enabled: true
      })
      
      expect(s3_endpoint.is_gateway_endpoint?).to eq(true)
      expect(dynamodb_endpoint.is_gateway_endpoint?).to eq(true)
      expect(ec2_endpoint.is_interface_endpoint?).to eq(true)
      expect(ssm_endpoint.is_interface_endpoint?).to eq(true)
    end
  end
  
  describe "advanced configurations" do
    it "creates endpoint with restrictive policy" do
      restrictive_policy = {
        Version: "2012-10-17",
        Statement: [
          {
            Effect: "Allow",
            Principal: { AWS: "arn:aws:iam::123456789012:root" },
            Action: ["s3:GetObject", "s3:PutObject"],
            Resource: ["arn:aws:s3:::my-secure-bucket/*"]
          },
          {
            Effect: "Deny",
            Principal: "*",
            Action: "s3:*",
            Resource: "*",
            Condition: {
              StringNotEquals: {
                "aws:SourceVpce": "${aws_vpc_endpoint.s3_secure.id}"
              }
            }
          }
        ]
      }
      
      result = test_instance.aws_vpc_endpoint(:s3_secure, {
        vpc_id: "vpc-12345678",
        service_name: "com.amazonaws.us-east-1.s3",
        vpc_endpoint_type: "Gateway",
        route_table_ids: ["rtb-12345678"],
        policy: restrictive_policy.to_json,
        tags: {
          Name: "secure-s3-endpoint",
          Security: "restricted"
        }
      })
      
      expect(result.resource_attributes[:policy]).to include("aws:SourceVpce")
    end
    
    it "creates Interface endpoint with IPv6 support" do
      result = test_instance.aws_vpc_endpoint(:ec2_ipv6, {
        vpc_id: "vpc-12345678",
        service_name: "com.amazonaws.us-east-1.ec2",
        vpc_endpoint_type: "Interface",
        subnet_ids: ["subnet-12345678"],
        security_group_ids: ["sg-12345678"],
        ip_address_type: "dualstack",
        dns_options: {
          dns_record_ip_type: "dualstack"
        },
        tags: {
          Name: "ec2-ipv6-endpoint",
          IPSupport: "dual-stack"
        }
      })
      
      expect(result.resource_attributes[:ip_address_type]).to eq("dualstack")
      expect(result.resource_attributes[:dns_options][:dns_record_ip_type]).to eq("dualstack")
    end
  end
  
  describe "error conditions" do
    it "handles missing required attributes" do
      expect {
        test_instance.aws_vpc_endpoint(:invalid, {
          service_name: "com.amazonaws.us-east-1.s3"
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "handles invalid endpoint type" do
      expect {
        test_instance.aws_vpc_endpoint(:invalid_type, {
          vpc_id: "vpc-12345678",
          service_name: "com.amazonaws.us-east-1.s3",
          vpc_endpoint_type: "InvalidType"
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "handles mismatched endpoint type and service" do
      # S3 cannot be Interface endpoint
      expect {
        test_instance.aws_vpc_endpoint(:s3_interface, {
          vpc_id: "vpc-12345678",
          service_name: "com.amazonaws.us-east-1.s3",
          vpc_endpoint_type: "Interface",
          subnet_ids: ["subnet-12345678"]
        })
      }.not_to raise_error # AWS will validate this, not our code
    end
  end
end