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
require 'pangea/resources/cloudflare_zone/resource'
require 'pangea/resources/cloudflare_zone_dnssec/resource'
require 'pangea/resources/cloudflare_zone_dnssec/types'

RSpec.describe 'cloudflare_zone_dnssec synthesis' do
  include Pangea::Resources::Cloudflare

  let(:synthesizer) { TerraformSynthesizer.new }
  let(:zone_id) { "023e105f4ecef8ad9ca31a8372d0c353" }

  describe 'terraform synthesis' do
    it 'synthesizes basic DNSSEC configuration' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_zone_dnssec(:basic, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353"
        })
      end

      result = synthesizer.synthesis
      dnssec = result[:resource][:cloudflare_zone_dnssec][:basic]

      expect(dnssec).to include(
        zone_id: zone_id
      )
      expect(dnssec).not_to have_key(:dnssec_presigned)
      expect(dnssec).not_to have_key(:dnssec_multi_signer)
    end

    it 'synthesizes DNSSEC with presigned records' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_zone_dnssec(:presigned, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          dnssec_presigned: true
        })
      end

      result = synthesizer.synthesis
      dnssec = result[:resource][:cloudflare_zone_dnssec][:presigned]

      expect(dnssec[:dnssec_presigned]).to be true
    end

    it 'synthesizes DNSSEC with multi-signer enabled' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_zone_dnssec(:multi_signer, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          dnssec_multi_signer: true
        })
      end

      result = synthesizer.synthesis
      dnssec = result[:resource][:cloudflare_zone_dnssec][:multi_signer]

      expect(dnssec[:dnssec_multi_signer]).to be true
    end

    it 'synthesizes DNSSEC with both presigned and multi-signer' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_zone_dnssec(:advanced, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          dnssec_presigned: true,
          dnssec_multi_signer: true
        })
      end

      result = synthesizer.synthesis
      dnssec = result[:resource][:cloudflare_zone_dnssec][:advanced]

      expect(dnssec[:dnssec_presigned]).to be true
      expect(dnssec[:dnssec_multi_signer]).to be true
    end
  end

  describe 'resource composition' do
    it 'creates zone with DNSSEC enabled' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare

        # Create zone
        zone_ref = cloudflare_zone(:example, {
          zone: "example.com",
          plan: "free",
          type: "full"
        })

        # Enable DNSSEC for the zone
        cloudflare_zone_dnssec(:example_dnssec, {
          zone_id: zone_ref.zone_id
        })
      end

      result = synthesizer.synthesis

      expect(result[:resource][:cloudflare_zone]).to have_key(:example)
      expect(result[:resource][:cloudflare_zone_dnssec]).to have_key(:example_dnssec)

      dnssec = result[:resource][:cloudflare_zone_dnssec][:example_dnssec]
      expect(dnssec[:zone_id]).to eq("${cloudflare_zone.example.id}")
    end

    it 'creates multiple zones with DNSSEC' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare

        # Primary zone
        zone1 = cloudflare_zone(:primary, {
          zone: "primary.com",
          plan: "free",
          type: "full"
        })

        cloudflare_zone_dnssec(:primary_dnssec, {
          zone_id: zone1.zone_id
        })

        # Secondary zone
        zone2 = cloudflare_zone(:secondary, {
          zone: "secondary.com",
          plan: "pro",
          type: "full"
        })

        cloudflare_zone_dnssec(:secondary_dnssec, {
          zone_id: zone2.zone_id,
          dnssec_presigned: true
        })
      end

      result = synthesizer.synthesis

      expect(result[:resource][:cloudflare_zone_dnssec]).to have_key(:primary_dnssec)
      expect(result[:resource][:cloudflare_zone_dnssec]).to have_key(:secondary_dnssec)
      expect(result[:resource][:cloudflare_zone_dnssec][:secondary_dnssec][:dnssec_presigned]).to be true
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_zone_dnssec(:test, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353"
        })
      end

      expect(ref.id).to eq("${cloudflare_zone_dnssec.test.id}")
      expect(ref.outputs[:status]).to eq("${cloudflare_zone_dnssec.test.status}")
      expect(ref.outputs[:digest]).to eq("${cloudflare_zone_dnssec.test.digest}")
      expect(ref.outputs[:ds]).to eq("${cloudflare_zone_dnssec.test.ds}")
    end
  end
end
