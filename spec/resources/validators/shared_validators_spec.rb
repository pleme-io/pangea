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
require 'pangea/resources/validators/shared_validators'

RSpec.describe Pangea::Resources::Validators::SharedValidators do
  let(:validators) { described_class }

  describe '.valid_cidr!' do
    it 'accepts valid CIDR blocks' do
      expect(validators.valid_cidr!('10.0.0.0/16')).to eq('10.0.0.0/16')
      expect(validators.valid_cidr!('192.168.1.0/24')).to eq('192.168.1.0/24')
      expect(validators.valid_cidr!('0.0.0.0/0')).to eq('0.0.0.0/0')
    end

    it 'rejects invalid CIDR formats' do
      expect { validators.valid_cidr!('10.0.0.0') }.to raise_error(described_class::ValidationError)
      expect { validators.valid_cidr!('not-a-cidr') }.to raise_error(described_class::ValidationError)
    end

    it 'rejects invalid prefix lengths' do
      expect { validators.valid_cidr!('10.0.0.0/33') }.to raise_error(described_class::ValidationError)
    end

    it 'rejects invalid IP octets' do
      expect { validators.valid_cidr!('256.0.0.0/16') }.to raise_error(described_class::ValidationError)
    end
  end

  describe '.valid_port!' do
    it 'accepts valid port numbers' do
      expect(validators.valid_port!(0)).to eq(0)
      expect(validators.valid_port!(80)).to eq(80)
      expect(validators.valid_port!(65535)).to eq(65535)
    end

    it 'rejects invalid port numbers' do
      expect { validators.valid_port!(-1) }.to raise_error(described_class::ValidationError)
      expect { validators.valid_port!(65536) }.to raise_error(described_class::ValidationError)
      expect { validators.valid_port!('80') }.to raise_error(described_class::ValidationError)
    end
  end

  describe '.valid_port_range!' do
    it 'accepts valid port ranges' do
      expect(validators.valid_port_range!(80, 443)).to be true
      expect(validators.valid_port_range!(22, 22)).to be true
    end

    it 'rejects inverted ranges' do
      expect { validators.valid_port_range!(443, 80) }.to raise_error(described_class::ValidationError)
    end
  end

  describe '.valid_aws_region!' do
    it 'accepts valid AWS regions' do
      expect(validators.valid_aws_region!('us-east-1')).to eq('us-east-1')
      expect(validators.valid_aws_region!('eu-central-1')).to eq('eu-central-1')
    end

    it 'rejects invalid regions' do
      expect { validators.valid_aws_region!('invalid') }.to raise_error(described_class::ValidationError)
    end
  end

  describe '.valid_aws_az!' do
    it 'accepts valid availability zones' do
      expect(validators.valid_aws_az!('us-east-1a')).to eq('us-east-1a')
      expect(validators.valid_aws_az!('eu-west-2b')).to eq('eu-west-2b')
    end

    it 'rejects invalid AZs' do
      expect { validators.valid_aws_az!('us-east-1') }.to raise_error(described_class::ValidationError)
    end
  end

  describe '.valid_domain!' do
    it 'accepts valid domain names' do
      expect(validators.valid_domain!('example.com')).to eq('example.com')
      expect(validators.valid_domain!('sub.example.com')).to eq('sub.example.com')
    end

    it 'accepts wildcard domains when allowed' do
      expect(validators.valid_domain!('*.example.com', allow_wildcard: true)).to eq('*.example.com')
    end

    it 'rejects wildcard domains when not allowed' do
      expect { validators.valid_domain!('*.example.com') }.to raise_error(described_class::ValidationError)
    end
  end

  describe '.valid_email!' do
    it 'accepts valid email addresses' do
      expect(validators.valid_email!('user@example.com')).to eq('user@example.com')
      expect(validators.valid_email!('user.name+tag@domain.co.uk')).to eq('user.name+tag@domain.co.uk')
    end

    it 'rejects invalid emails' do
      expect { validators.valid_email!('not-an-email') }.to raise_error(described_class::ValidationError)
    end
  end

  describe '.terraform_interpolation?' do
    it 'identifies Terraform interpolations' do
      expect(validators.terraform_interpolation?('${aws_vpc.main.id}')).to be true
      expect(validators.terraform_interpolation?('${var.name}')).to be true
    end

    it 'rejects non-interpolations' do
      expect(validators.terraform_interpolation?('plain-string')).to be false
      expect(validators.terraform_interpolation?('${incomplete')).to be false
    end
  end

  describe '.valid_hex!' do
    it 'accepts valid hex strings of specified length' do
      expect(validators.valid_hex!('abc123def456', length: 12)).to eq('abc123def456')
    end

    it 'accepts Terraform interpolations when allowed' do
      expect(validators.valid_hex!('${var.id}', length: 32)).to eq('${var.id}')
    end

    it 'rejects invalid hex strings' do
      expect { validators.valid_hex!('invalid', length: 12) }.to raise_error(described_class::ValidationError)
    end
  end

  describe '.valid_arn!' do
    it 'accepts valid AWS ARNs' do
      expect(validators.valid_arn!('arn:aws:s3:us-east-1:123456789012:bucket/my-bucket')).to be_a(String)
    end

    it 'validates specific service when provided' do
      expect(validators.valid_arn!('arn:aws:s3:us-east-1:123456789012:bucket', service: 's3')).to be_a(String)
    end

    it 'rejects invalid ARNs' do
      expect { validators.valid_arn!('not-an-arn') }.to raise_error(described_class::ValidationError)
    end
  end

  describe '.valid_json!' do
    it 'accepts valid JSON strings' do
      expect(validators.valid_json!('{"key": "value"}')).to eq('{"key": "value"}')
    end

    it 'rejects invalid JSON' do
      expect { validators.valid_json!('not json') }.to raise_error(described_class::ValidationError)
    end
  end

  describe '.valid_base64!' do
    it 'accepts valid base64 strings' do
      expect(validators.valid_base64!('SGVsbG8gV29ybGQ=')).to eq('SGVsbG8gV29ybGQ=')
    end

    it 'rejects invalid base64' do
      expect { validators.valid_base64!('not-base64!!!') }.to raise_error(described_class::ValidationError)
    end
  end
end
