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
require 'pangea/resources/aws_autoscaling_group/resource'

RSpec.describe 'aws_autoscaling_group synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic ASG with launch template' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_autoscaling_group(:web, {
          min_size: 1,
          max_size: 5,
          launch_template: {
            id: '${aws_launch_template.web.id}',
            version: '$Latest'
          }
        })
      end

      result = synthesizer.synthesis
      asg = result[:resource][:aws_autoscaling_group][:web]

      expect(asg[:min_size]).to eq(1)
      expect(asg[:max_size]).to eq(5)
      expect(asg[:launch_template][:version]).to eq('$Latest')
    end

    it 'synthesizes ASG with desired capacity' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_autoscaling_group(:scaled, {
          min_size: 2,
          max_size: 10,
          desired_capacity: 4,
          launch_template: { id: 'lt-123', version: '$Latest' }
        })
      end

      result = synthesizer.synthesis
      asg = result[:resource][:aws_autoscaling_group][:scaled]

      expect(asg[:desired_capacity]).to eq(4)
    end

    it 'synthesizes ASG with VPC subnets' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_autoscaling_group(:vpc_asg, {
          min_size: 1,
          max_size: 3,
          vpc_zone_identifier: ['${aws_subnet.a.id}', '${aws_subnet.b.id}'],
          launch_template: { id: 'lt-123', version: '$Latest' }
        })
      end

      result = synthesizer.synthesis
      asg = result[:resource][:aws_autoscaling_group][:vpc_asg]

      expect(asg[:vpc_zone_identifier]).to include('${aws_subnet.a.id}')
    end

    it 'synthesizes ASG with ELB health check' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_autoscaling_group(:elb_health, {
          min_size: 1,
          max_size: 3,
          health_check_type: 'ELB',
          health_check_grace_period: 300,
          launch_template: { id: 'lt-123', version: '$Latest' }
        })
      end

      result = synthesizer.synthesis
      asg = result[:resource][:aws_autoscaling_group][:elb_health]

      expect(asg[:health_check_type]).to eq('ELB')
      expect(asg[:health_check_grace_period]).to eq(300)
    end

    it 'synthesizes ASG with target groups' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_autoscaling_group(:with_tg, {
          min_size: 1,
          max_size: 5,
          target_group_arns: ['${aws_lb_target_group.main.arn}'],
          launch_template: { id: 'lt-123', version: '$Latest' }
        })
      end

      result = synthesizer.synthesis
      asg = result[:resource][:aws_autoscaling_group][:with_tg]

      expect(asg[:target_group_arns]).to include('${aws_lb_target_group.main.arn}')
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_autoscaling_group(:test, {
          min_size: 1,
          max_size: 3,
          launch_template: { id: 'lt-123', version: '$Latest' }
        })
      end

      expect(ref.id).to eq('${aws_autoscaling_group.test.id}')
      expect(ref.outputs[:arn]).to eq('${aws_autoscaling_group.test.arn}')
      expect(ref.outputs[:name]).to eq('${aws_autoscaling_group.test.name}')
    end
  end
end
