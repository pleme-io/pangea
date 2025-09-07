# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'AWS Resource Functions' do
  # Include the AWS resource functions for testing
  include Pangea::Resources::AWS

  describe '#aws_vpc' do
    subject { aws_vpc(:test_vpc, valid_vpc_attributes) }

    it_behaves_like 'a valid resource function', 'aws_vpc'

    it 'includes all required VPC attributes' do
      expect(subject.attributes).to include(
        cidr_block: '10.0.0.0/16',
        enable_dns_hostnames: true,
        enable_dns_support: true
      )
    end

    it 'includes proper tags' do
      expect(subject.attributes[:tags]).to include(
        Name: 'test-vpc',
        Environment: 'test'
      )
    end

    it 'provides standard VPC outputs' do
      expected_outputs = %i[id arn cidr_block default_network_acl_id default_route_table_id 
                            default_security_group_id dhcp_options_id internet_gateway_id 
                            ipv6_association_id ipv6_cidr_block main_route_table_id owner_id]
      
      expected_outputs.each do |output|
        expect(subject.outputs).to have_key(output)
        expect(subject.outputs[output]).to eq("${aws_vpc.test_vpc.#{output}}")
      end
    end

    it 'validates CIDR block format' do
      invalid_attrs = valid_vpc_attributes.merge(cidr_block: 'invalid-cidr')
      
      expect {
        aws_vpc(:invalid_vpc, invalid_attrs)
      }.to raise_error(Dry::Struct::Error, /cidr_block/)
    end

    it 'validates boolean fields' do
      invalid_attrs = valid_vpc_attributes.merge(enable_dns_hostnames: 'not_boolean')
      
      expect {
        aws_vpc(:invalid_vpc, invalid_attrs)  
      }.to raise_error(Dry::Struct::Error)
    end

    it 'provides computed attributes through ComputedAttributes' do
      expect(subject.computed_attributes).to be_a(Pangea::Resources::AWS::VpcComputedAttributes)
      expect(subject.computed_attributes.is_default_vpc?).to be false
      expect(subject.computed_attributes.dns_enabled?).to be true
    end
  end

  describe '#aws_subnet' do
    let(:vpc_ref) { create_test_vpc_reference }
    subject { aws_subnet(:test_subnet, valid_subnet_attributes(vpc_ref)) }

    it_behaves_like 'a valid resource function', 'aws_subnet'

    it 'references VPC correctly' do
      expect(subject.attributes[:vpc_id]).to eq(vpc_ref.id)
    end

    it 'includes subnet-specific attributes' do
      expect(subject.attributes).to include(
        cidr_block: '10.0.1.0/24',
        availability_zone: 'us-east-1a',
        map_public_ip_on_launch: true
      )
    end

    it 'provides standard subnet outputs' do
      expected_outputs = %i[id arn vpc_id cidr_block availability_zone 
                           availability_zone_id ipv6_cidr_block ipv6_cidr_block_association_id 
                           map_public_ip_on_launch owner_id]
      
      expected_outputs.each do |output|
        expect(subject.outputs).to have_key(output)
      end
    end

    it 'validates CIDR is within VPC CIDR range' do
      # This would require more sophisticated validation in the actual implementation
      invalid_attrs = valid_subnet_attributes(vpc_ref).merge(cidr_block: '192.168.1.0/24')
      
      expect {
        aws_subnet(:invalid_subnet, invalid_attrs)
      }.to raise_error(Dry::Struct::Error, /cidr_block/)
    end

    it 'creates computed attributes for subnet type detection' do
      expect(subject.computed_attributes).to respond_to(:is_public?)
      expect(subject.computed_attributes.is_public?).to be true
    end
  end

  describe '#aws_security_group' do
    let(:vpc_ref) { create_test_vpc_reference }
    subject { aws_security_group(:test_sg, valid_security_group_attributes(vpc_ref)) }

    it_behaves_like 'a valid resource function', 'aws_security_group'

    it 'includes security group specific attributes' do
      expect(subject.attributes).to include(
        name: 'test-sg',
        description: 'Test security group',
        vpc_id: vpc_ref.id
      )
    end

    it 'includes ingress and egress rules' do
      expect(subject.attributes[:ingress_rules]).to be_an(Array)
      expect(subject.attributes[:egress_rules]).to be_an(Array)
      expect(subject.attributes[:ingress_rules]).not_to be_empty
      expect(subject.attributes[:egress_rules]).not_to be_empty
    end

    it 'validates rule structure' do
      invalid_rule_attrs = valid_security_group_attributes(vpc_ref)
      invalid_rule_attrs[:ingress_rules] = [{ invalid: 'rule' }]
      
      expect {
        aws_security_group(:invalid_sg, invalid_rule_attrs)
      }.to raise_error(Dry::Struct::Error)
    end

    it 'provides security group outputs' do
      expected_outputs = %i[id arn vpc_id owner_id name description]
      
      expected_outputs.each do |output|
        expect(subject.outputs).to have_key(output)
      end
    end

    it 'validates port ranges in rules' do
      invalid_attrs = valid_security_group_attributes(vpc_ref)
      invalid_attrs[:ingress_rules] = [{
        from_port: 80,
        to_port: 70,  # Invalid: to_port < from_port
        protocol: 'tcp',
        cidr_blocks: ['0.0.0.0/0']
      }]
      
      expect {
        aws_security_group(:invalid_sg, invalid_attrs)
      }.to raise_error(Dry::Struct::Error)
    end
  end

  describe '#aws_instance' do
    let(:subnet_ref) { create_test_subnet_reference }
    subject { aws_instance(:test_instance, valid_ec2_attributes(subnet_ref)) }

    it_behaves_like 'a valid resource function', 'aws_instance'

    it 'includes EC2 instance attributes' do
      expect(subject.attributes).to include(
        ami: 'ami-12345678',
        instance_type: 't3.micro',
        subnet_id: subnet_ref.id
      )
    end

    it 'includes user data when provided' do
      expect(subject.attributes[:user_data]).to be_present
      expect(subject.attributes[:user_data]).to start_with('IyEvYmlu')  # Base64 encoded
    end

    it 'validates instance type format' do
      invalid_attrs = valid_ec2_attributes(subnet_ref).merge(instance_type: 'invalid-type')
      
      expect {
        aws_instance(:invalid_instance, invalid_attrs)
      }.to raise_error(Dry::Struct::Error, /instance_type/)
    end

    it 'validates AMI ID format' do
      invalid_attrs = valid_ec2_attributes(subnet_ref).merge(ami: 'invalid-ami')
      
      expect {
        aws_instance(:invalid_instance, invalid_attrs)
      }.to raise_error(Dry::Struct::Error, /ami/)
    end

    it 'provides instance outputs' do
      expected_outputs = %i[id arn instance_state public_dns public_ip 
                           private_dns private_ip subnet_id vpc_security_group_ids]
      
      expected_outputs.each do |output|
        expect(subject.outputs).to have_key(output)
      end
    end
  end

  describe '#aws_s3_bucket' do
    subject { aws_s3_bucket(:test_bucket, valid_s3_attributes) }

    it_behaves_like 'a valid resource function', 'aws_s3_bucket'

    it 'includes S3 bucket attributes' do
      bucket_name = subject.attributes[:bucket]
      expect(bucket_name).to start_with('test-bucket-')
      expect(subject.attributes[:versioning]).to eq('Enabled')
    end

    it 'includes encryption configuration' do
      expect(subject.attributes[:encryption]).to include(
        sse_algorithm: 'AES256'
      )
    end

    it 'includes lifecycle rules' do
      expect(subject.attributes[:lifecycle_rules]).to be_an(Array)
      expect(subject.attributes[:lifecycle_rules].first).to include(
        id: 'test_lifecycle',
        status: 'Enabled'
      )
    end

    it 'validates bucket name format' do
      invalid_attrs = valid_s3_attributes.merge(bucket_name: 'Invalid_Bucket_Name!')
      
      expect {
        aws_s3_bucket(:invalid_bucket, invalid_attrs)
      }.to raise_error(Dry::Struct::Error, /bucket_name/)
    end

    it 'provides S3 bucket outputs' do
      expected_outputs = %i[id arn bucket bucket_domain_name bucket_regional_domain_name
                           hosted_zone_id region website_endpoint website_domain]
      
      expected_outputs.each do |output|
        expect(subject.outputs).to have_key(output)
      end
    end
  end

  describe '#aws_db_instance' do
    subject { aws_db_instance(:test_db, valid_rds_attributes) }

    it_behaves_like 'a valid resource function', 'aws_db_instance'

    it 'includes RDS instance attributes' do
      expect(subject.attributes).to include(
        identifier: 'test-db',
        engine: 'postgres',
        engine_version: '14.9',
        instance_class: 'db.t3.micro'
      )
    end

    it 'includes security and backup configuration' do
      expect(subject.attributes).to include(
        storage_encrypted: true,
        backup_retention_period: 7,
        deletion_protection: false
      )
    end

    it 'validates engine types' do
      invalid_attrs = valid_rds_attributes.merge(engine: 'invalid-engine')
      
      expect {
        aws_db_instance(:invalid_db, invalid_attrs)
      }.to raise_error(Dry::Struct::Error, /engine/)
    end

    it 'validates instance class format' do
      invalid_attrs = valid_rds_attributes.merge(instance_class: 'invalid-class')
      
      expect {
        aws_db_instance(:invalid_db, invalid_attrs)
      }.to raise_error(Dry::Struct::Error, /instance_class/)
    end

    it 'provides RDS outputs' do
      expected_outputs = %i[id arn endpoint hosted_zone_id port resource_id
                           ca_cert_identifier db_name username engine engine_version]
      
      expected_outputs.each do |output|
        expect(subject.outputs).to have_key(output)
      end
    end
  end

  describe '#aws_lb' do
    let(:subnet_refs) { [create_test_subnet_reference, create_test_subnet_reference] }
    subject { aws_lb(:test_alb, valid_alb_attributes(subnet_refs)) }

    it_behaves_like 'a valid resource function', 'aws_lb'

    it 'includes load balancer attributes' do
      expect(subject.attributes).to include(
        name: 'test-alb',
        load_balancer_type: 'application',
        subnets: subnet_refs.map(&:id)
      )
    end

    it 'validates load balancer type' do
      invalid_attrs = valid_alb_attributes(subnet_refs).merge(load_balancer_type: 'invalid')
      
      expect {
        aws_lb(:invalid_alb, invalid_attrs)
      }.to raise_error(Dry::Struct::Error, /load_balancer_type/)
    end

    it 'requires multiple subnets for application load balancer' do
      single_subnet_attrs = valid_alb_attributes([subnet_refs.first])
      
      expect {
        aws_lb(:invalid_alb, single_subnet_attrs)
      }.to raise_error(Dry::Struct::Error, /subnets/)
    end

    it 'provides load balancer outputs' do
      expected_outputs = %i[id arn dns_name hosted_zone_id load_balancer_type
                           vpc_id subnet_mapping security_groups]
      
      expected_outputs.each do |output|
        expect(subject.outputs).to have_key(output)
      end
    end
  end

  describe 'resource composition patterns' do
    it 'creates VPC with subnets and security groups' do
      # Create VPC
      vpc = aws_vpc(:main_vpc, valid_vpc_attributes)
      
      # Create subnets in the VPC
      public_subnet = aws_subnet(:public_subnet, {
        vpc_id: vpc.ref(:id),
        cidr_block: '10.0.1.0/24',
        availability_zone: 'us-east-1a',
        map_public_ip_on_launch: true
      })
      
      private_subnet = aws_subnet(:private_subnet, {
        vpc_id: vpc.ref(:id), 
        cidr_block: '10.0.2.0/24',
        availability_zone: 'us-east-1b',
        map_public_ip_on_launch: false
      })
      
      # Create security group
      web_sg = aws_security_group(:web_sg, {
        name: 'web-sg',
        description: 'Web tier security group',
        vpc_id: vpc.ref(:id),
        ingress_rules: [
          {
            from_port: 80,
            to_port: 80,
            protocol: 'tcp',
            cidr_blocks: ['0.0.0.0/0']
          }
        ]
      })
      
      # Verify references are properly established
      expect(public_subnet.attributes[:vpc_id]).to eq("${aws_vpc.main_vpc.id}")
      expect(private_subnet.attributes[:vpc_id]).to eq("${aws_vpc.main_vpc.id}")
      expect(web_sg.attributes[:vpc_id]).to eq("${aws_vpc.main_vpc.id}")
    end

    it 'creates complete web server setup' do
      # Infrastructure
      vpc = aws_vpc(:web_vpc, valid_vpc_attributes)
      subnet = aws_subnet(:web_subnet, valid_subnet_attributes(vpc))
      security_group = aws_security_group(:web_sg, valid_security_group_attributes(vpc))
      
      # Compute
      instance = aws_instance(:web_server, {
        ami: 'ami-12345678',
        instance_type: 't3.micro',
        subnet_id: subnet.ref(:id),
        vpc_security_group_ids: [security_group.ref(:id)],
        user_data: base64encode('#!/bin/bash\nyum install -y httpd\nsystemctl start httpd'),
        tags: { Name: 'web-server', Role: 'frontend' }
      })
      
      # Load balancer
      alb = aws_lb(:web_alb, {
        name: 'web-alb',
        load_balancer_type: 'application',
        subnets: [subnet.ref(:id)],
        security_groups: [security_group.ref(:id)]
      })
      
      # Storage
      bucket = aws_s3_bucket(:web_assets, {
        bucket_name: 'web-assets-bucket',
        versioning: 'Enabled',
        tags: { Purpose: 'web-assets' }
      })
      
      # Verify all resources are properly configured
      expect(instance.attributes[:subnet_id]).to include('aws_subnet.web_subnet.id')
      expect(instance.attributes[:vpc_security_group_ids]).to include(match(/aws_security_group\.web_sg\.id/))
      expect(alb.attributes[:subnets]).to include(match(/aws_subnet\.web_subnet\.id/))
    end
  end

  describe 'error handling and validation' do
    it 'provides clear error messages for validation failures' do
      expect {
        aws_vpc(:invalid, { cidr_block: 'not-a-cidr' })
      }.to raise_error(Dry::Struct::Error, /cidr_block/)
    end

    it 'validates required fields are present' do
      expect {
        aws_instance(:incomplete, { ami: 'ami-12345' })  # Missing instance_type
      }.to raise_error(Dry::Struct::Error, /instance_type/)
    end

    it 'validates field types are correct' do
      expect {
        aws_s3_bucket(:invalid, { versioning: true })  # Should be string
      }.to raise_error(Dry::Struct::Error)
    end
  end
end