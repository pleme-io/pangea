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
require 'pangea/resources/aws_instance/resource'

RSpec.describe 'aws_instance synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic EC2 instance' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_instance(:web, {
          ami: 'ami-0123456789abcdef0',
          instance_type: 't3.micro'
        })
      end

      result = synthesizer.synthesis
      instance = result[:resource][:aws_instance][:web]

      expect(instance[:ami]).to eq('ami-0123456789abcdef0')
      expect(instance[:instance_type]).to eq('t3.micro')
    end

    it 'synthesizes instance with subnet and security groups' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_instance(:vpc_instance, {
          ami: 'ami-0123456789abcdef0',
          instance_type: 't3.small',
          subnet_id: '${aws_subnet.private.id}',
          vpc_security_group_ids: ['${aws_security_group.web.id}']
        })
      end

      result = synthesizer.synthesis
      instance = result[:resource][:aws_instance][:vpc_instance]

      expect(instance[:subnet_id]).to eq('${aws_subnet.private.id}')
      expect(instance[:vpc_security_group_ids]).to include('${aws_security_group.web.id}')
    end

    it 'synthesizes instance with key pair' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_instance(:ssh_instance, {
          ami: 'ami-0123456789abcdef0',
          instance_type: 't3.micro',
          key_name: 'my-key-pair'
        })
      end

      result = synthesizer.synthesis
      instance = result[:resource][:aws_instance][:ssh_instance]

      expect(instance[:key_name]).to eq('my-key-pair')
    end

    it 'synthesizes instance with tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_instance(:tagged, {
          ami: 'ami-0123456789abcdef0',
          instance_type: 't3.micro',
          tags: { Name: 'web-server', Environment: 'production' }
        })
      end

      result = synthesizer.synthesis
      instance = result[:resource][:aws_instance][:tagged]

      expect(instance[:tags][:Name]).to eq('web-server')
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_instance(:test, {
          ami: 'ami-test',
          instance_type: 't3.micro'
        })
      end

      expect(ref.outputs[:public_ip]).to eq('${aws_instance.test.public_ip}')
      expect(ref.outputs[:private_ip]).to eq('${aws_instance.test.private_ip}')
    end
  end
end
