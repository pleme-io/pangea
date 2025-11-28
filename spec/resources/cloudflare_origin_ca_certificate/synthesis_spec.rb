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
require 'pangea/resources/cloudflare_origin_ca_certificate/resource'
require 'pangea/resources/cloudflare_origin_ca_certificate/types'

RSpec.describe 'cloudflare_origin_ca_certificate synthesis' do
  include Pangea::Resources::Cloudflare

  let(:synthesizer) { TerraformSynthesizer.new }
  let(:test_csr) { "-----BEGIN CERTIFICATE REQUEST-----\nMIICdDCCAVwCAQAwLzEtMCsGA1UEAxMkZXhhbXBsZS5jb20=\n-----END CERTIFICATE REQUEST-----" }

  describe 'RSA certificates' do
    it 'synthesizes 1-year RSA certificate' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        test_csr = "-----BEGIN CERTIFICATE REQUEST-----\nMIICdDCCAVwCAQAwLzEtMCsGA1UEAxMkZXhhbXBsZS5jb20=\n-----END CERTIFICATE REQUEST-----"
        cloudflare_origin_ca_certificate(:rsa_cert, {
          csr: test_csr,
          hostnames: ["example.com", "www.example.com"],
          request_type: "origin-rsa",
          requested_validity: 365
        })
      end

      result = synthesizer.synthesis
      cert = result[:resource][:cloudflare_origin_ca_certificate][:rsa_cert]

      expect(cert[:csr]).to include("BEGIN CERTIFICATE REQUEST")
      expect(cert[:hostnames]).to eq(["example.com", "www.example.com"])
      expect(cert[:request_type]).to eq("origin-rsa")
      expect(cert[:requested_validity]).to eq(365)
    end

    it 'synthesizes long-lived RSA certificate' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        test_csr = "-----BEGIN CERTIFICATE REQUEST-----\nMIICdDCCAVwCAQAwLzEtMCsGA1UEAxMkZXhhbXBsZS5jb20=\n-----END CERTIFICATE REQUEST-----"
        cloudflare_origin_ca_certificate(:long_cert, {
          csr: test_csr,
          hostnames: ["api.example.com"],
          request_type: "origin-rsa",
          requested_validity: 5475
        })
      end

      result = synthesizer.synthesis
      cert = result[:resource][:cloudflare_origin_ca_certificate][:long_cert]

      expect(cert[:requested_validity]).to eq(5475)
    end
  end

  describe 'ECC certificates' do
    it 'synthesizes ECC certificate' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        test_csr = "-----BEGIN CERTIFICATE REQUEST-----\nMIICdDCCAVwCAQAwLzEtMCsGA1UEAxMkZXhhbXBsZS5jb20=\n-----END CERTIFICATE REQUEST-----"
        cloudflare_origin_ca_certificate(:ecc_cert, {
          csr: test_csr,
          hostnames: ["example.com"],
          request_type: "origin-ecc",
          requested_validity: 90
        })
      end

      result = synthesizer.synthesis
      cert = result[:resource][:cloudflare_origin_ca_certificate][:ecc_cert]

      expect(cert[:request_type]).to eq("origin-ecc")
      expect(cert[:requested_validity]).to eq(90)
    end
  end

  describe 'keyless certificates' do
    it 'synthesizes keyless certificate' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        test_csr = "-----BEGIN CERTIFICATE REQUEST-----\nMIICdDCCAVwCAQAwLzEtMCsGA1UEAxMkZXhhbXBsZS5jb20=\n-----END CERTIFICATE REQUEST-----"
        cloudflare_origin_ca_certificate(:keyless, {
          csr: test_csr,
          hostnames: ["secure.example.com"],
          request_type: "keyless-certificate",
          requested_validity: 365
        })
      end

      result = synthesizer.synthesis
      cert = result[:resource][:cloudflare_origin_ca_certificate][:keyless]

      expect(cert[:request_type]).to eq("keyless-certificate")
    end
  end

  describe 'wildcard certificates' do
    it 'synthesizes wildcard certificate' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        test_csr = "-----BEGIN CERTIFICATE REQUEST-----\nMIICdDCCAVwCAQAwLzEtMCsGA1UEAxMkZXhhbXBsZS5jb20=\n-----END CERTIFICATE REQUEST-----"
        cloudflare_origin_ca_certificate(:wildcard, {
          csr: test_csr,
          hostnames: ["*.example.com", "example.com"],
          request_type: "origin-rsa",
          requested_validity: 365
        })
      end

      result = synthesizer.synthesis
      cert = result[:resource][:cloudflare_origin_ca_certificate][:wildcard]

      expect(cert[:hostnames]).to include("*.example.com")
      expect(cert[:hostnames]).to include("example.com")
    end
  end

  describe 'various validity periods' do
    it 'synthesizes 1-week certificate' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        test_csr = "-----BEGIN CERTIFICATE REQUEST-----\nMIICdDCCAVwCAQAwLzEtMCsGA1UEAxMkZXhhbXBsZS5jb20=\n-----END CERTIFICATE REQUEST-----"
        cloudflare_origin_ca_certificate(:weekly, {
          csr: test_csr,
          hostnames: ["test.example.com"],
          request_type: "origin-rsa",
          requested_validity: 7
        })
      end

      result = synthesizer.synthesis
      cert = result[:resource][:cloudflare_origin_ca_certificate][:weekly]

      expect(cert[:requested_validity]).to eq(7)
    end

    it 'synthesizes 1-month certificate' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        test_csr = "-----BEGIN CERTIFICATE REQUEST-----\nMIICdDCCAVwCAQAwLzEtMCsGA1UEAxMkZXhhbXBsZS5jb20=\n-----END CERTIFICATE REQUEST-----"
        cloudflare_origin_ca_certificate(:monthly, {
          csr: test_csr,
          hostnames: ["test.example.com"],
          request_type: "origin-rsa",
          requested_validity: 30
        })
      end

      result = synthesizer.synthesis
      cert = result[:resource][:cloudflare_origin_ca_certificate][:monthly]

      expect(cert[:requested_validity]).to eq(30)
    end

    it 'synthesizes 3-year certificate' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        test_csr = "-----BEGIN CERTIFICATE REQUEST-----\nMIICdDCCAVwCAQAwLzEtMCsGA1UEAxMkZXhhbXBsZS5jb20=\n-----END CERTIFICATE REQUEST-----"
        cloudflare_origin_ca_certificate(:three_years, {
          csr: test_csr,
          hostnames: ["prod.example.com"],
          request_type: "origin-rsa",
          requested_validity: 1095
        })
      end

      result = synthesizer.synthesis
      cert = result[:resource][:cloudflare_origin_ca_certificate][:three_years]

      expect(cert[:requested_validity]).to eq(1095)
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        test_csr = "-----BEGIN CERTIFICATE REQUEST-----\nMIICdDCCAVwCAQAwLzEtMCsGA1UEAxMkZXhhbXBsZS5jb20=\n-----END CERTIFICATE REQUEST-----"
        cloudflare_origin_ca_certificate(:test, {
          csr: test_csr,
          hostnames: ["example.com"],
          request_type: "origin-rsa",
          requested_validity: 365
        })
      end

      expect(ref.id).to eq("${cloudflare_origin_ca_certificate.test.id}")
      expect(ref.outputs[:certificate]).to eq("${cloudflare_origin_ca_certificate.test.certificate}")
      expect(ref.outputs[:expires_on]).to eq("${cloudflare_origin_ca_certificate.test.expires_on}")
    end
  end

  describe 'validation' do
    it 'requires at least one hostname' do
      expect {
        Cloudflare::Types::OriginCACertificateAttributes.new(
          csr: test_csr,
          hostnames: [],
          request_type: "origin-rsa",
          requested_validity: 365
        )
      }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'rejects invalid request type' do
      expect {
        Cloudflare::Types::OriginCACertificateAttributes.new(
          csr: test_csr,
          hostnames: ["example.com"],
          request_type: "invalid",
          requested_validity: 365
        )
      }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'rejects invalid validity period' do
      expect {
        Cloudflare::Types::OriginCACertificateAttributes.new(
          csr: test_csr,
          hostnames: ["example.com"],
          request_type: "origin-rsa",
          requested_validity: 60  # Not in allowed list
        )
      }.to raise_error(Dry::Types::ConstraintError)
    end
  end

  describe 'helper methods' do
    it 'identifies RSA certificate' do
      attrs = Cloudflare::Types::OriginCACertificateAttributes.new(
        csr: test_csr,
        hostnames: ["example.com"],
        request_type: "origin-rsa",
        requested_validity: 365
      )

      expect(attrs.rsa?).to be true
      expect(attrs.ecc?).to be false
      expect(attrs.keyless?).to be false
    end

    it 'identifies ECC certificate' do
      attrs = Cloudflare::Types::OriginCACertificateAttributes.new(
        csr: test_csr,
        hostnames: ["example.com"],
        request_type: "origin-ecc",
        requested_validity: 365
      )

      expect(attrs.rsa?).to be false
      expect(attrs.ecc?).to be true
      expect(attrs.keyless?).to be false
    end

    it 'detects wildcards' do
      attrs = Cloudflare::Types::OriginCACertificateAttributes.new(
        csr: test_csr,
        hostnames: ["*.example.com", "example.com"],
        request_type: "origin-rsa",
        requested_validity: 365
      )

      expect(attrs.has_wildcards?).to be true
    end

    it 'provides validity description' do
      attrs = Cloudflare::Types::OriginCACertificateAttributes.new(
        csr: test_csr,
        hostnames: ["example.com"],
        request_type: "origin-rsa",
        requested_validity: 365
      )

      expect(attrs.validity_description).to eq("1 year")
    end
  end
end
