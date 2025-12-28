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
require 'pangea/resources/aws_api_gateway_api_key/resource'

RSpec.describe 'aws_api_gateway_api_key synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic API key' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_api_key(:main, {
          name: 'my-api-key'
        })
      end

      result = synthesizer.synthesis
      key = result[:resource][:aws_api_gateway_api_key][:main]

      expect(key[:name]).to eq('my-api-key')
      expect(key[:enabled]).to be true
    end

    it 'synthesizes disabled API key' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_api_key(:disabled, {
          name: 'disabled-key',
          enabled: false
        })
      end

      result = synthesizer.synthesis
      key = result[:resource][:aws_api_gateway_api_key][:disabled]

      expect(key[:enabled]).to be false
    end

    it 'synthesizes API key with description' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_api_key(:described, {
          name: 'described-key',
          description: 'Key for partner API access'
        })
      end

      result = synthesizer.synthesis
      key = result[:resource][:aws_api_gateway_api_key][:described]

      expect(key[:description]).to eq('Key for partner API access')
    end

    it 'synthesizes API key with tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_api_key(:tagged, {
          name: 'tagged-key',
          tags: { Environment: 'production', Team: 'platform' }
        })
      end

      result = synthesizer.synthesis
      key = result[:resource][:aws_api_gateway_api_key][:tagged]

      expect(key[:tags][:Environment]).to eq('production')
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_api_key(:test, { name: 'test-key' })
      end

      expect(ref.id).to eq('${aws_api_gateway_api_key.test.id}')
      expect(ref.outputs[:arn]).to eq('${aws_api_gateway_api_key.test.arn}')
      expect(ref.outputs[:value]).to eq('${aws_api_gateway_api_key.test.value}')
    end
  end
end
