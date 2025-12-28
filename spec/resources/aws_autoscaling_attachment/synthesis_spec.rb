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
require 'pangea/resources/aws_autoscaling_attachment/resource'

RSpec.describe 'aws_autoscaling_attachment synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes attachment to ALB target group' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_autoscaling_attachment(:alb, {
          autoscaling_group_name: '${aws_autoscaling_group.web.name}',
          lb_target_group_arn: '${aws_lb_target_group.main.arn}'
        })
      end

      result = synthesizer.synthesis
      attachment = result[:resource][:aws_autoscaling_attachment][:alb]

      expect(attachment[:autoscaling_group_name]).to eq('${aws_autoscaling_group.web.name}')
      expect(attachment[:lb_target_group_arn]).to eq('${aws_lb_target_group.main.arn}')
    end

    it 'synthesizes attachment to classic ELB' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_autoscaling_attachment(:classic, {
          autoscaling_group_name: '${aws_autoscaling_group.web.name}',
          elb: 'my-classic-lb'
        })
      end

      result = synthesizer.synthesis
      attachment = result[:resource][:aws_autoscaling_attachment][:classic]

      expect(attachment[:elb]).to eq('my-classic-lb')
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_autoscaling_attachment(:test, {
          autoscaling_group_name: 'test-asg',
          lb_target_group_arn: 'arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/test/abc123'
        })
      end

      expect(ref.id).to eq('${aws_autoscaling_attachment.test.id}')
    end
  end
end
