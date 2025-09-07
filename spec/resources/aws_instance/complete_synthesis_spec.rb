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

# Load aws_instance resource for terraform synthesis testing
require 'pangea/resources/aws_instance/resource'

RSpec.describe "aws_instance terraform synthesis" do
  describe "real terraform synthesis" do
    # Note: These tests require terraform_synthesizer gem to be available
    # They test actual terraform JSON generation
    
    let(:mock_synthesizer) do
      # Mock synthesizer that captures method calls to verify terraform structure
      Class.new do
        attr_reader :resources, :method_calls
        
        def initialize
          @resources = {}
          @method_calls = []
        end
        
        def resource(type, name)
          @method_calls << [:resource, type, name]
          resource_context = ResourceContext.new(self, type, name)
          @resources["#{type}.#{name}"] = resource_context
          yield if block_given?
          resource_context
        end
        
        def method_missing(method_name, *args, &block)
          @method_calls << [method_name, *args]
          if block_given?
            # For nested blocks like tags, root_block_device, ebs_block_device
            nested_context = NestedContext.new(self, method_name)
            yield
          end
          args.first if args.any?
        end
        
        def respond_to_missing?(method_name, include_private = false)
          true
        end
        
        class ResourceContext
          attr_reader :synthesizer, :type, :name, :attributes
          
          def initialize(synthesizer, type, name)
            @synthesizer = synthesizer
            @type = type
            @name = name
            @attributes = {}
          end
          
          def method_missing(method_name, *args, &block)
            @synthesizer.method_calls << [method_name, *args]
            @attributes[method_name] = args.first if args.any?
            
            if block_given?
              # For nested blocks like tags, root_block_device, ebs_block_device
              nested_context = NestedContext.new(@synthesizer, method_name)
              @attributes[method_name] = nested_context
              yield
            end
            
            args.first if args.any?
          end
          
          def respond_to_missing?(method_name, include_private = false)
            true
          end
        end
        
        class NestedContext
          attr_reader :synthesizer, :context_name, :attributes
          
          def initialize(synthesizer, context_name)
            @synthesizer = synthesizer
            @context_name = context_name
            @attributes = {}
          end
          
          def method_missing(method_name, *args, &block)
            @synthesizer.method_calls << [method_name, *args]
            @attributes[method_name] = args.first if args.any?
            args.first if args.any?
          end
          
          def respond_to_missing?(method_name, include_private = false)
            true
          end
        end
      end
    end
    
    let(:test_synthesizer) { mock_synthesizer.new }
    let(:ami_id) { "ami-0c02fb55956c7d316" }
    let(:subnet_id) { "${aws_subnet.test.id}" }
    
    it "synthesizes basic EC2 instance terraform correctly" do
      # Create a test class that uses our mock synthesizer
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Call aws_instance function
      ref = test_instance.aws_instance(:test_instance, {
        ami: ami_id,
        instance_type: "t3.micro"
      })
      
      # Verify the function returned correct ResourceReference
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_instance')
      expect(ref.name).to eq(:test_instance)
      
      # Verify terraform synthesis calls were made correctly
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_instance, :test_instance],
        [:ami, ami_id],
        [:instance_type, "t3.micro"],
        [:monitoring, false],
        [:ebs_optimized, false],
        [:disable_api_termination, false]
      )
      
      # Verify resource was created in synthesizer
      expect(test_synthesizer.resources).to have_key("aws_instance.test_instance")
    end
    
    it "synthesizes instance with network configuration correctly" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Call aws_instance function with network configuration
      ref = test_instance.aws_instance(:web_instance, {
        ami: ami_id,
        instance_type: "t3.small",
        subnet_id: subnet_id,
        vpc_security_group_ids: ["sg-12345"],
        availability_zone: "us-east-1a",
        associate_public_ip_address: true
      })
      
      # Verify network configuration synthesis
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_instance, :web_instance],
        [:ami, ami_id],
        [:instance_type, "t3.small"],
        [:subnet_id, subnet_id],
        [:vpc_security_group_ids, ["sg-12345"]],
        [:availability_zone, "us-east-1a"],
        [:associate_public_ip_address, true]
      )
    end
    
    it "synthesizes instance with root block device correctly" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Call aws_instance function with root block device
      ref = test_instance.aws_instance(:storage_instance, {
        ami: ami_id,
        instance_type: "m5.large",
        root_block_device: {
          volume_type: "gp3",
          volume_size: 100,
          throughput: 250,
          encrypted: true,
          delete_on_termination: true
        }
      })
      
      # Verify root block device synthesis
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_instance, :storage_instance],
        [:ami, ami_id],
        [:instance_type, "m5.large"],
        [:root_block_device]
      )
      
      # Verify root block device nested attributes
      expect(test_synthesizer.method_calls).to include(
        [:volume_type, "gp3"],
        [:volume_size, 100],
        [:throughput, 250],
        [:encrypted, true],
        [:delete_on_termination, true]
      )
    end
    
    it "synthesizes instance with EBS block devices correctly" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Call aws_instance function with EBS block devices
      ref = test_instance.aws_instance(:database_instance, {
        ami: ami_id,
        instance_type: "r5.xlarge",
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
      
      # Verify EBS block device synthesis
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_instance, :database_instance],
        [:ami, ami_id],
        [:instance_type, "r5.xlarge"],
        [:ebs_block_device]
      )
      
      # Verify EBS block device nested attributes
      expect(test_synthesizer.method_calls).to include(
        [:device_name, "/dev/sdf"],
        [:volume_type, "io2"],
        [:volume_size, 1000],
        [:iops, 10000],
        [:encrypted, true],
        [:delete_on_termination, false]
      )
    end
    
    it "synthesizes instance with user data correctly" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      user_data = <<~USERDATA
        #!/bin/bash
        yum update -y
        yum install -y httpd
        systemctl start httpd
      USERDATA
      
      # Call aws_instance function with user data
      ref = test_instance.aws_instance(:app_instance, {
        ami: ami_id,
        instance_type: "c5.large",
        key_name: "app-key",
        user_data: user_data,
        iam_instance_profile: "app-profile"
      })
      
      # Verify instance configuration synthesis
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_instance, :app_instance],
        [:ami, ami_id],
        [:instance_type, "c5.large"],
        [:key_name, "app-key"],
        [:user_data, user_data],
        [:iam_instance_profile, "app-profile"]
      )
    end
    
    it "synthesizes instance with behavior settings correctly" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Call aws_instance function with behavior settings
      ref = test_instance.aws_instance(:production_instance, {
        ami: ami_id,
        instance_type: "m5.2xlarge",
        instance_initiated_shutdown_behavior: "terminate",
        monitoring: true,
        ebs_optimized: true,
        source_dest_check: false,
        disable_api_termination: true
      })
      
      # Verify behavior settings synthesis
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_instance, :production_instance],
        [:ami, ami_id],
        [:instance_type, "m5.2xlarge"],
        [:instance_initiated_shutdown_behavior, "terminate"],
        [:monitoring, true],
        [:ebs_optimized, true],
        [:source_dest_check, false],
        [:disable_api_termination, true]
      )
    end
    
    it "synthesizes instance with tags correctly" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Call aws_instance function with tags
      ref = test_instance.aws_instance(:tagged_instance, {
        ami: ami_id,
        instance_type: "t3.medium",
        tags: { Name: "web-server", Environment: "production", Owner: "devops" }
      })
      
      # Verify basic terraform synthesis
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_instance, :tagged_instance],
        [:ami, ami_id],
        [:instance_type, "t3.medium"]
      )
      
      # Verify tags block was called
      expect(test_synthesizer.method_calls).to include([:tags])
      expect(test_synthesizer.method_calls).to include([:Name, "web-server"])
      expect(test_synthesizer.method_calls).to include([:Environment, "production"])
      expect(test_synthesizer.method_calls).to include([:Owner, "devops"])
    end
    
    it "handles instance without optional attributes correctly" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Call aws_instance function with minimal attributes
      ref = test_instance.aws_instance(:minimal_instance, {
        ami: ami_id,
        instance_type: "t3.micro"
      })
      
      # Verify basic synthesis
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_instance, :minimal_instance],
        [:ami, ami_id],
        [:instance_type, "t3.micro"],
        [:monitoring, false],
        [:ebs_optimized, false],
        [:disable_api_termination, false]
      )
      
      # Verify optional attributes were NOT called
      subnet_id_calls = test_synthesizer.method_calls.select { |call| call[0] == :subnet_id }
      expect(subnet_id_calls).to be_empty
      
      key_name_calls = test_synthesizer.method_calls.select { |call| call[0] == :key_name }
      expect(key_name_calls).to be_empty
      
      # Verify tags block was NOT called (since no tags provided)
      tags_calls = test_synthesizer.method_calls.select { |call| call[0] == :tags }
      expect(tags_calls).to be_empty
    end
    
    it "validates terraform reference outputs" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      ref = test_instance.aws_instance(:output_test, {
        ami: ami_id,
        instance_type: "m5.large",
        subnet_id: subnet_id
      })
      
      # Verify all outputs have correct terraform reference format
      expected_outputs = [:id, :arn, :public_ip, :private_ip, :public_dns, 
                         :private_dns, :instance_state, :subnet_id, 
                         :availability_zone, :key_name, :vpc_security_group_ids]
      
      expected_outputs.each do |output|
        expect(ref.outputs[output]).to match(/\A\$\{aws_instance\.output_test\.#{output}\}\z/)
      end
    end
  end
end