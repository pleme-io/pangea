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
require 'pangea/resources/aws_api_gateway_method/resource'

RSpec.describe 'aws_api_gateway_method synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic GET method' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_method(:get_users, {
          rest_api_id: '${aws_api_gateway_rest_api.main.id}',
          resource_id: '${aws_api_gateway_resource.users.id}',
          http_method: 'GET',
          authorization: 'NONE'
        })
      end

      result = synthesizer.synthesis
      method = result[:resource][:aws_api_gateway_method][:get_users]

      expect(method[:http_method]).to eq('GET')
      expect(method[:authorization]).to eq('NONE')
    end

    it 'synthesizes method with API key required' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_method(:protected_get, {
          rest_api_id: '${aws_api_gateway_rest_api.main.id}',
          resource_id: '${aws_api_gateway_resource.users.id}',
          http_method: 'GET',
          authorization: 'NONE',
          api_key_required: true
        })
      end

      result = synthesizer.synthesis
      method = result[:resource][:aws_api_gateway_method][:protected_get]

      expect(method[:api_key_required]).to be true
    end

    it 'synthesizes method with IAM authorization' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_method(:iam_protected, {
          rest_api_id: '${aws_api_gateway_rest_api.main.id}',
          resource_id: '${aws_api_gateway_resource.users.id}',
          http_method: 'POST',
          authorization: 'AWS_IAM'
        })
      end

      result = synthesizer.synthesis
      method = result[:resource][:aws_api_gateway_method][:iam_protected]

      expect(method[:authorization]).to eq('AWS_IAM')
    end

    it 'synthesizes method with request parameters' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_method(:with_params, {
          rest_api_id: '${aws_api_gateway_rest_api.main.id}',
          resource_id: '${aws_api_gateway_resource.users.id}',
          http_method: 'GET',
          authorization: 'NONE',
          request_parameters: {
            'method.request.querystring.page' => true,
            'method.request.header.Authorization' => true
          }
        })
      end

      result = synthesizer.synthesis
      method = result[:resource][:aws_api_gateway_method][:with_params]

      expect(method[:request_parameters]['method.request.querystring.page']).to be true
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_method(:test, {
          rest_api_id: 'api-id',
          resource_id: 'resource-id',
          http_method: 'GET',
          authorization: 'NONE'
        })
      end

      expect(ref.id).to eq('${aws_api_gateway_method.test.id}')
      expect(ref.outputs[:http_method]).to eq('${aws_api_gateway_method.test.http_method}')
    end
  end
end
