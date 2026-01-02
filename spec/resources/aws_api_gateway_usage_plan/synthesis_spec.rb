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
require 'pangea/resources/aws_api_gateway_usage_plan/resource'

RSpec.describe 'aws_api_gateway_usage_plan synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic usage plan' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_usage_plan(:basic, {
          name: 'basic-plan',
          api_stages: [
            { api_id: '${aws_api_gateway_rest_api.main.id}', stage: 'prod' }
          ]
        })
      end

      result = synthesizer.synthesis
      plan = result[:resource][:aws_api_gateway_usage_plan][:basic]

      expect(plan[:name]).to eq('basic-plan')
    end

    it 'synthesizes usage plan with throttling' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_usage_plan(:throttled, {
          name: 'throttled-plan',
          api_stages: [
            { api_id: '${aws_api_gateway_rest_api.main.id}', stage: 'prod' }
          ],
          throttle_settings: { burst_limit: 100, rate_limit: 50 }
        })
      end

      result = synthesizer.synthesis
      plan = result[:resource][:aws_api_gateway_usage_plan][:throttled]

      expect(plan[:throttle_settings][:burst_limit]).to eq(100)
      expect(plan[:throttle_settings][:rate_limit]).to eq(50)
    end

    it 'synthesizes usage plan with quota' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_usage_plan(:quota, {
          name: 'quota-plan',
          api_stages: [
            { api_id: '${aws_api_gateway_rest_api.main.id}', stage: 'prod' }
          ],
          quota_settings: { limit: 10000, period: 'MONTH' }
        })
      end

      result = synthesizer.synthesis
      plan = result[:resource][:aws_api_gateway_usage_plan][:quota]

      expect(plan[:quota_settings][:limit]).to eq(10000)
      expect(plan[:quota_settings][:period]).to eq('MONTH')
    end

    it 'synthesizes usage plan with tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_usage_plan(:tagged, {
          name: 'tagged-plan',
          api_stages: [
            { api_id: 'api-id', stage: 'prod' }
          ],
          tags: { Tier: 'premium' }
        })
      end

      result = synthesizer.synthesis
      plan = result[:resource][:aws_api_gateway_usage_plan][:tagged]

      expect(plan[:tags][:Tier]).to eq('premium')
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_api_gateway_usage_plan(:test, {
          name: 'test-plan',
          api_stages: [{ api_id: 'api-id', stage: 'test' }]
        })
      end

      expect(ref.id).to eq('${aws_api_gateway_usage_plan.test.id}')
      expect(ref.outputs[:arn]).to eq('${aws_api_gateway_usage_plan.test.arn}')
    end
  end
end
