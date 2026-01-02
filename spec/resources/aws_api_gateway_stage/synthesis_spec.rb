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
require 'pangea/resources/aws_api_gateway_stage/resource'

RSpec.describe 'aws_api_gateway_stage synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic stage' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_stage(:prod, {
          rest_api_id: '${aws_api_gateway_rest_api.main.id}',
          deployment_id: '${aws_api_gateway_deployment.v1.id}',
          stage_name: 'prod'
        })
      end

      result = synthesizer.synthesis
      stage = result[:resource][:aws_api_gateway_stage][:prod]

      expect(stage[:stage_name]).to eq('prod')
    end

    it 'synthesizes stage with caching' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_stage(:cached, {
          rest_api_id: '${aws_api_gateway_rest_api.main.id}',
          deployment_id: '${aws_api_gateway_deployment.v1.id}',
          stage_name: 'prod',
          cache_cluster_enabled: true,
          cache_cluster_size: '0.5'
        })
      end

      result = synthesizer.synthesis
      stage = result[:resource][:aws_api_gateway_stage][:cached]

      expect(stage[:cache_cluster_enabled]).to be true
      expect(stage[:cache_cluster_size]).to eq('0.5')
    end

    it 'synthesizes stage with X-Ray tracing' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_stage(:traced, {
          rest_api_id: '${aws_api_gateway_rest_api.main.id}',
          deployment_id: '${aws_api_gateway_deployment.v1.id}',
          stage_name: 'prod',
          xray_tracing_enabled: true
        })
      end

      result = synthesizer.synthesis
      stage = result[:resource][:aws_api_gateway_stage][:traced]

      expect(stage[:xray_tracing_enabled]).to be true
    end

    it 'synthesizes stage with access logging' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_stage(:logged, {
          rest_api_id: '${aws_api_gateway_rest_api.main.id}',
          deployment_id: '${aws_api_gateway_deployment.v1.id}',
          stage_name: 'prod',
          access_log_settings: {
            destination_arn: '${aws_cloudwatch_log_group.api.arn}',
            format: '$requestId'
          }
        })
      end

      result = synthesizer.synthesis
      stage = result[:resource][:aws_api_gateway_stage][:logged]

      expect(stage[:access_log_settings][:format]).to eq('$requestId')
    end

    it 'synthesizes stage with variables' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_stage(:with_vars, {
          rest_api_id: '${aws_api_gateway_rest_api.main.id}',
          deployment_id: '${aws_api_gateway_deployment.v1.id}',
          stage_name: 'dev',
          variables: { 'environment' => 'development' }
        })
      end

      result = synthesizer.synthesis
      stage = result[:resource][:aws_api_gateway_stage][:with_vars]

      expect(stage[:variables]['environment']).to eq('development')
    end

    it 'synthesizes stage with tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_stage(:tagged, {
          rest_api_id: '${aws_api_gateway_rest_api.main.id}',
          deployment_id: '${aws_api_gateway_deployment.v1.id}',
          stage_name: 'prod',
          tags: { Environment: 'production' }
        })
      end

      result = synthesizer.synthesis
      stage = result[:resource][:aws_api_gateway_stage][:tagged]

      expect(stage[:tags][:Environment]).to eq('production')
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_stage(:test, {
          rest_api_id: 'api-id',
          deployment_id: 'deploy-id',
          stage_name: 'test'
        })
      end

      expect(ref.id).to eq('${aws_api_gateway_stage.test.id}')
      expect(ref.outputs[:invoke_url]).to eq('${aws_api_gateway_stage.test.invoke_url}')
      expect(ref.outputs[:arn]).to eq('${aws_api_gateway_stage.test.arn}')
    end
  end
end
