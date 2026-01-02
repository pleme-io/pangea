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
require 'pangea/resources/aws_sns_topic/resource'

RSpec.describe 'aws_sns_topic synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic SNS topic' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sns_topic(:alerts, {
          name: 'alerts-topic'
        })
      end

      result = synthesizer.synthesis
      topic = result[:resource][:aws_sns_topic][:alerts]

      expect(topic[:name]).to eq('alerts-topic')
    end

    it 'synthesizes FIFO topic' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sns_topic(:fifo_alerts, {
          name: 'alerts.fifo',
          fifo_topic: true,
          content_based_deduplication: true
        })
      end

      result = synthesizer.synthesis
      topic = result[:resource][:aws_sns_topic][:fifo_alerts]

      expect(topic[:fifo_topic]).to be true
      expect(topic[:content_based_deduplication]).to be true
    end

    it 'synthesizes encrypted topic' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sns_topic(:encrypted, {
          name: 'encrypted-topic',
          kms_master_key_id: '${aws_kms_key.sns.arn}'
        })
      end

      result = synthesizer.synthesis
      topic = result[:resource][:aws_sns_topic][:encrypted]

      expect(topic[:kms_master_key_id]).to eq('${aws_kms_key.sns.arn}')
    end

    it 'synthesizes topic with display name' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sns_topic(:notifications, {
          name: 'notifications',
          display_name: 'App Notifications'
        })
      end

      result = synthesizer.synthesis
      topic = result[:resource][:aws_sns_topic][:notifications]

      expect(topic[:display_name]).to eq('App Notifications')
    end

    it 'synthesizes topic with tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sns_topic(:tagged, {
          name: 'tagged-topic',
          tags: { Environment: 'production' }
        })
      end

      result = synthesizer.synthesis
      topic = result[:resource][:aws_sns_topic][:tagged]

      expect(topic[:tags][:Environment]).to eq('production')
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sns_topic(:test, { name: 'test-topic' })
      end

      expect(ref.outputs[:arn]).to eq('${aws_sns_topic.test.arn}')
      expect(ref.outputs[:name]).to eq('${aws_sns_topic.test.name}')
    end
  end
end
