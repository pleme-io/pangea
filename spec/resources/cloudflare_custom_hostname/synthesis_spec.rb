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
require 'pangea/resources/cloudflare_custom_hostname/resource'
require 'pangea/resources/cloudflare_custom_hostname/types'

RSpec.describe 'cloudflare_custom_hostname synthesis' do
  include Pangea::Resources::Cloudflare

  let(:synthesizer) { TerraformSynthesizer.new }
  let(:zone_id) { "023e105f4ecef8ad9ca31a8372d0c353" }

  describe 'basic custom hostnames' do
    it 'synthesizes minimal custom hostname' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_custom_hostname(:basic, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          hostname: "app.customer.com"
        })
      end

      result = synthesizer.synthesis
      hostname = result[:resource][:cloudflare_custom_hostname][:basic]

      expect(hostname[:zone_id]).to eq(zone_id)
      expect(hostname[:hostname]).to eq("app.customer.com")
    end

    it 'synthesizes custom hostname with HTTP validation' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_custom_hostname(:http_validation, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          hostname: "app.customer.com",
          ssl: {
            method: "http",
            type: "dv"
          }
        })
      end

      result = synthesizer.synthesis
      hostname = result[:resource][:cloudflare_custom_hostname][:http_validation]

      expect(hostname[:ssl][:method]).to eq("http")
      expect(hostname[:ssl][:type]).to eq("dv")
    end

    it 'synthesizes custom hostname with TXT validation' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_custom_hostname(:txt_validation, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          hostname: "app.customer.com",
          ssl: {
            method: "txt",
            type: "dv"
          }
        })
      end

      result = synthesizer.synthesis
      hostname = result[:resource][:cloudflare_custom_hostname][:txt_validation]

      expect(hostname[:ssl][:method]).to eq("txt")
    end
  end

  describe 'certificate authorities' do
    it 'synthesizes with Let\'s Encrypt' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_custom_hostname(:lets_encrypt, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          hostname: "app.customer.com",
          ssl: {
            method: "http",
            certificate_authority: "lets_encrypt"
          }
        })
      end

      result = synthesizer.synthesis
      hostname = result[:resource][:cloudflare_custom_hostname][:lets_encrypt]

      expect(hostname[:ssl][:certificate_authority]).to eq("lets_encrypt")
    end

    it 'synthesizes with DigiCert' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_custom_hostname(:digicert, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          hostname: "secure.customer.com",
          ssl: {
            method: "txt",
            certificate_authority: "digicert",
            bundle_method: "ubiquitous"
          }
        })
      end

      result = synthesizer.synthesis
      hostname = result[:resource][:cloudflare_custom_hostname][:digicert]

      expect(hostname[:ssl][:certificate_authority]).to eq("digicert")
      expect(hostname[:ssl][:bundle_method]).to eq("ubiquitous")
    end

    it 'synthesizes with Google Trust Services' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_custom_hostname(:google, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          hostname: "api.customer.com",
          ssl: {
            method: "http",
            certificate_authority: "google"
          }
        })
      end

      result = synthesizer.synthesis
      hostname = result[:resource][:cloudflare_custom_hostname][:google]

      expect(hostname[:ssl][:certificate_authority]).to eq("google")
    end
  end

  describe 'wildcard hostnames' do
    it 'synthesizes wildcard custom hostname' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_custom_hostname(:wildcard, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          hostname: "*.customer.com",
          ssl: {
            method: "txt",
            type: "dv_wildcard",
            wildcard: true
          }
        })
      end

      result = synthesizer.synthesis
      hostname = result[:resource][:cloudflare_custom_hostname][:wildcard]

      expect(hostname[:hostname]).to eq("*.customer.com")
      expect(hostname[:ssl][:type]).to eq("dv_wildcard")
      expect(hostname[:ssl][:wildcard]).to be true
    end
  end

  describe 'custom origin configuration' do
    it 'synthesizes with custom origin server' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_custom_hostname(:custom_origin, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          hostname: "app.customer.com",
          ssl: { method: "http" },
          custom_origin_server: "origin.myapp.com"
        })
      end

      result = synthesizer.synthesis
      hostname = result[:resource][:cloudflare_custom_hostname][:custom_origin]

      expect(hostname[:custom_origin_server]).to eq("origin.myapp.com")
    end

    it 'synthesizes with custom origin SNI' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_custom_hostname(:custom_sni, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          hostname: "app.customer.com",
          ssl: { method: "http" },
          custom_origin_server: "origin.myapp.com",
          custom_origin_sni: "sni.myapp.com"
        })
      end

      result = synthesizer.synthesis
      hostname = result[:resource][:cloudflare_custom_hostname][:custom_sni]

      expect(hostname[:custom_origin_server]).to eq("origin.myapp.com")
      expect(hostname[:custom_origin_sni]).to eq("sni.myapp.com")
    end
  end

  describe 'custom metadata' do
    it 'synthesizes with custom metadata' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_custom_hostname(:with_metadata, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          hostname: "app.customer.com",
          ssl: { method: "http" },
          custom_metadata: {
            "customer_id" => "cust_123",
            "plan" => "enterprise",
            "region" => "us-east"
          }
        })
      end

      result = synthesizer.synthesis
      hostname = result[:resource][:cloudflare_custom_hostname][:with_metadata]

      expect(hostname[:custom_metadata]).to be_a(Hash)
      expect(hostname[:custom_metadata][:customer_id]).to eq("cust_123")
      expect(hostname[:custom_metadata][:plan]).to eq("enterprise")
    end
  end

  describe 'SSL settings' do
    it 'synthesizes with SSL settings' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_custom_hostname(:ssl_settings, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          hostname: "secure.customer.com",
          ssl: {
            method: "txt",
            settings: {
              min_tls_version: "1.2",
              http2: "on",
              tls13: "on",
              early_hints: "on"
            }
          }
        })
      end

      result = synthesizer.synthesis
      hostname = result[:resource][:cloudflare_custom_hostname][:ssl_settings]

      expect(hostname[:ssl][:settings][:min_tls_version]).to eq("1.2")
      expect(hostname[:ssl][:settings][:http2]).to eq("on")
      expect(hostname[:ssl][:settings][:tls13]).to eq("on")
      expect(hostname[:ssl][:settings][:early_hints]).to eq("on")
    end

    it 'synthesizes with cipher suites' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_custom_hostname(:ciphers, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          hostname: "api.customer.com",
          ssl: {
            method: "http",
            settings: {
              min_tls_version: "1.3",
              ciphers: ["TLS_AES_128_GCM_SHA256", "TLS_AES_256_GCM_SHA384"]
            }
          }
        })
      end

      result = synthesizer.synthesis
      hostname = result[:resource][:cloudflare_custom_hostname][:ciphers]

      expect(hostname[:ssl][:settings][:ciphers]).to be_an(Array)
      expect(hostname[:ssl][:settings][:ciphers].length).to eq(2)
    end
  end

  describe 'bundle methods' do
    it 'synthesizes with ubiquitous bundle' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_custom_hostname(:ubiquitous, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          hostname: "app.customer.com",
          ssl: {
            method: "http",
            bundle_method: "ubiquitous"
          }
        })
      end

      result = synthesizer.synthesis
      hostname = result[:resource][:cloudflare_custom_hostname][:ubiquitous]

      expect(hostname[:ssl][:bundle_method]).to eq("ubiquitous")
    end

    it 'synthesizes with optimal bundle' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_custom_hostname(:optimal, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          hostname: "app.customer.com",
          ssl: {
            method: "http",
            bundle_method: "optimal"
          }
        })
      end

      result = synthesizer.synthesis
      hostname = result[:resource][:cloudflare_custom_hostname][:optimal]

      expect(hostname[:ssl][:bundle_method]).to eq("optimal")
    end
  end

  describe 'SSL validation waiting' do
    it 'synthesizes with wait_for_ssl_pending_validation' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_custom_hostname(:wait_ssl, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          hostname: "app.customer.com",
          ssl: { method: "http" },
          wait_for_ssl_pending_validation: true
        })
      end

      result = synthesizer.synthesis
      hostname = result[:resource][:cloudflare_custom_hostname][:wait_ssl]

      expect(hostname[:wait_for_ssl_pending_validation]).to be true
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_custom_hostname(:test, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          hostname: "app.customer.com",
          ssl: { method: "http" }
        })
      end

      expect(ref.id).to eq("${cloudflare_custom_hostname.test.id}")
      expect(ref.outputs[:status]).to eq("${cloudflare_custom_hostname.test.status}")
      expect(ref.outputs[:ssl_status]).to eq("${cloudflare_custom_hostname.test.ssl.0.status}")
    end
  end

  describe 'validation' do
    it 'requires valid hostname format' do
      expect {
        Cloudflare::Types::CustomHostnameAttributes.new(
          zone_id: zone_id,
          hostname: "invalid_hostname!"
        )
      }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'rejects invalid SSL method' do
      expect {
        Cloudflare::Types::CustomHostnameAttributes.new(
          zone_id: zone_id,
          hostname: "app.customer.com",
          ssl: { method: "invalid" }
        )
      }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'rejects invalid certificate authority' do
      expect {
        Cloudflare::Types::CustomHostnameAttributes.new(
          zone_id: zone_id,
          hostname: "app.customer.com",
          ssl: {
            method: "http",
            certificate_authority: "invalid_ca"
          }
        )
      }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'rejects invalid min_tls_version' do
      expect {
        Cloudflare::Types::CustomHostnameAttributes.new(
          zone_id: zone_id,
          hostname: "app.customer.com",
          ssl: {
            method: "http",
            settings: { min_tls_version: "0.9" }
          }
        )
      }.to raise_error(Dry::Types::ConstraintError)
    end
  end

  describe 'helper methods' do
    it 'identifies SSL configuration' do
      attrs = Cloudflare::Types::CustomHostnameAttributes.new(
        zone_id: zone_id,
        hostname: "app.customer.com",
        ssl: { method: "http" }
      )

      expect(attrs.ssl_configured?).to be true
    end

    it 'identifies custom origin' do
      attrs = Cloudflare::Types::CustomHostnameAttributes.new(
        zone_id: zone_id,
        hostname: "app.customer.com",
        custom_origin_server: "origin.myapp.com"
      )

      expect(attrs.custom_origin?).to be true
    end

    it 'detects wildcard hostnames' do
      attrs = Cloudflare::Types::CustomHostnameAttributes.new(
        zone_id: zone_id,
        hostname: "*.customer.com"
      )

      expect(attrs.wildcard?).to be true
    end

    it 'detects custom metadata' do
      attrs = Cloudflare::Types::CustomHostnameAttributes.new(
        zone_id: zone_id,
        hostname: "app.customer.com",
        custom_metadata: { "key" => "value" }
      )

      expect(attrs.has_custom_metadata?).to be true
    end

    it 'identifies custom certificate' do
      ssl = Cloudflare::Types::CustomHostnameSSL.new(
        custom_certificate: "-----BEGIN CERTIFICATE-----",
        custom_key: "-----BEGIN PRIVATE KEY-----"
      )

      expect(ssl.custom_certificate?).to be true
    end

    it 'identifies wildcard SSL' do
      ssl = Cloudflare::Types::CustomHostnameSSL.new(
        wildcard: true
      )

      expect(ssl.wildcard?).to be true
    end
  end
end
