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
require 'json'

# Mock TerraformSynthesizer for testing
class MockTerraformSynthesizer
  def initialize
    @resources = {}
    @data_sources = {}
    @variables = {}
    @outputs = {}
  end

  def resource(type, name)
    @resources["#{type}.#{name}"] = { type: type, name: name, attributes: {} }
    resource_builder = MockResourceBuilder.new(@resources["#{type}.#{name}"][:attributes])
    yield resource_builder if block_given?
  end
  
  def data(type, name)
    @data_sources["#{type}.#{name}"] = { type: type, name: name, attributes: {} }
    data_builder = MockResourceBuilder.new(@data_sources["#{type}.#{name}"][:attributes])
    yield data_builder if block_given?
  end
  
  def variable(name)
    @variables[name.to_s] = { name: name, attributes: {} }
    variable_builder = MockResourceBuilder.new(@variables[name.to_s][:attributes])
    yield variable_builder if block_given?
  end
  
  def output(name)
    @outputs[name.to_s] = { name: name, attributes: {} }
    output_builder = MockResourceBuilder.new(@outputs[name.to_s][:attributes])
    yield output_builder if block_given?
  end

  def synthesis
    result = {}
    
    if @resources.any?
      result["resource"] = {}
      @resources.each do |key, resource_data|
        type = resource_data[:type].to_s
        name = resource_data[:name].to_s
        result["resource"][type] ||= {}
        result["resource"][type][name] = resource_data[:attributes]
      end
    end
    
    if @data_sources.any?
      result["data"] = {}
      @data_sources.each do |key, data_source|
        type = data_source[:type].to_s
        name = data_source[:name].to_s
        result["data"][type] ||= {}
        result["data"][type][name] = data_source[:attributes]
      end
    end
    
    if @variables.any?
      result["variable"] = {}
      @variables.each do |key, variable|
        name = variable[:name].to_s
        result["variable"][name] = variable[:attributes]
      end
    end
    
    if @outputs.any?
      result["output"] = {}
      @outputs.each do |key, output|
        name = output[:name].to_s
        result["output"][name] = output[:attributes]
      end
    end
    
    result
  end
  
  def get_resources
    @resources
  end
end

class MockResourceBuilder
  def initialize(attributes)
    @attributes = attributes
  end
  
  def method_missing(method_name, *args)
    if args.any?
      @attributes[method_name.to_s] = args.first
    else
      if block_given?
        nested_builder = self.class.new({})
        yield nested_builder
        @attributes[method_name.to_s] = nested_builder.instance_variable_get(:@attributes)
      end
    end
  end
  
  def respond_to_missing?(method_name, include_private = false)
    true
  end
end

