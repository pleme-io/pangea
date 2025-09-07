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

# Load aws_autoscaling_group resource and types for testing
require 'pangea/resources/aws_autoscaling_group/resource'
require 'pangea/resources/aws_autoscaling_group/types'

RSpec.describe "aws_autoscaling_group resource function" do
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
  let(:subnet_a) { "${aws_subnet.private_a.id}" }
  let(:subnet_b) { "${aws_subnet.private_b.id}" }
  let(:launch_template_id) { "${aws_launch_template.web.id}" }
  let(:target_group_arn) { "${aws_lb_target_group.web.arn}" }
  
  describe "LaunchTemplateSpecification validation" do
    it "validates that either id or name is specified" do
      expect {
        Pangea::Resources::AWS::Types::LaunchTemplateSpecification.new({})
      }.to raise_error(Dry::Struct::Error, /Launch template must specify either 'id' or 'name'/)
    end
    
    it "validates that both id and name cannot be specified" do
      expect {
        Pangea::Resources::AWS::Types::LaunchTemplateSpecification.new({
          id: "lt-12345678",
          name: "web-template"
        })
      }.to raise_error(Dry::Struct::Error, /Launch template cannot specify both 'id' and 'name'/)
    end
    
    it "accepts launch template with id" do
      spec = Pangea::Resources::AWS::Types::LaunchTemplateSpecification.new({
        id: launch_template_id,
        version: "$Latest"
      })
      
      expect(spec.id).to eq(launch_template_id)
      expect(spec.name).to be_nil
      expect(spec.version).to eq("$Latest")
    end
    
    it "accepts launch template with name" do
      spec = Pangea::Resources::AWS::Types::LaunchTemplateSpecification.new({
        name: "web-template",
        version: "1"
      })
      
      expect(spec.name).to eq("web-template")
      expect(spec.id).to be_nil
      expect(spec.version).to eq("1")
    end
    
    it "applies default version" do
      spec = Pangea::Resources::AWS::Types::LaunchTemplateSpecification.new({
        id: launch_template_id
      })
      
      expect(spec.version).to eq("$Latest")
    end
    
    it "compacts hash output correctly" do
      spec = Pangea::Resources::AWS::Types::LaunchTemplateSpecification.new({
        name: "web-template"
      })
      
      hash = spec.to_h
      expect(hash).to eq({
        name: "web-template",
        version: "$Latest"
      })
      expect(hash).not_to have_key(:id)
    end
  end
  
  describe "InstanceRefreshPreferences validation" do
    it "accepts default instance refresh preferences" do
      prefs = Pangea::Resources::AWS::Types::InstanceRefreshPreferences.new({})
      
      expect(prefs.min_healthy_percentage).to eq(90)
      expect(prefs.instance_warmup).to be_nil
      expect(prefs.checkpoint_percentages).to eq([])
      expect(prefs.checkpoint_delay).to be_nil
    end
    
    it "accepts custom instance refresh preferences" do
      prefs = Pangea::Resources::AWS::Types::InstanceRefreshPreferences.new({
        min_healthy_percentage: 80,
        instance_warmup: 300,
        checkpoint_percentages: [20, 50, 100],
        checkpoint_delay: 600
      })
      
      expect(prefs.min_healthy_percentage).to eq(80)
      expect(prefs.instance_warmup).to eq(300)
      expect(prefs.checkpoint_percentages).to eq([20, 50, 100])
      expect(prefs.checkpoint_delay).to eq(600)
    end
    
    it "validates percentage constraints" do
      expect {
        Pangea::Resources::AWS::Types::InstanceRefreshPreferences.new({
          min_healthy_percentage: 150
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "compacts hash output correctly" do
      prefs = Pangea::Resources::AWS::Types::InstanceRefreshPreferences.new({
        min_healthy_percentage: 85,
        instance_warmup: 300
      })
      
      hash = prefs.to_h
      expect(hash).to include(min_healthy_percentage: 85, instance_warmup: 300)
      expect(hash).not_to have_key(:checkpoint_percentages)
      expect(hash).not_to have_key(:checkpoint_delay)
    end
  end
  
  describe "AutoScalingTag validation" do
    it "accepts basic auto scaling tag" do
      tag = Pangea::Resources::AWS::Types::AutoScalingTag.new({
        key: "Name",
        value: "web-server"
      })
      
      expect(tag.key).to eq("Name")
      expect(tag.value).to eq("web-server")
      expect(tag.propagate_at_launch).to eq(true)
    end
    
    it "accepts tag with custom propagate_at_launch" do
      tag = Pangea::Resources::AWS::Types::AutoScalingTag.new({
        key: "Environment",
        value: "production",
        propagate_at_launch: false
      })
      
      expect(tag.key).to eq("Environment")
      expect(tag.value).to eq("production")
      expect(tag.propagate_at_launch).to eq(false)
    end
    
    it "converts to hash correctly" do
      tag = Pangea::Resources::AWS::Types::AutoScalingTag.new({
        key: "Team",
        value: "platform",
        propagate_at_launch: true
      })
      
      hash = tag.to_h
      expect(hash).to eq({
        key: "Team",
        value: "platform",
        propagate_at_launch: true
      })
    end
  end
  
  describe "AutoScalingGroupAttributes validation" do
    it "validates required min_size and max_size" do
      expect {
        Pangea::Resources::AWS::Types::AutoScalingGroupAttributes.new({
          max_size: 10,
          vpc_zone_identifier: [subnet_a],
          launch_template: { id: launch_template_id }
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates min_size <= max_size relationship" do
      expect {
        Pangea::Resources::AWS::Types::AutoScalingGroupAttributes.new({
          min_size: 10,
          max_size: 5,
          vpc_zone_identifier: [subnet_a],
          launch_template: { id: launch_template_id }
        })
      }.to raise_error(Dry::Struct::Error, /min_size .* cannot be greater than max_size/)
    end
    
    it "validates desired_capacity within min/max range" do
      expect {
        Pangea::Resources::AWS::Types::AutoScalingGroupAttributes.new({
          min_size: 2,
          max_size: 10,
          desired_capacity: 15,
          vpc_zone_identifier: [subnet_a],
          launch_template: { id: launch_template_id }
        })
      }.to raise_error(Dry::Struct::Error, /desired_capacity .* must be between min_size .* and max_size/)
    end
    
    it "validates that launch configuration is specified" do
      expect {
        Pangea::Resources::AWS::Types::AutoScalingGroupAttributes.new({
          min_size: 1,
          max_size: 5,
          vpc_zone_identifier: [subnet_a]
        })
      }.to raise_error(Dry::Struct::Error, /Auto Scaling Group must specify one of/)
    end
    
    it "validates mutual exclusivity of launch configurations" do
      expect {
        Pangea::Resources::AWS::Types::AutoScalingGroupAttributes.new({
          min_size: 1,
          max_size: 5,
          vpc_zone_identifier: [subnet_a],
          launch_configuration: "web-lc",
          launch_template: { id: launch_template_id }
        })
      }.to raise_error(Dry::Struct::Error, /Auto Scaling Group can only specify one of/)
    end
    
    it "validates network configuration requirement" do
      expect {
        Pangea::Resources::AWS::Types::AutoScalingGroupAttributes.new({
          min_size: 1,
          max_size: 5,
          launch_template: { id: launch_template_id }
        })
      }.to raise_error(Dry::Struct::Error, /Auto Scaling Group must specify either vpc_zone_identifier or availability_zones/)
    end
    
    it "accepts valid ASG with launch template" do
      attrs = Pangea::Resources::AWS::Types::AutoScalingGroupAttributes.new({
        min_size: 2,
        max_size: 10,
        desired_capacity: 4,
        vpc_zone_identifier: [subnet_a, subnet_b],
        launch_template: {
          id: launch_template_id,
          version: "$Latest"
        }
      })
      
      expect(attrs.min_size).to eq(2)
      expect(attrs.max_size).to eq(10)
      expect(attrs.desired_capacity).to eq(4)
      expect(attrs.vpc_zone_identifier).to eq([subnet_a, subnet_b])
      expect(attrs.launch_template.id).to eq(launch_template_id)
    end
    
    it "accepts valid ASG with launch configuration" do
      attrs = Pangea::Resources::AWS::Types::AutoScalingGroupAttributes.new({
        min_size: 1,
        max_size: 3,
        availability_zones: ["us-east-1a", "us-east-1b"],
        launch_configuration: "web-lc"
      })
      
      expect(attrs.launch_configuration).to eq("web-lc")
      expect(attrs.availability_zones).to eq(["us-east-1a", "us-east-1b"])
    end
    
    it "validates health check type enum" do
      expect {
        Pangea::Resources::AWS::Types::AutoScalingGroupAttributes.new({
          min_size: 1,
          max_size: 5,
          vpc_zone_identifier: [subnet_a],
          launch_template: { id: launch_template_id },
          health_check_type: "invalid"
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates termination policies enum" do
      expect {
        Pangea::Resources::AWS::Types::AutoScalingGroupAttributes.new({
          min_size: 1,
          max_size: 5,
          vpc_zone_identifier: [subnet_a],
          launch_template: { id: launch_template_id },
          termination_policies: ["InvalidPolicy"]
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    describe "computed properties" do
      let(:lt_attrs) do
        Pangea::Resources::AWS::Types::AutoScalingGroupAttributes.new({
          min_size: 1,
          max_size: 5,
          vpc_zone_identifier: [subnet_a],
          launch_template: { id: launch_template_id }
        })
      end
      
      let(:lc_attrs) do
        Pangea::Resources::AWS::Types::AutoScalingGroupAttributes.new({
          min_size: 1,
          max_size: 5,
          vpc_zone_identifier: [subnet_a],
          launch_configuration: "web-lc"
        })
      end
      
      it "detects launch template usage" do
        expect(lt_attrs.uses_launch_template?).to eq(true)
        expect(lc_attrs.uses_launch_template?).to eq(false)
      end
      
      it "detects mixed instances usage" do
        mixed_attrs = Pangea::Resources::AWS::Types::AutoScalingGroupAttributes.new({
          min_size: 1,
          max_size: 5,
          vpc_zone_identifier: [subnet_a],
          mixed_instances_policy: { some: "config" }
        })
        
        expect(mixed_attrs.uses_mixed_instances?).to eq(true)
        expect(lt_attrs.uses_mixed_instances?).to eq(false)
      end
      
      it "detects target group usage" do
        tg_attrs = Pangea::Resources::AWS::Types::AutoScalingGroupAttributes.new({
          min_size: 1,
          max_size: 5,
          vpc_zone_identifier: [subnet_a],
          launch_template: { id: launch_template_id },
          target_group_arns: [target_group_arn]
        })
        
        expect(tg_attrs.uses_target_groups?).to eq(true)
        expect(lt_attrs.uses_target_groups?).to eq(false)
      end
      
      it "detects classic load balancer usage" do
        clb_attrs = Pangea::Resources::AWS::Types::AutoScalingGroupAttributes.new({
          min_size: 1,
          max_size: 5,
          vpc_zone_identifier: [subnet_a],
          launch_template: { id: launch_template_id },
          load_balancers: ["web-clb"]
        })
        
        expect(clb_attrs.uses_classic_load_balancers?).to eq(true)
        expect(lt_attrs.uses_classic_load_balancers?).to eq(false)
      end
    end
    
    it "compacts to_h output correctly" do
      attrs = Pangea::Resources::AWS::Types::AutoScalingGroupAttributes.new({
        min_size: 2,
        max_size: 10,
        vpc_zone_identifier: [subnet_a],
        launch_template: { id: launch_template_id },
        tags: [
          { key: "Name", value: "web-asg" }
        ]
      })
      
      hash = attrs.to_h
      expect(hash).to include(:min_size, :max_size, :vpc_zone_identifier, :launch_template, :tags)
      expect(hash).not_to have_key(:desired_capacity)
      expect(hash).not_to have_key(:availability_zones)
      expect(hash[:tags]).to be_an(Array)
      expect(hash[:tags][0]).to be_a(Hash)
    end
  end
  
  describe "aws_autoscaling_group function behavior" do
    it "creates a resource reference with minimal attributes" do
      ref = test_instance.aws_autoscaling_group(:test, {
        min_size: 1,
        max_size: 3,
        vpc_zone_identifier: [subnet_a],
        launch_template: { id: launch_template_id }
      })
      
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_autoscaling_group')
      expect(ref.name).to eq(:test)
    end
    
    it "creates a resource reference with launch configuration" do
      ref = test_instance.aws_autoscaling_group(:lc_asg, {
        min_size: 2,
        max_size: 6,
        availability_zones: ["us-east-1a", "us-east-1b"],
        launch_configuration: "web-lc"
      })
      
      expect(ref.resource_attributes[:min_size]).to eq(2)
      expect(ref.resource_attributes[:max_size]).to eq(6)
      expect(ref.resource_attributes[:launch_configuration]).to eq("web-lc")
      expect(ref.resource_attributes[:availability_zones]).to eq(["us-east-1a", "us-east-1b"])
    end
    
    it "creates a resource reference with comprehensive configuration" do
      ref = test_instance.aws_autoscaling_group(:comprehensive, {
        min_size: 3,
        max_size: 15,
        desired_capacity: 6,
        vpc_zone_identifier: [subnet_a, subnet_b],
        launch_template: {
          id: launch_template_id,
          version: "2"
        },
        health_check_type: "ELB",
        health_check_grace_period: 600,
        target_group_arns: [target_group_arn],
        termination_policies: ["OldestInstance", "Default"],
        tags: [
          { key: "Name", value: "comprehensive-asg", propagate_at_launch: true },
          { key: "Environment", value: "production", propagate_at_launch: false }
        ],
        instance_refresh: {
          min_healthy_percentage: 85,
          instance_warmup: 300
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:min_size]).to eq(3)
      expect(attrs[:max_size]).to eq(15)
      expect(attrs[:desired_capacity]).to eq(6)
      expect(attrs[:launch_template][:version]).to eq("2")
      expect(attrs[:health_check_type]).to eq("ELB")
      expect(attrs[:health_check_grace_period]).to eq(600)
      expect(attrs[:target_group_arns]).to eq([target_group_arn])
      expect(attrs[:termination_policies]).to eq(["OldestInstance", "Default"])
      expect(attrs[:tags].length).to eq(2)
      expect(attrs[:instance_refresh][:min_healthy_percentage]).to eq(85)
    end
    
    it "validates attributes in function call" do
      expect {
        test_instance.aws_autoscaling_group(:invalid, {
          min_size: 10,
          max_size: 5,
          vpc_zone_identifier: [subnet_a],
          launch_template: { id: launch_template_id }
        })
      }.to raise_error(Dry::Struct::Error, /min_size .* cannot be greater than max_size/)
    end
    
    it "provides all expected outputs" do
      ref = test_instance.aws_autoscaling_group(:test, {
        min_size: 1,
        max_size: 5,
        vpc_zone_identifier: [subnet_a],
        launch_template: { id: launch_template_id }
      })
      
      expected_outputs = [
        :id, :arn, :name, :min_size, :max_size, :desired_capacity,
        :default_cooldown, :availability_zones, :load_balancers, :target_group_arns,
        :health_check_type, :health_check_grace_period, :vpc_zone_identifier
      ]
      
      expected_outputs.each do |output|
        expect(ref.outputs).to have_key(output)
        expect(ref.outputs[output]).to include("${aws_autoscaling_group.test.")
      end
    end
    
    it "provides computed properties via method delegation" do
      ref = test_instance.aws_autoscaling_group(:test, {
        min_size: 1,
        max_size: 5,
        vpc_zone_identifier: [subnet_a],
        launch_template: { id: launch_template_id },
        target_group_arns: [target_group_arn]
      })
      
      expect(ref.uses_launch_template?).to eq(true)
      expect(ref.uses_mixed_instances?).to eq(false)
      expect(ref.uses_target_groups?).to eq(true)
      expect(ref.uses_classic_load_balancers?).to eq(false)
    end
  end
  
  describe "common auto scaling group patterns" do
    it "creates a basic web application ASG" do
      ref = test_instance.aws_autoscaling_group(:web, {
        min_size: 2,
        max_size: 10,
        desired_capacity: 4,
        vpc_zone_identifier: [subnet_a, subnet_b],
        launch_template: {
          id: launch_template_id,
          version: "$Latest"
        },
        health_check_type: "ELB",
        health_check_grace_period: 300,
        target_group_arns: [target_group_arn],
        tags: [
          { key: "Name", value: "web-asg", propagate_at_launch: true },
          { key: "Environment", value: "production", propagate_at_launch: true }
        ]
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:min_size]).to eq(2)
      expect(attrs[:max_size]).to eq(10)
      expect(attrs[:desired_capacity]).to eq(4)
      expect(attrs[:health_check_type]).to eq("ELB")
      expect(attrs[:target_group_arns]).to eq([target_group_arn])
      expect(ref.uses_launch_template?).to eq(true)
      expect(ref.uses_target_groups?).to eq(true)
    end
    
    it "creates an ASG with instance refresh" do
      ref = test_instance.aws_autoscaling_group(:refreshable, {
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
      
      attrs = ref.resource_attributes
      expect(attrs[:instance_refresh][:min_healthy_percentage]).to eq(90)
      expect(attrs[:instance_refresh][:instance_warmup]).to eq(120)
      expect(attrs[:instance_refresh][:checkpoint_percentages]).to eq([50])
      expect(attrs[:instance_refresh][:checkpoint_delay]).to eq(300)
    end
    
    it "creates an ASG with mixed instances policy" do
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
      
      ref = test_instance.aws_autoscaling_group(:mixed, {
        min_size: 3,
        max_size: 20,
        vpc_zone_identifier: [subnet_a, subnet_b],
        mixed_instances_policy: mixed_policy
      })
      
      expect(ref.resource_attributes[:mixed_instances_policy]).to eq(mixed_policy)
      expect(ref.uses_mixed_instances?).to eq(true)
      expect(ref.uses_launch_template?).to eq(false)
    end
    
    it "creates an ASG with lifecycle management" do
      ref = test_instance.aws_autoscaling_group(:lifecycle, {
        min_size: 1,
        max_size: 5,
        vpc_zone_identifier: [subnet_a],
        launch_template: { id: launch_template_id },
        max_instance_lifetime: 604800, # 7 days
        protect_from_scale_in: true,
        termination_policies: ["OldestInstance", "Default"],
        capacity_rebalance: true
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:max_instance_lifetime]).to eq(604800)
      expect(attrs[:protect_from_scale_in]).to eq(true)
      expect(attrs[:termination_policies]).to eq(["OldestInstance", "Default"])
      expect(attrs[:capacity_rebalance]).to eq(true)
    end
    
    it "creates an ASG with metrics collection" do
      ref = test_instance.aws_autoscaling_group(:metrics, {
        min_size: 2,
        max_size: 8,
        vpc_zone_identifier: [subnet_a, subnet_b],
        launch_template: { id: launch_template_id },
        enabled_metrics: [
          "GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity",
          "GroupInServiceInstances", "GroupTotalInstances"
        ],
        metrics_granularity: "1Minute"
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:enabled_metrics]).to include("GroupMinSize", "GroupDesiredCapacity")
      expect(attrs[:metrics_granularity]).to eq("1Minute")
    end
    
    it "creates an ASG with classic load balancers" do
      ref = test_instance.aws_autoscaling_group(:classic_lb, {
        min_size: 2,
        max_size: 6,
        availability_zones: ["us-east-1a", "us-east-1b"],
        launch_configuration: "web-lc",
        load_balancers: ["web-clb-1", "web-clb-2"],
        health_check_type: "ELB",
        health_check_grace_period: 300
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:load_balancers]).to eq(["web-clb-1", "web-clb-2"])
      expect(attrs[:health_check_type]).to eq("ELB")
      expect(ref.uses_classic_load_balancers?).to eq(true)
    end
  end
  
  describe "resource reference integration" do
    it "provides terraform interpolation syntax for outputs" do
      ref = test_instance.aws_autoscaling_group(:test_asg, {
        min_size: 1,
        max_size: 5,
        vpc_zone_identifier: [subnet_a],
        launch_template: { id: launch_template_id }
      })
      
      expect(ref.outputs[:id]).to eq("${aws_autoscaling_group.test_asg.id}")
      expect(ref.outputs[:arn]).to eq("${aws_autoscaling_group.test_asg.arn}")
      expect(ref.outputs[:name]).to eq("${aws_autoscaling_group.test_asg.name}")
      expect(ref.outputs[:min_size]).to eq("${aws_autoscaling_group.test_asg.min_size}")
      expect(ref.outputs[:max_size]).to eq("${aws_autoscaling_group.test_asg.max_size}")
      expect(ref.outputs[:desired_capacity]).to eq("${aws_autoscaling_group.test_asg.desired_capacity}")
    end
    
    it "can be used with Auto Scaling Policies" do
      asg_ref = test_instance.aws_autoscaling_group(:policy_asg, {
        min_size: 1,
        max_size: 10,
        vpc_zone_identifier: [subnet_a],
        launch_template: { id: launch_template_id }
      })
      
      # Simulate using ASG reference in scaling policy
      asg_name = asg_ref.outputs[:name]
      
      expect(asg_name).to eq("${aws_autoscaling_group.policy_asg.name}")
    end
    
    it "supports complex cross-resource references" do
      ref = test_instance.aws_autoscaling_group(:cross_ref, {
        min_size: 1,
        max_size: 5,
        vpc_zone_identifier: ["${data.aws_subnets.private.ids}"],
        launch_template: {
          id: "${aws_launch_template.app.id}",
          version: "${aws_launch_template.app.latest_version}"
        },
        target_group_arns: ["${aws_lb_target_group.app.arn}"],
        tags: [
          {
            key: "Name",
            value: "${var.environment}-${var.application}-asg",
            propagate_at_launch: true
          }
        ]
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:vpc_zone_identifier][0]).to include("data.aws_subnets.private.ids")
      expect(attrs[:launch_template][:id]).to include("aws_launch_template.app.id")
      expect(attrs[:launch_template][:version]).to include("aws_launch_template.app.latest_version")
      expect(attrs[:target_group_arns][0]).to include("aws_lb_target_group.app.arn")
      expect(attrs[:tags][0][:value]).to include("var.environment")
    end
  end
  
  describe "error conditions and edge cases" do
    it "handles empty tag arrays gracefully" do
      ref = test_instance.aws_autoscaling_group(:empty_tags, {
        min_size: 1,
        max_size: 3,
        vpc_zone_identifier: [subnet_a],
        launch_template: { id: launch_template_id },
        tags: []
      })
      
      expect(ref.resource_attributes[:tags]).to eq([])
    end
    
    it "handles no desired_capacity gracefully" do
      ref = test_instance.aws_autoscaling_group(:no_desired, {
        min_size: 2,
        max_size: 8,
        vpc_zone_identifier: [subnet_a],
        launch_template: { id: launch_template_id }
      })
      
      # desired_capacity should not be present in attributes
      expect(ref.resource_attributes).not_to have_key(:desired_capacity)
    end
    
    it "handles string keys in attributes" do
      ref = test_instance.aws_autoscaling_group(:string_keys, {
        "min_size" => 1,
        "max_size" => 5,
        "vpc_zone_identifier" => [subnet_a],
        "launch_template" => { "id" => launch_template_id }
      })
      
      expect(ref.resource_attributes[:min_size]).to eq(1)
      expect(ref.resource_attributes[:max_size]).to eq(5)
      expect(ref.resource_attributes[:launch_template][:id]).to eq(launch_template_id)
    end
  end
end