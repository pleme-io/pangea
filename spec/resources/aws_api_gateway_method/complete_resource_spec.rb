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

# Load aws_api_gateway_method resource and types for testing
require 'pangea/resources/aws_api_gateway_method/resource'
require 'pangea/resources/aws_api_gateway_method/types'

RSpec.describe "aws_api_gateway_method resource function" do
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
  let(:resource_id) { "xyz789uvw012" }
  let(:authorizer_id) { "auth123def456" }

  describe "ApiGatewayMethodAttributes validation" do
    it "accepts basic method with required attributes" do
      method = Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "GET"
      })
      
      expect(method.rest_api_id).to eq(rest_api_id)
      expect(method.resource_id).to eq(resource_id)
      expect(method.http_method).to eq("GET")
      expect(method.authorization).to eq("NONE")
      expect(method.api_key_required).to be false
      expect(method.requires_authorization?).to be false
      expect(method.cors_enabled?).to be false
    end
    
    it "accepts all valid HTTP methods" do
      valid_methods = ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'HEAD', 'PATCH', 'ANY']
      
      valid_methods.each do |method|
        expect {
          Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
            rest_api_id: rest_api_id,
            resource_id: resource_id,
            http_method: method
          })
        }.not_to raise_error, "Failed for method: #{method}"
      end
    end
    
    it "accepts all valid authorization types" do
      valid_auth_types = ['NONE', 'AWS_IAM', 'CUSTOM', 'COGNITO_USER_POOLS']
      
      valid_auth_types.each do |auth_type|
        attributes = {
          rest_api_id: rest_api_id,
          resource_id: resource_id,
          http_method: "GET",
          authorization: auth_type
        }
        
        # Add authorizer_id for types that require it
        if ['CUSTOM', 'COGNITO_USER_POOLS'].include?(auth_type)
          attributes[:authorizer_id] = authorizer_id
        end
        
        expect {
          Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new(attributes)
        }.not_to raise_error, "Failed for authorization type: #{auth_type}"
      end
    end
    
    it "accepts method with IAM authorization" do
      method = Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "POST",
        authorization: "AWS_IAM"
      })
      
      expect(method.authorization).to eq("AWS_IAM")
      expect(method.requires_authorization?).to be true
      expect(method.is_iam_authorized?).to be true
      expect(method.is_cognito_authorized?).to be false
      expect(method.is_custom_authorized?).to be false
    end
    
    it "accepts method with custom authorization" do
      method = Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "POST",
        authorization: "CUSTOM",
        authorizer_id: authorizer_id
      })
      
      expect(method.authorization).to eq("CUSTOM")
      expect(method.authorizer_id).to eq(authorizer_id)
      expect(method.requires_authorization?).to be true
      expect(method.is_custom_authorized?).to be true
      expect(method.is_iam_authorized?).to be false
      expect(method.is_cognito_authorized?).to be false
    end
    
    it "accepts method with Cognito User Pool authorization" do
      method = Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "POST",
        authorization: "COGNITO_USER_POOLS",
        authorizer_id: authorizer_id,
        authorization_scopes: ["read", "write"]
      })
      
      expect(method.authorization).to eq("COGNITO_USER_POOLS")
      expect(method.authorizer_id).to eq(authorizer_id)
      expect(method.authorization_scopes).to eq(["read", "write"])
      expect(method.requires_authorization?).to be true
      expect(method.is_cognito_authorized?).to be true
      expect(method.is_iam_authorized?).to be false
      expect(method.is_custom_authorized?).to be false
    end
    
    it "accepts method with API key requirement" do
      method = Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "GET",
        api_key_required: true
      })
      
      expect(method.api_key_required).to be true
    end
    
    it "accepts method with request parameters" do
      method = Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "GET",
        request_parameters: {
          "method.request.path.id" => true,
          "method.request.querystring.page" => false,
          "method.request.header.Authorization" => true
        }
      })
      
      expect(method.request_parameters).to include(
        "method.request.path.id" => true,
        "method.request.querystring.page" => false,
        "method.request.header.Authorization" => true
      )
    end
    
    it "accepts method with request models" do
      method = Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "POST",
        request_models: {
          "application/json" => "UserModel",
          "application/xml" => "UserXmlModel"
        }
      })
      
      expect(method.request_models).to include(
        "application/json" => "UserModel",
        "application/xml" => "UserXmlModel"
      )
      expect(method.has_request_validation?).to be true
    end
    
    it "accepts method with request validator" do
      method = Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "POST",
        request_validator_id: "validator123"
      })
      
      expect(method.request_validator_id).to eq("validator123")
      expect(method.has_request_validation?).to be true
    end
    
    it "accepts method with operation name" do
      method = Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "GET",
        operation_name: "getUserById"
      })
      
      expect(method.operation_name).to eq("getUserById")
    end
    
    it "identifies OPTIONS method as CORS enabled" do
      method = Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "OPTIONS"
      })
      
      expect(method.cors_enabled?).to be true
    end
    
    it "rejects invalid HTTP method" do
      expect {
        Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
          rest_api_id: rest_api_id,
          resource_id: resource_id,
          http_method: "INVALID"
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "rejects invalid authorization type" do
      expect {
        Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
          rest_api_id: rest_api_id,
          resource_id: resource_id,
          http_method: "GET",
          authorization: "INVALID"
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "requires authorizer_id for CUSTOM authorization" do
      expect {
        Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
          rest_api_id: rest_api_id,
          resource_id: resource_id,
          http_method: "GET",
          authorization: "CUSTOM"
        })
      }.to raise_error(Dry::Struct::Error, /authorizer_id is required when authorization is CUSTOM/)
    end
    
    it "requires authorizer_id for COGNITO_USER_POOLS authorization" do
      expect {
        Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
          rest_api_id: rest_api_id,
          resource_id: resource_id,
          http_method: "GET",
          authorization: "COGNITO_USER_POOLS"
        })
      }.to raise_error(Dry::Struct::Error, /authorizer_id is required when authorization is COGNITO_USER_POOLS/)
    end
    
    it "accepts empty authorizer_id for NONE and AWS_IAM authorization" do
      ['NONE', 'AWS_IAM'].each do |auth_type|
        expect {
          Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
            rest_api_id: rest_api_id,
            resource_id: resource_id,
            http_method: "GET",
            authorization: auth_type
          })
        }.not_to raise_error, "Should accept empty authorizer_id for #{auth_type}"
      end
    end
    
    it "restricts authorization_scopes to COGNITO_USER_POOLS" do
      ['NONE', 'AWS_IAM', 'CUSTOM'].each do |auth_type|
        attributes = {
          rest_api_id: rest_api_id,
          resource_id: resource_id,
          http_method: "GET",
          authorization: auth_type,
          authorization_scopes: ["read", "write"]
        }
        
        # Add authorizer_id for CUSTOM
        attributes[:authorizer_id] = authorizer_id if auth_type == 'CUSTOM'
        
        expect {
          Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new(attributes)
        }.to raise_error(Dry::Struct::Error, /authorization_scopes can only be used with COGNITO_USER_POOLS/), "Should reject scopes for #{auth_type}"
      end
    end
    
    it "validates request parameter format" do
      valid_parameters = [
        "method.request.path.id",
        "method.request.querystring.page",
        "method.request.header.Authorization",
        "method.request.multivalueheader.X-Custom",
        "method.request.multivaluequerystring.tags"
      ]
      
      valid_parameters.each do |param|
        expect {
          Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
            rest_api_id: rest_api_id,
            resource_id: resource_id,
            http_method: "GET",
            request_parameters: { param => true }
          })
        }.not_to raise_error, "Should accept valid parameter: #{param}"
      end
    end
    
    it "rejects invalid request parameter format" do
      invalid_parameters = [
        "request.path.id",
        "method.path.id",
        "method.request.invalid.id",
        "method.request..id",
        "invalid.format"
      ]
      
      invalid_parameters.each do |param|
        expect {
          Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
            rest_api_id: rest_api_id,
            resource_id: resource_id,
            http_method: "GET",
            request_parameters: { param => true }
          })
        }.to raise_error(Dry::Struct::Error, /Invalid request parameter format/), "Should reject invalid parameter: #{param}"
      end
    end
    
    it "validates content type format for request models" do
      valid_content_types = [
        "application/json",
        "application/xml",
        "text/plain",
        "multipart/form-data",
        "application/vnd.api+json"
      ]
      
      valid_content_types.each do |content_type|
        expect {
          Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
            rest_api_id: rest_api_id,
            resource_id: resource_id,
            http_method: "POST",
            request_models: { content_type => "Model" }
          })
        }.not_to raise_error, "Should accept valid content type: #{content_type}"
      end
    end
    
    it "rejects invalid content type format for request models" do
      invalid_content_types = [
        "invalid",
        "application",
        "/json",
        "application/",
        "text with spaces"
      ]
      
      invalid_content_types.each do |content_type|
        expect {
          Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
            rest_api_id: rest_api_id,
            resource_id: resource_id,
            http_method: "POST",
            request_models: { content_type => "Model" }
          })
        }.to raise_error(Dry::Struct::Error, /Invalid content type format/), "Should reject invalid content type: #{content_type}"
      end
    end
    
    it "accepts string keys in attributes" do
      method = Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
        "rest_api_id" => rest_api_id,
        "resource_id" => resource_id,
        "http_method" => "GET",
        "authorization" => "AWS_IAM"
      })
      
      expect(method.rest_api_id).to eq(rest_api_id)
      expect(method.authorization).to eq("AWS_IAM")
    end
  end
  
  describe "aws_api_gateway_method function" do
    it "creates API Gateway method with basic configuration" do
      result = test_instance.aws_api_gateway_method(:get_users, {
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "GET"
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.type).to eq("aws_api_gateway_method")
      expect(result.name).to eq(:get_users)
    end
    
    it "creates method with IAM authorization" do
      result = test_instance.aws_api_gateway_method(:post_users, {
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "POST",
        authorization: "AWS_IAM"
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.is_iam_authorized?).to be true
      expect(result.requires_authorization?).to be true
    end
    
    it "creates method with custom authorization" do
      result = test_instance.aws_api_gateway_method(:secure_endpoint, {
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "POST",
        authorization: "CUSTOM",
        authorizer_id: authorizer_id
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.is_custom_authorized?).to be true
      expect(result.requires_authorization?).to be true
    end
    
    it "creates method with Cognito authorization and scopes" do
      result = test_instance.aws_api_gateway_method(:cognito_endpoint, {
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "POST",
        authorization: "COGNITO_USER_POOLS",
        authorizer_id: authorizer_id,
        authorization_scopes: ["read", "write"]
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.is_cognito_authorized?).to be true
      expect(result.requires_authorization?).to be true
    end
    
    it "creates CORS OPTIONS method" do
      result = test_instance.aws_api_gateway_method(:cors_options, {
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "OPTIONS"
      })
      
      expect(result.cors_enabled?).to be true
    end
    
    it "validates attributes through dry-struct" do
      expect {
        test_instance.aws_api_gateway_method(:invalid, {
          rest_api_id: rest_api_id,
          resource_id: resource_id,
          http_method: "INVALID"
        })
      }.to raise_error(Dry::Struct::Error)
    end
  end
  
  describe "computed properties" do
    it "correctly identifies authorization requirements" do
      none_method = Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "GET",
        authorization: "NONE"
      })
      
      iam_method = Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "GET",
        authorization: "AWS_IAM"
      })
      
      expect(none_method.requires_authorization?).to be false
      expect(iam_method.requires_authorization?).to be true
    end
    
    it "correctly identifies authorization types" do
      iam_method = Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "GET",
        authorization: "AWS_IAM"
      })
      
      custom_method = Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "GET",
        authorization: "CUSTOM",
        authorizer_id: authorizer_id
      })
      
      cognito_method = Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "GET",
        authorization: "COGNITO_USER_POOLS",
        authorizer_id: authorizer_id
      })
      
      expect(iam_method.is_iam_authorized?).to be true
      expect(iam_method.is_custom_authorized?).to be false
      expect(iam_method.is_cognito_authorized?).to be false
      
      expect(custom_method.is_custom_authorized?).to be true
      expect(custom_method.is_iam_authorized?).to be false
      expect(custom_method.is_cognito_authorized?).to be false
      
      expect(cognito_method.is_cognito_authorized?).to be true
      expect(cognito_method.is_iam_authorized?).to be false
      expect(cognito_method.is_custom_authorized?).to be false
    end
    
    it "correctly identifies request validation" do
      no_validation_method = Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "GET"
      })
      
      model_validation_method = Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "POST",
        request_models: { "application/json" => "UserModel" }
      })
      
      validator_method = Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "POST",
        request_validator_id: "validator123"
      })
      
      expect(no_validation_method.has_request_validation?).to be false
      expect(model_validation_method.has_request_validation?).to be true
      expect(validator_method.has_request_validation?).to be true
    end
    
    it "correctly identifies CORS methods" do
      options_method = Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "OPTIONS"
      })
      
      get_method = Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "GET"
      })
      
      expect(options_method.cors_enabled?).to be true
      expect(get_method.cors_enabled?).to be false
    end
  end
  
  describe "helper methods" do
    it "builds request parameters correctly" do
      param_name, required = Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.build_request_parameter('path', 'id', true)
      
      expect(param_name).to eq("method.request.path.id")
      expect(required).to be true
    end
    
    it "validates parameter location" do
      valid_locations = ['path', 'querystring', 'header', 'multivalueheader', 'multivaluequerystring']
      
      valid_locations.each do |location|
        expect {
          Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.build_request_parameter(location, 'test')
        }.not_to raise_error, "Should accept location: #{location}"
      end
      
      expect {
        Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.build_request_parameter('invalid', 'test')
      }.to raise_error(ArgumentError, /Invalid location/)
    end
    
    it "provides common request parameters" do
      common_params = Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.common_request_parameters
      
      expect(common_params).to be_a(Hash)
      expect(common_params).to have_key(:authorization)
      expect(common_params).to have_key(:content_type)
      expect(common_params).to have_key(:page)
      expect(common_params).to have_key(:id)
      
      auth_param = common_params[:authorization]
      expect(auth_param[0]).to eq("method.request.header.Authorization")
      expect(auth_param[1]).to be true
    end
    
    it "provides common content types" do
      common_types = Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.common_content_types
      
      expect(common_types).to be_a(Hash)
      expect(common_types[:json]).to eq('application/json')
      expect(common_types[:xml]).to eq('application/xml')
      expect(common_types[:form]).to eq('application/x-www-form-urlencoded')
      expect(common_types[:multipart]).to eq('multipart/form-data')
    end
  end
  
  describe "RESTful patterns" do
    it "supports standard CRUD operations" do
      # Create (POST /users)
      create_method = Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
        rest_api_id: rest_api_id,
        resource_id: "users_resource",
        http_method: "POST",
        operation_name: "createUser"
      })
      
      # Read (GET /users/{id})
      read_method = Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
        rest_api_id: rest_api_id,
        resource_id: "user_by_id_resource",
        http_method: "GET",
        operation_name: "getUserById",
        request_parameters: {
          "method.request.path.id" => true
        }
      })
      
      # Update (PUT /users/{id})
      update_method = Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
        rest_api_id: rest_api_id,
        resource_id: "user_by_id_resource",
        http_method: "PUT",
        operation_name: "updateUser"
      })
      
      # Delete (DELETE /users/{id})
      delete_method = Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
        rest_api_id: rest_api_id,
        resource_id: "user_by_id_resource",
        http_method: "DELETE",
        operation_name: "deleteUser"
      })
      
      expect(create_method.operation_name).to eq("createUser")
      expect(read_method.operation_name).to eq("getUserById")
      expect(update_method.operation_name).to eq("updateUser")
      expect(delete_method.operation_name).to eq("deleteUser")
    end
    
    it "supports collection listing with pagination" do
      list_method = Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
        rest_api_id: rest_api_id,
        resource_id: "users_resource",
        http_method: "GET",
        operation_name: "listUsers",
        request_parameters: {
          "method.request.querystring.page" => false,
          "method.request.querystring.limit" => false,
          "method.request.querystring.sort" => false
        }
      })
      
      expect(list_method.operation_name).to eq("listUsers")
      expect(list_method.request_parameters).to include(
        "method.request.querystring.page" => false,
        "method.request.querystring.limit" => false
      )
    end
    
    it "supports search endpoints" do
      search_method = Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
        rest_api_id: rest_api_id,
        resource_id: "search_resource",
        http_method: "GET",
        operation_name: "searchUsers",
        request_parameters: {
          "method.request.querystring.q" => true,
          "method.request.querystring.filter" => false
        }
      })
      
      expect(search_method.operation_name).to eq("searchUsers")
      expect(search_method.request_parameters["method.request.querystring.q"]).to be true
    end
  end
  
  describe "edge cases and error conditions" do
    it "handles nil attributes gracefully" do
      expect {
        Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new(nil)
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "handles empty hash gracefully" do
      expect {
        Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({})
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates minimum required attributes" do
      expect {
        Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
          rest_api_id: rest_api_id
        })
      }.to raise_error(Dry::Struct::Error)
      
      expect {
        Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
          rest_api_id: rest_api_id,
          resource_id: resource_id
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "handles empty strings properly" do
      expect {
        Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
          rest_api_id: "",
          resource_id: resource_id,
          http_method: "GET"
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "accepts complex request parameter configurations" do
      method = Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "POST",
        request_parameters: {
          "method.request.path.userId" => true,
          "method.request.querystring.expand" => false,
          "method.request.header.Content-Type" => true,
          "method.request.header.Authorization" => true,
          "method.request.multivalueheader.X-Custom-Headers" => false
        }
      })
      
      expect(method.request_parameters.size).to eq(5)
    end
    
    it "accepts multiple request models" do
      method = Pangea::Resources::AWS::Types::ApiGatewayMethodAttributes.new({
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "POST",
        request_models: {
          "application/json" => "UserJsonModel",
          "application/xml" => "UserXmlModel",
          "application/x-www-form-urlencoded" => "UserFormModel"
        }
      })
      
      expect(method.request_models.size).to eq(3)
      expect(method.has_request_validation?).to be true
    end
  end
end