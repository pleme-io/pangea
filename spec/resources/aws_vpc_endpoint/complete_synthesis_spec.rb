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
require 'terraform-synthesizer'

# Require the AWS VPC Endpoint module
require 'pangea/resources/aws_vpc_endpoint/resource'
require 'pangea/resources/aws_vpc_endpoint/types'

RSpec.describe "aws_vpc_endpoint synthesis" do
  let(:synthesizer) { TerraformSynthesizer.new }

  # Extend the synthesizer with our AwsVpcEndpoint module for resource access
  before do
    synthesizer.extend(Pangea::Resources::AwsVpcEndpoint)
  end

  describe "basic endpoint synthesis" do
    it "synthesizes minimal S3 Gateway endpoint" do
      result = synthesizer.instance_eval do
        aws_vpc_endpoint(:s3_gateway, {
          vpc_id: "vpc-12345678",
          service_name: "com.amazonaws.us-east-1.s3",
          vpc_endpoint_type: "Gateway",
          route_table_ids: ["rtb-12345678"],
          tags: {
            Name: "s3-gateway-endpoint"
          }
        })
        
        synthesis
      end
      
      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_vpc_endpoint")
      expect(result["resource"]["aws_vpc_endpoint"]).to have_key("s3_gateway")
      
      endpoint = result["resource"]["aws_vpc_endpoint"]["s3_gateway"]
      expect(endpoint["vpc_id"]).to eq("vpc-12345678")
      expect(endpoint["service_name"]).to eq("com.amazonaws.us-east-1.s3")
      expect(endpoint["vpc_endpoint_type"]).to eq("Gateway")
      expect(endpoint["route_table_ids"]).to eq(["rtb-12345678"])
      expect(endpoint["tags"]["Name"]).to eq("s3-gateway-endpoint")
    end
    
    it "synthesizes minimal Interface endpoint" do
      result = synthesizer.instance_eval do
        aws_vpc_endpoint(:ec2_interface, {
          vpc_id: "vpc-12345678",
          service_name: "com.amazonaws.us-east-1.ec2",
          vpc_endpoint_type: "Interface",
          subnet_ids: ["subnet-12345678"],
          tags: {
            Name: "ec2-interface-endpoint"
          }
        })
        
        synthesis
      end
      
      endpoint = result["resource"]["aws_vpc_endpoint"]["ec2_interface"]
      
      expect(endpoint["vpc_id"]).to eq("vpc-12345678")
      expect(endpoint["service_name"]).to eq("com.amazonaws.us-east-1.ec2")
      expect(endpoint["vpc_endpoint_type"]).to eq("Interface")
      expect(endpoint["subnet_ids"]).to eq(["subnet-12345678"])
      expect(endpoint["private_dns_enabled"]).to eq(true) # Default value
    end
  end
  
  describe "Gateway endpoint synthesis" do
    it "synthesizes S3 Gateway endpoint with multiple route tables" do
      result = synthesizer.instance_eval do
        aws_vpc_endpoint(:s3_multi_route, {
          vpc_id: "vpc-12345678",
          service_name: "com.amazonaws.us-east-1.s3",
          vpc_endpoint_type: "Gateway",
          route_table_ids: ["rtb-public-1a", "rtb-public-1b", "rtb-private-1a", "rtb-private-1b"],
          tags: {
            Name: "s3-gateway-multi-rt",
            Environment: "production"
          }
        })
        
        synthesis
      end
      
      endpoint = result["resource"]["aws_vpc_endpoint"]["s3_multi_route"]
      
      expect(endpoint["route_table_ids"]).to have(4).items
      expect(endpoint["route_table_ids"]).to include("rtb-public-1a", "rtb-public-1b")
      expect(endpoint["route_table_ids"]).to include("rtb-private-1a", "rtb-private-1b")
    end
    
    it "synthesizes DynamoDB Gateway endpoint" do
      result = synthesizer.instance_eval do
        aws_vpc_endpoint(:dynamodb_gateway, {
          vpc_id: "vpc-87654321",
          service_name: "com.amazonaws.us-west-2.dynamodb",
          vpc_endpoint_type: "Gateway",
          route_table_ids: ["rtb-11111111", "rtb-22222222"],
          tags: {
            Name: "dynamodb-gateway-endpoint",
            Service: "dynamodb"
          }
        })
        
        synthesis
      end
      
      endpoint = result["resource"]["aws_vpc_endpoint"]["dynamodb_gateway"]
      
      expect(endpoint["service_name"]).to eq("com.amazonaws.us-west-2.dynamodb")
      expect(endpoint["vpc_endpoint_type"]).to eq("Gateway")
      expect(endpoint["route_table_ids"]).to have(2).items
    end
    
    it "synthesizes Gateway endpoint with custom policy" do
      result = synthesizer.instance_eval do
        policy = {
          Version: "2012-10-17",
          Statement: [{
            Effect: "Allow",
            Principal: "*",
            Action: ["s3:GetObject", "s3:ListBucket"],
            Resource: [
              "arn:aws:s3:::my-bucket",
              "arn:aws:s3:::my-bucket/*"
            ]
          }]
        }
        
        aws_vpc_endpoint(:s3_with_policy, {
          vpc_id: "vpc-12345678",
          service_name: "com.amazonaws.us-east-1.s3",
          vpc_endpoint_type: "Gateway",
          route_table_ids: ["rtb-12345678"],
          policy: policy.to_json
        })
        
        synthesis
      end
      
      endpoint = result["resource"]["aws_vpc_endpoint"]["s3_with_policy"]
      
      expect(endpoint).to have_key("policy")
      policy_data = JSON.parse(endpoint["policy"])
      expect(policy_data["Statement"]).to be_an(Array)
      expect(policy_data["Statement"].first["Action"]).to include("s3:GetObject")
    end
  end
  
  describe "Interface endpoint synthesis" do
    it "synthesizes Interface endpoint with security groups" do
      result = synthesizer.instance_eval do
        aws_vpc_endpoint(:ec2_secure, {
          vpc_id: "vpc-12345678",
          service_name: "com.amazonaws.us-east-1.ec2",
          vpc_endpoint_type: "Interface",
          subnet_ids: ["subnet-12345678", "subnet-87654321"],
          security_group_ids: ["sg-endpoint-12345", "sg-endpoint-67890"],
          private_dns_enabled: true,
          tags: {
            Name: "ec2-secure-endpoint"
          }
        })
        
        synthesis
      end
      
      endpoint = result["resource"]["aws_vpc_endpoint"]["ec2_secure"]
      
      expect(endpoint["subnet_ids"]).to have(2).items
      expect(endpoint["security_group_ids"]).to have(2).items
      expect(endpoint["security_group_ids"]).to include("sg-endpoint-12345")
      expect(endpoint["private_dns_enabled"]).to eq(true)
    end
    
    it "synthesizes Interface endpoint with DNS options" do
      result = synthesizer.instance_eval do
        aws_vpc_endpoint(:ec2_dns_custom, {
          vpc_id: "vpc-12345678",
          service_name: "com.amazonaws.us-east-1.ec2",
          vpc_endpoint_type: "Interface",
          subnet_ids: ["subnet-12345678"],
          private_dns_enabled: true,
          dns_options: {
            dns_record_ip_type: "ipv4"
          }
        })
        
        synthesis
      end
      
      endpoint = result["resource"]["aws_vpc_endpoint"]["ec2_dns_custom"]
      
      expect(endpoint["dns_options"]).to be_a(Hash)
      expect(endpoint["dns_options"]["dns_record_ip_type"]).to eq("ipv4")
    end
    
    it "synthesizes Interface endpoint with IPv6 support" do
      result = synthesizer.instance_eval do
        aws_vpc_endpoint(:ec2_ipv6, {
          vpc_id: "vpc-12345678",
          service_name: "com.amazonaws.us-east-1.ec2",
          vpc_endpoint_type: "Interface",
          subnet_ids: ["subnet-12345678"],
          ip_address_type: "dualstack",
          dns_options: {
            dns_record_ip_type: "dualstack"
          }
        })
        
        synthesis
      end
      
      endpoint = result["resource"]["aws_vpc_endpoint"]["ec2_ipv6"]
      
      expect(endpoint["ip_address_type"]).to eq("dualstack")
      expect(endpoint["dns_options"]["dns_record_ip_type"]).to eq("dualstack")
    end
    
    it "synthesizes PrivateLink endpoint" do
      result = synthesizer.instance_eval do
        aws_vpc_endpoint(:privatelink, {
          vpc_id: "vpc-12345678",
          service_name: "com.amazonaws.vpce.us-east-1.vpce-svc-123456789abcdef0",
          vpc_endpoint_type: "Interface",
          subnet_ids: ["subnet-12345678", "subnet-87654321"],
          security_group_ids: ["sg-privatelink"],
          private_dns_enabled: true
        })
        
        synthesis
      end
      
      endpoint = result["resource"]["aws_vpc_endpoint"]["privatelink"]
      
      expect(endpoint["service_name"]).to include("vpce-svc")
      expect(endpoint["vpc_endpoint_type"]).to eq("Interface")
      expect(endpoint["private_dns_enabled"]).to eq(true)
    end
  end
  
  describe "real-world patterns synthesis" do
    it "synthesizes complete private subnet connectivity pattern" do
      result = synthesizer.instance_eval do
        # S3 Gateway endpoint
        s3_endpoint = aws_vpc_endpoint(:s3, {
          vpc_id: "vpc-prod-12345",
          service_name: "com.amazonaws.us-east-1.s3",
          vpc_endpoint_type: "Gateway",
          route_table_ids: ["rtb-private-1a", "rtb-private-1b", "rtb-private-1c"],
          tags: {
            Name: "prod-s3-endpoint",
            Environment: "production"
          }
        })
        
        # DynamoDB Gateway endpoint
        dynamodb_endpoint = aws_vpc_endpoint(:dynamodb, {
          vpc_id: "vpc-prod-12345",
          service_name: "com.amazonaws.us-east-1.dynamodb",
          vpc_endpoint_type: "Gateway",
          route_table_ids: ["rtb-private-1a", "rtb-private-1b", "rtb-private-1c"],
          tags: {
            Name: "prod-dynamodb-endpoint",
            Environment: "production"
          }
        })
        
        # EC2 Interface endpoint
        ec2_endpoint = aws_vpc_endpoint(:ec2, {
          vpc_id: "vpc-prod-12345",
          service_name: "com.amazonaws.us-east-1.ec2",
          vpc_endpoint_type: "Interface",
          subnet_ids: ["subnet-private-1a", "subnet-private-1b", "subnet-private-1c"],
          security_group_ids: ["sg-endpoints"],
          private_dns_enabled: true,
          tags: {
            Name: "prod-ec2-endpoint",
            Environment: "production"
          }
        })
        
        synthesis
      end
      
      # Verify all endpoints are created
      expect(result["resource"]["aws_vpc_endpoint"]).to have_key("s3")
      expect(result["resource"]["aws_vpc_endpoint"]).to have_key("dynamodb")
      expect(result["resource"]["aws_vpc_endpoint"]).to have_key("ec2")
      
      # Verify Gateway endpoints
      expect(result["resource"]["aws_vpc_endpoint"]["s3"]["vpc_endpoint_type"]).to eq("Gateway")
      expect(result["resource"]["aws_vpc_endpoint"]["dynamodb"]["vpc_endpoint_type"]).to eq("Gateway")
      
      # Verify Interface endpoint
      expect(result["resource"]["aws_vpc_endpoint"]["ec2"]["vpc_endpoint_type"]).to eq("Interface")
      expect(result["resource"]["aws_vpc_endpoint"]["ec2"]["private_dns_enabled"]).to eq(true)
    end
    
    it "synthesizes Systems Manager connectivity pattern" do
      result = synthesizer.instance_eval do
        # SSM endpoint
        ssm_endpoint = aws_vpc_endpoint(:ssm, {
          vpc_id: "vpc-12345678",
          service_name: "com.amazonaws.us-east-1.ssm",
          vpc_endpoint_type: "Interface",
          subnet_ids: ["subnet-private-1a"],
          security_group_ids: ["sg-ssm-endpoints"],
          private_dns_enabled: true,
          tags: {
            Name: "ssm-endpoint",
            Purpose: "systems-manager"
          }
        })
        
        # SSM Messages endpoint
        ssm_messages_endpoint = aws_vpc_endpoint(:ssm_messages, {
          vpc_id: "vpc-12345678",
          service_name: "com.amazonaws.us-east-1.ssmmessages",
          vpc_endpoint_type: "Interface",
          subnet_ids: ["subnet-private-1a"],
          security_group_ids: ["sg-ssm-endpoints"],
          private_dns_enabled: true,
          tags: {
            Name: "ssm-messages-endpoint",
            Purpose: "systems-manager"
          }
        })
        
        # EC2 Messages endpoint
        ec2_messages_endpoint = aws_vpc_endpoint(:ec2_messages, {
          vpc_id: "vpc-12345678",
          service_name: "com.amazonaws.us-east-1.ec2messages",
          vpc_endpoint_type: "Interface",
          subnet_ids: ["subnet-private-1a"],
          security_group_ids: ["sg-ssm-endpoints"],
          private_dns_enabled: true,
          tags: {
            Name: "ec2-messages-endpoint",
            Purpose: "systems-manager"
          }
        })
        
        synthesis
      end
      
      # Verify all SSM-related endpoints
      expect(result["resource"]["aws_vpc_endpoint"]).to have_key("ssm")
      expect(result["resource"]["aws_vpc_endpoint"]).to have_key("ssm_messages")
      expect(result["resource"]["aws_vpc_endpoint"]).to have_key("ec2_messages")
      
      # All should use the same security group
      ["ssm", "ssm_messages", "ec2_messages"].each do |endpoint_name|
        endpoint = result["resource"]["aws_vpc_endpoint"][endpoint_name]
        expect(endpoint["security_group_ids"]).to eq(["sg-ssm-endpoints"])
        expect(endpoint["private_dns_enabled"]).to eq(true)
      end
    end
    
    it "synthesizes multi-AZ high availability pattern" do
      result = synthesizer.instance_eval do
        aws_vpc_endpoint(:rds_multi_az, {
          vpc_id: "vpc-12345678",
          service_name: "com.amazonaws.us-east-1.rds",
          vpc_endpoint_type: "Interface",
          subnet_ids: ["subnet-private-1a", "subnet-private-1b", "subnet-private-1c"],
          security_group_ids: ["sg-rds-endpoint"],
          private_dns_enabled: true,
          ip_address_type: "ipv4",
          dns_options: {
            dns_record_ip_type: "ipv4"
          },
          tags: {
            Name: "rds-ha-endpoint",
            Pattern: "multi-az-ha",
            Environment: "production"
          }
        })
        
        synthesis
      end
      
      endpoint = result["resource"]["aws_vpc_endpoint"]["rds_multi_az"]
      
      expect(endpoint["subnet_ids"]).to have(3).items
      expect(endpoint["tags"]["Pattern"]).to eq("multi-az-ha")
    end
    
    it "synthesizes secure endpoint with restrictive policy" do
      result = synthesizer.instance_eval do
        restrictive_policy = {
          Version: "2012-10-17",
          Statement: [
            {
              Sid: "RestrictBucketAccess",
              Effect: "Allow",
              Principal: {
                AWS: "arn:aws:iam::123456789012:root"
              },
              Action: [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject"
              ],
              Resource: [
                "arn:aws:s3:::my-secure-bucket/*"
              ]
            },
            {
              Sid: "DenyUnencryptedObjectUploads",
              Effect: "Deny",
              Principal: "*",
              Action: "s3:PutObject",
              Resource: "arn:aws:s3:::my-secure-bucket/*",
              Condition: {
                StringNotEquals: {
                  "s3:x-amz-server-side-encryption": "AES256"
                }
              }
            }
          ]
        }
        
        aws_vpc_endpoint(:s3_secure, {
          vpc_id: "vpc-secure-12345",
          service_name: "com.amazonaws.us-east-1.s3",
          vpc_endpoint_type: "Gateway",
          route_table_ids: ["rtb-secure"],
          policy: restrictive_policy.to_json,
          tags: {
            Name: "s3-secure-endpoint",
            Security: "restricted",
            Compliance: "required"
          }
        })
        
        synthesis
      end
      
      endpoint = result["resource"]["aws_vpc_endpoint"]["s3_secure"]
      policy = JSON.parse(endpoint["policy"])
      
      expect(policy["Statement"]).to have(2).items
      expect(policy["Statement"][0]["Sid"]).to eq("RestrictBucketAccess")
      expect(policy["Statement"][1]["Sid"]).to eq("DenyUnencryptedObjectUploads")
      expect(endpoint["tags"]["Security"]).to eq("restricted")
    end
  end
  
  describe "tag synthesis" do
    it "synthesizes comprehensive tags" do
      result = synthesizer.instance_eval do
        aws_vpc_endpoint(:tagged_endpoint, {
          vpc_id: "vpc-12345678",
          service_name: "com.amazonaws.us-east-1.s3",
          vpc_endpoint_type: "Gateway",
          route_table_ids: ["rtb-12345678"],
          tags: {
            Name: "production-s3-endpoint",
            Environment: "production",
            Application: "data-processing",
            Team: "dataops",
            CostCenter: "engineering",
            ManagedBy: "terraform",
            Purpose: "s3-private-access",
            Backup: "not-required"
          }
        })
        
        synthesis
      end
      
      tags = result["resource"]["aws_vpc_endpoint"]["tagged_endpoint"]["tags"]
      expect(tags).to include(
        Name: "production-s3-endpoint",
        Environment: "production",
        Application: "data-processing",
        Team: "dataops"
      )
    end
  end
end