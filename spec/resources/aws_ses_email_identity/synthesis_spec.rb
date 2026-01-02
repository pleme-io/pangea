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
require 'pangea/resources/aws_ses_email_identity/resource'

RSpec.describe 'aws_ses_email_identity synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic email identity' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ses_email_identity(:sender, {
          email: 'sender@example.com'
        })
      end

      result = synthesizer.synthesis
      identity = result[:resource][:aws_ses_email_identity][:sender]

      expect(identity[:email]).to eq('sender@example.com')
    end

    it 'normalizes email to lowercase' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ses_email_identity(:uppercase, {
          email: 'Sender@Example.COM'
        })
      end

      result = synthesizer.synthesis
      identity = result[:resource][:aws_ses_email_identity][:uppercase]

      expect(identity[:email]).to eq('sender@example.com')
    end

    it 'synthesizes multiple email identities' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ses_email_identity(:noreply, { email: 'noreply@example.com' })
        aws_ses_email_identity(:support, { email: 'support@example.com' })
      end

      result = synthesizer.synthesis

      expect(result[:resource][:aws_ses_email_identity][:noreply][:email]).to eq('noreply@example.com')
      expect(result[:resource][:aws_ses_email_identity][:support][:email]).to eq('support@example.com')
    end

    it 'synthesizes email with subdomain' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ses_email_identity(:subdomain_email, {
          email: 'alerts@mail.example.com'
        })
      end

      result = synthesizer.synthesis
      identity = result[:resource][:aws_ses_email_identity][:subdomain_email]

      expect(identity[:email]).to eq('alerts@mail.example.com')
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ses_email_identity(:test, { email: 'test@example.com' })
      end

      expect(ref.outputs[:email]).to eq('${aws_ses_email_identity.test.email}')
      expect(ref.outputs[:arn]).to eq('${aws_ses_email_identity.test.arn}')
    end

    it 'returns ResourceReference object' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ses_email_identity(:ref_test, { email: 'ref@example.com' })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_ses_email_identity')
      expect(ref.name).to eq(:ref_test)
    end
  end

  describe 'terraform validation' do
    it 'produces valid terraform structure' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ses_email_identity(:validation, { email: 'valid@example.com' })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result[:resource]).to be_a(Hash)
      expect(result[:resource][:aws_ses_email_identity]).to be_a(Hash)
      expect(result[:resource][:aws_ses_email_identity][:validation]).to be_a(Hash)

      identity = result[:resource][:aws_ses_email_identity][:validation]
      expect(identity).to have_key(:email)
      expect(identity[:email]).to be_a(String)
    end
  end
end
