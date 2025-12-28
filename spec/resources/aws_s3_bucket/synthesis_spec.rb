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
require 'pangea/resources/aws_s3_bucket/resource'

RSpec.describe 'aws_s3_bucket synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic S3 bucket' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_s3_bucket(:data, {
          bucket: 'my-data-bucket'
        })
      end

      result = synthesizer.synthesis
      bucket = result[:resource][:aws_s3_bucket][:data]

      expect(bucket[:bucket]).to eq('my-data-bucket')
    end

    it 'synthesizes bucket with versioning' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_s3_bucket(:versioned, {
          bucket: 'versioned-bucket',
          versioning: { enabled: true }
        })
      end

      result = synthesizer.synthesis
      bucket = result[:resource][:aws_s3_bucket][:versioned]

      expect(bucket[:versioning][:enabled]).to be true
    end

    it 'synthesizes bucket with encryption' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_s3_bucket(:encrypted, {
          bucket: 'encrypted-bucket',
          server_side_encryption_configuration: {
            rule: {
              apply_server_side_encryption_by_default: {
                sse_algorithm: 'aws:kms',
                kms_master_key_id: '${aws_kms_key.bucket.arn}'
              }
            }
          }
        })
      end

      result = synthesizer.synthesis
      bucket = result[:resource][:aws_s3_bucket][:encrypted]

      sse = bucket[:server_side_encryption_configuration][:rule][:apply_server_side_encryption_by_default]
      expect(sse[:sse_algorithm]).to eq('aws:kms')
    end

    it 'synthesizes bucket with tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_s3_bucket(:tagged, {
          bucket: 'tagged-bucket',
          tags: { Environment: 'production', Team: 'platform' }
        })
      end

      result = synthesizer.synthesis
      bucket = result[:resource][:aws_s3_bucket][:tagged]

      expect(bucket[:tags][:Environment]).to eq('production')
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_s3_bucket(:test, { bucket: 'test-bucket' })
      end

      expect(ref.outputs[:arn]).to eq('${aws_s3_bucket.test.arn}')
      expect(ref.outputs[:bucket_domain_name]).to eq('${aws_s3_bucket.test.bucket_domain_name}')
    end
  end
end
