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
require 'pangea/resources/aws_cloudwatch_log_group/resource'

RSpec.describe 'aws_cloudwatch_log_group synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic log group' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_log_group(:app_logs, {
          name: '/aws/lambda/my-function'
        })
      end

      result = synthesizer.synthesis
      log_group = result[:resource][:aws_cloudwatch_log_group][:app_logs]

      expect(log_group[:name]).to eq('/aws/lambda/my-function')
    end

    it 'synthesizes log group with retention' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_log_group(:with_retention, {
          name: '/app/logs',
          retention_in_days: 30
        })
      end

      result = synthesizer.synthesis
      log_group = result[:resource][:aws_cloudwatch_log_group][:with_retention]

      expect(log_group[:retention_in_days]).to eq(30)
    end

    it 'synthesizes encrypted log group' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_log_group(:encrypted, {
          name: '/secure/logs',
          kms_key_id: '${aws_kms_key.logs.arn}'
        })
      end

      result = synthesizer.synthesis
      log_group = result[:resource][:aws_cloudwatch_log_group][:encrypted]

      expect(log_group[:kms_key_id]).to eq('${aws_kms_key.logs.arn}')
    end

    it 'synthesizes log group with tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_log_group(:tagged, {
          name: '/app/logs',
          tags: { Environment: 'production', Application: 'web' }
        })
      end

      result = synthesizer.synthesis
      log_group = result[:resource][:aws_cloudwatch_log_group][:tagged]

      expect(log_group[:tags][:Environment]).to eq('production')
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_log_group(:test, { name: '/test/logs' })
      end

      expect(ref.outputs[:arn]).to eq('${aws_cloudwatch_log_group.test.arn}')
      expect(ref.outputs[:name]).to eq('${aws_cloudwatch_log_group.test.name}')
    end
  end
end
