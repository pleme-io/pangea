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


# Test helpers for resource function testing
module ResourceHelpers
  # Generate test attributes for AWS VPC
  def valid_vpc_attributes
    {
      cidr_block: '10.0.0.0/16',
      enable_dns_hostnames: true,
      enable_dns_support: true,
      tags: {
        Name: 'test-vpc',
        Environment: 'test'
      }
    }
  end

  # Generate test attributes for AWS Subnet
  def valid_subnet_attributes(vpc_ref = nil)
    {
      vpc_id: vpc_ref&.id || 'vpc-12345678',
      cidr_block: '10.0.1.0/24',
      availability_zone: 'us-east-1a',
      map_public_ip_on_launch: true,
      tags: {
        Name: 'test-subnet',
        Type: 'public'
      }
    }
  end

  # Generate test attributes for AWS Security Group
  def valid_security_group_attributes(vpc_ref = nil)
    {
      name: 'test-sg',
      description: 'Test security group',
      vpc_id: vpc_ref&.id || 'vpc-12345678',
      ingress_rules: [
        {
          from_port: 80,
          to_port: 80,
          protocol: 'tcp',
          cidr_blocks: ['0.0.0.0/0'],
          description: 'HTTP'
        },
        {
          from_port: 443,
          to_port: 443,
          protocol: 'tcp',
          cidr_blocks: ['0.0.0.0/0'],
          description: 'HTTPS'
        }
      ],
      egress_rules: [
        {
          from_port: 0,
          to_port: 0,
          protocol: '-1',
          cidr_blocks: ['0.0.0.0/0'],
          description: 'All outbound'
        }
      ],
      tags: {
        Name: 'test-security-group'
      }
    }
  end

  # Generate test attributes for AWS EC2 instance
  def valid_ec2_attributes(subnet_ref = nil)
    {
      ami: 'ami-12345678',
      instance_type: 't3.micro',
      subnet_id: subnet_ref&.id || 'subnet-12345678',
      key_name: 'test-key',
      user_data: base64encode('#!/bin/bash\necho "Hello World"'),
      tags: {
        Name: 'test-instance',
        Environment: 'test'
      }
    }
  end

  # Generate test attributes for AWS RDS instance
  def valid_rds_attributes
    {
      identifier: 'test-db',
      engine: 'postgres',
      engine_version: '14.9',
      instance_class: 'db.t3.micro',
      allocated_storage: 20,
      storage_type: 'gp2',
      storage_encrypted: true,
      db_name: 'testdb',
      username: 'admin',
      manage_master_user_password: true,
      vpc_security_group_ids: ['sg-12345678'],
      db_subnet_group_name: 'test-subnet-group',
      backup_retention_period: 7,
      backup_window: '03:00-04:00',
      maintenance_window: 'sun:04:00-sun:05:00',
      deletion_protection: false,
      skip_final_snapshot: true,
      tags: {
        Name: 'test-database',
        Environment: 'test'
      }
    }
  end

  # Generate test attributes for AWS S3 bucket
  def valid_s3_attributes
    {
      bucket_name: "test-bucket-#{Time.now.to_i}",
      versioning: 'Enabled',
      encryption: {
        sse_algorithm: 'AES256'
      },
      lifecycle_rules: [
        {
          id: 'test_lifecycle',
          status: 'Enabled',
          transitions: [
            {
              days: 30,
              storage_class: 'STANDARD_IA'
            }
          ],
          expiration: { days: 365 }
        }
      ],
      tags: {
        Name: 'test-bucket',
        Purpose: 'testing'
      }
    }
  end

  # Generate test attributes for AWS Load Balancer
  def valid_alb_attributes(subnet_refs = nil)
    {
      name: 'test-alb',
      load_balancer_type: 'application',
      subnets: subnet_refs&.map(&:id) || ['subnet-12345678', 'subnet-87654321'],
      security_groups: ['sg-12345678'],
      tags: {
        Name: 'test-load-balancer',
        Environment: 'test'
      }
    }
  end

  # Generate invalid attributes for testing validation
  def invalid_vpc_attributes
    {
      cidr_block: 'invalid-cidr',  # Invalid CIDR format
      enable_dns_hostnames: 'not_boolean',  # Should be boolean
      tags: 'not_a_hash'  # Should be hash
    }
  end

  # Helper to create a mock terraform reference
  def mock_terraform_ref(resource_type, resource_name, attribute)
    "${#{resource_type}.#{resource_name}.#{attribute}}"
  end

  # Helper to simulate base64 encoding for user data
  def base64encode(data)
    require 'base64'
    Base64.strict_encode64(data)
  end

  # Helper to create consistent test tags
  def test_tags(additional_tags = {})
    {
      Environment: 'test',
      ManagedBy: 'pangea-test',
      CreatedAt: Time.now.strftime('%Y-%m-%d')
    }.merge(additional_tags)
  end

  # Helper to generate random AWS resource IDs for testing
  def generate_aws_id(prefix)
    "#{prefix}-#{SecureRandom.hex(4)}"
  end

  # Helper to create a basic VPC reference for testing dependent resources
  def create_test_vpc_reference
    Pangea::Resources::ResourceReference.new(
      type: 'aws_vpc',
      name: :test_vpc,
      resource_attributes: valid_vpc_attributes,
      outputs: {
        id: mock_terraform_ref('aws_vpc', 'test_vpc', 'id'),
        arn: mock_terraform_ref('aws_vpc', 'test_vpc', 'arn'),
        cidr_block: mock_terraform_ref('aws_vpc', 'test_vpc', 'cidr_block')
      }
    )
  end

  # Helper to create a basic subnet reference for testing
  def create_test_subnet_reference
    Pangea::Resources::ResourceReference.new(
      type: 'aws_subnet',
      name: :test_subnet,
      resource_attributes: valid_subnet_attributes,
      outputs: {
        id: mock_terraform_ref('aws_subnet', 'test_subnet', 'id'),
        arn: mock_terraform_ref('aws_subnet', 'test_subnet', 'arn'),
        vpc_id: mock_terraform_ref('aws_subnet', 'test_subnet', 'vpc_id')
      }
    )
  end
end

RSpec.configure do |config|
  config.include ResourceHelpers
end