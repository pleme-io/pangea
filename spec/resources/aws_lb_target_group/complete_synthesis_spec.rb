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

# Load aws_lb_target_group resource for terraform synthesis testing
require 'pangea/resources/aws_lb_target_group/resource'

RSpec.describe "aws_lb_target_group terraform synthesis" do
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
            # For nested blocks like health_check, stickiness, tags
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
    let(:vpc_id) { "${aws_vpc.main.id}" }
    
    it "synthesizes basic HTTP target group terraform correctly" do
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
      
      # Call aws_lb_target_group function with minimal HTTP configuration
      ref = test_instance.aws_lb_target_group(:basic_tg, {
        port: 80,
        protocol: "HTTP",
        vpc_id: vpc_id
      })
      
      # Verify the function returned correct ResourceReference
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_lb_target_group')
      expect(ref.name).to eq(:basic_tg)
      
      # Verify terraform synthesis calls were made correctly
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_lb_target_group, :basic_tg],
        [:port, 80],
        [:protocol, "HTTP"],
        [:vpc_id, vpc_id]
      )
      
      # Verify resource was created in synthesizer
      expect(test_synthesizer.resources).to have_key("aws_lb_target_group.basic_tg")
    end
    
    it "synthesizes target group with name correctly" do
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
      
      # Call aws_lb_target_group function with name
      ref = test_instance.aws_lb_target_group(:named_tg, {
        name: "web-target-group",
        port: 80,
        protocol: "HTTP",
        vpc_id: vpc_id
      })
      
      # Verify name synthesis
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_lb_target_group, :named_tg],
        [:name, "web-target-group"]
      )
      
      # Verify name_prefix was NOT called
      name_prefix_calls = test_synthesizer.method_calls.select { |call| call[0] == :name_prefix }
      expect(name_prefix_calls).to be_empty
    end
    
    it "synthesizes target group with name_prefix correctly" do
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
      
      # Call aws_lb_target_group function with name_prefix
      ref = test_instance.aws_lb_target_group(:prefix_tg, {
        name_prefix: "web-",
        port: 443,
        protocol: "HTTPS",
        vpc_id: vpc_id
      })
      
      # Verify name_prefix synthesis
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_lb_target_group, :prefix_tg],
        [:name_prefix, "web-"],
        [:port, 443],
        [:protocol, "HTTPS"]
      )
      
      # Verify name was NOT called
      name_calls = test_synthesizer.method_calls.select { |call| call[0] == :name && call[1] != "web-" }
      expect(name_calls).to be_empty
    end
    
    it "synthesizes target group with health check correctly" do
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
      
      # Call aws_lb_target_group function with health check
      ref = test_instance.aws_lb_target_group(:hc_tg, {
        port: 80,
        protocol: "HTTP",
        vpc_id: vpc_id,
        health_check: {
          enabled: true,
          interval: 15,
          path: "/api/health",
          port: "8080",
          protocol: "HTTP",
          timeout: 10,
          healthy_threshold: 2,
          unhealthy_threshold: 3,
          matcher: "200-299"
        }
      })
      
      # Verify health check synthesis
      expect(test_synthesizer.method_calls).to include(
        [:health_check],
        [:enabled, true],
        [:interval, 15],
        [:path, "/api/health"],
        [:port, "8080"],
        [:protocol, "HTTP"],
        [:timeout, 10],
        [:healthy_threshold, 2],
        [:unhealthy_threshold, 3],
        [:matcher, "200-299"]
      )
    end
    
    it "synthesizes target group with stickiness correctly" do
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
      
      # Call aws_lb_target_group function with lb_cookie stickiness
      ref = test_instance.aws_lb_target_group(:sticky_tg, {
        port: 80,
        protocol: "HTTP",
        vpc_id: vpc_id,
        stickiness: {
          enabled: true,
          type: "lb_cookie",
          duration: 3600
        }
      })
      
      # Verify stickiness synthesis
      expect(test_synthesizer.method_calls).to include(
        [:stickiness],
        [:enabled, true],
        [:type, "lb_cookie"],
        [:duration, 3600]
      )
      
      # Verify cookie_name was NOT called for lb_cookie
      cookie_calls = test_synthesizer.method_calls.select { |call| call[0] == :cookie_name }
      expect(cookie_calls).to be_empty
    end
    
    it "synthesizes target group with app_cookie stickiness correctly" do
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
      
      # Call aws_lb_target_group function with app_cookie stickiness
      ref = test_instance.aws_lb_target_group(:app_cookie_tg, {
        port: 443,
        protocol: "HTTPS",
        vpc_id: vpc_id,
        stickiness: {
          enabled: true,
          type: "app_cookie",
          cookie_name: "JSESSIONID"
        }
      })
      
      # Verify app_cookie stickiness synthesis
      expect(test_synthesizer.method_calls).to include(
        [:stickiness],
        [:enabled, true],
        [:type, "app_cookie"],
        [:cookie_name, "JSESSIONID"]
      )
      
      # Verify duration was NOT called for app_cookie
      duration_calls = test_synthesizer.method_calls.select { |call| call[0] == :duration }
      expect(duration_calls).to be_empty
    end
    
    it "synthesizes TCP target group correctly" do
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
      
      # Call aws_lb_target_group function with TCP protocol
      ref = test_instance.aws_lb_target_group(:tcp_tg, {
        port: 3306,
        protocol: "TCP",
        vpc_id: vpc_id,
        target_type: "instance",
        deregistration_delay: 60,
        health_check: {
          enabled: true,
          protocol: "TCP",
          interval: 10,
          timeout: 5
        }
      })
      
      # Verify TCP target group synthesis
      expect(test_synthesizer.method_calls).to include(
        [:port, 3306],
        [:protocol, "TCP"],
        [:deregistration_delay, 60],
        [:health_check]
      )
      
      # Verify stickiness was NOT called (TCP doesn't support it)
      stickiness_calls = test_synthesizer.method_calls.select { |call| call[0] == :stickiness }
      expect(stickiness_calls).to be_empty
      
      # Verify health check path was NOT called (TCP doesn't support it)
      path_calls = test_synthesizer.method_calls.select { |call| call[0] == :path }
      expect(path_calls).to be_empty
      
      # Verify matcher was NOT called (TCP doesn't support it)
      matcher_calls = test_synthesizer.method_calls.select { |call| call[0] == :matcher }
      expect(matcher_calls).to be_empty
    end
    
    it "synthesizes target group with tags correctly" do
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
      
      # Call aws_lb_target_group function with tags
      ref = test_instance.aws_lb_target_group(:tagged_tg, {
        port: 80,
        protocol: "HTTP",
        vpc_id: vpc_id,
        tags: {
          Name: "web-target-group",
          Environment: "production",
          Application: "web-app",
          ManagedBy: "pangea"
        }
      })
      
      # Verify tags synthesis
      expect(test_synthesizer.method_calls).to include(
        [:tags],
        [:Name, "web-target-group"],
        [:Environment, "production"],
        [:Application, "web-app"],
        [:ManagedBy, "pangea"]
      )
    end
    
    it "synthesizes target group with optional attributes correctly" do
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
      
      # Call aws_lb_target_group function with optional attributes
      ref = test_instance.aws_lb_target_group(:optional_tg, {
        port: 8080,
        protocol: "HTTP",
        vpc_id: vpc_id,
        target_type: "ip",
        slow_start: 30,
        proxy_protocol_v2: true,
        preserve_client_ip: true,
        ip_address_type: "ipv6",
        protocol_version: "HTTP2"
      })
      
      # Verify optional attributes synthesis
      expect(test_synthesizer.method_calls).to include(
        [:target_type, "ip"],
        [:slow_start, 30],
        [:proxy_protocol_v2, true],
        [:preserve_client_ip, true],
        [:ip_address_type, "ipv6"],
        [:protocol_version, "HTTP2"]
      )
    end
    
    it "synthesizes Lambda target group correctly" do
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
      
      # Call aws_lb_target_group function for Lambda
      ref = test_instance.aws_lb_target_group(:lambda_tg, {
        name: "lambda-target-group",
        port: 443,
        protocol: "HTTPS",
        vpc_id: vpc_id,
        target_type: "lambda",
        health_check: {
          enabled: false
        }
      })
      
      # Verify Lambda target group synthesis
      expect(test_synthesizer.method_calls).to include(
        [:name, "lambda-target-group"],
        [:target_type, "lambda"],
        [:health_check],
        [:enabled, false]
      )
    end
    
    it "synthesizes UDP target group correctly" do
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
      
      # Call aws_lb_target_group function with UDP protocol
      ref = test_instance.aws_lb_target_group(:udp_tg, {
        port: 53,
        protocol: "UDP",
        vpc_id: vpc_id,
        health_check: {
          enabled: true,
          protocol: "TCP",  # UDP health checks use TCP
          port: "8080"
        }
      })
      
      # Verify UDP target group synthesis
      expect(test_synthesizer.method_calls).to include(
        [:port, 53],
        [:protocol, "UDP"],
        [:health_check],
        [:protocol, "TCP"],
        [:port, "8080"]
      )
    end
    
    it "synthesizes comprehensive target group correctly" do
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
      
      # Call aws_lb_target_group function with comprehensive config
      ref = test_instance.aws_lb_target_group(:comprehensive_tg, {
        name: "comprehensive-target-group",
        port: 8080,
        protocol: "HTTP",
        vpc_id: vpc_id,
        target_type: "ip",
        deregistration_delay: 120,
        slow_start: 60,
        protocol_version: "HTTP2",
        health_check: {
          enabled: true,
          interval: 15,
          path: "/api/health",
          timeout: 10,
          healthy_threshold: 2,
          unhealthy_threshold: 3,
          matcher: "200,204"
        },
        stickiness: {
          enabled: true,
          type: "lb_cookie",
          duration: 1800
        },
        tags: {
          Name: "comprehensive-tg",
          Environment: "production",
          Application: "api"
        }
      })
      
      # Verify comprehensive synthesis includes all major components
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_lb_target_group, :comprehensive_tg],
        [:name, "comprehensive-target-group"],
        [:port, 8080],
        [:protocol, "HTTP"],
        [:target_type, "ip"],
        [:deregistration_delay, 120],
        [:slow_start, 60],
        [:protocol_version, "HTTP2"],
        [:health_check],
        [:path, "/api/health"],
        [:stickiness],
        [:duration, 1800],
        [:tags],
        [:Application, "api"]
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
      ref = test_instance.aws_lb_target_group(:conditional_tg, {
        port: 80,
        protocol: "HTTP",
        vpc_id: vpc_id,
        target_type: "instance",  # Default value
        deregistration_delay: 300, # Default value
        slow_start: 0,            # Default value
        proxy_protocol_v2: false, # Default value
        ip_address_type: "ipv4"   # Default value
      })
      
      # Verify default values are NOT synthesized (conditionals)
      target_type_calls = test_synthesizer.method_calls.select { |call| call[0] == :target_type }
      expect(target_type_calls).to be_empty
      
      deregistration_calls = test_synthesizer.method_calls.select { |call| call[0] == :deregistration_delay }
      expect(deregistration_calls).to be_empty
      
      slow_start_calls = test_synthesizer.method_calls.select { |call| call[0] == :slow_start }
      expect(slow_start_calls).to be_empty
      
      proxy_calls = test_synthesizer.method_calls.select { |call| call[0] == :proxy_protocol_v2 }
      expect(proxy_calls).to be_empty
      
      ip_type_calls = test_synthesizer.method_calls.select { |call| call[0] == :ip_address_type }
      expect(ip_type_calls).to be_empty
    end
    
    it "handles nil health check correctly" do
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
      
      # Call without health check
      ref = test_instance.aws_lb_target_group(:no_hc_tg, {
        port: 80,
        protocol: "HTTP",
        vpc_id: vpc_id
      })
      
      # Verify health_check block was NOT called
      hc_calls = test_synthesizer.method_calls.select { |call| call[0] == :health_check }
      expect(hc_calls).to be_empty
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
      ref = test_instance.aws_lb_target_group(:empty_tags_tg, {
        port: 80,
        protocol: "HTTP",
        vpc_id: vpc_id,
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
      
      ref = test_instance.aws_lb_target_group(:output_test, {
        port: 80,
        protocol: "HTTP",
        vpc_id: vpc_id
      })
      
      # Verify all outputs have correct terraform reference format
      expected_outputs = [:id, :arn, :arn_suffix, :name, :port, :protocol, :vpc_id, :target_type, :health_check, :stickiness]
      
      expected_outputs.each do |output|
        expect(ref.outputs[output]).to match(/\A\$\{aws_lb_target_group\.output_test\./)
      end
      
      # Verify specific output formats
      expect(ref.outputs[:id]).to eq("${aws_lb_target_group.output_test.id}")
      expect(ref.outputs[:arn]).to eq("${aws_lb_target_group.output_test.arn}")
      expect(ref.outputs[:arn_suffix]).to eq("${aws_lb_target_group.output_test.arn_suffix}")
      expect(ref.outputs[:name]).to eq("${aws_lb_target_group.output_test.name}")
      expect(ref.outputs[:port]).to eq("${aws_lb_target_group.output_test.port}")
      expect(ref.outputs[:protocol]).to eq("${aws_lb_target_group.output_test.protocol}")
    end
  end
end