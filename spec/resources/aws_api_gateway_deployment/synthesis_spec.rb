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
require 'pangea/resources/aws_api_gateway_deployment/resource'

RSpec.describe 'aws_api_gateway_deployment synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic deployment' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_deployment(:v1, {
          rest_api_id: '${aws_api_gateway_rest_api.main.id}'
        })
      end

      result = synthesizer.synthesis
      deployment = result[:resource][:aws_api_gateway_deployment][:v1]

      expect(deployment[:rest_api_id]).to eq('${aws_api_gateway_rest_api.main.id}')
    end

    it 'synthesizes deployment with stage' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_deployment(:prod, {
          rest_api_id: '${aws_api_gateway_rest_api.main.id}',
          stage_name: 'prod',
          stage_description: 'Production deployment'
        })
      end

      result = synthesizer.synthesis
      deployment = result[:resource][:aws_api_gateway_deployment][:prod]

      expect(deployment[:stage_name]).to eq('prod')
      expect(deployment[:stage_description]).to eq('Production deployment')
    end

    it 'synthesizes deployment with variables' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_deployment(:with_vars, {
          rest_api_id: '${aws_api_gateway_rest_api.main.id}',
          stage_name: 'dev',
          variables: { 'env' => 'development', 'debug' => 'true' }
        })
      end

      result = synthesizer.synthesis
      deployment = result[:resource][:aws_api_gateway_deployment][:with_vars]

      expect(deployment[:variables][:env]).to eq('development')
    end

    it 'synthesizes deployment with triggers' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_deployment(:triggered, {
          rest_api_id: '${aws_api_gateway_rest_api.main.id}',
          triggers: { 'redeployment' => '${sha256(file("api.json"))}' }
        })
      end

      result = synthesizer.synthesis
      deployment = result[:resource][:aws_api_gateway_deployment][:triggered]

      expect(deployment[:triggers][:redeployment]).to include('sha256')
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_deployment(:test, {
          rest_api_id: 'api-id'
        })
      end

      expect(ref.id).to eq('${aws_api_gateway_deployment.test.id}')
      expect(ref.outputs[:invoke_url]).to eq('${aws_api_gateway_deployment.test.invoke_url}')
      expect(ref.outputs[:execution_arn]).to eq('${aws_api_gateway_deployment.test.execution_arn}')
    end
  end
end
