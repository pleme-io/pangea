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
require 'pangea/resources/cloudflare_list_item/resource'
require 'pangea/resources/cloudflare_list_item/types'

RSpec.describe 'cloudflare_list_item synthesis' do
  include Pangea::Resources::Cloudflare

  let(:synthesizer) { TerraformSynthesizer.new }
  let(:account_id) { "a" * 32 }
  let(:list_id) { "2c0fc9fa937b11eaa1b71c4d701ab86e" }

  describe 'IP list items' do
    it 'synthesizes IPv4 address item' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_list_item(:blocked_ip, {
          account_id: "a" * 32,
          list_id: "2c0fc9fa937b11eaa1b71c4d701ab86e",
          ip: "192.0.2.1",
          comment: "Known attacker"
        })
      end

      result = synthesizer.synthesis
      item = result[:resource][:cloudflare_list_item][:blocked_ip]

      expect(item[:account_id]).to eq(account_id)
      expect(item[:list_id]).to eq(list_id)
      expect(item[:ip]).to eq("192.0.2.1")
      expect(item[:comment]).to eq("Known attacker")
    end

    it 'synthesizes IPv4 CIDR item' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_list_item(:blocked_range, {
          account_id: "a" * 32,
          list_id: "2c0fc9fa937b11eaa1b71c4d701ab86e",
          ip: "192.0.2.0/24"
        })
      end

      result = synthesizer.synthesis
      item = result[:resource][:cloudflare_list_item][:blocked_range]

      expect(item[:ip]).to eq("192.0.2.0/24")
    end

    it 'synthesizes IPv6 CIDR item' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_list_item(:ipv6_block, {
          account_id: "a" * 32,
          list_id: "2c0fc9fa937b11eaa1b71c4d701ab86e",
          ip: "2001:db8::/32"
        })
      end

      result = synthesizer.synthesis
      item = result[:resource][:cloudflare_list_item][:ipv6_block]

      expect(item[:ip]).to eq("2001:db8::/32")
    end
  end

  describe 'ASN list items' do
    it 'synthesizes ASN item' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_list_item(:blocked_asn, {
          account_id: "a" * 32,
          list_id: "2c0fc9fa937b11eaa1b71c4d701ab86e",
          asn: 13335,
          comment: "Cloudflare ASN"
        })
      end

      result = synthesizer.synthesis
      item = result[:resource][:cloudflare_list_item][:blocked_asn]

      expect(item[:asn]).to eq(13335)
      expect(item[:comment]).to eq("Cloudflare ASN")
    end
  end

  describe 'Hostname list items' do
    it 'synthesizes hostname item' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_list_item(:blocked_host, {
          account_id: "a" * 32,
          list_id: "2c0fc9fa937b11eaa1b71c4d701ab86e",
          hostname: { url_hostname: "evil.example.com" }
        })
      end

      result = synthesizer.synthesis
      item = result[:resource][:cloudflare_list_item][:blocked_host]

      expect(item[:hostname][:url_hostname]).to eq("evil.example.com")
    end

    it 'synthesizes wildcard hostname item' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_list_item(:wildcard_host, {
          account_id: "a" * 32,
          list_id: "2c0fc9fa937b11eaa1b71c4d701ab86e",
          hostname: { url_hostname: "*.malicious.com" }
        })
      end

      result = synthesizer.synthesis
      item = result[:resource][:cloudflare_list_item][:wildcard_host]

      expect(item[:hostname][:url_hostname]).to eq("*.malicious.com")
    end
  end

  describe 'Redirect list items' do
    it 'synthesizes basic redirect' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_list_item(:simple_redirect, {
          account_id: "a" * 32,
          list_id: "2c0fc9fa937b11eaa1b71c4d701ab86e",
          redirect: {
            source_url: "example.com/old",
            target_url: "https://example.com/new"
          }
        })
      end

      result = synthesizer.synthesis
      item = result[:resource][:cloudflare_list_item][:simple_redirect]

      expect(item[:redirect][:source_url]).to eq("example.com/old")
      expect(item[:redirect][:target_url]).to eq("https://example.com/new")
    end

    it 'synthesizes permanent redirect with all options' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_list_item(:full_redirect, {
          account_id: "a" * 32,
          list_id: "2c0fc9fa937b11eaa1b71c4d701ab86e",
          redirect: {
            source_url: "old.example.com/path",
            target_url: "https://new.example.com/newpath",
            status_code: 301,
            include_subdomains: "enabled",
            preserve_path_suffix: "enabled",
            preserve_query_string: "enabled",
            subpath_matching: "enabled"
          }
        })
      end

      result = synthesizer.synthesis
      item = result[:resource][:cloudflare_list_item][:full_redirect]
      redirect = item[:redirect]

      expect(redirect[:status_code]).to eq(301)
      expect(redirect[:include_subdomains]).to eq("enabled")
      expect(redirect[:preserve_path_suffix]).to eq("enabled")
      expect(redirect[:preserve_query_string]).to eq("enabled")
      expect(redirect[:subpath_matching]).to eq("enabled")
    end

    it 'synthesizes temporary redirect' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_list_item(:temp_redirect, {
          account_id: "a" * 32,
          list_id: "2c0fc9fa937b11eaa1b71c4d701ab86e",
          redirect: {
            source_url: "example.com/maintenance",
            target_url: "https://status.example.com",
            status_code: 302
          }
        })
      end

      result = synthesizer.synthesis
      item = result[:resource][:cloudflare_list_item][:temp_redirect]

      expect(item[:redirect][:status_code]).to eq(302)
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_list_item(:test, {
          account_id: "a" * 32,
          list_id: "2c0fc9fa937b11eaa1b71c4d701ab86e",
          ip: "192.0.2.1"
        })
      end

      expect(ref.id).to eq("${cloudflare_list_item.test.id}")
      expect(ref.outputs[:item_id]).to eq("${cloudflare_list_item.test.id}")
    end
  end

  describe 'validation' do
    it 'requires exactly one item type' do
      expect {
        Cloudflare::Types::ListItemAttributes.new(
          account_id: "a" * 32,
          list_id: "2c0fc9fa937b11eaa1b71c4d701ab86e"
        )
      }.to raise_error(Dry::Struct::Error, /Must specify exactly one of/)
    end

    it 'rejects multiple item types' do
      expect {
        Cloudflare::Types::ListItemAttributes.new(
          account_id: "a" * 32,
          list_id: "2c0fc9fa937b11eaa1b71c4d701ab86e",
          ip: "192.0.2.1",
          asn: 13335
        )
      }.to raise_error(Dry::Struct::Error, /Can only specify one of/)
    end
  end
end
