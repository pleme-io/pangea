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

# Load aws_launch_template resource and types for testing
require 'pangea/resources/aws_launch_template/resource'
require 'pangea/resources/aws_launch_template/types'

RSpec.describe "aws_launch_template resource function" do
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
  let(:sg_id) { "${aws_security_group.web.id}" }
  let(:subnet_id) { "${aws_subnet.private.id}" }
  let(:role_name) { "ec2-instance-role" }
  
  describe "IamInstanceProfile validation" do
    it "accepts string input for name" do
      profile = Pangea::Resources::AWS::Types::IamInstanceProfile.new("my-role")
      expect(profile.name).to eq("my-role")
      expect(profile.arn).to be_nil
    end
    
    it "accepts hash input with name" do
      profile = Pangea::Resources::AWS::Types::IamInstanceProfile.new(name: "my-role")
      expect(profile.name).to eq("my-role")
      expect(profile.arn).to be_nil
    end
    
    it "accepts hash input with ARN" do
      arn = "arn:aws:iam::123456789012:instance-profile/my-role"
      profile = Pangea::Resources::AWS::Types::IamInstanceProfile.new(arn: arn)
      expect(profile.arn).to eq(arn)
      expect(profile.name).to be_nil
    end
    
    it "compacts hash output correctly" do
      profile = Pangea::Resources::AWS::Types::IamInstanceProfile.new("my-role")
      hash = profile.to_h
      expect(hash).to eq({ name: "my-role" })
      expect(hash).not_to have_key(:arn)
    end
  end
  
  describe "BlockDeviceMapping validation" do
    it "accepts minimal block device mapping" do
      bdm = Pangea::Resources::AWS::Types::BlockDeviceMapping.new({
        device_name: "/dev/sda1"
      })
      
      expect(bdm.device_name).to eq("/dev/sda1")
      expect(bdm.ebs).to be_nil
      expect(bdm.no_device).to be_nil
      expect(bdm.virtual_name).to be_nil
    end
    
    it "accepts block device with EBS configuration" do
      bdm = Pangea::Resources::AWS::Types::BlockDeviceMapping.new({
        device_name: "/dev/sda1",
        ebs: {
          volume_size: 100,
          volume_type: "gp3",
          encrypted: true,
          delete_on_termination: false,
          iops: 3000,
          throughput: 125
        }
      })
      
      expect(bdm.device_name).to eq("/dev/sda1")
      expect(bdm.ebs[:volume_size]).to eq(100)
      expect(bdm.ebs[:volume_type]).to eq("gp3")
      expect(bdm.ebs[:encrypted]).to eq(true)
      expect(bdm.ebs[:delete_on_termination]).to eq(false)
      expect(bdm.ebs[:iops]).to eq(3000)
      expect(bdm.ebs[:throughput]).to eq(125)
    end
    
    it "applies EBS defaults correctly" do
      bdm = Pangea::Resources::AWS::Types::BlockDeviceMapping.new({
        device_name: "/dev/sda1",
        ebs: {
          volume_size: 50
        }
      })
      
      expect(bdm.ebs[:volume_type]).to eq("gp3")
      expect(bdm.ebs[:encrypted]).to eq(false)
      expect(bdm.ebs[:delete_on_termination]).to eq(true)
    end
    
    it "validates EBS volume type enum" do
      expect {
        Pangea::Resources::AWS::Types::BlockDeviceMapping.new({
          device_name: "/dev/sda1",
          ebs: {
            volume_type: "invalid"
          }
        })
      }.to raise_error(Dry::Struct::Error)
    end
  end
  
  describe "NetworkInterface validation" do
    it "accepts minimal network interface" do
      ni = Pangea::Resources::AWS::Types::NetworkInterface.new({})
      
      expect(ni.device_index).to eq(0)
      expect(ni.delete_on_termination).to eq(true)
      expect(ni.groups).to eq([])
      expect(ni.associate_public_ip_address).to be_nil
    end
    
    it "accepts network interface with full configuration" do
      ni = Pangea::Resources::AWS::Types::NetworkInterface.new({
        device_index: 1,
        subnet_id: subnet_id,
        groups: [sg_id],
        associate_public_ip_address: false,
        delete_on_termination: false,
        description: "Primary network interface",
        private_ip_address: "10.0.1.100"
      })
      
      expect(ni.device_index).to eq(1)
      expect(ni.subnet_id).to eq(subnet_id)
      expect(ni.groups).to eq([sg_id])
      expect(ni.associate_public_ip_address).to eq(false)
      expect(ni.delete_on_termination).to eq(false)
      expect(ni.description).to eq("Primary network interface")
      expect(ni.private_ip_address).to eq("10.0.1.100")
    end
    
    it "compacts hash output correctly" do
      ni = Pangea::Resources::AWS::Types::NetworkInterface.new({
        device_index: 0,
        groups: [sg_id]
      })
      
      hash = ni.to_h
      expect(hash).to include(device_index: 0, groups: [sg_id], delete_on_termination: true)
      expect(hash).not_to have_key(:associate_public_ip_address)
      expect(hash).not_to have_key(:description)
    end
  end
  
  describe "TagSpecification validation" do
    it "accepts valid tag specification" do
      ts = Pangea::Resources::AWS::Types::TagSpecification.new({
        resource_type: "instance",
        tags: { Name: "web-server", Environment: "production" }
      })
      
      expect(ts.resource_type).to eq("instance")
      expect(ts.tags).to eq({ Name: "web-server", Environment: "production" })
    end
    
    it "validates resource_type enum" do
      expect {
        Pangea::Resources::AWS::Types::TagSpecification.new({
          resource_type: "invalid",
          tags: {}
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "accepts all valid resource types" do
      valid_types = ['instance', 'volume', 'elastic-gpu', 'spot-instances-request', 'network-interface']
      
      valid_types.each do |type|
        ts = Pangea::Resources::AWS::Types::TagSpecification.new({
          resource_type: type,
          tags: { Name: "test" }
        })
        expect(ts.resource_type).to eq(type)
      end
    end
  end
  
  describe "LaunchTemplateData validation" do
    it "accepts empty launch template data" do
      data = Pangea::Resources::AWS::Types::LaunchTemplateData.new({})
      
      expect(data.image_id).to be_nil
      expect(data.instance_type).to be_nil
      expect(data.security_group_ids).to eq([])
      expect(data.block_device_mappings).to eq([])
      expect(data.network_interfaces).to eq([])
      expect(data.tag_specifications).to eq([])
    end
    
    it "accepts launch template data with basic configuration" do
      data = Pangea::Resources::AWS::Types::LaunchTemplateData.new({
        image_id: "ami-12345678",
        instance_type: "t3.micro",
        key_name: "my-key",
        vpc_security_group_ids: [sg_id]
      })
      
      expect(data.image_id).to eq("ami-12345678")
      expect(data.instance_type).to eq("t3.micro")
      expect(data.key_name).to eq("my-key")
      expect(data.vpc_security_group_ids).to eq([sg_id])
    end
    
    it "accepts launch template data with complex nested structures" do
      data = Pangea::Resources::AWS::Types::LaunchTemplateData.new({
        image_id: "ami-12345678",
        instance_type: "m5.large",
        iam_instance_profile: { name: role_name },
        monitoring: { enabled: true },
        instance_initiated_shutdown_behavior: "terminate",
        disable_api_termination: true,
        block_device_mappings: [{
          device_name: "/dev/sda1",
          ebs: {
            volume_size: 100,
            volume_type: "gp3",
            encrypted: true
          }
        }],
        network_interfaces: [{
          device_index: 0,
          subnet_id: subnet_id,
          groups: [sg_id]
        }],
        tag_specifications: [{
          resource_type: "instance",
          tags: { Name: "test-instance" }
        }]
      })
      
      expect(data.image_id).to eq("ami-12345678")
      expect(data.instance_type).to eq("m5.large")
      expect(data.iam_instance_profile.name).to eq(role_name)
      expect(data.monitoring[:enabled]).to eq(true)
      expect(data.instance_initiated_shutdown_behavior).to eq("terminate")
      expect(data.disable_api_termination).to eq(true)
      expect(data.block_device_mappings.length).to eq(1)
      expect(data.network_interfaces.length).to eq(1)
      expect(data.tag_specifications.length).to eq(1)
    end
    
    it "validates instance type enum" do
      expect {
        Pangea::Resources::AWS::Types::LaunchTemplateData.new({
          instance_type: "invalid.type"
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates shutdown behavior enum" do
      expect {
        Pangea::Resources::AWS::Types::LaunchTemplateData.new({
          instance_initiated_shutdown_behavior: "invalid"
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "compacts to_h output correctly" do
      data = Pangea::Resources::AWS::Types::LaunchTemplateData.new({
        image_id: "ami-12345678",
        instance_type: "t3.micro",
        vpc_security_group_ids: [sg_id]
      })
      
      hash = data.to_h
      expect(hash).to eq({
        image_id: "ami-12345678",
        instance_type: "t3.micro",
        vpc_security_group_ids: [sg_id]
      })
      expect(hash).not_to have_key(:key_name)
      expect(hash).not_to have_key(:user_data)
    end
  end
  
  describe "LaunchTemplateAttributes validation" do
    it "validates mutual exclusivity of name and name_prefix" do
      expect {
        Pangea::Resources::AWS::Types::LaunchTemplateAttributes.new({
          name: "my-template",
          name_prefix: "my-prefix-",
          launch_template_data: {}
        })
      }.to raise_error(Dry::Struct::Error, /Cannot specify both 'name' and 'name_prefix'/)
    end
    
    it "accepts launch template with name" do
      attrs = Pangea::Resources::AWS::Types::LaunchTemplateAttributes.new({
        name: "my-template",
        description: "Test template",
        launch_template_data: {
          image_id: "ami-12345678"
        }
      })
      
      expect(attrs.name).to eq("my-template")
      expect(attrs.name_prefix).to be_nil
      expect(attrs.description).to eq("Test template")
    end
    
    it "accepts launch template with name_prefix" do
      attrs = Pangea::Resources::AWS::Types::LaunchTemplateAttributes.new({
        name_prefix: "my-prefix-",
        launch_template_data: {
          instance_type: "t3.micro"
        }
      })
      
      expect(attrs.name_prefix).to eq("my-prefix-")
      expect(attrs.name).to be_nil
    end
    
    it "provides empty launch_template_data when not specified" do
      attrs = Pangea::Resources::AWS::Types::LaunchTemplateAttributes.new({
        name: "empty-template"
      })
      
      expect(attrs.launch_template_data).to be_a(Pangea::Resources::AWS::Types::LaunchTemplateData)
      expect(attrs.launch_template_data.image_id).to be_nil
    end
    
    it "compacts hash output correctly" do
      attrs = Pangea::Resources::AWS::Types::LaunchTemplateAttributes.new({
        name: "my-template",
        launch_template_data: {
          image_id: "ami-12345678"
        },
        tags: { Name: "my-template" }
      })
      
      hash = attrs.to_h
      expect(hash).to include(:name, :launch_template_data, :tags)
      expect(hash).not_to have_key(:name_prefix)
      expect(hash).not_to have_key(:description)
    end
  end
  
  describe "aws_launch_template function behavior" do
    it "creates a resource reference with minimal attributes" do
      ref = test_instance.aws_launch_template(:test, {
        name: "test-template",
        launch_template_data: {
          image_id: "ami-12345678"
        }
      })
      
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_launch_template')
      expect(ref.name).to eq(:test)
    end
    
    it "creates a resource reference with name_prefix" do
      ref = test_instance.aws_launch_template(:prefix_template, {
        name_prefix: "web-",
        launch_template_data: {
          instance_type: "t3.micro"
        }
      })
      
      expect(ref.resource_attributes[:name_prefix]).to eq("web-")
      expect(ref.resource_attributes[:name]).to be_nil
    end
    
    it "creates a resource reference with complex launch data" do
      ref = test_instance.aws_launch_template(:complex, {
        name: "complex-template",
        description: "Complex launch template with all features",
        launch_template_data: {
          image_id: "ami-12345678",
          instance_type: "m5.large",
          key_name: "my-key",
          vpc_security_group_ids: [sg_id],
          user_data: "IyEvYmluL2Jhc2gKZWNobyAiSGVsbG8gV29ybGQi", # Base64 encoded
          iam_instance_profile: { name: role_name },
          monitoring: { enabled: true },
          block_device_mappings: [{
            device_name: "/dev/sda1",
            ebs: {
              volume_size: 100,
              volume_type: "gp3",
              encrypted: true
            }
          }]
        }
      })
      
      launch_data = ref.resource_attributes[:launch_template_data]
      expect(launch_data[:image_id]).to eq("ami-12345678")
      expect(launch_data[:instance_type]).to eq("m5.large")
      expect(launch_data[:iam_instance_profile][:name]).to eq(role_name)
      expect(launch_data[:monitoring][:enabled]).to eq(true)
      expect(launch_data[:block_device_mappings].length).to eq(1)
    end
    
    it "handles tags correctly" do
      ref = test_instance.aws_launch_template(:tagged, {
        name: "tagged-template",
        launch_template_data: {},
        tags: {
          Name: "tagged-template",
          Environment: "test",
          ManagedBy: "pangea"
        }
      })
      
      expect(ref.resource_attributes[:tags]).to eq({
        Name: "tagged-template",
        Environment: "test",
        ManagedBy: "pangea"
      })
    end
    
    it "validates attributes in function call" do
      expect {
        test_instance.aws_launch_template(:invalid, {
          name: "invalid-template",
          name_prefix: "invalid-",
          launch_template_data: {}
        })
      }.to raise_error(Dry::Struct::Error, /Cannot specify both 'name' and 'name_prefix'/)
    end
    
    it "provides all expected outputs" do
      ref = test_instance.aws_launch_template(:test, {
        name: "test-template",
        launch_template_data: {}
      })
      
      expected_outputs = [:id, :arn, :latest_version, :default_version, :name]
      expected_outputs.each do |output|
        expect(ref.outputs).to have_key(output)
        expect(ref.outputs[output]).to include("${aws_launch_template.test.")
      end
    end
  end
  
  describe "common launch template patterns" do
    it "creates a basic web server template" do
      ref = test_instance.aws_launch_template(:web_server, {
        name: "web-server-template",
        description: "Launch template for web servers",
        launch_template_data: {
          image_id: "ami-12345678",
          instance_type: "t3.micro",
          key_name: "web-server-key",
          vpc_security_group_ids: [sg_id],
          user_data: "IyEvYmluL2Jhc2gKYXB0IHVwZGF0ZSAmJiBhcHQgaW5zdGFsbCAteSBuZ2lueA=="
        },
        tags: {
          Name: "web-server-template",
          Type: "web-server",
          Environment: "production"
        }
      })
      
      launch_data = ref.resource_attributes[:launch_template_data]
      expect(launch_data[:image_id]).to eq("ami-12345678")
      expect(launch_data[:instance_type]).to eq("t3.micro")
      expect(launch_data[:vpc_security_group_ids]).to eq([sg_id])
      expect(ref.resource_attributes[:tags][:Type]).to eq("web-server")
    end
    
    it "creates a template with custom block devices" do
      ref = test_instance.aws_launch_template(:database, {
        name: "database-template",
        launch_template_data: {
          image_id: "ami-12345678",
          instance_type: "r5.large",
          block_device_mappings: [
            {
              device_name: "/dev/sda1",
              ebs: {
                volume_size: 50,
                volume_type: "gp3",
                encrypted: true,
                delete_on_termination: true
              }
            },
            {
              device_name: "/dev/sdf",
              ebs: {
                volume_size: 1000,
                volume_type: "io2",
                iops: 10000,
                encrypted: true,
                delete_on_termination: false
              }
            }
          ]
        }
      })
      
      bdms = ref.resource_attributes[:launch_template_data][:block_device_mappings]
      expect(bdms.length).to eq(2)
      expect(bdms[0][:device_name]).to eq("/dev/sda1")
      expect(bdms[0][:ebs][:volume_size]).to eq(50)
      expect(bdms[1][:device_name]).to eq("/dev/sdf")
      expect(bdms[1][:ebs][:volume_type]).to eq("io2")
      expect(bdms[1][:ebs][:iops]).to eq(10000)
    end
    
    it "creates a template with network interface configuration" do
      ref = test_instance.aws_launch_template(:custom_network, {
        name: "custom-network-template",
        launch_template_data: {
          image_id: "ami-12345678",
          instance_type: "t3.micro",
          network_interfaces: [{
            device_index: 0,
            subnet_id: subnet_id,
            groups: [sg_id],
            associate_public_ip_address: false,
            delete_on_termination: true
          }]
        }
      })
      
      nis = ref.resource_attributes[:launch_template_data][:network_interfaces]
      expect(nis.length).to eq(1)
      expect(nis[0][:device_index]).to eq(0)
      expect(nis[0][:subnet_id]).to eq(subnet_id)
      expect(nis[0][:associate_public_ip_address]).to eq(false)
    end
    
    it "creates a template with tag specifications" do
      ref = test_instance.aws_launch_template(:tagged_instances, {
        name_prefix: "tagged-",
        launch_template_data: {
          image_id: "ami-12345678",
          instance_type: "t3.small",
          tag_specifications: [
            {
              resource_type: "instance",
              tags: {
                Name: "auto-tagged-instance",
                Environment: "production",
                Team: "platform"
              }
            },
            {
              resource_type: "volume",
              tags: {
                Name: "auto-tagged-volume",
                Encrypted: "true"
              }
            }
          ]
        }
      })
      
      tag_specs = ref.resource_attributes[:launch_template_data][:tag_specifications]
      expect(tag_specs.length).to eq(2)
      expect(tag_specs[0][:resource_type]).to eq("instance")
      expect(tag_specs[0][:tags][:Team]).to eq("platform")
      expect(tag_specs[1][:resource_type]).to eq("volume")
      expect(tag_specs[1][:tags][:Encrypted]).to eq("true")
    end
    
    it "creates a template for Auto Scaling Group" do
      ref = test_instance.aws_launch_template(:asg_template, {
        name_prefix: "asg-",
        description: "Template for Auto Scaling Group instances",
        launch_template_data: {
          image_id: "ami-12345678",
          instance_type: "t3.small",
          iam_instance_profile: { name: "ec2-auto-scaling-role" },
          vpc_security_group_ids: [sg_id],
          monitoring: { enabled: true },
          instance_initiated_shutdown_behavior: "terminate",
          tag_specifications: [{
            resource_type: "instance",
            tags: {
              Name: "asg-instance",
              ManagedBy: "auto-scaling-group"
            }
          }]
        }
      })
      
      launch_data = ref.resource_attributes[:launch_template_data]
      expect(launch_data[:iam_instance_profile][:name]).to eq("ec2-auto-scaling-role")
      expect(launch_data[:monitoring][:enabled]).to eq(true)
      expect(launch_data[:instance_initiated_shutdown_behavior]).to eq("terminate")
    end
  end
  
  describe "resource reference integration" do
    it "provides terraform interpolation syntax for outputs" do
      ref = test_instance.aws_launch_template(:test_lt, {
        name: "test-template",
        launch_template_data: {
          image_id: "ami-12345678"
        }
      })
      
      expect(ref.outputs[:id]).to eq("${aws_launch_template.test_lt.id}")
      expect(ref.outputs[:arn]).to eq("${aws_launch_template.test_lt.arn}")
      expect(ref.outputs[:latest_version]).to eq("${aws_launch_template.test_lt.latest_version}")
      expect(ref.outputs[:default_version]).to eq("${aws_launch_template.test_lt.default_version}")
      expect(ref.outputs[:name]).to eq("${aws_launch_template.test_lt.name}")
    end
    
    it "can be used with Auto Scaling Group" do
      template_ref = test_instance.aws_launch_template(:for_asg, {
        name: "asg-template",
        launch_template_data: {
          image_id: "ami-12345678",
          instance_type: "t3.micro"
        }
      })
      
      # Simulate using launch template reference in ASG
      template_id = template_ref.outputs[:id]
      template_version = template_ref.outputs[:latest_version]
      
      expect(template_id).to eq("${aws_launch_template.for_asg.id}")
      expect(template_version).to eq("${aws_launch_template.for_asg.latest_version}")
    end
    
    it "supports complex cross-resource references" do
      ref = test_instance.aws_launch_template(:cross_ref, {
        name: "cross-reference-template",
        launch_template_data: {
          image_id: "${data.aws_ami.latest.id}",
          instance_type: "t3.micro",
          vpc_security_group_ids: ["${aws_security_group.web.id}"],
          subnet_id: "${aws_subnet.private.id}",
          iam_instance_profile: { arn: "${aws_iam_instance_profile.ec2.arn}" },
          user_data: "${base64encode(templatefile(\"user_data.sh\", { env = var.environment }))}"
        }
      })
      
      launch_data = ref.resource_attributes[:launch_template_data]
      expect(launch_data[:image_id]).to include("data.aws_ami.latest.id")
      expect(launch_data[:vpc_security_group_ids][0]).to include("aws_security_group.web.id")
      expect(launch_data[:iam_instance_profile][:arn]).to include("aws_iam_instance_profile.ec2.arn")
      expect(launch_data[:user_data]).to include("base64encode")
    end
  end
  
  describe "error conditions and edge cases" do
    it "handles empty launch template data gracefully" do
      ref = test_instance.aws_launch_template(:empty_data, {
        name: "empty-template",
        launch_template_data: {}
      })
      
      expect(ref.resource_attributes[:launch_template_data]).to eq({})
    end
    
    it "handles empty arrays gracefully" do
      ref = test_instance.aws_launch_template(:empty_arrays, {
        name: "empty-arrays-template",
        launch_template_data: {
          security_group_ids: [],
          block_device_mappings: [],
          network_interfaces: [],
          tag_specifications: []
        }
      })
      
      launch_data = ref.resource_attributes[:launch_template_data]
      expect(launch_data).not_to have_key(:security_group_ids)
      expect(launch_data).not_to have_key(:block_device_mappings)
      expect(launch_data).not_to have_key(:network_interfaces)
      expect(launch_data).not_to have_key(:tag_specifications)
    end
    
    it "handles string keys in attributes" do
      ref = test_instance.aws_launch_template(:string_keys, {
        "name" => "string-key-template",
        "description" => "Template with string keys",
        "launch_template_data" => {
          "image_id" => "ami-12345678",
          "instance_type" => "t3.micro"
        }
      })
      
      expect(ref.resource_attributes[:name]).to eq("string-key-template")
      expect(ref.resource_attributes[:description]).to eq("Template with string keys")
      expect(ref.resource_attributes[:launch_template_data][:image_id]).to eq("ami-12345678")
    end
  end
end