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
require 'pangea/resources/aws_sqs_queue/resource'

RSpec.describe 'aws_sqs_queue synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic SQS queue' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sqs_queue(:tasks, {
          name: 'tasks-queue'
        })
      end

      result = synthesizer.synthesis
      queue = result[:resource][:aws_sqs_queue][:tasks]

      expect(queue[:name]).to eq('tasks-queue')
    end

    it 'synthesizes FIFO queue' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sqs_queue(:ordered, {
          name: 'ordered.fifo',
          fifo_queue: true,
          content_based_deduplication: true
        })
      end

      result = synthesizer.synthesis
      queue = result[:resource][:aws_sqs_queue][:ordered]

      expect(queue[:fifo_queue]).to be true
      expect(queue[:content_based_deduplication]).to be true
    end

    it 'synthesizes queue with custom visibility timeout' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sqs_queue(:long_processing, {
          name: 'long-processing',
          visibility_timeout_seconds: 300
        })
      end

      result = synthesizer.synthesis
      queue = result[:resource][:aws_sqs_queue][:long_processing]

      expect(queue[:visibility_timeout_seconds]).to eq(300)
    end

    it 'synthesizes encrypted queue' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sqs_queue(:encrypted, {
          name: 'encrypted-queue',
          kms_master_key_id: '${aws_kms_key.sqs.arn}'
        })
      end

      result = synthesizer.synthesis
      queue = result[:resource][:aws_sqs_queue][:encrypted]

      expect(queue[:kms_master_key_id]).to eq('${aws_kms_key.sqs.arn}')
    end

    it 'synthesizes queue with dead letter queue' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sqs_queue(:with_dlq, {
          name: 'with-dlq',
          redrive_policy: {
            deadLetterTargetArn: '${aws_sqs_queue.dlq.arn}',
            maxReceiveCount: 3
          }
        })
      end

      result = synthesizer.synthesis
      queue = result[:resource][:aws_sqs_queue][:with_dlq]

      expect(queue[:redrive_policy]).to include('deadLetterTargetArn')
    end

    it 'synthesizes queue with tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sqs_queue(:tagged, {
          name: 'tagged-queue',
          tags: { Environment: 'production' }
        })
      end

      result = synthesizer.synthesis
      queue = result[:resource][:aws_sqs_queue][:tagged]

      expect(queue[:tags][:Environment]).to eq('production')
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sqs_queue(:test, { name: 'test-queue' })
      end

      expect(ref.outputs[:arn]).to eq('${aws_sqs_queue.test.arn}')
      expect(ref.outputs[:url]).to eq('${aws_sqs_queue.test.url}')
    end
  end
end
