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
require 'pangea/resources/aws_api_gateway_rest_api/resource'

RSpec.describe 'aws_api_gateway_rest_api synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic REST API' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_rest_api(:example, {
          name: 'my-api'
        })
      end

      result = synthesizer.synthesis
      api = result[:resource][:aws_api_gateway_rest_api][:example]

      expect(api[:name]).to eq('my-api')
      expect(api[:api_key_source]).to eq('HEADER')
      expect(api[:minimum_tls_version]).to eq('TLS_1_2')
    end

    it 'synthesizes regional API with description' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_rest_api(:regional, {
          name: 'regional-api',
          description: 'A regional REST API',
          endpoint_configuration: { types: ['REGIONAL'] }
        })
      end

      result = synthesizer.synthesis
      api = result[:resource][:aws_api_gateway_rest_api][:regional]

      expect(api[:name]).to eq('regional-api')
      expect(api[:description]).to eq('A regional REST API')
      expect(api[:endpoint_configuration][:types]).to eq(['REGIONAL'])
    end

    it 'synthesizes API with binary media types' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_rest_api(:binary, {
          name: 'binary-api',
          binary_media_types: ['image/png', 'application/pdf']
        })
      end

      result = synthesizer.synthesis
      api = result[:resource][:aws_api_gateway_rest_api][:binary]

      expect(api[:binary_media_types]).to include('image/png', 'application/pdf')
    end

    it 'synthesizes API with tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_rest_api(:tagged, {
          name: 'tagged-api',
          tags: { Environment: 'production', Team: 'platform' }
        })
      end

      result = synthesizer.synthesis
      api = result[:resource][:aws_api_gateway_rest_api][:tagged]

      expect(api[:tags][:Environment]).to eq('production')
      expect(api[:tags][:Team]).to eq('platform')
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_rest_api(:test, { name: 'test-api' })
      end

      expect(ref.id).to eq('${aws_api_gateway_rest_api.test.id}')
      expect(ref.outputs[:root_resource_id]).to eq('${aws_api_gateway_rest_api.test.root_resource_id}')
      expect(ref.outputs[:execution_arn]).to eq('${aws_api_gateway_rest_api.test.execution_arn}')
    end
  end
end
