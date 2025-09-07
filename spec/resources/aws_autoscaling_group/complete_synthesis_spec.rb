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

# Load aws_autoscaling_group resource for terraform synthesis testing
require 'pangea/resources/aws_autoscaling_group/resource'

RSpec.describe "aws_autoscaling_group terraform synthesis" do
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
            # For nested blocks like launch_template, tags, instance_refresh
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
              # For deeply nested blocks like preferences
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
    let(:subnet_a) { "${aws_subnet.private_a.id}" }
    let(:subnet_b) { "${aws_subnet.private_b.id}" }
    let(:launch_template_id) { "${aws_launch_template.web.id}" }
    let(:target_group_arn) { "${aws_lb_target_group.web.arn}" }
    
    it "synthesizes basic auto scaling group terraform correctly" do
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
      
      # Call aws_autoscaling_group function with minimal configuration
      ref = test_instance.aws_autoscaling_group(:basic_asg, {
        min_size: 1,
        max_size: 5,
        vpc_zone_identifier: [subnet_a],
        launch_template: { id: launch_template_id }
      })
      
      # Verify the function returned correct ResourceReference
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_autoscaling_group')
      expect(ref.name).to eq(:basic_asg)
      
      # Verify terraform synthesis calls were made correctly
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_autoscaling_group, :basic_asg],
        [:min_size, 1],
        [:max_size, 5],
        [:vpc_zone_identifier, [subnet_a]],
        [:launch_template],
        [:id, launch_template_id]
      )
      
      # Verify resource was created in synthesizer
      expect(test_synthesizer.resources).to have_key("aws_autoscaling_group.basic_asg")
    end
    
    it "synthesizes ASG with launch configuration correctly" do
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
      
      # Call aws_autoscaling_group function with launch configuration
      ref = test_instance.aws_autoscaling_group(:lc_asg, {
        min_size: 2,
        max_size: 6,
        availability_zones: ["us-east-1a", "us-east-1b"],
        launch_configuration: "web-lc"
      })
      
      # Verify launch configuration synthesis
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_autoscaling_group, :lc_asg],
        [:min_size, 2],
        [:max_size, 6],
        [:availability_zones, ["us-east-1a", "us-east-1b"]],
        [:launch_configuration, "web-lc"]
      )
      
      # Verify launch_template was NOT called
      lt_calls = test_synthesizer.method_calls.select { |call| call[0] == :launch_template }
      expect(lt_calls).to be_empty
    end
    
    it "synthesizes ASG with desired capacity and health checks correctly" do
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
      
      # Call aws_autoscaling_group function with comprehensive config
      ref = test_instance.aws_autoscaling_group(:comprehensive_asg, {
        min_size: 2,
        max_size: 10,
        desired_capacity: 4,
        vpc_zone_identifier: [subnet_a, subnet_b],
        launch_template: {
          id: launch_template_id,
          version: "2"
        },
        health_check_type: "ELB",
        health_check_grace_period: 600
      })
      
      # Verify comprehensive synthesis
      expect(test_synthesizer.method_calls).to include(
        [:min_size, 2],
        [:max_size, 10],
        [:desired_capacity, 4],
        [:vpc_zone_identifier, [subnet_a, subnet_b]],
        [:launch_template],
        [:id, launch_template_id],
        [:version, "2"],
        [:health_check_type, "ELB"],
        [:health_check_grace_period, 600]
      )
    end
    
    it "synthesizes ASG with target groups correctly" do
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
      
      tg1 = "${aws_lb_target_group.web.arn}"
      tg2 = "${aws_lb_target_group.api.arn}"
      
      # Call aws_autoscaling_group function with target groups
      ref = test_instance.aws_autoscaling_group(:tg_asg, {
        min_size: 3,
        max_size: 9,
        vpc_zone_identifier: [subnet_a, subnet_b],
        launch_template: { id: launch_template_id },
        target_group_arns: [tg1, tg2]
      })
      
      # Verify target group synthesis
      expect(test_synthesizer.method_calls).to include(
        [:target_group_arns, [tg1, tg2]]
      )
    end
    
    it "synthesizes ASG with tags correctly" do
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
      
      # Call aws_autoscaling_group function with tags
      ref = test_instance.aws_autoscaling_group(:tagged_asg, {
        min_size: 1,
        max_size: 5,
        vpc_zone_identifier: [subnet_a],
        launch_template: { id: launch_template_id },
        tags: [
          { key: "Name", value: "web-asg", propagate_at_launch: true },
          { key: "Environment", value: "production", propagate_at_launch: true },
          { key: "Team", value: "platform", propagate_at_launch: false }
        ]
      })
      
      # Verify tags synthesis - should be called as array
      tag_calls = test_synthesizer.method_calls.select { |call| call[0] == :tag }
      expect(tag_calls.length).to eq(1)
      
      # The tag call should include an array of hashes
      tag_array = tag_calls.first[1]
      expect(tag_array).to be_an(Array)
      expect(tag_array.length).to eq(3)
      expect(tag_array[0]).to include(key: "Name", value: "web-asg", propagate_at_launch: true)
      expect(tag_array[1]).to include(key: "Environment", value: "production")
      expect(tag_array[2]).to include(key: "Team", value: "platform", propagate_at_launch: false)
    end
    
    it "synthesizes ASG with instance refresh correctly" do
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
      
      # Call aws_autoscaling_group function with instance refresh
      ref = test_instance.aws_autoscaling_group(:refresh_asg, {
        min_size: 3,
        max_size: 9,
        vpc_zone_identifier: [subnet_a, subnet_b],
        launch_template: { name: "app-template" },
        instance_refresh: {
          min_healthy_percentage: 90,
          instance_warmup: 120,
          checkpoint_percentages: [50],
          checkpoint_delay: 300
        }
      })
      
      # Verify instance refresh synthesis
      expect(test_synthesizer.method_calls).to include(
        [:instance_refresh],
        [:preferences],
        [:min_healthy_percentage, 90],
        [:instance_warmup, 120],
        [:checkpoint_percentages, [50]],
        [:checkpoint_delay, 300]
      )
    end
    
    it "synthesizes ASG with mixed instances policy correctly" do
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
      
      mixed_policy = {
        launch_template: {
          launch_template_specification: {
            launch_template_id: launch_template_id,
            version: "$Latest"
          }
        },
        instances_distribution: {
          on_demand_percentage: 20,
          spot_allocation_strategy: "lowest-price"
        }
      }
      
      # Call aws_autoscaling_group function with mixed instances
      ref = test_instance.aws_autoscaling_group(:mixed_asg, {
        min_size: 3,
        max_size: 20,
        vpc_zone_identifier: [subnet_a, subnet_b],
        mixed_instances_policy: mixed_policy
      })
      
      # Verify mixed instances policy synthesis
      expect(test_synthesizer.method_calls).to include(
        [:mixed_instances_policy, mixed_policy]
      )
      
      # Verify launch_template was NOT called (since using mixed_instances_policy)
      lt_calls = test_synthesizer.method_calls.select { |call| call[0] == :launch_template && call[1] != mixed_policy }
      expect(lt_calls).to be_empty
    end
    
    it "synthesizes ASG with termination policies correctly" do
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
      
      # Call aws_autoscaling_group function with termination policies
      ref = test_instance.aws_autoscaling_group(:termination_asg, {
        min_size: 2,
        max_size: 8,
        vpc_zone_identifier: [subnet_a, subnet_b],
        launch_template: { id: launch_template_id },
        termination_policies: ["OldestInstance", "Default"],
        protect_from_scale_in: true,
        max_instance_lifetime: 604800
      })
      
      # Verify termination policies synthesis
      expect(test_synthesizer.method_calls).to include(
        [:termination_policies, ["OldestInstance", "Default"]],
        [:protect_from_scale_in, true],
        [:max_instance_lifetime, 604800]
      )
    end
    
    it "synthesizes ASG with metrics collection correctly" do
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
      
      metrics = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances"]
      
      # Call aws_autoscaling_group function with metrics
      ref = test_instance.aws_autoscaling_group(:metrics_asg, {
        min_size: 1,
        max_size: 5,
        vpc_zone_identifier: [subnet_a],
        launch_template: { id: launch_template_id },
        enabled_metrics: metrics,
        metrics_granularity: "1Minute"
      })
      
      # Verify metrics synthesis
      expect(test_synthesizer.method_calls).to include(
        [:enabled_metrics, metrics],
        [:metrics_granularity, "1Minute"]
      )
    end
    
    it "synthesizes ASG with classic load balancers correctly" do
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
      
      # Call aws_autoscaling_group function with classic load balancers
      ref = test_instance.aws_autoscaling_group(:clb_asg, {
        min_size: 2,
        max_size: 6,
        availability_zones: ["us-east-1a", "us-east-1b"],
        launch_configuration: "web-lc",
        load_balancers: ["web-clb-1", "web-clb-2"],
        health_check_type: "ELB"
      })
      
      # Verify classic load balancer synthesis
      expect(test_synthesizer.method_calls).to include(
        [:load_balancers, ["web-clb-1", "web-clb-2"]],
        [:health_check_type, "ELB"]
      )
    end
    
    it "synthesizes ASG with capacity and scaling options correctly" do
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
      
      # Call aws_autoscaling_group function with capacity options
      ref = test_instance.aws_autoscaling_group(:capacity_asg, {
        min_size: 2,
        max_size: 10,
        vpc_zone_identifier: [subnet_a, subnet_b],
        launch_template: { id: launch_template_id },
        default_cooldown: 600,
        wait_for_capacity_timeout: "15m",
        min_elb_capacity: 2,
        capacity_rebalance: true,
        service_linked_role_arn: "arn:aws:iam::123456789012:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
      })
      
      # Verify capacity options synthesis
      expect(test_synthesizer.method_calls).to include(
        [:default_cooldown, 600],
        [:wait_for_capacity_timeout, "15m"],
        [:min_elb_capacity, 2],
        [:capacity_rebalance, true],
        [:service_linked_role_arn, "arn:aws:iam::123456789012:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"]
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
      
      # Call with default values to test conditionals
      ref = test_instance.aws_autoscaling_group(:conditional_asg, {
        min_size: 1,
        max_size: 5,
        vpc_zone_identifier: [subnet_a],
        launch_template: { id: launch_template_id },
        default_cooldown: 300, # Default value
        protect_from_scale_in: false, # Default value
        capacity_rebalance: false # Default value
      })
      
      # Verify default values are NOT synthesized (conditionals)
      cooldown_calls = test_synthesizer.method_calls.select { |call| call[0] == :default_cooldown }
      expect(cooldown_calls).to be_empty
      
      protect_calls = test_synthesizer.method_calls.select { |call| call[0] == :protect_from_scale_in }
      expect(protect_calls).to be_empty
      
      rebalance_calls = test_synthesizer.method_calls.select { |call| call[0] == :capacity_rebalance }
      expect(rebalance_calls).to be_empty
    end
    
    it "handles empty arrays correctly" do
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
      ref = test_instance.aws_autoscaling_group(:empty_arrays_asg, {
        min_size: 1,
        max_size: 5,
        vpc_zone_identifier: [subnet_a],
        launch_template: { id: launch_template_id },
        termination_policies: [],
        enabled_metrics: [],
        target_group_arns: [],
        load_balancers: [],
        tags: []
      })
      
      # Verify empty arrays are NOT synthesized
      termination_calls = test_synthesizer.method_calls.select { |call| call[0] == :termination_policies }
      expect(termination_calls).to be_empty
      
      metrics_calls = test_synthesizer.method_calls.select { |call| call[0] == :enabled_metrics }
      expect(metrics_calls).to be_empty
      
      tg_calls = test_synthesizer.method_calls.select { |call| call[0] == :target_group_arns }
      expect(tg_calls).to be_empty
      
      lb_calls = test_synthesizer.method_calls.select { |call| call[0] == :load_balancers }
      expect(lb_calls).to be_empty
      
      tag_calls = test_synthesizer.method_calls.select { |call| call[0] == :tag }
      expect(tag_calls).to be_empty
    end
    
    it "synthesizes ASG for multi-AZ deployment" do
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
      
      subnets = [
        "${aws_subnet.private_us_east_1a.id}",
        "${aws_subnet.private_us_east_1b.id}",
        "${aws_subnet.private_us_east_1c.id}"
      ]
      
      # Call aws_autoscaling_group function for multi-AZ
      ref = test_instance.aws_autoscaling_group(:multi_az_asg, {
        min_size: 6,
        max_size: 18,
        desired_capacity: 9,
        vpc_zone_identifier: subnets,
        launch_template: {
          id: launch_template_id,
          version: "$Latest"
        },
        health_check_type: "ELB",
        health_check_grace_period: 300,
        target_group_arns: [target_group_arn],
        tags: [
          { key: "Name", value: "multi-az-asg", propagate_at_launch: true },
          { key: "MultiAZ", value: "true", propagate_at_launch: false }
        ]
      })
      
      # Verify multi-AZ synthesis
      expect(test_synthesizer.method_calls).to include(
        [:min_size, 6],
        [:max_size, 18],
        [:desired_capacity, 9],
        [:vpc_zone_identifier, subnets],
        [:target_group_arns, [target_group_arn]]
      )
      
      # Verify tag array format
      tag_calls = test_synthesizer.method_calls.select { |call| call[0] == :tag }
      expect(tag_calls.length).to eq(1)
      tag_array = tag_calls.first[1]
      expect(tag_array.length).to eq(2)
      expect(tag_array.any? { |t| t[:key] == "MultiAZ" && t[:value] == "true" }).to eq(true)
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
      
      ref = test_instance.aws_autoscaling_group(:output_test, {
        min_size: 1,
        max_size: 5,
        vpc_zone_identifier: [subnet_a],
        launch_template: { id: launch_template_id }
      })
      
      # Verify all outputs have correct terraform reference format
      expected_outputs = [
        :id, :arn, :name, :min_size, :max_size, :desired_capacity,
        :default_cooldown, :availability_zones, :load_balancers, :target_group_arns,
        :health_check_type, :health_check_grace_period, :vpc_zone_identifier
      ]
      
      expected_outputs.each do |output|
        expect(ref.outputs[output]).to match(/\A\$\{aws_autoscaling_group\.output_test\./)
      end
      
      # Verify specific output formats
      expect(ref.outputs[:id]).to eq("${aws_autoscaling_group.output_test.id}")
      expect(ref.outputs[:arn]).to eq("${aws_autoscaling_group.output_test.arn}")
      expect(ref.outputs[:name]).to eq("${aws_autoscaling_group.output_test.name}")
      expect(ref.outputs[:min_size]).to eq("${aws_autoscaling_group.output_test.min_size}")
      expect(ref.outputs[:max_size]).to eq("${aws_autoscaling_group.output_test.max_size}")
      expect(ref.outputs[:desired_capacity]).to eq("${aws_autoscaling_group.output_test.desired_capacity}")
    end
  end
end