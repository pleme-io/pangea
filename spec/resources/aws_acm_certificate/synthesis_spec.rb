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
require 'pangea/resources/aws_acm_certificate/resource'

RSpec.describe 'aws_acm_certificate synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic certificate with DNS validation' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_acm_certificate(:example, {
          domain_name: 'example.com'
        })
      end

      result = synthesizer.synthesis
      cert = result[:resource][:aws_acm_certificate][:example]

      expect(cert[:domain_name]).to eq('example.com')
      expect(cert[:validation_method]).to eq('DNS')
    end

    it 'synthesizes wildcard certificate' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_acm_certificate(:wildcard, {
          domain_name: '*.example.com',
          validation_method: 'DNS'
        })
      end

      result = synthesizer.synthesis
      cert = result[:resource][:aws_acm_certificate][:wildcard]

      expect(cert[:domain_name]).to eq('*.example.com')
    end

    it 'synthesizes certificate with subject alternative names' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_acm_certificate(:multi_domain, {
          domain_name: 'example.com',
          subject_alternative_names: ['www.example.com', 'api.example.com']
        })
      end

      result = synthesizer.synthesis
      cert = result[:resource][:aws_acm_certificate][:multi_domain]

      expect(cert[:domain_name]).to eq('example.com')
      expect(cert[:subject_alternative_names]).to include('www.example.com', 'api.example.com')
    end

    it 'synthesizes certificate with tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_acm_certificate(:tagged, {
          domain_name: 'example.com',
          tags: { Name: 'example-cert', Environment: 'production' }
        })
      end

      result = synthesizer.synthesis
      cert = result[:resource][:aws_acm_certificate][:tagged]

      expect(cert[:tags][:Name]).to eq('example-cert')
      expect(cert[:tags][:Environment]).to eq('production')
    end

    it 'synthesizes certificate with email validation' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_acm_certificate(:email_validated, {
          domain_name: 'example.com',
          validation_method: 'EMAIL'
        })
      end

      result = synthesizer.synthesis
      cert = result[:resource][:aws_acm_certificate][:email_validated]

      expect(cert[:validation_method]).to eq('EMAIL')
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_acm_certificate(:test, { domain_name: 'test.com' })
      end

      expect(ref.id).to eq('${aws_acm_certificate.test.id}')
      expect(ref.outputs[:arn]).to eq('${aws_acm_certificate.test.arn}')
      expect(ref.outputs[:domain_validation_options]).to eq('${aws_acm_certificate.test.domain_validation_options}')
    end
  end
end
