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
require 'terraform-synthesizer'
require 'pangea/resources/aws_api_gateway_integration/resource'

RSpec.describe 'aws_api_gateway_integration synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes Lambda proxy integration' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_integration(:lambda_proxy, {
          rest_api_id: '${aws_api_gateway_rest_api.main.id}',
          resource_id: '${aws_api_gateway_resource.users.id}',
          http_method: 'GET',
          type: 'AWS_PROXY',
          integration_http_method: 'POST',
          uri: '${aws_lambda_function.handler.invoke_arn}'
        })
      end

      result = synthesizer.synthesis
      integration = result[:resource][:aws_api_gateway_integration][:lambda_proxy]

      expect(integration[:type]).to eq('AWS_PROXY')
      expect(integration[:integration_http_method]).to eq('POST')
    end

    it 'synthesizes mock integration' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_integration(:mock, {
          rest_api_id: '${aws_api_gateway_rest_api.main.id}',
          resource_id: '${aws_api_gateway_resource.health.id}',
          http_method: 'GET',
          type: 'MOCK'
        })
      end

      result = synthesizer.synthesis
      integration = result[:resource][:aws_api_gateway_integration][:mock]

      expect(integration[:type]).to eq('MOCK')
    end

    it 'synthesizes HTTP integration with VPC link' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_integration(:vpc_link, {
          rest_api_id: '${aws_api_gateway_rest_api.main.id}',
          resource_id: '${aws_api_gateway_resource.api.id}',
          http_method: 'ANY',
          type: 'HTTP_PROXY',
          integration_http_method: 'ANY',
          uri: 'http://internal-lb.example.com',
          connection_type: 'VPC_LINK',
          connection_id: '${aws_api_gateway_vpc_link.main.id}'
        })
      end

      result = synthesizer.synthesis
      integration = result[:resource][:aws_api_gateway_integration][:vpc_link]

      expect(integration[:connection_type]).to eq('VPC_LINK')
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_integration(:test, {
          rest_api_id: 'api-id',
          resource_id: 'resource-id',
          http_method: 'GET',
          type: 'MOCK'
        })
      end

      expect(ref.outputs[:rest_api_id]).to eq('${aws_api_gateway_integration.test.rest_api_id}')
      expect(ref.outputs[:type]).to eq('${aws_api_gateway_integration.test.type}')
    end
  end
end
