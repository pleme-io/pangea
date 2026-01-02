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
require 'pangea/resources/aws_autoscaling_policy/resource'

RSpec.describe 'aws_autoscaling_policy synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes simple scaling policy' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_autoscaling_policy(:scale_up, {
          autoscaling_group_name: '${aws_autoscaling_group.web.name}',
          policy_type: 'SimpleScaling',
          adjustment_type: 'ChangeInCapacity',
          scaling_adjustment: 2
        })
      end

      result = synthesizer.synthesis
      policy = result[:resource][:aws_autoscaling_policy][:scale_up]

      expect(policy[:policy_type]).to eq('SimpleScaling')
      expect(policy[:adjustment_type]).to eq('ChangeInCapacity')
      expect(policy[:scaling_adjustment]).to eq(2)
    end

    it 'synthesizes target tracking policy' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_autoscaling_policy(:cpu_tracking, {
          autoscaling_group_name: '${aws_autoscaling_group.web.name}',
          policy_type: 'TargetTrackingScaling',
          target_tracking_configuration: {
            target_value: 70.0,
            predefined_metric_specification: {
              predefined_metric_type: 'ASGAverageCPUUtilization'
            }
          }
        })
      end

      result = synthesizer.synthesis
      policy = result[:resource][:aws_autoscaling_policy][:cpu_tracking]

      expect(policy[:policy_type]).to eq('TargetTrackingScaling')
      expect(policy[:target_tracking_configuration][:target_value]).to eq(70.0)
    end

    it 'synthesizes step scaling policy' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_autoscaling_policy(:step_scale, {
          autoscaling_group_name: '${aws_autoscaling_group.web.name}',
          policy_type: 'StepScaling',
          adjustment_type: 'ChangeInCapacity',
          step_adjustments: [
            { metric_interval_lower_bound: 0, scaling_adjustment: 1 }
          ]
        })
      end

      result = synthesizer.synthesis
      policy = result[:resource][:aws_autoscaling_policy][:step_scale]

      expect(policy[:policy_type]).to eq('StepScaling')
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_autoscaling_policy(:test, {
          autoscaling_group_name: 'test-asg',
          policy_type: 'SimpleScaling',
          adjustment_type: 'ChangeInCapacity',
          scaling_adjustment: 1
        })
      end

      expect(ref.id).to eq('${aws_autoscaling_policy.test.id}')
      expect(ref.outputs[:arn]).to eq('${aws_autoscaling_policy.test.arn}')
    end
  end
end
