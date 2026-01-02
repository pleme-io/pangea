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
require 'pangea/resources/aws_ses_domain_identity/resource'

RSpec.describe 'aws_ses_domain_identity synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic domain identity' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ses_domain_identity(:main, {
          domain: 'example.com'
        })
      end

      result = synthesizer.synthesis
      identity = result[:resource][:aws_ses_domain_identity][:main]

      expect(identity[:domain]).to eq('example.com')
    end

    it 'synthesizes subdomain identity' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ses_domain_identity(:subdomain, {
          domain: 'mail.example.com'
        })
      end

      result = synthesizer.synthesis
      identity = result[:resource][:aws_ses_domain_identity][:subdomain]

      expect(identity[:domain]).to eq('mail.example.com')
    end

    it 'synthesizes multiple domain identities' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ses_domain_identity(:primary, { domain: 'primary.com' })
        aws_ses_domain_identity(:secondary, { domain: 'secondary.com' })
      end

      result = synthesizer.synthesis

      expect(result[:resource][:aws_ses_domain_identity][:primary][:domain]).to eq('primary.com')
      expect(result[:resource][:aws_ses_domain_identity][:secondary][:domain]).to eq('secondary.com')
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ses_domain_identity(:test, { domain: 'test.com' })
      end

      expect(ref.outputs[:domain]).to eq('${aws_ses_domain_identity.test.domain}')
      expect(ref.outputs[:arn]).to eq('${aws_ses_domain_identity.test.arn}')
      expect(ref.outputs[:verification_token]).to eq('${aws_ses_domain_identity.test.verification_token}')
    end

    it 'returns ResourceReference object' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ses_domain_identity(:ref_test, { domain: 'example.org' })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_ses_domain_identity')
      expect(ref.name).to eq(:ref_test)
    end
  end

  describe 'terraform validation' do
    it 'produces valid terraform structure' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ses_domain_identity(:validation, { domain: 'valid.com' })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result[:resource]).to be_a(Hash)
      expect(result[:resource][:aws_ses_domain_identity]).to be_a(Hash)
      expect(result[:resource][:aws_ses_domain_identity][:validation]).to be_a(Hash)

      identity = result[:resource][:aws_ses_domain_identity][:validation]
      expect(identity).to have_key(:domain)
      expect(identity[:domain]).to be_a(String)
    end
  end
end
