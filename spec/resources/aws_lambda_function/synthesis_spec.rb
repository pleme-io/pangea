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
require 'pangea/resources/aws_lambda_function/resource'

RSpec.describe 'aws_lambda_function synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic Lambda function' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_lambda_function(:handler, {
          function_name: 'my-function',
          role: '${aws_iam_role.lambda.arn}',
          handler: 'index.handler',
          runtime: 'nodejs18.x',
          filename: 'lambda.zip'
        })
      end

      result = synthesizer.synthesis
      func = result[:resource][:aws_lambda_function][:handler]

      expect(func[:function_name]).to eq('my-function')
      expect(func[:handler]).to eq('index.handler')
      expect(func[:runtime]).to eq('nodejs18.x')
    end

    it 'synthesizes Lambda with S3 source' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_lambda_function(:s3_source, {
          function_name: 's3-function',
          role: '${aws_iam_role.lambda.arn}',
          handler: 'main.handler',
          runtime: 'python3.11',
          s3_bucket: 'my-deployment-bucket',
          s3_key: 'functions/handler.zip'
        })
      end

      result = synthesizer.synthesis
      func = result[:resource][:aws_lambda_function][:s3_source]

      expect(func[:s3_bucket]).to eq('my-deployment-bucket')
      expect(func[:s3_key]).to eq('functions/handler.zip')
    end

    it 'synthesizes Lambda with environment variables' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_lambda_function(:with_env, {
          function_name: 'env-function',
          role: '${aws_iam_role.lambda.arn}',
          handler: 'index.handler',
          runtime: 'nodejs18.x',
          filename: 'lambda.zip',
          environment: { variables: { LOG_LEVEL: 'INFO', TABLE_NAME: 'my-table' } }
        })
      end

      result = synthesizer.synthesis
      func = result[:resource][:aws_lambda_function][:with_env]

      expect(func[:environment][:variables][:LOG_LEVEL]).to eq('INFO')
    end

    it 'synthesizes Lambda with VPC config' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_lambda_function(:vpc_function, {
          function_name: 'vpc-function',
          role: '${aws_iam_role.lambda.arn}',
          handler: 'index.handler',
          runtime: 'nodejs18.x',
          filename: 'lambda.zip',
          vpc_config: {
            subnet_ids: ['${aws_subnet.a.id}', '${aws_subnet.b.id}'],
            security_group_ids: ['${aws_security_group.lambda.id}']
          }
        })
      end

      result = synthesizer.synthesis
      func = result[:resource][:aws_lambda_function][:vpc_function]

      expect(func[:vpc_config][:subnet_ids]).to include('${aws_subnet.a.id}')
    end

    it 'synthesizes Lambda with custom memory and timeout' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_lambda_function(:custom_config, {
          function_name: 'custom-function',
          role: '${aws_iam_role.lambda.arn}',
          handler: 'index.handler',
          runtime: 'nodejs18.x',
          filename: 'lambda.zip',
          memory_size: 512,
          timeout: 30
        })
      end

      result = synthesizer.synthesis
      func = result[:resource][:aws_lambda_function][:custom_config]

      expect(func[:memory_size]).to eq(512)
      expect(func[:timeout]).to eq(30)
    end

    it 'synthesizes Lambda with tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_lambda_function(:tagged, {
          function_name: 'tagged-function',
          role: '${aws_iam_role.lambda.arn}',
          handler: 'index.handler',
          runtime: 'nodejs18.x',
          filename: 'lambda.zip',
          tags: { Environment: 'production', Service: 'api' }
        })
      end

      result = synthesizer.synthesis
      func = result[:resource][:aws_lambda_function][:tagged]

      expect(func[:tags][:Environment]).to eq('production')
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_lambda_function(:test, {
          function_name: 'test-function',
          role: 'arn:aws:iam::123456789012:role/test',
          handler: 'index.handler',
          runtime: 'nodejs18.x',
          filename: 'lambda.zip'
        })
      end

      expect(ref.outputs[:arn]).to eq('${aws_lambda_function.test.arn}')
      expect(ref.outputs[:invoke_arn]).to eq('${aws_lambda_function.test.invoke_arn}')
      expect(ref.outputs[:qualified_arn]).to eq('${aws_lambda_function.test.qualified_arn}')
    end
  end
end
