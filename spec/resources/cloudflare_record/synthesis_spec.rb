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
require 'pangea/resources/cloudflare_record/resource'
require 'pangea/resources/cloudflare_record/types'

RSpec.describe 'cloudflare_record synthesis' do
  include Pangea::Resources::Cloudflare

  let(:synthesizer) { TerraformSynthesizer.new }
  let(:zone_id) { "a" * 32 }

  describe 'terraform synthesis' do
    it 'synthesizes basic A record' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_record(:www, {
          zone_id: "a" * 32,
          name: "www",
          type: "A",
          value: "192.0.2.1"
        })
      end

      result = synthesizer.synthesis
      record = result[:resource][:cloudflare_record][:www]

      expect(record).to include(
        zone_id: zone_id,
        name: "www",
        type: "A",
        value: "192.0.2.1",
        ttl: 1  # Automatic
      )
      expect(record).not_to have_key(:proxied)  # False by default, not included
    end

    it 'synthesizes proxied A record (orange cloud)' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_record(:cdn, {
          zone_id: "a" * 32,
          name: "cdn",
          type: "A",
          value: "192.0.2.1",
          proxied: true
        })
      end

      result = synthesizer.synthesis
      record = result[:resource][:cloudflare_record][:cdn]

      expect(record[:proxied]).to be true
      expect(record[:ttl]).to eq(1)  # Must be automatic for proxied
    end

    it 'synthesizes MX record with priority' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_record(:mx_primary, {
          zone_id: "a" * 32,
          name: "@",
          type: "MX",
          value: "mail.example.com",
          priority: 10
        })
      end

      result = synthesizer.synthesis
      record = result[:resource][:cloudflare_record][:mx_primary]

      expect(record[:type]).to eq("MX")
      expect(record[:priority]).to eq(10)
      expect(record).not_to have_key(:proxied)
    end

    it 'synthesizes TXT record with comment' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_record(:spf, {
          zone_id: "a" * 32,
          name: "@",
          type: "TXT",
          value: "v=spf1 include:_spf.google.com ~all",
          comment: "SPF record for Google Workspace"
        })
      end

      result = synthesizer.synthesis
      record = result[:resource][:cloudflare_record][:spf]

      expect(record[:type]).to eq("TXT")
      expect(record[:value]).to match(/spf1/)
      expect(record[:comment]).to eq("SPF record for Google Workspace")
    end

    it 'synthesizes CNAME record' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_record(:blog, {
          zone_id: "a" * 32,
          name: "blog",
          type: "CNAME",
          value: "example.com",
          proxied: true,
          tags: { "Type" => "blog", "Environment" => "production" }
        })
      end

      result = synthesizer.synthesis
      record = result[:resource][:cloudflare_record][:blog]

      expect(record[:type]).to eq("CNAME")
      expect(record[:proxied]).to be true
      expect(record[:tags]).to include(Type: "blog", Environment: "production")
    end
  end

  describe 'resource composition' do
    it 'creates multiple records for a zone' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare

        # Root domain
        cloudflare_record(:root, {
          zone_id: "a" * 32,
          name: "@",
          type: "A",
          value: "192.0.2.1",
          proxied: true
        })

        # WWW subdomain
        cloudflare_record(:www, {
          zone_id: "a" * 32,
          name: "www",
          type: "A",
          value: "192.0.2.1",
          proxied: true
        })

        # Mail server
        cloudflare_record(:mx1, {
          zone_id: "a" * 32,
          name: "@",
          type: "MX",
          value: "mail.example.com",
          priority: 10
        })
      end

      result = synthesizer.synthesis
      records = result[:resource][:cloudflare_record]

      expect(records).to have_key(:root)
      expect(records).to have_key(:www)
      expect(records).to have_key(:mx1)
      expect(records[:root][:proxied]).to be true
      expect(records[:mx1][:priority]).to eq(10)
    end
  end
end
