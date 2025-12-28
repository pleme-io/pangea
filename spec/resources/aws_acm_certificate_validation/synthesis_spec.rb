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
require 'pangea/resources/aws_acm_certificate_validation/resource'

RSpec.describe 'aws_acm_certificate_validation synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }
  let(:valid_cert_arn) { 'arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012' }

  describe 'terraform synthesis' do
    it 'synthesizes basic certificate validation' do
      arn = valid_cert_arn
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_acm_certificate_validation(:example, {
          certificate_arn: arn
        })
      end

      result = synthesizer.synthesis
      validation = result[:resource][:aws_acm_certificate_validation][:example]

      expect(validation[:certificate_arn]).to eq(valid_cert_arn)
    end

    it 'synthesizes validation with DNS record FQDNs' do
      arn = valid_cert_arn
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_acm_certificate_validation(:dns_validated, {
          certificate_arn: arn,
          validation_record_fqdns: ['_abc123.example.com', '_def456.www.example.com']
        })
      end

      result = synthesizer.synthesis
      validation = result[:resource][:aws_acm_certificate_validation][:dns_validated]

      expect(validation[:certificate_arn]).to eq(valid_cert_arn)
      expect(validation[:validation_record_fqdns]).to include('_abc123.example.com')
    end

    it 'synthesizes validation with custom timeouts' do
      arn = valid_cert_arn
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_acm_certificate_validation(:with_timeout, {
          certificate_arn: arn,
          timeouts: { create: '10m' }
        })
      end

      result = synthesizer.synthesis
      validation = result[:resource][:aws_acm_certificate_validation][:with_timeout]

      expect(validation[:timeouts][:create]).to eq('10m')
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      arn = valid_cert_arn
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_acm_certificate_validation(:test, { certificate_arn: arn })
      end

      expect(ref.id).to eq('${aws_acm_certificate_validation.test.id}')
      expect(ref.outputs[:certificate_arn]).to eq('${aws_acm_certificate_validation.test.certificate_arn}')
    end
  end
end
