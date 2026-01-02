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
require 'pangea/resources/aws_lb/resource'

RSpec.describe 'aws_lb synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes application load balancer' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_lb(:web, {
          name: 'web-alb',
          load_balancer_type: 'application',
          internal: false,
          subnet_ids: ['${aws_subnet.a.id}', '${aws_subnet.b.id}'],
          security_groups: ['${aws_security_group.alb.id}']
        })
      end

      result = synthesizer.synthesis
      lb = result[:resource][:aws_lb][:web]

      expect(lb[:name]).to eq('web-alb')
      expect(lb[:load_balancer_type]).to eq('application')
      expect(lb[:internal]).to be false
    end

    it 'synthesizes network load balancer' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_lb(:network, {
          name: 'network-nlb',
          load_balancer_type: 'network',
          internal: true,
          subnet_ids: ['${aws_subnet.a.id}', '${aws_subnet.b.id}']
        })
      end

      result = synthesizer.synthesis
      lb = result[:resource][:aws_lb][:network]

      expect(lb[:load_balancer_type]).to eq('network')
      expect(lb[:internal]).to be true
    end

    it 'synthesizes load balancer with access logs' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_lb(:logged, {
          name: 'logged-alb',
          load_balancer_type: 'application',
          internal: false,
          subnet_ids: ['${aws_subnet.a.id}'],
          access_logs: {
            bucket: 'my-logs-bucket',
            prefix: 'alb-logs',
            enabled: true
          }
        })
      end

      result = synthesizer.synthesis
      lb = result[:resource][:aws_lb][:logged]

      expect(lb[:access_logs][:bucket]).to eq('my-logs-bucket')
      expect(lb[:access_logs][:enabled]).to be true
    end

    it 'synthesizes load balancer with tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_lb(:tagged, {
          name: 'tagged-alb',
          load_balancer_type: 'application',
          internal: false,
          subnet_ids: ['${aws_subnet.a.id}'],
          tags: { Environment: 'production' }
        })
      end

      result = synthesizer.synthesis
      lb = result[:resource][:aws_lb][:tagged]

      expect(lb[:tags][:Environment]).to eq('production')
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_lb(:test, {
          name: 'test-alb',
          load_balancer_type: 'application',
          internal: false,
          subnet_ids: ['subnet-123']
        })
      end

      expect(ref.outputs[:arn]).to eq('${aws_lb.test.arn}')
      expect(ref.outputs[:dns_name]).to eq('${aws_lb.test.dns_name}')
      expect(ref.outputs[:zone_id]).to eq('${aws_lb.test.zone_id}')
    end
  end
end
