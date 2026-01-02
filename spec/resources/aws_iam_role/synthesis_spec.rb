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
require 'pangea/resources/aws_iam_role/resource'

RSpec.describe 'aws_iam_role synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }
  let(:lambda_trust_policy) do
    {
      Version: '2012-10-17',
      Statement: [{
        Effect: 'Allow',
        Principal: { Service: 'lambda.amazonaws.com' },
        Action: 'sts:AssumeRole'
      }]
    }
  end

  describe 'terraform synthesis' do
    it 'synthesizes basic IAM role' do
      policy = lambda_trust_policy
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_role(:lambda_exec, {
          name: 'lambda-execution-role',
          assume_role_policy: policy
        })
      end

      result = synthesizer.synthesis
      role = result[:resource][:aws_iam_role][:lambda_exec]

      expect(role[:name]).to eq('lambda-execution-role')
      expect(role[:assume_role_policy]).to include('lambda.amazonaws.com')
    end

    it 'synthesizes role with description' do
      policy = lambda_trust_policy
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_role(:described, {
          name: 'described-role',
          description: 'Role for Lambda function execution',
          assume_role_policy: policy
        })
      end

      result = synthesizer.synthesis
      role = result[:resource][:aws_iam_role][:described]

      expect(role[:description]).to eq('Role for Lambda function execution')
    end

    it 'synthesizes role with custom path' do
      policy = lambda_trust_policy
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_role(:pathed, {
          name: 'pathed-role',
          path: '/application/',
          assume_role_policy: policy
        })
      end

      result = synthesizer.synthesis
      role = result[:resource][:aws_iam_role][:pathed]

      expect(role[:path]).to eq('/application/')
    end

    it 'synthesizes role with tags' do
      policy = lambda_trust_policy
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_role(:tagged, {
          name: 'tagged-role',
          assume_role_policy: policy,
          tags: { Environment: 'production', Team: 'platform' }
        })
      end

      result = synthesizer.synthesis
      role = result[:resource][:aws_iam_role][:tagged]

      expect(role[:tags][:Environment]).to eq('production')
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      policy = lambda_trust_policy
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_role(:test, {
          name: 'test-role',
          assume_role_policy: policy
        })
      end

      expect(ref.outputs[:arn]).to eq('${aws_iam_role.test.arn}')
      expect(ref.outputs[:name]).to eq('${aws_iam_role.test.name}')
    end
  end
end
