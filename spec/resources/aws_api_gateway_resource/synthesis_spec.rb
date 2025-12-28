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
require 'pangea/resources/aws_api_gateway_resource/resource'

RSpec.describe 'aws_api_gateway_resource synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic API resource' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_resource(:users, {
          rest_api_id: '${aws_api_gateway_rest_api.main.id}',
          parent_id: '${aws_api_gateway_rest_api.main.root_resource_id}',
          path_part: 'users'
        })
      end

      result = synthesizer.synthesis
      resource = result[:resource][:aws_api_gateway_resource][:users]

      expect(resource[:rest_api_id]).to eq('${aws_api_gateway_rest_api.main.id}')
      expect(resource[:path_part]).to eq('users')
    end

    it 'synthesizes path parameter resource' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_resource(:user_id, {
          rest_api_id: '${aws_api_gateway_rest_api.main.id}',
          parent_id: '${aws_api_gateway_resource.users.id}',
          path_part: '{userId}'
        })
      end

      result = synthesizer.synthesis
      resource = result[:resource][:aws_api_gateway_resource][:user_id]

      expect(resource[:path_part]).to eq('{userId}')
    end

    it 'synthesizes greedy path parameter' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_resource(:proxy, {
          rest_api_id: '${aws_api_gateway_rest_api.main.id}',
          parent_id: '${aws_api_gateway_rest_api.main.root_resource_id}',
          path_part: '{proxy+}'
        })
      end

      result = synthesizer.synthesis
      resource = result[:resource][:aws_api_gateway_resource][:proxy]

      expect(resource[:path_part]).to eq('{proxy+}')
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_resource(:test, {
          rest_api_id: 'api-id',
          parent_id: 'parent-id',
          path_part: 'test'
        })
      end

      expect(ref.id).to eq('${aws_api_gateway_resource.test.id}')
      expect(ref.outputs[:path]).to eq('${aws_api_gateway_resource.test.path}')
    end
  end
end
