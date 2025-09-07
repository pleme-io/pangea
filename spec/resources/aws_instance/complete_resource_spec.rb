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

# Load aws_instance resource and types for testing
require 'pangea/resources/aws_instance/resource'
require 'pangea/resources/aws_instance/types'

RSpec.describe "aws_instance resource function" do
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
  let(:ami_id) { "ami-0c02fb55956c7d316" }
  let(:subnet_id) { "${aws_subnet.test.id}" }
  
  describe "InstanceAttributes validation" do
    it "validates required ami attribute" do
      expect {
        Pangea::Resources::AWS::InstanceAttributes.new({
          instance_type: "t3.micro"
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates required instance_type attribute" do
      expect {
        Pangea::Resources::AWS::InstanceAttributes.new({
          ami: ami_id
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "accepts minimal valid instance attributes" do
      attrs = Pangea::Resources::AWS::InstanceAttributes.new({
        ami: ami_id,
        instance_type: "t3.micro"
      })
      
      expect(attrs.ami).to eq(ami_id)
      expect(attrs.instance_type).to eq("t3.micro")
    end
    
    it "applies default values for optional attributes" do
      attrs = Pangea::Resources::AWS::InstanceAttributes.new({
        ami: ami_id,
        instance_type: "t3.micro"
      })
      
      expect(attrs.vpc_security_group_ids).to eq([])
      expect(attrs.ebs_block_device).to eq([])
      expect(attrs.monitoring).to eq(false)
      expect(attrs.ebs_optimized).to eq(false)
      expect(attrs.disable_api_termination).to eq(false)
      expect(attrs.tags).to eq({})
    end
    
    it "accepts network configuration attributes" do
      attrs = Pangea::Resources::AWS::InstanceAttributes.new({
        ami: ami_id,
        instance_type: "t3.micro",
        subnet_id: subnet_id,
        vpc_security_group_ids: ["sg-12345", "sg-67890"],
        availability_zone: "us-east-1a",
        associate_public_ip_address: true
      })
      
      expect(attrs.subnet_id).to eq(subnet_id)
      expect(attrs.vpc_security_group_ids).to eq(["sg-12345", "sg-67890"])
      expect(attrs.availability_zone).to eq("us-east-1a")
      expect(attrs.associate_public_ip_address).to eq(true)
    end
    
    it "accepts instance configuration attributes" do
      user_data = <<~USERDATA
        #!/bin/bash
        yum update -y
      USERDATA
      
      attrs = Pangea::Resources::AWS::InstanceAttributes.new({
        ami: ami_id,
        instance_type: "m5.large",
        key_name: "my-key-pair",
        user_data: user_data,
        iam_instance_profile: "app-instance-profile"
      })
      
      expect(attrs.key_name).to eq("my-key-pair")
      expect(attrs.user_data).to eq(user_data)
      expect(attrs.iam_instance_profile).to eq("app-instance-profile")
    end
    
    it "accepts root block device configuration" do
      attrs = Pangea::Resources::AWS::InstanceAttributes.new({
        ami: ami_id,
        instance_type: "t3.micro",
        root_block_device: {
          volume_type: "gp3",
          volume_size: 50,
          throughput: 250,
          encrypted: true,
          delete_on_termination: true
        }
      })
      
      rbd = attrs.root_block_device
      expect(rbd[:volume_type]).to eq("gp3")
      expect(rbd[:volume_size]).to eq(50)
      expect(rbd[:throughput]).to eq(250)
      expect(rbd[:encrypted]).to eq(true)
      expect(rbd[:delete_on_termination]).to eq(true)
    end
    
    it "accepts EBS block device configuration" do
      attrs = Pangea::Resources::AWS::InstanceAttributes.new({
        ami: ami_id,
        instance_type: "r5.large",
        ebs_block_device: [
          {
            device_name: "/dev/sdf",
            volume_type: "io2",
            volume_size: 1000,
            iops: 10000,
            encrypted: true,
            delete_on_termination: false
          }
        ]
      })
      
      ebs = attrs.ebs_block_device.first
      expect(ebs[:device_name]).to eq("/dev/sdf")
      expect(ebs[:volume_type]).to eq("io2")
      expect(ebs[:volume_size]).to eq(1000)
      expect(ebs[:iops]).to eq(10000)
      expect(ebs[:encrypted]).to eq(true)
      expect(ebs[:delete_on_termination]).to eq(false)
    end
    
    it "accepts instance behavior attributes" do
      attrs = Pangea::Resources::AWS::InstanceAttributes.new({
        ami: ami_id,
        instance_type: "c5.xlarge",
        instance_initiated_shutdown_behavior: "terminate",
        monitoring: true,
        ebs_optimized: true,
        source_dest_check: false,
        disable_api_termination: true
      })
      
      expect(attrs.instance_initiated_shutdown_behavior).to eq("terminate")
      expect(attrs.monitoring).to eq(true)
      expect(attrs.ebs_optimized).to eq(true)
      expect(attrs.source_dest_check).to eq(false)
      expect(attrs.disable_api_termination).to eq(true)
    end
    
    it "accepts tags" do
      attrs = Pangea::Resources::AWS::InstanceAttributes.new({
        ami: ami_id,
        instance_type: "t3.micro",
        tags: { Name: "web-server", Environment: "production" }
      })
      
      expect(attrs.tags).to eq({
        Name: "web-server",
        Environment: "production"
      })
    end
    
    describe "user data validation" do
      it "validates user_data exclusivity" do
        expect {
          Pangea::Resources::AWS::InstanceAttributes.new({
            ami: ami_id,
            instance_type: "t3.micro",
            user_data: "#!/bin/bash\necho hello",
            user_data_base64: "IyEvYmluL2Jhc2gK"
          })
        }.to raise_error(Dry::Struct::Error, /Cannot specify both 'user_data' and 'user_data_base64'/)
      end
      
      it "accepts user_data alone" do
        attrs = Pangea::Resources::AWS::InstanceAttributes.new({
          ami: ami_id,
          instance_type: "t3.micro",
          user_data: "#!/bin/bash\necho hello"
        })
        
        expect(attrs.user_data).to eq("#!/bin/bash\necho hello")
        expect(attrs.user_data_base64).to be_nil
      end
      
      it "accepts user_data_base64 alone" do
        attrs = Pangea::Resources::AWS::InstanceAttributes.new({
          ami: ami_id,
          instance_type: "t3.micro",
          user_data_base64: "IyEvYmluL2Jhc2gK"
        })
        
        expect(attrs.user_data_base64).to eq("IyEvYmluL2Jhc2gK")
        expect(attrs.user_data).to be_nil
      end
    end
    
    describe "storage validation" do
      it "validates IOPS only for io1/io2 volumes" do
        expect {
          Pangea::Resources::AWS::InstanceAttributes.new({
            ami: ami_id,
            instance_type: "t3.micro",
            root_block_device: {
              volume_type: "gp3",
              iops: 5000
            }
          })
        }.to raise_error(Dry::Struct::Error, /IOPS can only be specified for io1 or io2/)
      end
      
      it "accepts IOPS for io1 volumes" do
        attrs = Pangea::Resources::AWS::InstanceAttributes.new({
          ami: ami_id,
          instance_type: "t3.micro",
          root_block_device: {
            volume_type: "io1",
            iops: 5000
          }
        })
        
        expect(attrs.root_block_device[:volume_type]).to eq("io1")
        expect(attrs.root_block_device[:iops]).to eq(5000)
      end
      
      it "accepts IOPS for io2 volumes" do
        attrs = Pangea::Resources::AWS::InstanceAttributes.new({
          ami: ami_id,
          instance_type: "t3.micro",
          root_block_device: {
            volume_type: "io2",
            iops: 10000
          }
        })
        
        expect(attrs.root_block_device[:volume_type]).to eq("io2")
        expect(attrs.root_block_device[:iops]).to eq(10000)
      end
      
      it "validates throughput only for gp3 volumes" do
        expect {
          Pangea::Resources::AWS::InstanceAttributes.new({
            ami: ami_id,
            instance_type: "t3.micro",
            root_block_device: {
              volume_type: "gp2",
              throughput: 250
            }
          })
        }.to raise_error(Dry::Struct::Error, /Throughput can only be specified for gp3/)
      end
      
      it "accepts throughput for gp3 volumes" do
        attrs = Pangea::Resources::AWS::InstanceAttributes.new({
          ami: ami_id,
          instance_type: "t3.micro",
          root_block_device: {
            volume_type: "gp3",
            throughput: 250
          }
        })
        
        expect(attrs.root_block_device[:volume_type]).to eq("gp3")
        expect(attrs.root_block_device[:throughput]).to eq(250)
      end
    end
    
    describe "helper methods" do
      it "extracts instance family correctly" do
        attrs = Pangea::Resources::AWS::InstanceAttributes.new({
          ami: ami_id,
          instance_type: "m5.2xlarge"
        })
        
        expect(attrs.instance_family).to eq("m5")
      end
      
      it "extracts instance size correctly" do
        attrs = Pangea::Resources::AWS::InstanceAttributes.new({
          ami: ami_id,
          instance_type: "c5.xlarge"
        })
        
        expect(attrs.instance_size).to eq("xlarge")
      end
      
      it "detects EBS optimization support" do
        # t3 family should not support EBS optimization
        t3_attrs = Pangea::Resources::AWS::InstanceAttributes.new({
          ami: ami_id,
          instance_type: "t3.micro"
        })
        expect(t3_attrs.supports_ebs_optimization?).to eq(false)
        
        # m5 family should support EBS optimization
        m5_attrs = Pangea::Resources::AWS::InstanceAttributes.new({
          ami: ami_id,
          instance_type: "m5.large"
        })
        expect(m5_attrs.supports_ebs_optimization?).to eq(true)
      end
      
      it "predicts public IP assignment" do
        # Explicitly set to true
        public_attrs = Pangea::Resources::AWS::InstanceAttributes.new({
          ami: ami_id,
          instance_type: "t3.micro",
          associate_public_ip_address: true
        })
        expect(public_attrs.will_have_public_ip?).to eq(true)
        
        # Explicitly set to false
        private_attrs = Pangea::Resources::AWS::InstanceAttributes.new({
          ami: ami_id,
          instance_type: "t3.micro",
          associate_public_ip_address: false
        })
        expect(private_attrs.will_have_public_ip?).to eq(false)
        
        # Not set - depends on subnet
        unset_attrs = Pangea::Resources::AWS::InstanceAttributes.new({
          ami: ami_id,
          instance_type: "t3.micro"
        })
        expect(unset_attrs.will_have_public_ip?).to be_nil
      end
      
      it "estimates hourly costs" do
        # Known instance type
        t3_micro = Pangea::Resources::AWS::InstanceAttributes.new({
          ami: ami_id,
          instance_type: "t3.micro"
        })
        expect(t3_micro.estimated_hourly_cost).to eq(0.0104)
        
        # Unknown instance type should use default
        unknown_attrs = Pangea::Resources::AWS::InstanceAttributes.new({
          ami: ami_id,
          instance_type: "x1e.32xlarge"
        })
        expect(unknown_attrs.estimated_hourly_cost).to eq(0.10)
      end
    end
  end
  
  describe "aws_instance function behavior" do
    it "creates a resource reference with minimal attributes" do
      ref = test_instance.aws_instance(:test, {
        ami: ami_id,
        instance_type: "t3.micro"
      })
      
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_instance')
      expect(ref.name).to eq(:test)
    end
    
    it "creates a resource reference with network attributes" do
      ref = test_instance.aws_instance(:web, {
        ami: ami_id,
        instance_type: "t3.small",
        subnet_id: subnet_id,
        vpc_security_group_ids: ["sg-12345"],
        associate_public_ip_address: true
      })
      
      expect(ref.resource_attributes[:subnet_id]).to eq(subnet_id)
      expect(ref.resource_attributes[:vpc_security_group_ids]).to eq(["sg-12345"])
      expect(ref.resource_attributes[:associate_public_ip_address]).to eq(true)
    end
    
    it "handles root block device configuration" do
      ref = test_instance.aws_instance(:storage, {
        ami: ami_id,
        instance_type: "m5.large",
        root_block_device: {
          volume_type: "gp3",
          volume_size: 100,
          encrypted: true
        }
      })
      
      rbd = ref.resource_attributes[:root_block_device]
      expect(rbd[:volume_type]).to eq("gp3")
      expect(rbd[:volume_size]).to eq(100)
      expect(rbd[:encrypted]).to eq(true)
    end
    
    it "handles EBS block devices" do
      ref = test_instance.aws_instance(:database, {
        ami: ami_id,
        instance_type: "r5.xlarge",
        ebs_block_device: [
          {
            device_name: "/dev/sdf",
            volume_type: "io2",
            volume_size: 500,
            iops: 8000,
            encrypted: true
          }
        ]
      })
      
      ebs = ref.resource_attributes[:ebs_block_device].first
      expect(ebs[:device_name]).to eq("/dev/sdf")
      expect(ebs[:volume_type]).to eq("io2")
      expect(ebs[:volume_size]).to eq(500)
      expect(ebs[:iops]).to eq(8000)
    end
    
    it "handles instance configuration" do
      ref = test_instance.aws_instance(:app, {
        ami: ami_id,
        instance_type: "c5.large",
        key_name: "app-key",
        user_data: "#!/bin/bash\necho hello",
        iam_instance_profile: "app-profile",
        monitoring: true,
        ebs_optimized: true
      })
      
      expect(ref.resource_attributes[:key_name]).to eq("app-key")
      expect(ref.resource_attributes[:user_data]).to eq("#!/bin/bash\necho hello")
      expect(ref.resource_attributes[:iam_instance_profile]).to eq("app-profile")
      expect(ref.resource_attributes[:monitoring]).to eq(true)
      expect(ref.resource_attributes[:ebs_optimized]).to eq(true)
    end
    
    it "handles tags correctly" do
      ref = test_instance.aws_instance(:tagged, {
        ami: ami_id,
        instance_type: "t3.micro",
        tags: { Name: "web-server", Environment: "prod" }
      })
      
      expect(ref.resource_attributes[:tags]).to eq({
        Name: "web-server",
        Environment: "prod"
      })
    end
    
    it "validates attributes in function call" do
      expect {
        test_instance.aws_instance(:invalid, {
          ami: ami_id,
          instance_type: "t3.micro",
          user_data: "data",
          user_data_base64: "base64data"
        })
      }.to raise_error(Dry::Struct::Error, /Cannot specify both/)
    end
    
    it "provides all expected outputs" do
      ref = test_instance.aws_instance(:test, {
        ami: ami_id,
        instance_type: "t3.micro"
      })
      
      expected_outputs = [:id, :arn, :public_ip, :private_ip, :public_dns, 
                         :private_dns, :instance_state, :subnet_id, 
                         :availability_zone, :key_name, :vpc_security_group_ids]
      expected_outputs.each do |output|
        expect(ref.outputs).to have_key(output)
        expect(ref.outputs[output]).to include("${aws_instance.test.#{output}}")
      end
    end
    
    it "provides computed properties" do
      ref = test_instance.aws_instance(:test, {
        ami: ami_id,
        instance_type: "m5.xlarge"
      })
      
      expect(ref.compute_family).to eq("m5")
      expect(ref.compute_size).to eq("xlarge")
      
      # Test with explicit public IP setting
      public_ref = test_instance.aws_instance(:public_test, {
        ami: ami_id,
        instance_type: "t3.micro",
        associate_public_ip_address: true
      })
      expect(public_ref.will_have_public_ip?).to eq(true)
    end
  end
  
  describe "common instance patterns" do
    it "creates a basic web server instance" do
      ref = test_instance.aws_instance(:web, {
        ami: ami_id,
        instance_type: "t3.small",
        subnet_id: subnet_id,
        vpc_security_group_ids: ["${aws_security_group.web.id}"],
        associate_public_ip_address: true,
        key_name: "web-key",
        user_data: <<~USERDATA,
          #!/bin/bash
          yum update -y
          yum install -y httpd
          systemctl start httpd
        USERDATA
        tags: { Name: "web-server", Role: "frontend" }
      })
      
      expect(ref.resource_attributes[:instance_type]).to eq("t3.small")
      expect(ref.resource_attributes[:associate_public_ip_address]).to eq(true)
      expect(ref.resource_attributes[:user_data]).to include("httpd")
      expect(ref.resource_attributes[:tags][:Role]).to eq("frontend")
    end
    
    it "creates an application server with IAM role" do
      ref = test_instance.aws_instance(:app, {
        ami: ami_id,
        instance_type: "m5.large",
        subnet_id: subnet_id,
        vpc_security_group_ids: ["${aws_security_group.app.id}"],
        iam_instance_profile: "${aws_iam_instance_profile.app.name}",
        root_block_device: {
          volume_type: "gp3",
          volume_size: 50,
          encrypted: true
        },
        monitoring: true,
        ebs_optimized: true,
        tags: { Name: "app-server", Tier: "application" }
      })
      
      expect(ref.resource_attributes[:iam_instance_profile]).to include("iam_instance_profile")
      expect(ref.resource_attributes[:root_block_device][:encrypted]).to eq(true)
      expect(ref.resource_attributes[:monitoring]).to eq(true)
      expect(ref.resource_attributes[:tags][:Tier]).to eq("application")
    end
    
    it "creates a high-performance database instance" do
      ref = test_instance.aws_instance(:database, {
        ami: ami_id,
        instance_type: "r5.2xlarge",
        subnet_id: subnet_id,
        vpc_security_group_ids: ["${aws_security_group.db.id}"],
        root_block_device: {
          volume_type: "gp3",
          volume_size: 100,
          throughput: 250,
          encrypted: true
        },
        ebs_block_device: [
          {
            device_name: "/dev/sdf",
            volume_type: "io2",
            volume_size: 1000,
            iops: 20000,
            encrypted: true,
            delete_on_termination: false
          }
        ],
        disable_api_termination: true,
        monitoring: true,
        ebs_optimized: true,
        tags: {
          Name: "database-server",
          Type: "primary-database",
          Critical: "true"
        }
      })
      
      expect(ref.resource_attributes[:instance_type]).to eq("r5.2xlarge")
      expect(ref.resource_attributes[:disable_api_termination]).to eq(true)
      expect(ref.resource_attributes[:ebs_block_device].first[:iops]).to eq(20000)
      expect(ref.resource_attributes[:tags][:Critical]).to eq("true")
    end
    
    it "creates a minimal development instance" do
      ref = test_instance.aws_instance(:dev, {
        ami: ami_id,
        instance_type: "t3.micro",
        key_name: "dev-key",
        tags: { Name: "dev-instance", Environment: "development" }
      })
      
      expect(ref.resource_attributes[:instance_type]).to eq("t3.micro")
      expect(ref.resource_attributes[:key_name]).to eq("dev-key")
      expect(ref.resource_attributes[:monitoring]).to eq(false)  # Default
      expect(ref.resource_attributes[:tags][:Environment]).to eq("development")
    end
  end
end