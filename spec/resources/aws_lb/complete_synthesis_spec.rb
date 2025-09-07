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

# Load aws_lb resource for terraform synthesis testing
require 'pangea/resources/aws_lb/resource'

RSpec.describe "aws_lb terraform synthesis" do
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
            # For nested blocks like access_logs, tags
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
            args.first if args.any?
          end
          
          def respond_to_missing?(method_name, include_private = false)
            true
          end
        end
      end
    end
    
    let(:test_synthesizer) { mock_synthesizer.new }
    let(:subnet_ids) { ["subnet-12345", "subnet-67890"] }
    let(:security_group_ids) { ["sg-abcdef"] }
    
    it "synthesizes basic application load balancer terraform correctly" do
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
      
      # Call aws_lb function with minimal ALB configuration
      ref = test_instance.aws_lb(:basic_alb, {
        subnet_ids: subnet_ids
      })
      
      # Verify the function returned correct ResourceReference
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_lb')
      expect(ref.name).to eq(:basic_alb)
      
      # Verify terraform synthesis calls were made correctly
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_lb, :basic_alb],
        [:load_balancer_type, "application"],
        [:internal, false],
        [:subnets, subnet_ids],
        [:enable_deletion_protection, false]
      )
      
      # Verify resource was created in synthesizer
      expect(test_synthesizer.resources).to have_key("aws_lb.basic_alb")
    end
    
    it "synthesizes application load balancer with security groups correctly" do
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
      
      # Call aws_lb function with ALB and security groups
      ref = test_instance.aws_lb(:alb_with_sg, {
        name: "web-application-lb",
        load_balancer_type: "application",
        subnet_ids: subnet_ids,
        security_groups: security_group_ids,
        internal: false
      })
      
      # Verify ALB-specific synthesis
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_lb, :alb_with_sg],
        [:name, "web-application-lb"],
        [:load_balancer_type, "application"],
        [:internal, false],
        [:subnets, subnet_ids],
        [:security_groups, security_group_ids]
      )
    end
    
    it "synthesizes network load balancer correctly" do
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
      
      # Call aws_lb function with NLB configuration
      ref = test_instance.aws_lb(:nlb_test, {
        name: "api-network-lb",
        load_balancer_type: "network",
        subnet_ids: subnet_ids,
        enable_cross_zone_load_balancing: true,
        internal: true
      })
      
      # Verify NLB-specific synthesis
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_lb, :nlb_test],
        [:name, "api-network-lb"],
        [:load_balancer_type, "network"],
        [:internal, true],
        [:subnets, subnet_ids],
        [:enable_cross_zone_load_balancing, true]
      )
      
      # Verify security_groups was NOT called for NLB
      security_groups_calls = test_synthesizer.method_calls.select { |call| call[0] == :security_groups }
      expect(security_groups_calls).to be_empty
    end
    
    it "synthesizes gateway load balancer correctly" do
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
      
      # Call aws_lb function with GWLB configuration
      ref = test_instance.aws_lb(:gwlb_test, {
        name: "security-gateway-lb",
        load_balancer_type: "gateway",
        subnet_ids: subnet_ids
      })
      
      # Verify GWLB synthesis
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_lb, :gwlb_test],
        [:name, "security-gateway-lb"],
        [:load_balancer_type, "gateway"],
        [:subnets, subnet_ids]
      )
    end
    
    it "synthesizes load balancer with access logs correctly" do
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
      
      # Call aws_lb function with access logs
      ref = test_instance.aws_lb(:logged_lb, {
        subnet_ids: subnet_ids,
        access_logs: {
          enabled: true,
          bucket: "lb-access-logs-bucket",
          prefix: "web-alb-logs"
        }
      })
      
      # Verify access logs synthesis
      expect(test_synthesizer.method_calls).to include(
        [:access_logs],
        [:bucket, "lb-access-logs-bucket"],
        [:enabled, true],
        [:prefix, "web-alb-logs"]
      )
    end
    
    it "synthesizes load balancer with access logs without prefix correctly" do
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
      
      # Call aws_lb function with access logs but no prefix
      ref = test_instance.aws_lb(:minimal_logs_lb, {
        subnet_ids: subnet_ids,
        access_logs: {
          enabled: false,
          bucket: "lb-logs-bucket"
        }
      })
      
      # Verify access logs synthesis without prefix
      expect(test_synthesizer.method_calls).to include(
        [:access_logs],
        [:bucket, "lb-logs-bucket"],
        [:enabled, false]
      )
      
      # Verify prefix was NOT called
      prefix_calls = test_synthesizer.method_calls.select { |call| call[0] == :prefix }
      expect(prefix_calls).to be_empty
    end
    
    it "synthesizes load balancer with IP address type correctly" do
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
      
      # Call aws_lb function with dual stack IP addressing
      ref = test_instance.aws_lb(:dualstack_lb, {
        subnet_ids: subnet_ids,
        ip_address_type: "dualstack"
      })
      
      # Verify IP address type synthesis
      expect(test_synthesizer.method_calls).to include(
        [:ip_address_type, "dualstack"]
      )
    end
    
    it "synthesizes load balancer with tags correctly" do
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
      
      # Call aws_lb function with tags
      ref = test_instance.aws_lb(:tagged_lb, {
        subnet_ids: subnet_ids,
        tags: {
          Name: "web-load-balancer",
          Environment: "production",
          Application: "web-app",
          ManagedBy: "pangea"
        }
      })
      
      # Verify tags synthesis
      expect(test_synthesizer.method_calls).to include(
        [:tags],
        [:Name, "web-load-balancer"],
        [:Environment, "production"],
        [:Application, "web-app"],
        [:ManagedBy, "pangea"]
      )
    end
    
    it "synthesizes internal load balancer correctly" do
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
      
      # Call aws_lb function with internal configuration
      ref = test_instance.aws_lb(:internal_lb, {
        load_balancer_type: "application",
        subnet_ids: subnet_ids,
        internal: true
      })
      
      # Verify internal flag synthesis
      expect(test_synthesizer.method_calls).to include(
        [:internal, true]
      )
    end
    
    it "synthesizes load balancer with deletion protection correctly" do
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
      
      # Call aws_lb function with deletion protection
      ref = test_instance.aws_lb(:protected_lb, {
        subnet_ids: subnet_ids,
        enable_deletion_protection: true
      })
      
      # Verify deletion protection synthesis
      expect(test_synthesizer.method_calls).to include(
        [:enable_deletion_protection, true]
      )
    end
    
    it "synthesizes comprehensive load balancer correctly" do
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
      
      # Call aws_lb function with comprehensive configuration
      ref = test_instance.aws_lb(:comprehensive_lb, {
        name: "comprehensive-alb",
        load_balancer_type: "application",
        internal: false,
        subnet_ids: subnet_ids,
        security_groups: security_group_ids,
        ip_address_type: "dualstack",
        enable_deletion_protection: true,
        access_logs: {
          enabled: true,
          bucket: "comprehensive-logs",
          prefix: "alb-logs"
        },
        tags: {
          Name: "comprehensive-alb",
          Environment: "production",
          Application: "web"
        }
      })
      
      # Verify comprehensive synthesis includes all major components
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_lb, :comprehensive_lb],
        [:name, "comprehensive-alb"],
        [:load_balancer_type, "application"],
        [:internal, false],
        [:subnets, subnet_ids],
        [:security_groups, security_group_ids],
        [:ip_address_type, "dualstack"],
        [:enable_deletion_protection, true],
        [:access_logs],
        [:bucket, "comprehensive-logs"],
        [:prefix, "alb-logs"],
        [:tags],
        [:Environment, "production"]
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
      
      # Call with defaults to test conditionals
      ref = test_instance.aws_lb(:conditional_lb, {
        subnet_ids: subnet_ids,
        load_balancer_type: "application",  # Default value
        internal: false,                    # Default value
        enable_deletion_protection: false, # Default value
        security_groups: []                 # Default value (empty)
      })
      
      # Verify certain defaults are still called
      expect(test_synthesizer.method_calls).to include(
        [:load_balancer_type, "application"],
        [:internal, false],
        [:enable_deletion_protection, false]
      )
      
      # Verify empty security groups are NOT synthesized for ALB
      security_groups_calls = test_synthesizer.method_calls.select { |call| call[0] == :security_groups && call[1] == [] }
      expect(security_groups_calls).to be_empty
    end
    
    it "handles nil optional attributes correctly" do
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
      
      # Call without optional attributes
      ref = test_instance.aws_lb(:minimal_lb, {
        subnet_ids: subnet_ids
      })
      
      # Verify optional attributes were NOT called
      ip_address_type_calls = test_synthesizer.method_calls.select { |call| call[0] == :ip_address_type }
      expect(ip_address_type_calls).to be_empty
      
      access_logs_calls = test_synthesizer.method_calls.select { |call| call[0] == :access_logs }
      expect(access_logs_calls).to be_empty
      
      name_calls = test_synthesizer.method_calls.select { |call| call[0] == :name }
      expect(name_calls).to be_empty
    end
    
    it "handles empty tags correctly" do
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
      
      # Call with empty tags
      ref = test_instance.aws_lb(:empty_tags_lb, {
        subnet_ids: subnet_ids,
        tags: {}
      })
      
      # Verify tags block was NOT called for empty hash
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
      
      ref = test_instance.aws_lb(:output_test, {
        subnet_ids: subnet_ids
      })
      
      # Verify all outputs have correct terraform reference format
      expected_outputs = [:id, :arn, :arn_suffix, :dns_name, :zone_id, :canonical_hosted_zone_id, :vpc_id]
      
      expected_outputs.each do |output|
        expect(ref.outputs[output]).to match(/\A\$\{aws_lb\.output_test\./)
      end
      
      # Verify specific output formats
      expect(ref.outputs[:id]).to eq("${aws_lb.output_test.id}")
      expect(ref.outputs[:arn]).to eq("${aws_lb.output_test.arn}")
      expect(ref.outputs[:arn_suffix]).to eq("${aws_lb.output_test.arn_suffix}")
      expect(ref.outputs[:dns_name]).to eq("${aws_lb.output_test.dns_name}")
      expect(ref.outputs[:zone_id]).to eq("${aws_lb.output_test.zone_id}")
      expect(ref.outputs[:canonical_hosted_zone_id]).to eq("${aws_lb.output_test.canonical_hosted_zone_id}")
      expect(ref.outputs[:vpc_id]).to eq("${aws_lb.output_test.vpc_id}")
    end
    
    it "synthesizes load balancer without name correctly" do
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
      
      # Call aws_lb function without explicit name (AWS will auto-generate)
      ref = test_instance.aws_lb(:auto_name_lb, {
        subnet_ids: subnet_ids
      })
      
      # Verify name was NOT called (AWS will auto-generate)
      name_calls = test_synthesizer.method_calls.select { |call| call[0] == :name }
      expect(name_calls).to be_empty
    end
    
    it "synthesizes cross-zone load balancing conditionally for NLB only" do
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
      
      # Call aws_lb for NLB with cross-zone load balancing
      nlb_ref = test_instance.aws_lb(:nlb_cross_zone, {
        load_balancer_type: "network",
        subnet_ids: subnet_ids,
        enable_cross_zone_load_balancing: false
      })
      
      # Verify cross-zone load balancing is included for NLB
      expect(test_synthesizer.method_calls).to include(
        [:enable_cross_zone_load_balancing, false]
      )
      
      # Reset for ALB test
      @test_synthesizer = mock_synthesizer.new
      test_instance = test_class.new(@test_synthesizer)
      
      # Call aws_lb for ALB (should not include cross-zone load balancing)
      alb_ref = test_instance.aws_lb(:alb_no_cross_zone, {
        load_balancer_type: "application",
        subnet_ids: subnet_ids
      })
      
      # Verify cross-zone load balancing is NOT included for ALB
      cross_zone_calls = @test_synthesizer.method_calls.select { |call| call[0] == :enable_cross_zone_load_balancing }
      expect(cross_zone_calls).to be_empty
    end
  end
end