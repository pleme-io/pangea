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
require 'pangea/resources/aws_cloudwatch_metric_alarm/resource'

RSpec.describe 'aws_cloudwatch_metric_alarm synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic CPU alarm' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_metric_alarm(:high_cpu, {
          alarm_name: 'high-cpu-alarm',
          comparison_operator: 'GreaterThanThreshold',
          evaluation_periods: 2,
          metric_name: 'CPUUtilization',
          namespace: 'AWS/EC2',
          period: 300,
          statistic: 'Average',
          threshold: 80.0
        })
      end

      result = synthesizer.synthesis
      alarm = result[:resource][:aws_cloudwatch_metric_alarm][:high_cpu]

      expect(alarm[:alarm_name]).to eq('high-cpu-alarm')
      expect(alarm[:comparison_operator]).to eq('GreaterThanThreshold')
      expect(alarm[:threshold]).to eq(80.0)
    end

    it 'synthesizes alarm with actions' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_metric_alarm(:with_actions, {
          alarm_name: 'alert-alarm',
          comparison_operator: 'GreaterThanThreshold',
          evaluation_periods: 1,
          metric_name: 'Errors',
          namespace: 'AWS/Lambda',
          period: 60,
          statistic: 'Sum',
          threshold: 1.0,
          alarm_actions: ['${aws_sns_topic.alerts.arn}']
        })
      end

      result = synthesizer.synthesis
      alarm = result[:resource][:aws_cloudwatch_metric_alarm][:with_actions]

      expect(alarm[:alarm_actions]).to include('${aws_sns_topic.alerts.arn}')
    end

    it 'synthesizes alarm with dimensions' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_metric_alarm(:instance_cpu, {
          alarm_name: 'instance-cpu',
          comparison_operator: 'GreaterThanThreshold',
          evaluation_periods: 2,
          metric_name: 'CPUUtilization',
          namespace: 'AWS/EC2',
          period: 300,
          statistic: 'Average',
          threshold: 80.0,
          dimensions: { InstanceId: 'i-1234567890abcdef0' }
        })
      end

      result = synthesizer.synthesis
      alarm = result[:resource][:aws_cloudwatch_metric_alarm][:instance_cpu]

      expect(alarm[:dimensions][:InstanceId]).to eq('i-1234567890abcdef0')
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_metric_alarm(:test, {
          alarm_name: 'test-alarm',
          comparison_operator: 'GreaterThanThreshold',
          evaluation_periods: 1,
          metric_name: 'Test',
          namespace: 'Test',
          period: 60,
          statistic: 'Sum',
          threshold: 1.0
        })
      end

      expect(ref.outputs[:arn]).to eq('${aws_cloudwatch_metric_alarm.test.arn}')
    end
  end
end
