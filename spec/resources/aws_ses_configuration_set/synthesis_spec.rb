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
require 'pangea/resources/aws_ses_configuration_set/resource'

RSpec.describe 'aws_ses_configuration_set synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic configuration set' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ses_configuration_set(:default, {
          name: 'default-config'
        })
      end

      result = synthesizer.synthesis
      config_set = result[:resource][:aws_ses_configuration_set][:default]

      expect(config_set[:name]).to eq('default-config')
    end

    it 'synthesizes configuration set with reputation metrics' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ses_configuration_set(:with_metrics, {
          name: 'metrics-enabled',
          reputation_metrics_enabled: true
        })
      end

      result = synthesizer.synthesis
      config_set = result[:resource][:aws_ses_configuration_set][:with_metrics]

      expect(config_set[:name]).to eq('metrics-enabled')
      expect(config_set[:reputation_metrics_enabled]).to be true
    end

    it 'synthesizes configuration set with sending disabled' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ses_configuration_set(:disabled, {
          name: 'sending-disabled',
          sending_enabled: false
        })
      end

      result = synthesizer.synthesis
      config_set = result[:resource][:aws_ses_configuration_set][:disabled]

      expect(config_set[:name]).to eq('sending-disabled')
      expect(config_set[:sending_enabled]).to be false
    end

    it 'synthesizes configuration set with TLS delivery options' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ses_configuration_set(:secure, {
          name: 'secure-config',
          delivery_options: {
            tls_policy: 'Require'
          }
        })
      end

      result = synthesizer.synthesis
      config_set = result[:resource][:aws_ses_configuration_set][:secure]

      expect(config_set[:name]).to eq('secure-config')
      expect(config_set[:delivery_options][:tls_policy]).to eq('Require')
    end

    it 'synthesizes multiple configuration sets' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ses_configuration_set(:transactional, { name: 'transactional' })
        aws_ses_configuration_set(:marketing, { name: 'marketing' })
      end

      result = synthesizer.synthesis

      expect(result[:resource][:aws_ses_configuration_set][:transactional][:name]).to eq('transactional')
      expect(result[:resource][:aws_ses_configuration_set][:marketing][:name]).to eq('marketing')
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ses_configuration_set(:test, { name: 'test-config' })
      end

      expect(ref.outputs[:name]).to eq('${aws_ses_configuration_set.test.name}')
      expect(ref.outputs[:arn]).to eq('${aws_ses_configuration_set.test.arn}')
      expect(ref.outputs[:last_fresh_start]).to eq('${aws_ses_configuration_set.test.last_fresh_start}')
    end

    it 'returns ResourceReference object' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ses_configuration_set(:ref_test, { name: 'ref-test' })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_ses_configuration_set')
      expect(ref.name).to eq(:ref_test)
    end
  end

  describe 'terraform validation' do
    it 'produces valid terraform structure' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ses_configuration_set(:validation, { name: 'validation-config' })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result[:resource]).to be_a(Hash)
      expect(result[:resource][:aws_ses_configuration_set]).to be_a(Hash)
      expect(result[:resource][:aws_ses_configuration_set][:validation]).to be_a(Hash)

      config_set = result[:resource][:aws_ses_configuration_set][:validation]
      expect(config_set).to have_key(:name)
      expect(config_set[:name]).to be_a(String)
    end
  end
end
