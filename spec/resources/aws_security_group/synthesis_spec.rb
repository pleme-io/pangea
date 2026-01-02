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
require 'pangea/resources/aws_security_group/resource'

RSpec.describe 'aws_security_group synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic security group' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_security_group(:web, {
          name_prefix: 'web-',
          vpc_id: '${aws_vpc.main.id}',
          description: 'Security group for web servers'
        })
      end

      result = synthesizer.synthesis
      sg = result[:resource][:aws_security_group][:web]

      expect(sg[:name_prefix]).to eq('web-')
      expect(sg[:vpc_id]).to eq('${aws_vpc.main.id}')
    end

    it 'synthesizes security group with ingress rules' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_security_group(:with_ingress, {
          name_prefix: 'web-',
          vpc_id: '${aws_vpc.main.id}',
          ingress_rules: [
            { from_port: 80, to_port: 80, protocol: 'tcp', cidr_blocks: ['0.0.0.0/0'] },
            { from_port: 443, to_port: 443, protocol: 'tcp', cidr_blocks: ['0.0.0.0/0'] }
          ]
        })
      end

      result = synthesizer.synthesis
      sg = result[:resource][:aws_security_group][:with_ingress]

      expect(sg[:ingress].length).to eq(2)
    end

    it 'synthesizes security group with egress rules' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_security_group(:with_egress, {
          name_prefix: 'app-',
          vpc_id: '${aws_vpc.main.id}',
          egress_rules: [
            { from_port: 0, to_port: 0, protocol: '-1', cidr_blocks: ['0.0.0.0/0'] }
          ]
        })
      end

      result = synthesizer.synthesis
      sg = result[:resource][:aws_security_group][:with_egress]

      expect(sg[:egress].length).to eq(1)
    end

    it 'synthesizes security group with tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_security_group(:tagged, {
          name_prefix: 'web-',
          vpc_id: '${aws_vpc.main.id}',
          tags: { Name: 'web-sg', Environment: 'production' }
        })
      end

      result = synthesizer.synthesis
      sg = result[:resource][:aws_security_group][:tagged]

      expect(sg[:tags][:Name]).to eq('web-sg')
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_security_group(:test, {
          name_prefix: 'test-',
          vpc_id: 'vpc-123'
        })
      end

      expect(ref.id).to eq('${aws_security_group.test.id}')
      expect(ref.outputs[:arn]).to eq('${aws_security_group.test.arn}')
    end
  end
end
