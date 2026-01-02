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
require 'pangea/resources/aws_sns_subscription/resource'

RSpec.describe 'aws_sns_subscription synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes SQS subscription' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sns_subscription(:sqs_sub, {
          topic_arn: 'arn:aws:sns:us-east-1:123456789012:my-topic',
          protocol: 'sqs',
          endpoint: 'arn:aws:sqs:us-east-1:123456789012:my-queue'
        })
      end

      result = synthesizer.synthesis
      subscription = result[:resource][:aws_sns_subscription][:sqs_sub]

      expect(subscription[:topic_arn]).to eq('arn:aws:sns:us-east-1:123456789012:my-topic')
      expect(subscription[:protocol]).to eq('sqs')
      expect(subscription[:endpoint]).to eq('arn:aws:sqs:us-east-1:123456789012:my-queue')
    end

    it 'synthesizes Lambda subscription' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sns_subscription(:lambda_sub, {
          topic_arn: 'arn:aws:sns:us-east-1:123456789012:alerts',
          protocol: 'lambda',
          endpoint: 'arn:aws:lambda:us-east-1:123456789012:function:process-alerts'
        })
      end

      result = synthesizer.synthesis
      subscription = result[:resource][:aws_sns_subscription][:lambda_sub]

      expect(subscription[:protocol]).to eq('lambda')
      expect(subscription[:endpoint]).to include('lambda')
    end

    it 'synthesizes HTTPS subscription' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sns_subscription(:webhook, {
          topic_arn: 'arn:aws:sns:us-east-1:123456789012:events',
          protocol: 'https',
          endpoint: 'https://webhook.example.com/sns'
        })
      end

      result = synthesizer.synthesis
      subscription = result[:resource][:aws_sns_subscription][:webhook]

      expect(subscription[:protocol]).to eq('https')
      expect(subscription[:endpoint]).to start_with('https://')
    end

    it 'synthesizes email subscription' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sns_subscription(:email_alert, {
          topic_arn: 'arn:aws:sns:us-east-1:123456789012:alerts',
          protocol: 'email',
          endpoint: 'alerts@example.com'
        })
      end

      result = synthesizer.synthesis
      subscription = result[:resource][:aws_sns_subscription][:email_alert]

      expect(subscription[:protocol]).to eq('email')
      expect(subscription[:endpoint]).to eq('alerts@example.com')
    end

    it 'synthesizes subscription with raw message delivery' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sns_subscription(:raw_sqs, {
          topic_arn: 'arn:aws:sns:us-east-1:123456789012:raw-topic',
          protocol: 'sqs',
          endpoint: 'arn:aws:sqs:us-east-1:123456789012:raw-queue',
          raw_message_delivery: true
        })
      end

      result = synthesizer.synthesis
      subscription = result[:resource][:aws_sns_subscription][:raw_sqs]

      expect(subscription[:raw_message_delivery]).to be true
    end

    it 'synthesizes subscription with filter policy' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sns_subscription(:filtered, {
          topic_arn: 'arn:aws:sns:us-east-1:123456789012:events',
          protocol: 'sqs',
          endpoint: 'arn:aws:sqs:us-east-1:123456789012:filtered-queue',
          filter_policy: '{"event_type": ["order_created", "order_updated"]}'
        })
      end

      result = synthesizer.synthesis
      subscription = result[:resource][:aws_sns_subscription][:filtered]

      expect(subscription[:filter_policy]).to include('event_type')
    end

    it 'synthesizes subscription with redrive policy' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sns_subscription(:with_dlq, {
          topic_arn: 'arn:aws:sns:us-east-1:123456789012:critical',
          protocol: 'sqs',
          endpoint: 'arn:aws:sqs:us-east-1:123456789012:critical-queue',
          redrive_policy: '{"deadLetterTargetArn": "arn:aws:sqs:us-east-1:123456789012:dlq"}'
        })
      end

      result = synthesizer.synthesis
      subscription = result[:resource][:aws_sns_subscription][:with_dlq]

      expect(subscription[:redrive_policy]).to include('deadLetterTargetArn')
    end

    it 'synthesizes multiple subscriptions' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sns_subscription(:sub1, {
          topic_arn: 'arn:aws:sns:us-east-1:123456789012:topic',
          protocol: 'sqs',
          endpoint: 'arn:aws:sqs:us-east-1:123456789012:queue1'
        })
        aws_sns_subscription(:sub2, {
          topic_arn: 'arn:aws:sns:us-east-1:123456789012:topic',
          protocol: 'sqs',
          endpoint: 'arn:aws:sqs:us-east-1:123456789012:queue2'
        })
      end

      result = synthesizer.synthesis

      expect(result[:resource][:aws_sns_subscription][:sub1]).to be_a(Hash)
      expect(result[:resource][:aws_sns_subscription][:sub2]).to be_a(Hash)
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sns_subscription(:test, {
          topic_arn: 'arn:aws:sns:us-east-1:123456789012:test',
          protocol: 'sqs',
          endpoint: 'arn:aws:sqs:us-east-1:123456789012:test-queue'
        })
      end

      expect(ref.outputs[:arn]).to eq('${aws_sns_subscription.test.arn}')
      expect(ref.outputs[:id]).to eq('${aws_sns_subscription.test.id}')
    end

    it 'returns ResourceReference object' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sns_subscription(:ref_test, {
          topic_arn: 'arn:aws:sns:us-east-1:123456789012:ref',
          protocol: 'sqs',
          endpoint: 'arn:aws:sqs:us-east-1:123456789012:ref-queue'
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_sns_subscription')
      expect(ref.name).to eq(:ref_test)
    end
  end

  describe 'terraform validation' do
    it 'produces valid terraform structure' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sns_subscription(:validation, {
          topic_arn: 'arn:aws:sns:us-east-1:123456789012:valid',
          protocol: 'sqs',
          endpoint: 'arn:aws:sqs:us-east-1:123456789012:valid-queue'
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result[:resource]).to be_a(Hash)
      expect(result[:resource][:aws_sns_subscription]).to be_a(Hash)
      expect(result[:resource][:aws_sns_subscription][:validation]).to be_a(Hash)

      subscription = result[:resource][:aws_sns_subscription][:validation]
      expect(subscription).to have_key(:topic_arn)
      expect(subscription).to have_key(:protocol)
      expect(subscription).to have_key(:endpoint)
    end
  end
end
