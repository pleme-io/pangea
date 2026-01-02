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
require 'pangea/resources/aws_sqs_queue_policy/resource'

RSpec.describe 'aws_sqs_queue_policy synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic queue policy' do
      policy_document = {
        Version: '2012-10-17',
        Statement: [
          {
            Effect: 'Allow',
            Principal: '*',
            Action: 'sqs:SendMessage',
            Resource: '${aws_sqs_queue.test.arn}'
          }
        ]
      }.to_json

      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sqs_queue_policy(:allow_send, {
          queue_url: '${aws_sqs_queue.test.url}',
          policy: policy_document
        })
      end

      result = synthesizer.synthesis
      queue_policy = result[:resource][:aws_sqs_queue_policy][:allow_send]

      expect(queue_policy[:queue_url]).to eq('${aws_sqs_queue.test.url}')
      expect(queue_policy[:policy]).to include('sqs:SendMessage')
    end

    it 'synthesizes SNS to SQS policy' do
      policy_document = {
        Version: '2012-10-17',
        Statement: [
          {
            Effect: 'Allow',
            Principal: { Service: 'sns.amazonaws.com' },
            Action: 'sqs:SendMessage',
            Resource: '${aws_sqs_queue.notifications.arn}',
            Condition: {
              ArnEquals: {
                'aws:SourceArn' => '${aws_sns_topic.alerts.arn}'
              }
            }
          }
        ]
      }.to_json

      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sqs_queue_policy(:sns_policy, {
          queue_url: '${aws_sqs_queue.notifications.url}',
          policy: policy_document
        })
      end

      result = synthesizer.synthesis
      queue_policy = result[:resource][:aws_sqs_queue_policy][:sns_policy]

      expect(queue_policy[:policy]).to include('sns.amazonaws.com')
      expect(queue_policy[:policy]).to include('ArnEquals')
    end

    it 'synthesizes cross-account access policy' do
      policy_document = {
        Version: '2012-10-17',
        Statement: [
          {
            Effect: 'Allow',
            Principal: { AWS: 'arn:aws:iam::123456789012:root' },
            Action: ['sqs:SendMessage', 'sqs:ReceiveMessage'],
            Resource: '${aws_sqs_queue.shared.arn}'
          }
        ]
      }.to_json

      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sqs_queue_policy(:cross_account, {
          queue_url: '${aws_sqs_queue.shared.url}',
          policy: policy_document
        })
      end

      result = synthesizer.synthesis
      queue_policy = result[:resource][:aws_sqs_queue_policy][:cross_account]

      expect(queue_policy[:policy]).to include('arn:aws:iam::123456789012:root')
    end

    it 'synthesizes multiple queue policies' do
      policy1 = { Version: '2012-10-17', Statement: [] }.to_json
      policy2 = { Version: '2012-10-17', Statement: [] }.to_json

      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sqs_queue_policy(:policy1, {
          queue_url: '${aws_sqs_queue.queue1.url}',
          policy: policy1
        })
        aws_sqs_queue_policy(:policy2, {
          queue_url: '${aws_sqs_queue.queue2.url}',
          policy: policy2
        })
      end

      result = synthesizer.synthesis

      expect(result[:resource][:aws_sqs_queue_policy][:policy1]).to be_a(Hash)
      expect(result[:resource][:aws_sqs_queue_policy][:policy2]).to be_a(Hash)
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      policy_document = { Version: '2012-10-17', Statement: [] }.to_json

      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sqs_queue_policy(:test, {
          queue_url: '${aws_sqs_queue.test.url}',
          policy: policy_document
        })
      end

      expect(ref.outputs[:id]).to eq('${aws_sqs_queue_policy.test.id}')
      expect(ref.outputs[:queue_url]).to eq('${aws_sqs_queue.test.url}')
    end

    it 'returns ResourceReference object' do
      policy_document = { Version: '2012-10-17', Statement: [] }.to_json

      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sqs_queue_policy(:ref_test, {
          queue_url: '${aws_sqs_queue.ref.url}',
          policy: policy_document
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_sqs_queue_policy')
      expect(ref.name).to eq(:ref_test)
    end
  end

  describe 'terraform validation' do
    it 'produces valid terraform structure' do
      policy_document = { Version: '2012-10-17', Statement: [] }.to_json

      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sqs_queue_policy(:validation, {
          queue_url: '${aws_sqs_queue.valid.url}',
          policy: policy_document
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result[:resource]).to be_a(Hash)
      expect(result[:resource][:aws_sqs_queue_policy]).to be_a(Hash)
      expect(result[:resource][:aws_sqs_queue_policy][:validation]).to be_a(Hash)

      queue_policy = result[:resource][:aws_sqs_queue_policy][:validation]
      expect(queue_policy).to have_key(:queue_url)
      expect(queue_policy).to have_key(:policy)
    end
  end
end
