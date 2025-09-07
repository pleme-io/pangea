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

# Load aws_api_gateway_rest_api resource and types for testing
require 'pangea/resources/aws_api_gateway_rest_api/resource'
require 'pangea/resources/aws_api_gateway_rest_api/types'

RSpec.describe "aws_api_gateway_rest_api resource function" do
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
  
  describe "ApiGatewayRestApiAttributes validation" do
    it "accepts minimal valid configuration" do
      api = Pangea::Resources::AWS::Types::ApiGatewayRestApiAttributes.new({
        name: "my-api",
        tags: {}
      })
      
      expect(api.name).to eq("my-api")
      expect(api.minimum_tls_version).to eq("TLS_1_2")
      expect(api.api_key_source).to eq("HEADER")
      expect(api.disable_execute_api_endpoint).to eq(false)
    end
    
    it "accepts full configuration" do
      api = Pangea::Resources::AWS::Types::ApiGatewayRestApiAttributes.new({
        name: "complex-api",
        description: "A complex REST API",
        endpoint_configuration: {
          types: ["REGIONAL"],
          vpc_endpoint_ids: []
        },
        version: "v1.0",
        binary_media_types: ["image/png", "image/jpeg"],
        minimum_compression_size: 1024,
        api_key_source: "AUTHORIZER",
        policy: '{"Version":"2012-10-17","Statement":[]}',
        disable_execute_api_endpoint: true,
        custom_domain_name: "api.example.com",
        tags: {
          Environment: "production",
          Team: "platform"
        }
      })
      
      expect(api.description).to eq("A complex REST API")
      expect(api.version).to eq("v1.0")
      expect(api.binary_media_types).to have(2).items
      expect(api.minimum_compression_size).to eq(1024)
      expect(api.api_key_source).to eq("AUTHORIZER")
      expect(api.disable_execute_api_endpoint).to eq(true)
      expect(api.custom_domain_name).to eq("api.example.com")
      expect(api.tags[:Environment]).to eq("production")
    end
    
    it "validates name format" do
      expect {
        Pangea::Resources::AWS::Types::ApiGatewayRestApiAttributes.new({
          name: "my api with spaces",
          tags: {}
        })
      }.to raise_error(Dry::Struct::Error, /API name must contain only alphanumeric characters/)
    end
    
    it "validates endpoint types" do
      expect {
        Pangea::Resources::AWS::Types::ApiGatewayRestApiAttributes.new({
          name: "test-api",
          endpoint_configuration: {
            types: ["INVALID"]
          },
          tags: {}
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
    
    it "validates private API requires VPC endpoints" do
      expect {
        Pangea::Resources::AWS::Types::ApiGatewayRestApiAttributes.new({
          name: "private-api",
          endpoint_configuration: {
            types: ["PRIVATE"],
            vpc_endpoint_ids: []
          },
          tags: {}
        })
      }.to raise_error(Dry::Struct::Error, /VPC endpoint IDs must be provided for PRIVATE API type/)
    end
    
    it "accepts private API with VPC endpoints" do
      api = Pangea::Resources::AWS::Types::ApiGatewayRestApiAttributes.new({
        name: "private-api",
        endpoint_configuration: {
          types: ["PRIVATE"],
          vpc_endpoint_ids: ["vpce-12345678"]
        },
        tags: {}
      })
      
      expect(api.endpoint_configuration[:types]).to include("PRIVATE")
      expect(api.endpoint_configuration[:vpc_endpoint_ids]).to include("vpce-12345678")
    end
    
    it "validates minimum compression size" do
      expect {
        Pangea::Resources::AWS::Types::ApiGatewayRestApiAttributes.new({
          name: "test-api",
          minimum_compression_size: 11000000,
          tags: {}
        })
      }.to raise_error(Dry::Struct::Error, /Minimum compression size must be between 0 and 10485760 bytes/)
    end
    
    it "validates binary media type format" do
      expect {
        Pangea::Resources::AWS::Types::ApiGatewayRestApiAttributes.new({
          name: "test-api",
          binary_media_types: ["invalid-format"],
          tags: {}
        })
      }.to raise_error(Dry::Struct::Error, /Invalid binary media type format/)
    end
    
    it "accepts valid binary media types" do
      api = Pangea::Resources::AWS::Types::ApiGatewayRestApiAttributes.new({
        name: "binary-api",
        binary_media_types: ["image/png", "application/pdf", "multipart/form-data"],
        tags: {}
      })
      
      expect(api.binary_media_types).to have(3).items
      expect(api.binary_media_types).to include("image/png", "application/pdf", "multipart/form-data")
    end
    
    it "validates TLS version" do
      expect {
        Pangea::Resources::AWS::Types::ApiGatewayRestApiAttributes.new({
          name: "test-api",
          minimum_tls_version: "SSL_3_0",
          tags: {}
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
    
    it "validates API key source" do
      expect {
        Pangea::Resources::AWS::Types::ApiGatewayRestApiAttributes.new({
          name: "test-api",
          api_key_source: "QUERY_STRING",
          tags: {}
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
  end
  
  describe "computed properties" do
    let(:edge_api) do
      Pangea::Resources::AWS::Types::ApiGatewayRestApiAttributes.new({
        name: "edge-api",
        endpoint_configuration: {
          types: ["EDGE"]
        },
        tags: {}
      })
    end
    
    let(:regional_api) do
      Pangea::Resources::AWS::Types::ApiGatewayRestApiAttributes.new({
        name: "regional-api",
        endpoint_configuration: {
          types: ["REGIONAL"]
        },
        tags: {}
      })
    end
    
    let(:private_api) do
      Pangea::Resources::AWS::Types::ApiGatewayRestApiAttributes.new({
        name: "private-api",
        endpoint_configuration: {
          types: ["PRIVATE"],
          vpc_endpoint_ids: ["vpce-12345678"]
        },
        tags: {}
      })
    end
    
    it "detects endpoint type" do
      expect(edge_api.is_edge_optimized?).to eq(true)
      expect(edge_api.is_regional?).to eq(false)
      expect(edge_api.is_private?).to eq(false)
      
      expect(regional_api.is_edge_optimized?).to eq(false)
      expect(regional_api.is_regional?).to eq(true)
      expect(regional_api.is_private?).to eq(false)
      
      expect(private_api.is_edge_optimized?).to eq(false)
      expect(private_api.is_regional?).to eq(false)
      expect(private_api.is_private?).to eq(true)
    end
    
    it "detects binary content support" do
      binary_api = Pangea::Resources::AWS::Types::ApiGatewayRestApiAttributes.new({
        name: "binary-api",
        binary_media_types: ["image/png"],
        tags: {}
      })
      
      expect(binary_api.supports_binary_content?).to eq(true)
      expect(regional_api.supports_binary_content?).to eq(false)
    end
    
    it "detects custom domain" do
      custom_domain_api = Pangea::Resources::AWS::Types::ApiGatewayRestApiAttributes.new({
        name: "custom-api",
        custom_domain_name: "api.example.com",
        tags: {}
      })
      
      expect(custom_domain_api.has_custom_domain?).to eq(true)
      expect(regional_api.has_custom_domain?).to eq(false)
    end
    
    it "provides cost estimation" do
      expect(edge_api.estimated_monthly_cost).to be_a(Float)
      expect(edge_api.estimated_monthly_cost).to be > 0
    end
    
    it "provides common binary types" do
      common_types = Pangea::Resources::AWS::Types::ApiGatewayRestApiAttributes.common_binary_types
      expect(common_types).to include("image/png", "image/jpeg", "application/pdf", "multipart/form-data")
    end
  end
  
  describe "aws_api_gateway_rest_api function" do
    it "creates basic REST API" do
      result = test_instance.aws_api_gateway_rest_api(:my_api, {
        name: "my-api",
        tags: {}
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.type).to eq('aws_api_gateway_rest_api')
      expect(result.name).to eq(:my_api)
      expect(result.id).to eq("${aws_api_gateway_rest_api.my_api.id}")
    end
    
    it "creates REST API with description" do
      result = test_instance.aws_api_gateway_rest_api(:described_api, {
        name: "described-api",
        description: "This is a test API for demonstration",
        tags: {}
      })
      
      expect(result.resource_attributes[:description]).to eq("This is a test API for demonstration")
    end
    
    it "creates edge-optimized API" do
      result = test_instance.aws_api_gateway_rest_api(:edge_api, {
        name: "edge-api",
        endpoint_configuration: {
          types: ["EDGE"]
        },
        tags: {}
      })
      
      expect(result.is_edge_optimized?).to eq(true)
      expect(result.is_regional?).to eq(false)
    end
    
    it "creates regional API" do
      result = test_instance.aws_api_gateway_rest_api(:regional_api, {
        name: "regional-api",
        endpoint_configuration: {
          types: ["REGIONAL"]
        },
        tags: {}
      })
      
      expect(result.is_regional?).to eq(true)
      expect(result.is_edge_optimized?).to eq(false)
    end
    
    it "creates private API with VPC endpoints" do
      result = test_instance.aws_api_gateway_rest_api(:private_api, {
        name: "private-api",
        endpoint_configuration: {
          types: ["PRIVATE"],
          vpc_endpoint_ids: ["vpce-12345678", "vpce-87654321"]
        },
        tags: {}
      })
      
      expect(result.is_private?).to eq(true)
      expect(result.resource_attributes[:endpoint_configuration][:vpc_endpoint_ids]).to have(2).items
    end
    
    it "creates API with binary media types" do
      result = test_instance.aws_api_gateway_rest_api(:binary_api, {
        name: "binary-api",
        binary_media_types: ["image/png", "image/jpeg", "application/pdf"],
        tags: {}
      })
      
      expect(result.supports_binary_content?).to eq(true)
      expect(result.resource_attributes[:binary_media_types]).to have(3).items
    end
    
    it "creates API with compression" do
      result = test_instance.aws_api_gateway_rest_api(:compressed_api, {
        name: "compressed-api",
        minimum_compression_size: 5120,
        tags: {}
      })
      
      expect(result.resource_attributes[:minimum_compression_size]).to eq(5120)
    end
    
    it "creates API with security settings" do
      result = test_instance.aws_api_gateway_rest_api(:secure_api, {
        name: "secure-api",
        minimum_tls_version: "TLS_1_2",
        api_key_source: "AUTHORIZER",
        policy: '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":"*","Action":"execute-api:Invoke","Resource":"*"}]}',
        tags: {}
      })
      
      expect(result.resource_attributes[:minimum_tls_version]).to eq("TLS_1_2")
      expect(result.resource_attributes[:api_key_source]).to eq("AUTHORIZER")
      expect(result.resource_attributes[:policy]).to include("execute-api:Invoke")
    end
    
    it "creates API with version and clone" do
      result = test_instance.aws_api_gateway_rest_api(:versioned_api, {
        name: "versioned-api",
        version: "v2.0",
        clone_from: "arn:aws:apigateway:us-east-1::/restapis/abcdef123",
        tags: {}
      })
      
      expect(result.resource_attributes[:version]).to eq("v2.0")
      expect(result.resource_attributes[:clone_from]).to eq("arn:aws:apigateway:us-east-1::/restapis/abcdef123")
    end
    
    it "creates API with OpenAPI body" do
      openapi_spec = '{"openapi":"3.0.0","info":{"title":"My API","version":"1.0.0"}}'
      
      result = test_instance.aws_api_gateway_rest_api(:openapi_api, {
        name: "openapi-api",
        body: openapi_spec,
        tags: {}
      })
      
      expect(result.resource_attributes[:body]).to eq(openapi_spec)
    end
    
    it "creates API with disabled execute endpoint" do
      result = test_instance.aws_api_gateway_rest_api(:disabled_api, {
        name: "disabled-api",
        disable_execute_api_endpoint: true,
        custom_domain_name: "api.example.com",
        tags: {}
      })
      
      expect(result.resource_attributes[:disable_execute_api_endpoint]).to eq(true)
      expect(result.has_custom_domain?).to eq(true)
    end
    
    it "creates API with tags" do
      result = test_instance.aws_api_gateway_rest_api(:tagged_api, {
        name: "tagged-api",
        tags: {
          Environment: "production",
          Application: "web-service",
          Team: "platform",
          CostCenter: "engineering"
        }
      })
      
      expect(result.resource_attributes[:tags]).to have(4).items
      expect(result.resource_attributes[:tags][:Environment]).to eq("production")
      expect(result.resource_attributes[:tags][:Team]).to eq("platform")
    end
    
    it "provides correct outputs" do
      result = test_instance.aws_api_gateway_rest_api(:test, {
        name: "test-api",
        tags: {}
      })
      
      expect(result.id).to eq("${aws_api_gateway_rest_api.test.id}")
      expect(result.root_resource_id).to eq("${aws_api_gateway_rest_api.test.root_resource_id}")
      expect(result.created_date).to eq("${aws_api_gateway_rest_api.test.created_date}")
      expect(result.execution_arn).to eq("${aws_api_gateway_rest_api.test.execution_arn}")
      expect(result.arn).to eq("${aws_api_gateway_rest_api.test.arn}")
      expect(result.tags_all).to eq("${aws_api_gateway_rest_api.test.tags_all}")
    end
    
    it "provides computed properties" do
      result = test_instance.aws_api_gateway_rest_api(:test, {
        name: "test-api",
        endpoint_configuration: {
          types: ["REGIONAL"]
        },
        binary_media_types: ["image/png"],
        tags: {}
      })
      
      expect(result.is_edge_optimized?).to eq(false)
      expect(result.is_regional?).to eq(true)
      expect(result.is_private?).to eq(false)
      expect(result.supports_binary_content?).to eq(true)
      expect(result.has_custom_domain?).to eq(false)
      expect(result.estimated_monthly_cost).to be_a(Float)
    end
  end
  
  describe "API patterns" do
    it "creates public REST API pattern" do
      result = test_instance.aws_api_gateway_rest_api(:public_api, {
        name: "public-rest-api",
        description: "Public-facing REST API",
        endpoint_configuration: {
          types: ["EDGE"]
        },
        minimum_tls_version: "TLS_1_2",
        tags: {
          Access: "public",
          Type: "rest"
        }
      })
      
      expect(result.is_edge_optimized?).to eq(true)
      expect(result.resource_attributes[:minimum_tls_version]).to eq("TLS_1_2")
    end
    
    it "creates microservice API pattern" do
      result = test_instance.aws_api_gateway_rest_api(:microservice_api, {
        name: "user-service-api",
        description: "User microservice API",
        endpoint_configuration: {
          types: ["REGIONAL"]
        },
        api_key_source: "HEADER",
        tags: {
          Service: "user-service",
          Type: "microservice"
        }
      })
      
      expect(result.is_regional?).to eq(true)
      expect(result.resource_attributes[:api_key_source]).to eq("HEADER")
    end
    
    it "creates file upload API pattern" do
      result = test_instance.aws_api_gateway_rest_api(:upload_api, {
        name: "file-upload-api",
        description: "API for file uploads",
        binary_media_types: ["image/png", "image/jpeg", "image/gif", "application/pdf", "multipart/form-data"],
        minimum_compression_size: 10240,
        tags: {
          Purpose: "file-upload",
          BinaryContent: "true"
        }
      })
      
      expect(result.supports_binary_content?).to eq(true)
      expect(result.resource_attributes[:binary_media_types]).to have(5).items
      expect(result.resource_attributes[:minimum_compression_size]).to eq(10240)
    end
    
    it "creates internal API pattern" do
      result = test_instance.aws_api_gateway_rest_api(:internal_api, {
        name: "internal-api",
        description: "Internal VPC-only API",
        endpoint_configuration: {
          types: ["PRIVATE"],
          vpc_endpoint_ids: ["vpce-12345678"]
        },
        disable_execute_api_endpoint: true,
        policy: '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":"*","Action":"execute-api:Invoke","Resource":"*","Condition":{"StringEquals":{"aws:SourceVpce":"vpce-12345678"}}}]}',
        tags: {
          Access: "internal",
          Network: "vpc-only"
        }
      })
      
      expect(result.is_private?).to eq(true)
      expect(result.resource_attributes[:disable_execute_api_endpoint]).to eq(true)
    end
  end
end