RSpec.describe 'aws_api_gateway_integration synthesis' do
  include Pangea::Resources::AWS
  
  let(:synthesizer) { MockTerraformSynthesizer.new }

  before do
    # Stub the TerraformSynthesizer constant to use our mock
    stub_const('TerraformSynthesizer', MockTerraformSynthesizer)
  end

  describe 'basic synthesis' do
    it 'synthesizes MOCK integration correctly' do
      synthesizer.instance_eval do
        aws_api_gateway_integration(:mock_test, {
          rest_api_id: 'api-abc123',
          resource_id: 'resource-def456',
          http_method: 'GET',
          type: 'MOCK'
        })
      end

      result = synthesizer.synthesis
      
      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_api_gateway_integration")
      expect(result["resource"]["aws_api_gateway_integration"]).to have_key("mock_test")
      
      integration = result["resource"]["aws_api_gateway_integration"]["mock_test"]
      expect(integration["rest_api_id"]).to eq('api-abc123')
      expect(integration["resource_id"]).to eq('resource-def456')
      expect(integration["http_method"]).to eq('GET')
      expect(integration["type"]).to eq('MOCK')
      expect(integration["connection_type"]).to eq('INTERNET')
      expect(integration["passthrough_behavior"]).to eq('WHEN_NO_MATCH')
      expect(integration["timeout_milliseconds"]).to eq(29000)
    end

    it 'synthesizes Lambda proxy integration correctly' do
      synthesizer.instance_eval do
        aws_api_gateway_integration(:lambda_proxy, {
          rest_api_id: 'api-abc123',
          resource_id: 'resource-def456',
          http_method: 'POST',
          type: 'AWS_PROXY',
          uri: 'arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123456789012:function:my-function/invocations',
          credentials: 'arn:aws:iam::123456789012:role/lambda-execution-role'
        })
      end

      result = synthesizer.synthesis
      integration = result["resource"]["aws_api_gateway_integration"]["lambda_proxy"]
      
      expect(integration["type"]).to eq('AWS_PROXY')
      expect(integration["uri"]).to include('lambda:path/2015-03-31/functions')
      expect(integration["credentials"]).to eq('arn:aws:iam::123456789012:role/lambda-execution-role')
    end

    it 'synthesizes Lambda custom integration correctly' do
      synthesizer.instance_eval do
        aws_api_gateway_integration(:lambda_custom, {
          rest_api_id: 'api-abc123',
          resource_id: 'resource-def456',
          http_method: 'POST',
          type: 'AWS',
          integration_http_method: 'POST',
          uri: 'arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123456789012:function:my-function/invocations',
          request_templates: {
            'application/json' => '{"input": $input.json("$"), "context": "$context.requestId"}'
          }
        })
      end

      result = synthesizer.synthesis
      integration = result["resource"]["aws_api_gateway_integration"]["lambda_custom"]
      
      expect(integration["type"]).to eq('AWS')
      expect(integration["integration_http_method"]).to eq('POST')
      expect(integration["request_templates"]).to have_key('application/json')
    end

    it 'synthesizes HTTP proxy integration correctly' do
      synthesizer.instance_eval do
        aws_api_gateway_integration(:http_proxy, {
          rest_api_id: 'api-abc123',
          resource_id: 'resource-def456',
          http_method: 'ANY',
          type: 'HTTP_PROXY',
          uri: 'https://backend.example.com/{proxy}'
        })
      end

      result = synthesizer.synthesis
      integration = result["resource"]["aws_api_gateway_integration"]["http_proxy"]
      
      expect(integration["type"]).to eq('HTTP_PROXY')
      expect(integration["uri"]).to eq('https://backend.example.com/{proxy}')
    end

    it 'synthesizes HTTP integration correctly' do
      synthesizer.instance_eval do
        aws_api_gateway_integration(:http_custom, {
          rest_api_id: 'api-abc123',
          resource_id: 'resource-def456',
          http_method: 'POST',
          type: 'HTTP',
          integration_http_method: 'POST',
          uri: 'https://api.example.com/webhook',
          request_templates: {
            'application/json' => '{"transformed": true, "data": $input.json("$")}'
          }
        })
      end

      result = synthesizer.synthesis
      integration = result["resource"]["aws_api_gateway_integration"]["http_custom"]
      
      expect(integration["type"]).to eq('HTTP')
      expect(integration["integration_http_method"]).to eq('POST')
      expect(integration["uri"]).to eq('https://api.example.com/webhook')
      expect(integration["request_templates"]).to have_key('application/json')
    end
  end

  describe 'connection configuration synthesis' do
    it 'synthesizes VPC Link integration correctly' do
      synthesizer.instance_eval do
        aws_api_gateway_integration(:vpc_link, {
          rest_api_id: 'api-abc123',
          resource_id: 'resource-def456',
          http_method: 'GET',
          type: 'HTTP_PROXY',
          uri: 'https://internal.example.com',
          connection_type: 'VPC_LINK',
          connection_id: 'vpc-link-123abc'
        })
      end

      result = synthesizer.synthesis
      integration = result["resource"]["aws_api_gateway_integration"]["vpc_link"]
      
      expect(integration["connection_type"]).to eq('VPC_LINK')
      expect(integration["connection_id"]).to eq('vpc-link-123abc')
    end

    it 'synthesizes internet connection correctly' do
      synthesizer.instance_eval do
        aws_api_gateway_integration(:internet, {
          rest_api_id: 'api-abc123',
          resource_id: 'resource-def456',
          http_method: 'GET',
          type: 'HTTP_PROXY',
          uri: 'https://public.example.com'
        })
      end

      result = synthesizer.synthesis
      integration = result["resource"]["aws_api_gateway_integration"]["internet"]
      
      expect(integration["connection_type"]).to eq('INTERNET')
      expect(integration).not_to have_key("connection_id")
    end
  end

  describe 'request configuration synthesis' do
    it 'synthesizes request templates correctly' do
      synthesizer.instance_eval do
        aws_api_gateway_integration(:request_templates, {
          rest_api_id: 'api-abc123',
          resource_id: 'resource-def456',
          http_method: 'POST',
          type: 'MOCK',
          request_templates: {
            'application/json' => '{"statusCode": 200, "message": "OK"}',
            'application/xml' => '<response><status>200</status></response>',
            'text/plain' => 'OK'
          }
        })
      end

      result = synthesizer.synthesis
      integration = result["resource"]["aws_api_gateway_integration"]["request_templates"]
      
      expect(integration["request_templates"]).to have_key('application/json')
      expect(integration["request_templates"]).to have_key('application/xml')
      expect(integration["request_templates"]).to have_key('text/plain')
    end

    it 'synthesizes request parameters correctly' do
      synthesizer.instance_eval do
        aws_api_gateway_integration(:request_params, {
          rest_api_id: 'api-abc123',
          resource_id: 'resource-def456',
          http_method: 'GET',
          type: 'MOCK',
          request_parameters: {
            'integration.request.path.id' => 'method.request.path.userId',
            'integration.request.header.Content-Type' => "'application/json'",
            'integration.request.querystring.version' => 'stageVariables.version'
          }
        })
      end

      result = synthesizer.synthesis
      integration = result["resource"]["aws_api_gateway_integration"]["request_params"]
      
      expect(integration["request_parameters"]).to have_key('integration.request.path.id')
      expect(integration["request_parameters"]).to have_key('integration.request.header.Content-Type')
      expect(integration["request_parameters"]).to have_key('integration.request.querystring.version')
    end

    it 'synthesizes passthrough behavior correctly' do
      ['WHEN_NO_MATCH', 'WHEN_NO_TEMPLATES', 'NEVER'].each do |behavior|
        synthesizer.instance_eval do
          aws_api_gateway_integration(:"passthrough_#{behavior.downcase}", {
            rest_api_id: 'api-abc123',
            resource_id: 'resource-def456',
            http_method: 'GET',
            type: 'MOCK',
            passthrough_behavior: behavior
          })
        end

        result = synthesizer.synthesis
        integration = result["resource"]["aws_api_gateway_integration"]["passthrough_#{behavior.downcase}"]
        expect(integration["passthrough_behavior"]).to eq(behavior)
      end
    end
  end

  describe 'caching configuration synthesis' do
    it 'synthesizes cache key parameters correctly' do
      synthesizer.instance_eval do
        aws_api_gateway_integration(:cached, {
          rest_api_id: 'api-abc123',
          resource_id: 'resource-def456',
          http_method: 'GET',
          type: 'MOCK',
          cache_key_parameters: [
            'method.request.path.id',
            'method.request.querystring.version',
            'method.request.header.Authorization'
          ]
        })
      end

      result = synthesizer.synthesis
      integration = result["resource"]["aws_api_gateway_integration"]["cached"]
      
      expect(integration["cache_key_parameters"]).to include('method.request.path.id')
      expect(integration["cache_key_parameters"]).to include('method.request.querystring.version')
      expect(integration["cache_key_parameters"]).to include('method.request.header.Authorization')
    end

    it 'synthesizes cache namespace correctly' do
      synthesizer.instance_eval do
        aws_api_gateway_integration(:cache_namespace, {
          rest_api_id: 'api-abc123',
          resource_id: 'resource-def456',
          http_method: 'GET',
          type: 'MOCK',
          cache_namespace: 'api-v1-users'
        })
      end

      result = synthesizer.synthesis
      integration = result["resource"]["aws_api_gateway_integration"]["cache_namespace"]
      
      expect(integration["cache_namespace"]).to eq('api-v1-users')
    end
  end

  describe 'timeout and content handling synthesis' do
    it 'synthesizes custom timeout correctly' do
      synthesizer.instance_eval do
        aws_api_gateway_integration(:custom_timeout, {
          rest_api_id: 'api-abc123',
          resource_id: 'resource-def456',
          http_method: 'GET',
          type: 'MOCK',
          timeout_milliseconds: 15000
        })
      end

      result = synthesizer.synthesis
      integration = result["resource"]["aws_api_gateway_integration"]["custom_timeout"]
      
      expect(integration["timeout_milliseconds"]).to eq(15000)
    end

    it 'synthesizes content handling correctly' do
      ['CONVERT_TO_BINARY', 'CONVERT_TO_TEXT'].each do |handling|
        synthesizer.instance_eval do
          aws_api_gateway_integration(:"content_#{handling.downcase}", {
            rest_api_id: 'api-abc123',
            resource_id: 'resource-def456',
            http_method: 'GET',
            type: 'MOCK',
            content_handling: handling
          })
        end

        result = synthesizer.synthesis
        integration = result["resource"]["aws_api_gateway_integration"]["content_#{handling.downcase}"]
        expect(integration["content_handling"]).to eq(handling)
      end
    end
  end

  describe 'AWS service integration synthesis' do
    it 'synthesizes DynamoDB integration correctly' do
      synthesizer.instance_eval do
        aws_api_gateway_integration(:dynamodb, {
          rest_api_id: 'api-abc123',
          resource_id: 'resource-def456',
          http_method: 'POST',
          type: 'AWS',
          integration_http_method: 'POST',
          uri: 'arn:aws:apigateway:us-east-1:dynamodb:action/Query',
          credentials: 'arn:aws:iam::123456789012:role/api-gateway-dynamodb',
          request_templates: {
            'application/json' => '{"TableName": "Users", "KeyConditionExpression": "id = :id", "ExpressionAttributeValues": {":id": {"S": "$input.params(\"id\")"}}}'
          }
        })
      end

      result = synthesizer.synthesis
      integration = result["resource"]["aws_api_gateway_integration"]["dynamodb"]
      
      expect(integration["type"]).to eq('AWS')
      expect(integration["uri"]).to include('dynamodb:action/Query')
      expect(integration["credentials"]).to eq('arn:aws:iam::123456789012:role/api-gateway-dynamodb')
      expect(integration["request_templates"]).to have_key('application/json')
    end

    it 'synthesizes S3 integration correctly' do
      synthesizer.instance_eval do
        aws_api_gateway_integration(:s3, {
          rest_api_id: 'api-abc123',
          resource_id: 'resource-def456',
          http_method: 'GET',
          type: 'AWS',
          integration_http_method: 'GET',
          uri: 'arn:aws:apigateway:us-east-1:s3:path/my-bucket/{key}',
          credentials: 'arn:aws:iam::123456789012:role/api-gateway-s3',
          request_parameters: {
            'integration.request.path.key' => 'method.request.path.filename'
          }
        })
      end

      result = synthesizer.synthesis
      integration = result["resource"]["aws_api_gateway_integration"]["s3"]
      
      expect(integration["type"]).to eq('AWS')
      expect(integration["uri"]).to include('s3:path/my-bucket')
      expect(integration["credentials"]).to eq('arn:aws:iam::123456789012:role/api-gateway-s3')
      expect(integration["request_parameters"]).to have_key('integration.request.path.key')
    end
  end

  describe 'complex integration scenarios' do
    it 'synthesizes multi-region Lambda integration correctly' do
      synthesizer.instance_eval do
        aws_api_gateway_integration(:multi_region_lambda, {
          rest_api_id: 'api-abc123',
          resource_id: 'resource-def456',
          http_method: 'POST',
          type: 'AWS_PROXY',
          uri: 'arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/arn:aws:lambda:${data.aws_region.current.name}:123456789012:function:${var.function_name}/invocations',
          credentials: '${var.lambda_execution_role_arn}'
        })
      end

      result = synthesizer.synthesis
      integration = result["resource"]["aws_api_gateway_integration"]["multi_region_lambda"]
      
      expect(integration["uri"]).to include('${data.aws_region.current.name}')
      expect(integration["credentials"]).to include('${var.lambda_execution_role_arn}')
    end

    it 'synthesizes comprehensive HTTP integration correctly' do
      synthesizer.instance_eval do
        aws_api_gateway_integration(:comprehensive_http, {
          rest_api_id: 'api-abc123',
          resource_id: 'resource-def456',
          http_method: 'POST',
          type: 'HTTP',
          integration_http_method: 'POST',
          uri: 'https://webhook.example.com/api/v1/events',
          connection_type: 'VPC_LINK',
          connection_id: 'vpc-link-abc123',
          request_templates: {
            'application/json' => '{"event": "$context.eventType", "data": $input.json("$"), "timestamp": "$context.requestTimeEpoch"}'
          },
          request_parameters: {
            'integration.request.header.X-API-Version' => "'v1'",
            'integration.request.header.X-Request-ID' => 'context.requestId',
            'integration.request.querystring.source' => "'api-gateway'"
          },
          passthrough_behavior: 'NEVER',
          timeout_milliseconds: 10000,
          cache_key_parameters: [
            'method.request.header.Authorization',
            'method.request.querystring.version'
          ],
          cache_namespace: 'webhook-cache-v1'
        })
      end

      result = synthesizer.synthesis
      integration = result["resource"]["aws_api_gateway_integration"]["comprehensive_http"]
      
      # Verify all attributes are present
      expect(integration["type"]).to eq('HTTP')
      expect(integration["connection_type"]).to eq('VPC_LINK')
      expect(integration["connection_id"]).to eq('vpc-link-abc123')
      expect(integration["request_templates"]).to have_key('application/json')
      expect(integration["request_parameters"]).to have_key('integration.request.header.X-API-Version')
      expect(integration["passthrough_behavior"]).to eq('NEVER')
      expect(integration["timeout_milliseconds"]).to eq(10000)
      expect(integration["cache_key_parameters"]).to include('method.request.header.Authorization')
      expect(integration["cache_namespace"]).to eq('webhook-cache-v1')
    end
  end

  describe 'template structure validation' do
    it 'creates valid Terraform JSON structure' do
      synthesizer.instance_eval do
        aws_api_gateway_integration(:structure_test, {
          rest_api_id: 'api-abc123',
          resource_id: 'resource-def456',
          http_method: 'GET',
          type: 'MOCK'
        })
      end

      result = synthesizer.synthesis
      
      # Validate top-level structure
      expect(result).to be_a(Hash)
      expect(result).to have_key("resource")
      
      # Validate resource structure
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]).to have_key("aws_api_gateway_integration")
      
      # Validate resource instance structure  
      expect(result["resource"]["aws_api_gateway_integration"]).to be_a(Hash)
      expect(result["resource"]["aws_api_gateway_integration"]).to have_key("structure_test")
      
      # Validate attributes
      integration = result["resource"]["aws_api_gateway_integration"]["structure_test"]
      expect(integration).to be_a(Hash)
      
      # Required attributes should be present
      %w[rest_api_id resource_id http_method type].each do |attr|
        expect(integration).to have_key(attr)
      end
      
      # Default attributes should be present
      %w[connection_type passthrough_behavior timeout_milliseconds].each do |attr|
        expect(integration).to have_key(attr)
      end
    end

    it 'serializes to valid JSON' do
      synthesizer.instance_eval do
        aws_api_gateway_integration(:json_test, {
          rest_api_id: 'api-abc123',
          resource_id: 'resource-def456',
          http_method: 'GET',
          type: 'MOCK',
          request_templates: {
            'application/json' => '{"status": "ok", "data": {"key": "value"}}'
          }
        })
      end

      result = synthesizer.synthesis
      
      # Should be able to serialize to JSON without errors
      expect { JSON.generate(result) }.not_to raise_error
      
      # Verify JSON structure
      json_string = JSON.generate(result)
      parsed_back = JSON.parse(json_string)
      
      expect(parsed_back).to eq(result)
    end
  end
end