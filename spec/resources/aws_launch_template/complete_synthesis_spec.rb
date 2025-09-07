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

# Load aws_launch_template resource for terraform synthesis testing
require 'pangea/resources/aws_launch_template/resource'

RSpec.describe "aws_launch_template terraform synthesis" do
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
            # For nested blocks like launch_template_data, tags, etc.
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
              # For nested blocks
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
            
            if block_given?
              # For deeply nested blocks
              nested_context = NestedContext.new(@synthesizer, method_name)
              yield
            end
            
            args.first if args.any?
          end
          
          def respond_to_missing?(method_name, include_private = false)
            true
          end
        end
      end
    end
    
    let(:test_synthesizer) { mock_synthesizer.new }
    let(:sg_id) { "${aws_security_group.web.id}" }
    let(:subnet_id) { "${aws_subnet.private.id}" }
    
    it "synthesizes basic launch template terraform correctly" do
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
      
      # Call aws_launch_template function with minimal configuration
      ref = test_instance.aws_launch_template(:basic_lt, {
        name: "basic-template",
        launch_template_data: {
          image_id: "ami-12345678",
          instance_type: "t3.micro"
        }
      })
      
      # Verify the function returned correct ResourceReference
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_launch_template')
      expect(ref.name).to eq(:basic_lt)
      
      # Verify terraform synthesis calls were made correctly
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_launch_template, :basic_lt],
        [:name, "basic-template"],
        [:launch_template_data],
        [:image_id, "ami-12345678"],
        [:instance_type, "t3.micro"]
      )
      
      # Verify resource was created in synthesizer
      expect(test_synthesizer.resources).to have_key("aws_launch_template.basic_lt")
    end
    
    it "synthesizes launch template with name_prefix correctly" do
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
      
      # Call aws_launch_template function with name_prefix
      ref = test_instance.aws_launch_template(:prefix_lt, {
        name_prefix: "web-server-",
        description: "Web server launch template",
        launch_template_data: {
          image_id: "ami-12345678",
          instance_type: "t3.small"
        }
      })
      
      # Verify name_prefix synthesis
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_launch_template, :prefix_lt],
        [:name_prefix, "web-server-"],
        [:description, "Web server launch template"]
      )
      
      # Verify name was NOT called
      name_calls = test_synthesizer.method_calls.select { |call| call[0] == :name && call[1] != "Web server launch template" }
      expect(name_calls).to be_empty
    end
    
    it "synthesizes launch template with IAM instance profile correctly" do
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
      
      # Call aws_launch_template function with IAM instance profile
      ref = test_instance.aws_launch_template(:iam_lt, {
        name: "iam-template",
        launch_template_data: {
          image_id: "ami-12345678",
          instance_type: "t3.micro",
          iam_instance_profile: { name: "ec2-role" }
        }
      })
      
      # Verify IAM instance profile synthesis
      expect(test_synthesizer.method_calls).to include(
        [:launch_template_data],
        [:iam_instance_profile],
        [:name, "ec2-role"]
      )
      
      # Verify arn was NOT called for name-based profile
      arn_calls = test_synthesizer.method_calls.select { |call| call[0] == :arn }
      expect(arn_calls).to be_empty
    end
    
    it "synthesizes launch template with block device mappings correctly" do
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
      
      # Call aws_launch_template function with block devices
      ref = test_instance.aws_launch_template(:storage_lt, {
        name: "storage-template",
        launch_template_data: {
          image_id: "ami-12345678",
          instance_type: "r5.large",
          block_device_mappings: [
            {
              device_name: "/dev/sda1",
              ebs: {
                volume_size: 100,
                volume_type: "gp3",
                encrypted: true,
                delete_on_termination: false
              }
            },
            {
              device_name: "/dev/sdf",
              ebs: {
                volume_size: 1000,
                volume_type: "io2",
                iops: 10000
              }
            }
          ]
        }
      })
      
      # Verify block device mapping synthesis
      expect(test_synthesizer.method_calls).to include(
        [:block_device_mappings],
        [:device_name, "/dev/sda1"],
        [:ebs],
        [:volume_size, 100],
        [:volume_type, "gp3"],
        [:encrypted, true],
        [:delete_on_termination, false]
      )
      
      expect(test_synthesizer.method_calls).to include(
        [:device_name, "/dev/sdf"],
        [:volume_size, 1000],
        [:volume_type, "io2"],
        [:iops, 10000]
      )
      
      # Verify two block_device_mappings blocks were called
      bdm_calls = test_synthesizer.method_calls.select { |call| call[0] == :block_device_mappings }
      expect(bdm_calls.length).to eq(2)
    end
    
    it "synthesizes launch template with network interfaces correctly" do
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
      
      # Call aws_launch_template function with network interfaces
      ref = test_instance.aws_launch_template(:network_lt, {
        name: "network-template",
        launch_template_data: {
          image_id: "ami-12345678",
          instance_type: "t3.micro",
          network_interfaces: [
            {
              device_index: 0,
              subnet_id: subnet_id,
              groups: [sg_id],
              associate_public_ip_address: false,
              delete_on_termination: true
            },
            {
              device_index: 1,
              network_interface_id: "${aws_network_interface.secondary.id}"
            }
          ]
        }
      })
      
      # Verify network interface synthesis
      expect(test_synthesizer.method_calls).to include(
        [:network_interfaces],
        [:device_index, 0],
        [:subnet_id, subnet_id],
        [:groups, [sg_id]],
        [:associate_public_ip_address, false]
      )
      
      expect(test_synthesizer.method_calls).to include(
        [:device_index, 1],
        [:network_interface_id, "${aws_network_interface.secondary.id}"]
      )
      
      # Verify two network_interfaces blocks were called
      ni_calls = test_synthesizer.method_calls.select { |call| call[0] == :network_interfaces }
      expect(ni_calls.length).to eq(2)
    end
    
    it "synthesizes launch template with tag specifications correctly" do
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
      
      # Call aws_launch_template function with tag specifications
      ref = test_instance.aws_launch_template(:tagged_lt, {
        name: "tagged-template",
        launch_template_data: {
          image_id: "ami-12345678",
          instance_type: "t3.micro",
          tag_specifications: [
            {
              resource_type: "instance",
              tags: {
                Name: "auto-tagged-instance",
                Environment: "production"
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
      
      # Verify tag specifications synthesis
      expect(test_synthesizer.method_calls).to include(
        [:tag_specifications],
        [:resource_type, "instance"],
        [:tags],
        [:Name, "auto-tagged-instance"],
        [:Environment, "production"]
      )
      
      expect(test_synthesizer.method_calls).to include(
        [:resource_type, "volume"],
        [:Name, "auto-tagged-volume"],
        [:Encrypted, "true"]
      )
      
      # Verify two tag_specifications blocks were called
      ts_calls = test_synthesizer.method_calls.select { |call| call[0] == :tag_specifications }
      expect(ts_calls.length).to eq(2)
    end
    
    it "synthesizes launch template with monitoring enabled correctly" do
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
      
      # Call aws_launch_template function with monitoring
      ref = test_instance.aws_launch_template(:monitoring_lt, {
        name: "monitoring-template",
        launch_template_data: {
          image_id: "ami-12345678",
          instance_type: "m5.large",
          monitoring: { enabled: true },
          instance_initiated_shutdown_behavior: "terminate",
          disable_api_termination: true
        }
      })
      
      # Verify monitoring and behavior synthesis
      expect(test_synthesizer.method_calls).to include(
        [:monitoring],
        [:enabled, true],
        [:instance_initiated_shutdown_behavior, "terminate"],
        [:disable_api_termination, true]
      )
    end
    
    it "synthesizes launch template with security groups correctly" do
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
      
      sg1 = "${aws_security_group.web.id}"
      sg2 = "${aws_security_group.app.id}"
      
      # Call aws_launch_template function with security groups
      ref = test_instance.aws_launch_template(:sg_lt, {
        name: "security-group-template",
        launch_template_data: {
          image_id: "ami-12345678",
          instance_type: "t3.micro",
          vpc_security_group_ids: [sg1, sg2],
          key_name: "my-key",
          user_data: "IyEvYmluL2Jhc2gKZWNobyAiSGVsbG8gV29ybGQi"
        }
      })
      
      # Verify security groups and other settings synthesis
      expect(test_synthesizer.method_calls).to include(
        [:vpc_security_group_ids, [sg1, sg2]],
        [:key_name, "my-key"],
        [:user_data, "IyEvYmluL2Jhc2gKZWNobyAiSGVsbG8gV29ybGQi"]
      )
    end
    
    it "synthesizes launch template with comprehensive configuration" do
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
      
      # Call aws_launch_template function with comprehensive config
      ref = test_instance.aws_launch_template(:comprehensive_lt, {
        name: "comprehensive-template",
        description: "Comprehensive launch template with all features",
        launch_template_data: {
          image_id: "ami-12345678",
          instance_type: "m5.large",
          key_name: "comprehensive-key",
          iam_instance_profile: { arn: "arn:aws:iam::123456789012:instance-profile/ec2-role" },
          vpc_security_group_ids: [sg_id],
          user_data: "IyEvYmluL2Jhc2gKZWNobyAiQ29tcHJlaGVuc2l2ZSBzZXR1cCI=",
          monitoring: { enabled: true },
          instance_initiated_shutdown_behavior: "terminate",
          block_device_mappings: [{
            device_name: "/dev/sda1",
            ebs: {
              volume_size: 100,
              volume_type: "gp3",
              encrypted: true
            }
          }],
          tag_specifications: [{
            resource_type: "instance",
            tags: { Name: "comprehensive-instance", Type: "web-server" }
          }]
        },
        tags: {
          Name: "comprehensive-template",
          Environment: "production",
          ManagedBy: "pangea"
        }
      })
      
      # Verify comprehensive synthesis includes all major components
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_launch_template, :comprehensive_lt],
        [:name, "comprehensive-template"],
        [:description, "Comprehensive launch template with all features"],
        [:launch_template_data],
        [:image_id, "ami-12345678"],
        [:instance_type, "m5.large"],
        [:key_name, "comprehensive-key"],
        [:iam_instance_profile],
        [:arn, "arn:aws:iam::123456789012:instance-profile/ec2-role"],
        [:vpc_security_group_ids, [sg_id]],
        [:monitoring],
        [:enabled, true],
        [:block_device_mappings],
        [:tag_specifications],
        [:tags] # Both template-level and tag specification tags
      )
      
      # Verify template-level tags were processed
      expect(test_synthesizer.method_calls).to include(
        [:Name, "comprehensive-template"],
        [:Environment, "production"],
        [:ManagedBy, "pangea"]
      )
    end
    
    it "synthesizes launch template for Auto Scaling Group usage" do
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
      
      # Call aws_launch_template function for ASG usage
      ref = test_instance.aws_launch_template(:asg_lt, {
        name_prefix: "asg-",
        description: "Template for Auto Scaling Group",
        launch_template_data: {
          image_id: "${data.aws_ami.latest.id}",
          instance_type: "t3.small",
          iam_instance_profile: { name: "asg-instance-role" },
          vpc_security_group_ids: ["${aws_security_group.asg.id}"],
          user_data: "${base64encode(data.template_file.user_data.rendered)}",
          monitoring: { enabled: true },
          instance_initiated_shutdown_behavior: "terminate",
          tag_specifications: [{
            resource_type: "instance",
            tags: {
              Name: "${var.environment}-asg-instance",
              Environment: "${var.environment}",
              ManagedBy: "auto-scaling-group"
            }
          }]
        }
      })
      
      # Verify ASG-specific synthesis patterns
      expect(test_synthesizer.method_calls).to include(
        [:name_prefix, "asg-"],
        [:image_id, "${data.aws_ami.latest.id}"],
        [:user_data, "${base64encode(data.template_file.user_data.rendered)}"],
        [:instance_initiated_shutdown_behavior, "terminate"],
        [:Name, "${var.environment}-asg-instance"],
        [:ManagedBy, "auto-scaling-group"]
      )
    end
    
    it "handles conditional attributes correctly" do
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
      
      # Call with minimal config to test conditionals
      ref = test_instance.aws_launch_template(:conditional_lt, {
        name: "conditional-template",
        launch_template_data: {
          image_id: "ami-12345678",
          instance_type: "t3.micro",
          instance_initiated_shutdown_behavior: "stop", # Default value
          disable_api_termination: false # Default value
        }
      })
      
      # Verify default values are NOT synthesized
      shutdown_calls = test_synthesizer.method_calls.select { |call| call[0] == :instance_initiated_shutdown_behavior }
      expect(shutdown_calls).to be_empty
      
      termination_calls = test_synthesizer.method_calls.select { |call| call[0] == :disable_api_termination }
      expect(termination_calls).to be_empty
    end
    
    it "handles empty nested arrays correctly" do
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
      
      # Call with empty arrays
      ref = test_instance.aws_launch_template(:empty_arrays_lt, {
        name: "empty-arrays-template",
        launch_template_data: {
          image_id: "ami-12345678",
          security_group_ids: [],
          vpc_security_group_ids: [],
          block_device_mappings: [],
          network_interfaces: [],
          tag_specifications: []
        }
      })
      
      # Verify empty arrays are NOT synthesized
      sg_calls = test_synthesizer.method_calls.select { |call| call[0] == :security_group_ids }
      expect(sg_calls).to be_empty
      
      vpc_sg_calls = test_synthesizer.method_calls.select { |call| call[0] == :vpc_security_group_ids }
      expect(vpc_sg_calls).to be_empty
      
      bdm_calls = test_synthesizer.method_calls.select { |call| call[0] == :block_device_mappings }
      expect(bdm_calls).to be_empty
      
      ni_calls = test_synthesizer.method_calls.select { |call| call[0] == :network_interfaces }
      expect(ni_calls).to be_empty
      
      ts_calls = test_synthesizer.method_calls.select { |call| call[0] == :tag_specifications }
      expect(ts_calls).to be_empty
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
      
      ref = test_instance.aws_launch_template(:output_test, {
        name: "output-test-template",
        launch_template_data: {
          image_id: "ami-12345678",
          instance_type: "t3.micro"
        }
      })
      
      # Verify all outputs have correct terraform reference format
      expected_outputs = [:id, :arn, :latest_version, :default_version, :name]
      
      expected_outputs.each do |output|
        expect(ref.outputs[output]).to match(/\A\$\{aws_launch_template\.output_test\./)
      end
      
      # Verify specific output formats
      expect(ref.outputs[:id]).to eq("${aws_launch_template.output_test.id}")
      expect(ref.outputs[:arn]).to eq("${aws_launch_template.output_test.arn}")
      expect(ref.outputs[:latest_version]).to eq("${aws_launch_template.output_test.latest_version}")
      expect(ref.outputs[:default_version]).to eq("${aws_launch_template.output_test.default_version}")
      expect(ref.outputs[:name]).to eq("${aws_launch_template.output_test.name}")
    end
  end
end