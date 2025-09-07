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


require 'spec_helper'

# Load aws_api_gateway_resource resource and types for testing
require 'pangea/resources/aws_api_gateway_resource/resource'
require 'pangea/resources/aws_api_gateway_resource/types'

RSpec.describe "aws_api_gateway_resource resource function" do
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
  
  # Test values
  let(:rest_api_id) { "abc123def456" }
  let(:root_resource_id) { "xyz789uvw012" }

  describe "ApiGatewayResourceAttributes validation" do
    it "accepts basic resource with required attributes" do
      resource = Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.new({
        rest_api_id: rest_api_id,
        parent_id: root_resource_id,
        path_part: "users"
      })
      
      expect(resource.rest_api_id).to eq(rest_api_id)
      expect(resource.parent_id).to eq(root_resource_id)
      expect(resource.path_part).to eq("users")
      expect(resource.is_path_parameter?).to be false
      expect(resource.is_greedy_parameter?).to be false
      expect(resource.parameter_name).to be_nil
      expect(resource.requires_request_validator?).to be false
    end
    
    it "accepts path parameter resource" do
      resource = Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.new({
        rest_api_id: rest_api_id,
        parent_id: "resource123",
        path_part: "{userId}"
      })
      
      expect(resource.path_part).to eq("{userId}")
      expect(resource.is_path_parameter?).to be true
      expect(resource.is_greedy_parameter?).to be false
      expect(resource.parameter_name).to eq("userId")
      expect(resource.requires_request_validator?).to be true
    end
    
    it "accepts greedy path parameter" do
      resource = Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.new({
        rest_api_id: rest_api_id,
        parent_id: "resource456",
        path_part: "{proxy+}"
      })
      
      expect(resource.path_part).to eq("{proxy+}")
      expect(resource.is_path_parameter?).to be true
      expect(resource.is_greedy_parameter?).to be true
      expect(resource.parameter_name).to eq("proxy")
      expect(resource.requires_request_validator?).to be true
    end
    
    it "accepts resource with alphanumeric path parts" do
      valid_paths = ["users", "user-info", "user_data", "v1", "api2", "health-check"]
      
      valid_paths.each do |path_part|
        expect {
          Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.new({
            rest_api_id: rest_api_id,
            parent_id: root_resource_id,
            path_part: path_part
          })
        }.not_to raise_error
      end
    end
    
    it "accepts resource with valid parameter formats" do
      valid_params = ["{id}", "{userId}", "{productId}", "{user-id}", "{proxy+}", "{catchAll+}"]
      
      valid_params.each do |param|
        expect {
          Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.new({
            rest_api_id: rest_api_id,
            parent_id: root_resource_id,
            path_part: param
          })
        }.not_to raise_error, "Failed for parameter: #{param}"
      end
    end
    
    it "rejects path part with forward slashes" do
      expect {
        Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.new({
          rest_api_id: rest_api_id,
          parent_id: root_resource_id,
          path_part: "users/profile"
        })
      }.to raise_error(Dry::Struct::Error, /Path part cannot contain slashes/)
    end
    
    it "rejects path part with invalid characters" do
      invalid_paths = ["user@info", "user.data", "user#tag", "user space", "user?query"]
      
      invalid_paths.each do |path_part|
        expect {
          Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.new({
            rest_api_id: rest_api_id,
            parent_id: root_resource_id,
            path_part: path_part
          })
        }.to raise_error(Dry::Struct::Error, /Path part must be alphanumeric/), "Should reject: #{path_part}"
      end
    end
    
    it "rejects malformed parameter brackets" do
      invalid_params = ["user}", "{user", "user{id}data", "{id}{name}", "{{id}}"]
      
      invalid_params.each do |param|
        expect {
          Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.new({
            rest_api_id: rest_api_id,
            parent_id: root_resource_id,
            path_part: param
          })
        }.to raise_error(Dry::Struct::Error), "Should reject malformed parameter: #{param}"
      end
    end
    
    it "rejects greedy parameter with extra content" do
      invalid_greedy = ["data{proxy+}", "{proxy+}data", "prefix{proxy+}suffix"]
      
      invalid_greedy.each do |param|
        expect {
          Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.new({
            rest_api_id: rest_api_id,
            parent_id: root_resource_id,
            path_part: param
          })
        }.to raise_error(Dry::Struct::Error, /Greedy path variables/), "Should reject: #{param}"
      end
    end
    
    it "rejects empty required attributes" do
      expect {
        Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.new({
          rest_api_id: "",
          parent_id: root_resource_id,
          path_part: "users"
        })
      }.to raise_error(Dry::Struct::Error)
      
      expect {
        Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.new({
          rest_api_id: rest_api_id,
          parent_id: "",
          path_part: "users"
        })
      }.to raise_error(Dry::Struct::Error)
      
      expect {
        Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.new({
          rest_api_id: rest_api_id,
          parent_id: root_resource_id,
          path_part: ""
        })
      }.to raise_error(Dry::Struct::Error)
    end
  end
  
  describe "aws_api_gateway_resource function" do
    it "creates API Gateway resource with basic configuration" do
      result = test_instance.aws_api_gateway_resource(:users, {
        rest_api_id: rest_api_id,
        parent_id: root_resource_id,
        path_part: "users"
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.resource_type).to eq(:aws_api_gateway_resource)
    end
    
    it "creates resource with parameter path part" do
      result = test_instance.aws_api_gateway_resource(:user_by_id, {
        rest_api_id: rest_api_id,
        parent_id: "users_resource_id",
        path_part: "{userId}"
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
    end
    
    it "creates resource with greedy parameter" do
      result = test_instance.aws_api_gateway_resource(:proxy, {
        rest_api_id: rest_api_id,
        parent_id: "admin_resource_id",
        path_part: "{proxy+}"
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
    end
    
    it "validates attributes through dry-struct" do
      expect {
        test_instance.aws_api_gateway_resource(:invalid, {
          rest_api_id: rest_api_id,
          parent_id: root_resource_id,
          path_part: "users/profile"
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "accepts string keys in attributes" do
      result = test_instance.aws_api_gateway_resource(:users_string_keys, {
        "rest_api_id" => rest_api_id,
        "parent_id" => root_resource_id,
        "path_part" => "users"
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
    end
  end
  
  describe "computed properties" do
    it "correctly identifies regular path parts" do
      resource = Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.new({
        rest_api_id: rest_api_id,
        parent_id: root_resource_id,
        path_part: "users"
      })
      
      expect(resource.is_path_parameter?).to be false
      expect(resource.is_greedy_parameter?).to be false
      expect(resource.parameter_name).to be_nil
      expect(resource.requires_request_validator?).to be false
    end
    
    it "correctly identifies path parameters" do
      resource = Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.new({
        rest_api_id: rest_api_id,
        parent_id: root_resource_id,
        path_part: "{userId}"
      })
      
      expect(resource.is_path_parameter?).to be true
      expect(resource.is_greedy_parameter?).to be false
      expect(resource.parameter_name).to eq("userId")
      expect(resource.requires_request_validator?).to be true
    end
    
    it "correctly identifies greedy parameters" do
      resource = Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.new({
        rest_api_id: rest_api_id,
        parent_id: root_resource_id,
        path_part: "{proxy+}"
      })
      
      expect(resource.is_path_parameter?).to be true
      expect(resource.is_greedy_parameter?).to be true
      expect(resource.parameter_name).to eq("proxy")
      expect(resource.requires_request_validator?).to be true
    end
    
    it "handles complex parameter names" do
      test_cases = [
        { path: "{user-id}", name: "user-id" },
        { path: "{product_id}", name: "product_id" },
        { path: "{catch-all+}", name: "catch-all" },
        { path: "{api_proxy+}", name: "api_proxy" }
      ]
      
      test_cases.each do |test_case|
        resource = Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.new({
          rest_api_id: rest_api_id,
          parent_id: root_resource_id,
          path_part: test_case[:path]
        })
        
        expect(resource.parameter_name).to eq(test_case[:name]), "Failed for path: #{test_case[:path]}"
      end
    end
  end
  
  describe "common path parts dictionary" do
    it "provides common path patterns" do
      common_paths = Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.common_path_parts
      
      expect(common_paths).to be_a(Hash)
      expect(common_paths[:items]).to eq("items")
      expect(common_paths[:item_id]).to eq("{id}")
      expect(common_paths[:users]).to eq("users")
      expect(common_paths[:user_id]).to eq("{userId}")
      expect(common_paths[:proxy]).to eq("{proxy+}")
      expect(common_paths[:search]).to eq("search")
      expect(common_paths[:health]).to eq("health")
    end
    
    it "includes version patterns" do
      common_paths = Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.common_path_parts
      expect(common_paths[:version]).to eq("v1")
    end
    
    it "includes operational patterns" do
      common_paths = Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.common_path_parts
      
      expect(common_paths[:metrics]).to eq("metrics")
      expect(common_paths[:webhooks]).to eq("webhooks")
      expect(common_paths[:batch]).to eq("batch")
      expect(common_paths[:export]).to eq("export")
      expect(common_paths[:import]).to eq("import")
    end
  end
  
  describe "path hierarchy validation" do
    it "validates simple hierarchy" do
      resources = [
        { id: "root", parent_id: nil, path_part: "" },
        { id: "users", parent_id: "root", path_part: "users" },
        { id: "user_id", parent_id: "users", path_part: "{userId}" }
      ]
      
      expect {
        Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.validate_path_hierarchy(resources)
      }.not_to raise_error
    end
    
    it "rejects invalid hierarchy with missing parent" do
      resources = [
        { id: "users", parent_id: "root", path_part: "users" },  # Missing root
        { id: "user_id", parent_id: "users", path_part: "{userId}" }
      ]
      
      expect {
        Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.validate_path_hierarchy(resources)
      }.to raise_error(/Parent resource .* not found/)
    end
    
    it "validates complex nested hierarchy" do
      resources = [
        { id: "root", parent_id: nil, path_part: "" },
        { id: "v1", parent_id: "root", path_part: "v1" },
        { id: "users", parent_id: "v1", path_part: "users" },
        { id: "user_id", parent_id: "users", path_part: "{userId}" },
        { id: "posts", parent_id: "user_id", path_part: "posts" },
        { id: "post_id", parent_id: "posts", path_part: "{postId}" }
      ]
      
      expect {
        Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.validate_path_hierarchy(resources)
      }.not_to raise_error
    end
  end
  
  describe "full path construction" do
    it "builds simple path from hierarchy" do
      resource_map = {
        "root" => { id: "root", parent_id: nil, path_part: "" },
        "users" => { id: "users", parent_id: "root", path_part: "users" }
      }
      
      path = Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.build_full_path("users", resource_map)
      expect(path).to eq("/users")
    end
    
    it "builds nested path from hierarchy" do
      resource_map = {
        "root" => { id: "root", parent_id: nil, path_part: "" },
        "v1" => { id: "v1", parent_id: "root", path_part: "v1" },
        "users" => { id: "users", parent_id: "v1", path_part: "users" },
        "user_id" => { id: "user_id", parent_id: "users", path_part: "{userId}" }
      }
      
      path = Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.build_full_path("user_id", resource_map)
      expect(path).to eq("/v1/users/{userId}")
    end
    
    it "builds complex nested path with parameters" do
      resource_map = {
        "root" => { id: "root", parent_id: nil, path_part: "" },
        "api" => { id: "api", parent_id: "root", path_part: "api" },
        "v2" => { id: "v2", parent_id: "api", path_part: "v2" },
        "users" => { id: "users", parent_id: "v2", path_part: "users" },
        "user_id" => { id: "user_id", parent_id: "users", path_part: "{userId}" },
        "posts" => { id: "posts", parent_id: "user_id", path_part: "posts" },
        "post_id" => { id: "post_id", parent_id: "posts", path_part: "{postId}" }
      }
      
      path = Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.build_full_path("post_id", resource_map)
      expect(path).to eq("/api/v2/users/{userId}/posts/{postId}")
    end
    
    it "handles greedy parameters in path" do
      resource_map = {
        "root" => { id: "root", parent_id: nil, path_part: "" },
        "admin" => { id: "admin", parent_id: "root", path_part: "admin" },
        "proxy" => { id: "proxy", parent_id: "admin", path_part: "{proxy+}" }
      }
      
      path = Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.build_full_path("proxy", resource_map)
      expect(path).to eq("/admin/{proxy+}")
    end
  end
  
  describe "RESTful patterns" do
    it "supports standard REST collection patterns" do
      # Standard REST API structure
      users_resource = Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.new({
        rest_api_id: rest_api_id,
        parent_id: root_resource_id,
        path_part: "users"
      })
      
      user_id_resource = Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.new({
        rest_api_id: rest_api_id,
        parent_id: "users_resource_id",
        path_part: "{userId}"
      })
      
      expect(users_resource.is_path_parameter?).to be false
      expect(user_id_resource.is_path_parameter?).to be true
      expect(user_id_resource.parameter_name).to eq("userId")
    end
    
    it "supports nested resource patterns" do
      # /users/{userId}/posts/{postId}
      posts_resource = Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.new({
        rest_api_id: rest_api_id,
        parent_id: "user_id_resource",
        path_part: "posts"
      })
      
      post_id_resource = Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.new({
        rest_api_id: rest_api_id,
        parent_id: "posts_resource",
        path_part: "{postId}"
      })
      
      expect(posts_resource.is_path_parameter?).to be false
      expect(post_id_resource.is_path_parameter?).to be true
      expect(post_id_resource.parameter_name).to eq("postId")
    end
    
    it "supports action-based patterns" do
      # /users/{userId}/activate
      action_resource = Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.new({
        rest_api_id: rest_api_id,
        parent_id: "user_id_resource",
        path_part: "activate"
      })
      
      expect(action_resource.is_path_parameter?).to be false
    end
    
    it "supports search patterns" do
      # /users/search
      search_resource = Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.new({
        rest_api_id: rest_api_id,
        parent_id: "users_resource",
        path_part: "search"
      })
      
      expect(search_resource.is_path_parameter?).to be false
    end
  end
  
  describe "microservices gateway patterns" do
    it "supports service routing patterns" do
      # /services/{serviceName}/{proxy+}
      services_resource = Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.new({
        rest_api_id: rest_api_id,
        parent_id: root_resource_id,
        path_part: "services"
      })
      
      service_name_resource = Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.new({
        rest_api_id: rest_api_id,
        parent_id: "services_resource",
        path_part: "{serviceName}"
      })
      
      proxy_resource = Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.new({
        rest_api_id: rest_api_id,
        parent_id: "service_name_resource",
        path_part: "{proxy+}"
      })
      
      expect(services_resource.is_path_parameter?).to be false
      expect(service_name_resource.is_path_parameter?).to be true
      expect(service_name_resource.parameter_name).to eq("serviceName")
      expect(proxy_resource.is_greedy_parameter?).to be true
      expect(proxy_resource.parameter_name).to eq("proxy")
    end
  end
  
  describe "edge cases and error conditions" do
    it "handles nil attributes gracefully" do
      expect {
        Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.new(nil)
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "handles empty hash gracefully" do
      expect {
        Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.new({})
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates minimum required attributes" do
      expect {
        Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.new({
          rest_api_id: rest_api_id
        })
      }.to raise_error(Dry::Struct::Error)
      
      expect {
        Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.new({
          rest_api_id: rest_api_id,
          parent_id: root_resource_id
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "accepts Unicode characters properly handled" do
      # While API Gateway has limitations, test the validation logic
      unicode_paths = ["café", "naïve", "resumé"]
      
      unicode_paths.each do |path_part|
        expect {
          Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.new({
            rest_api_id: rest_api_id,
            parent_id: root_resource_id,
            path_part: path_part
          })
        }.to raise_error(Dry::Struct::Error), "Should reject Unicode: #{path_part}"
      end
    end
  end
  
  describe "performance with large hierarchies" do
    it "handles reasonable sized resource hierarchies" do
      # Create a moderate-sized hierarchy (50 resources)
      resources = []
      resource_map = {}
      
      # Root resource
      resources << { id: "root", parent_id: nil, path_part: "" }
      resource_map["root"] = resources.last
      
      # Create 10 top-level resources with 4 nested levels each
      10.times do |i|
        top_id = "top_#{i}"
        resources << { id: top_id, parent_id: "root", path_part: "resource#{i}" }
        resource_map[top_id] = resources.last
        
        4.times do |j|
          nested_id = "#{top_id}_nested_#{j}"
          resources << { id: nested_id, parent_id: top_id, path_part: "nested#{j}" }
          resource_map[nested_id] = resources.last
        end
      end
      
      # Validate hierarchy
      expect {
        Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.validate_path_hierarchy(resources)
      }.not_to raise_error
      
      # Test path building for a deeply nested resource
      path = Pangea::Resources::AWS::Types::ApiGatewayResourceAttributes.build_full_path(
        "top_5_nested_3", resource_map
      )
      expect(path).to eq("/resource5/nested3")
    end
  end
end