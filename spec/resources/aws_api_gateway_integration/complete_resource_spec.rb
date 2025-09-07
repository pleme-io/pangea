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
require 'pangea/resources/aws_api_gateway_integration/resource'
require 'pangea/resources/aws_api_gateway_integration/types'

RSpec.describe 'aws_api_gateway_integration resource function' do
  let(:test_class) do
    Class.new do
      include Pangea::Resources::AWS
      
      def initialize
        @resources = []
      end
      
      def resource(type, name)
        resource_data = { type: type, name: name, attributes: {} }
        @resources << resource_data
        yield MockResourceBuilder.new(resource_data[:attributes]) if block_given?
        resource_data
      end
      
      def get_resources
        @resources
      end
    end
  end
  
  let(:mock_resource_builder) do
    Class.new do
      def initialize(attributes)
        @attributes = attributes
      end
      
      def method_missing(method_name, *args)
        if args.any?
          @attributes[method_name] = args.first
        end
        
        if block_given?
          nested_builder = self.class.new({})
          yield nested_builder
          @attributes[method_name] = nested_builder.instance_variable_get(:@attributes)
        end
      end
      
      def respond_to_missing?(method_name, include_private = false)
        true
      end
    end
  end
  
  before do
    stub_const('MockResourceBuilder', mock_resource_builder)
  end

  let(:test_instance) { test_class.new }
  
  describe 'AWS API Gateway Integration Types::ApiGatewayIntegrationAttributes' do
    describe 'basic attribute validation' do
      it 'creates integration with required attributes' do
        attrs = Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
          rest_api_id: 'api-123',
          resource_id: 'resource-456',
          http_method: 'GET',
          type: 'MOCK'
        })
        
        expect(attrs.rest_api_id).to eq('api-123')
        expect(attrs.resource_id).to eq('resource-456')
        expect(attrs.http_method).to eq('GET')
        expect(attrs.type).to eq('MOCK')
      end
      
      it 'applies default values' do
        attrs = Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
          rest_api_id: 'api-123',
          resource_id: 'resource-456',
          http_method: 'GET',
          type: 'MOCK'
        })
        
        expect(attrs.connection_type).to eq('INTERNET')
        expect(attrs.passthrough_behavior).to eq('WHEN_NO_MATCH')
        expect(attrs.timeout_milliseconds).to eq(29000)
        expect(attrs.cache_key_parameters).to eq([])
        expect(attrs.request_templates).to eq({})
        expect(attrs.request_parameters).to eq({})
      end
      
      it 'validates HTTP method enum' do
        valid_methods = ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'HEAD', 'PATCH', 'ANY']
        
        valid_methods.each do |method|
          expect {
            Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
              rest_api_id: 'api-123',
              resource_id: 'resource-456',
              http_method: method,
              type: 'MOCK'
            })
          }.not_to raise_error
        end
        
        expect {
          Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
            rest_api_id: 'api-123',
            resource_id: 'resource-456',
            http_method: 'INVALID',
            type: 'MOCK'
          })
        }.to raise_error(Dry::Struct::Error)
      end
      
      it 'validates integration type enum' do
        valid_types = ['MOCK', 'HTTP', 'HTTP_PROXY', 'AWS', 'AWS_PROXY']
        
        valid_types.each do |type|
          uri = type == 'MOCK' ? nil : 'https://example.com'
          expect {
            Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
              rest_api_id: 'api-123',
              resource_id: 'resource-456', 
              http_method: 'GET',
              type: type,
              uri: uri
            })
          }.not_to raise_error
        end
        
        expect {
          Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
            rest_api_id: 'api-123',
            resource_id: 'resource-456',
            http_method: 'GET',
            type: 'INVALID'
          })
        }.to raise_error(Dry::Struct::Error)
      end
    end
    
    describe 'integration type specific validation' do
      it 'requires URI for non-MOCK integrations' do
        ['HTTP', 'HTTP_PROXY', 'AWS', 'AWS_PROXY'].each do |type|
          expect {
            Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
              rest_api_id: 'api-123',
              resource_id: 'resource-456',
              http_method: 'GET',
              type: type
            })
          }.to raise_error(Dry::Struct::Error, /uri is required/)
        end
      end
      
      it 'does not require URI for MOCK integrations' do
        expect {
          Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
            rest_api_id: 'api-123',
            resource_id: 'resource-456',
            http_method: 'GET',
            type: 'MOCK'
          })
        }.not_to raise_error
      end
      
      it 'requires integration_http_method for HTTP and AWS integrations' do
        ['HTTP', 'AWS'].each do |type|
          expect {
            Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
              rest_api_id: 'api-123',
              resource_id: 'resource-456',
              http_method: 'GET',
              type: type,
              uri: 'https://example.com'
            })
          }.to raise_error(Dry::Struct::Error, /integration_http_method is required/)
        end
      end
      
      it 'does not require integration_http_method for proxy integrations' do
        ['HTTP_PROXY', 'AWS_PROXY'].each do |type|
          expect {
            Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
              rest_api_id: 'api-123',
              resource_id: 'resource-456',
              http_method: 'GET',
              type: type,
              uri: 'https://example.com'
            })
          }.not_to raise_error
        end
      end
    end
    
    describe 'VPC Link validation' do
      it 'requires connection_id for VPC_LINK connection type' do
        expect {
          Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
            rest_api_id: 'api-123',
            resource_id: 'resource-456',
            http_method: 'GET',
            type: 'HTTP_PROXY',
            uri: 'https://example.com',
            connection_type: 'VPC_LINK'
          })
        }.to raise_error(Dry::Struct::Error, /connection_id is required/)
      end
      
      it 'accepts connection_id with VPC_LINK' do
        expect {
          Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
            rest_api_id: 'api-123',
            resource_id: 'resource-456',
            http_method: 'GET',
            type: 'HTTP_PROXY',
            uri: 'https://example.com',
            connection_type: 'VPC_LINK',
            connection_id: 'vpc-link-123'
          })
        }.not_to raise_error
      end
    end
    
    describe 'parameter mapping validation' do
      it 'validates integration parameter format' do
        expect {
          Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
            rest_api_id: 'api-123',
            resource_id: 'resource-456',
            http_method: 'GET',
            type: 'MOCK',
            request_parameters: {
              'invalid.parameter' => 'method.request.path.id'
            }
          })
        }.to raise_error(Dry::Struct::Error, /Invalid integration parameter format/)
      end
      
      it 'accepts valid integration parameter formats' do
        valid_params = {
          'integration.request.path.id' => 'method.request.path.userId',
          'integration.request.querystring.version' => 'method.request.querystring.version',
          'integration.request.header.Content-Type' => "'application/json'",
          'integration.request.multivalueheader.Accept' => 'method.request.multivalueheader.Accept'
        }
        
        expect {
          Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
            rest_api_id: 'api-123',
            resource_id: 'resource-456',
            http_method: 'GET',
            type: 'MOCK',
            request_parameters: valid_params
          })
        }.not_to raise_error
      end
      
      it 'validates method parameter references' do
        expect {
          Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
            rest_api_id: 'api-123',
            resource_id: 'resource-456',
            http_method: 'GET',
            type: 'MOCK',
            request_parameters: {
              'integration.request.path.id' => 'invalid.reference'
            }
          })
        }.to raise_error(Dry::Struct::Error, /Invalid method parameter reference/)
      end
      
      it 'accepts valid method parameter references' do
        valid_references = {
          'integration.request.path.id' => 'method.request.path.userId',
          'integration.request.header.X-Custom' => "'static-value'",
          'integration.request.querystring.requestId' => 'context.requestId',
          'integration.request.header.Version' => 'stageVariables.version'
        }
        
        expect {
          Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
            rest_api_id: 'api-123',
            resource_id: 'resource-456',
            http_method: 'GET',
            type: 'MOCK',
            request_parameters: valid_references
          })
        }.not_to raise_error
      end
    end
    
    describe 'content handling validation' do
      it 'validates content handling values' do
        ['CONVERT_TO_BINARY', 'CONVERT_TO_TEXT'].each do |handling|
          expect {
            Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
              rest_api_id: 'api-123',
              resource_id: 'resource-456',
              http_method: 'GET',
              type: 'MOCK',
              content_handling: handling
            })
          }.not_to raise_error
        end
        
        expect {
          Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
            rest_api_id: 'api-123',
            resource_id: 'resource-456',
            http_method: 'GET',
            type: 'MOCK',
            content_handling: 'INVALID'
          })
        }.to raise_error(Dry::Struct::Error, /must be CONVERT_TO_BINARY or CONVERT_TO_TEXT/)
      end
    end
    
    describe 'timeout validation' do
      it 'enforces timeout bounds' do
        expect {
          Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
            rest_api_id: 'api-123',
            resource_id: 'resource-456',
            http_method: 'GET',
            type: 'MOCK',
            timeout_milliseconds: 30
          })
        }.to raise_error(Dry::Struct::Error)
        
        expect {
          Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
            rest_api_id: 'api-123',
            resource_id: 'resource-456',
            http_method: 'GET',
            type: 'MOCK',
            timeout_milliseconds: 30000
          })
        }.to raise_error(Dry::Struct::Error)
      end
      
      it 'accepts valid timeout values' do
        [50, 1000, 15000, 29000].each do |timeout|
          expect {
            Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
              rest_api_id: 'api-123',
              resource_id: 'resource-456',
              http_method: 'GET',
              type: 'MOCK',
              timeout_milliseconds: timeout
            })
          }.not_to raise_error
        end
      end
    end
    
    describe 'computed properties' do
      it 'detects proxy integrations' do
        proxy_attrs = Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
          rest_api_id: 'api-123',
          resource_id: 'resource-456',
          http_method: 'GET',
          type: 'HTTP_PROXY',
          uri: 'https://example.com'
        })
        
        non_proxy_attrs = Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
          rest_api_id: 'api-123',
          resource_id: 'resource-456',
          http_method: 'GET',
          type: 'HTTP',
          uri: 'https://example.com',
          integration_http_method: 'GET'
        })
        
        expect(proxy_attrs.is_proxy_integration?).to be true
        expect(non_proxy_attrs.is_proxy_integration?).to be false
      end
      
      it 'detects Lambda integrations' do
        lambda_attrs = Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
          rest_api_id: 'api-123',
          resource_id: 'resource-456',
          http_method: 'GET',
          type: 'AWS_PROXY',
          uri: 'arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123:function:test/invocations'
        })
        
        non_lambda_attrs = Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
          rest_api_id: 'api-123',
          resource_id: 'resource-456',
          http_method: 'GET',
          type: 'HTTP_PROXY',
          uri: 'https://example.com'
        })
        
        expect(lambda_attrs.is_lambda_integration?).to be true
        expect(non_lambda_attrs.is_lambda_integration?).to be false
      end
      
      it 'detects HTTP integrations' do
        http_attrs = Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
          rest_api_id: 'api-123',
          resource_id: 'resource-456',
          http_method: 'GET',
          type: 'HTTP',
          uri: 'https://example.com',
          integration_http_method: 'GET'
        })
        
        non_http_attrs = Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
          rest_api_id: 'api-123',
          resource_id: 'resource-456',
          http_method: 'GET',
          type: 'MOCK'
        })
        
        expect(http_attrs.is_http_integration?).to be true
        expect(non_http_attrs.is_http_integration?).to be false
      end
      
      it 'detects AWS service integrations' do
        aws_service_attrs = Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
          rest_api_id: 'api-123',
          resource_id: 'resource-456',
          http_method: 'GET',
          type: 'AWS',
          uri: 'arn:aws:apigateway:us-east-1:dynamodb:action/Query',
          integration_http_method: 'POST'
        })
        
        lambda_attrs = Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
          rest_api_id: 'api-123',
          resource_id: 'resource-456',
          http_method: 'GET',
          type: 'AWS',
          uri: 'arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/test/invocations',
          integration_http_method: 'POST'
        })
        
        expect(aws_service_attrs.is_aws_service_integration?).to be true
        expect(lambda_attrs.is_aws_service_integration?).to be false
      end
      
      it 'detects mock integrations' do
        mock_attrs = Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
          rest_api_id: 'api-123',
          resource_id: 'resource-456',
          http_method: 'GET',
          type: 'MOCK'
        })
        
        non_mock_attrs = Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
          rest_api_id: 'api-123',
          resource_id: 'resource-456',
          http_method: 'GET',
          type: 'HTTP',
          uri: 'https://example.com',
          integration_http_method: 'GET'
        })
        
        expect(mock_attrs.is_mock_integration?).to be true
        expect(non_mock_attrs.is_mock_integration?).to be false
      end
      
      it 'detects VPC Link usage' do
        vpc_link_attrs = Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
          rest_api_id: 'api-123',
          resource_id: 'resource-456',
          http_method: 'GET',
          type: 'HTTP_PROXY',
          uri: 'https://example.com',
          connection_type: 'VPC_LINK',
          connection_id: 'vpc-link-123'
        })
        
        internet_attrs = Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
          rest_api_id: 'api-123',
          resource_id: 'resource-456',
          http_method: 'GET',
          type: 'HTTP_PROXY',
          uri: 'https://example.com'
        })
        
        expect(vpc_link_attrs.uses_vpc_link?).to be true
        expect(internet_attrs.uses_vpc_link?).to be false
      end
      
      it 'detects caching configuration' do
        cached_attrs = Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
          rest_api_id: 'api-123',
          resource_id: 'resource-456',
          http_method: 'GET',
          type: 'MOCK',
          cache_key_parameters: ['method.request.path.id']
        })
        
        non_cached_attrs = Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
          rest_api_id: 'api-123',
          resource_id: 'resource-456',
          http_method: 'GET',
          type: 'MOCK'
        })
        
        expect(cached_attrs.has_caching?).to be true
        expect(non_cached_attrs.has_caching?).to be false
      end
      
      it 'detects IAM role requirement' do
        aws_service_attrs = Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
          rest_api_id: 'api-123',
          resource_id: 'resource-456',
          http_method: 'GET',
          type: 'AWS',
          uri: 'arn:aws:apigateway:us-east-1:dynamodb:action/Query',
          integration_http_method: 'POST'
        })
        
        lambda_attrs = Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
          rest_api_id: 'api-123',
          resource_id: 'resource-456',
          http_method: 'GET',
          type: 'AWS_PROXY',
          uri: 'arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/test/invocations'
        })
        
        expect(aws_service_attrs.requires_iam_role?).to be true
        expect(lambda_attrs.requires_iam_role?).to be false
      end
    end
    
    describe 'URI parsing' do
      it 'extracts Lambda function name from ARN' do
        attrs = Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
          rest_api_id: 'api-123',
          resource_id: 'resource-456',
          http_method: 'GET',
          type: 'AWS_PROXY',
          uri: 'arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123:function:my-function/invocations'
        })
        
        expect(attrs.lambda_function_name).to eq('my-function')
      end
      
      it 'extracts AWS service name' do
        attrs = Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.new({
          rest_api_id: 'api-123',
          resource_id: 'resource-456',
          http_method: 'GET',
          type: 'AWS',
          uri: 'arn:aws:apigateway:us-east-1:dynamodb:action/Query',
          integration_http_method: 'POST'
        })
        
        expect(attrs.aws_service_name).to eq('dynamodb')
      end
    end
    
    describe 'helper methods' do
      it 'creates Lambda proxy integration configuration' do
        config = Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.lambda_proxy_integration(
          'arn:aws:lambda:us-east-1:123:function:test',
          credentials: 'arn:aws:iam::123:role/lambda-role'
        )
        
        expect(config[:type]).to eq('AWS_PROXY')
        expect(config[:integration_http_method]).to eq('POST')
        expect(config[:uri]).to include('lambda:path/2015-03-31/functions')
        expect(config[:credentials]).to eq('arn:aws:iam::123:role/lambda-role')
      end
      
      it 'creates HTTP proxy integration configuration' do
        config = Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.http_proxy_integration('https://example.com')
        
        expect(config[:type]).to eq('HTTP_PROXY')
        expect(config[:integration_http_method]).to eq('ANY')
        expect(config[:uri]).to eq('https://example.com')
      end
      
      it 'creates mock integration configuration' do
        config = Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.mock_integration
        
        expect(config[:type]).to eq('MOCK')
        expect(config[:request_templates]).to have_key('application/json')
      end
      
      it 'creates DynamoDB integration configuration' do
        config = Pangea::Resources::AWS::Types::ApiGatewayIntegrationAttributes.dynamodb_integration(
          'users-table',
          'GetItem',
          credentials: 'arn:aws:iam::123:role/dynamodb-role'
        )
        
        expect(config[:type]).to eq('AWS')
        expect(config[:integration_http_method]).to eq('POST')
        expect(config[:uri]).to include('dynamodb:action/GetItem')
        expect(config[:credentials]).to eq('arn:aws:iam::123:role/dynamodb-role')
      end
    end
  end
  
  describe 'aws_api_gateway_integration resource function' do
    it 'creates integration resource with basic attributes' do
      result = test_instance.aws_api_gateway_integration(:test_integration, {
        rest_api_id: 'api-123',
        resource_id: 'resource-456',
        http_method: 'GET',
        type: 'MOCK'
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.type).to eq('aws_api_gateway_integration')
      expect(result.name).to eq(:test_integration)
      
      resources = test_instance.get_resources
      expect(resources.size).to eq(1)
      
      resource_data = resources.first
      expect(resource_data[:type]).to eq(:aws_api_gateway_integration)
      expect(resource_data[:name]).to eq(:test_integration)
      expect(resource_data[:attributes][:rest_api_id]).to eq('api-123')
      expect(resource_data[:attributes][:type]).to eq('MOCK')
    end
    
    it 'creates Lambda proxy integration with computed properties' do
      result = test_instance.aws_api_gateway_integration(:lambda_proxy, {
        rest_api_id: 'api-123',
        resource_id: 'resource-456',
        http_method: 'POST',
        type: 'AWS_PROXY',
        uri: 'arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123:function:test/invocations'
      })
      
      expect(result.is_proxy_integration?).to be true
      expect(result.is_lambda_integration?).to be true
      expect(result.requires_iam_role?).to be false
      expect(result.lambda_function_name).to eq('test')
    end
    
    it 'creates HTTP integration with request templates' do
      result = test_instance.aws_api_gateway_integration(:http_integration, {
        rest_api_id: 'api-123',
        resource_id: 'resource-456',
        http_method: 'POST',
        type: 'HTTP',
        uri: 'https://api.example.com/webhook',
        integration_http_method: 'POST',
        request_templates: {
          'application/json' => '{"transformed": $input.json("$")}'
        }
      })
      
      expect(result.is_http_integration?).to be true
      expect(result.is_proxy_integration?).to be false
      
      resources = test_instance.get_resources
      resource_data = resources.first
      expect(resource_data[:attributes][:request_templates]).to have_key('application/json')
    end
    
    it 'creates VPC Link integration' do
      result = test_instance.aws_api_gateway_integration(:vpc_integration, {
        rest_api_id: 'api-123',
        resource_id: 'resource-456',
        http_method: 'GET',
        type: 'HTTP_PROXY',
        uri: 'https://internal.example.com',
        connection_type: 'VPC_LINK',
        connection_id: 'vpc-link-123'
      })
      
      expect(result.uses_vpc_link?).to be true
      expect(result.connection_configuration[:type]).to eq('VPC_LINK')
      expect(result.connection_configuration[:id]).to eq('vpc-link-123')
    end
    
    it 'creates AWS service integration' do
      result = test_instance.aws_api_gateway_integration(:dynamodb_integration, {
        rest_api_id: 'api-123',
        resource_id: 'resource-456',
        http_method: 'POST',
        type: 'AWS',
        uri: 'arn:aws:apigateway:us-east-1:dynamodb:action/Query',
        integration_http_method: 'POST',
        credentials: 'arn:aws:iam::123:role/dynamodb-role'
      })
      
      expect(result.is_aws_service_integration?).to be true
      expect(result.requires_iam_role?).to be true
      expect(result.aws_service_name).to eq('dynamodb')
    end
    
    it 'creates integration with caching configuration' do
      result = test_instance.aws_api_gateway_integration(:cached_integration, {
        rest_api_id: 'api-123',
        resource_id: 'resource-456',
        http_method: 'GET',
        type: 'MOCK',
        cache_key_parameters: ['method.request.path.id', 'method.request.querystring.version'],
        cache_namespace: 'api-cache-v1'
      })
      
      expect(result.has_caching?).to be true
      expect(result.cache_configuration[:enabled]).to be true
      expect(result.cache_configuration[:key_parameters]).to include('method.request.path.id')
      expect(result.cache_configuration[:namespace]).to eq('api-cache-v1')
    end
    
    it 'creates integration with parameter mapping' do
      result = test_instance.aws_api_gateway_integration(:param_integration, {
        rest_api_id: 'api-123',
        resource_id: 'resource-456',
        http_method: 'GET',
        type: 'MOCK',
        request_parameters: {
          'integration.request.path.id' => 'method.request.path.userId',
          'integration.request.header.Content-Type' => "'application/json'"
        }
      })
      
      expect(result.request_configuration[:parameters]).to have_key('integration.request.path.id')
      expect(result.request_configuration[:parameters]).to have_key('integration.request.header.Content-Type')
    end
    
    it 'provides timeout in seconds' do
      result = test_instance.aws_api_gateway_integration(:timeout_integration, {
        rest_api_id: 'api-123',
        resource_id: 'resource-456',
        http_method: 'GET',
        type: 'MOCK',
        timeout_milliseconds: 15000
      })
      
      expect(result.timeout_seconds).to eq(15.0)
    end
    
    it 'has comprehensive outputs' do
      result = test_instance.aws_api_gateway_integration(:test_integration, {
        rest_api_id: 'api-123',
        resource_id: 'resource-456',
        http_method: 'GET',
        type: 'MOCK'
      })
      
      expected_outputs = [
        :rest_api_id, :resource_id, :http_method, :type,
        :integration_http_method, :uri, :connection_type,
        :connection_id, :credentials, :cache_key_parameters,
        :cache_namespace, :request_parameters, :request_templates,
        :passthrough_behavior, :content_handling, :timeout_milliseconds
      ]
      
      expected_outputs.each do |output|
        expect(result.outputs).to have_key(output)
      end
    end
  end
end