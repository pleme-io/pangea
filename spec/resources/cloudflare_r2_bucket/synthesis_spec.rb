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
require 'pangea/resources/cloudflare_r2_bucket/resource'
require 'pangea/resources/cloudflare_r2_bucket/types'

RSpec.describe 'cloudflare_r2_bucket synthesis' do
  include Pangea::Resources::Cloudflare

  let(:synthesizer) { TerraformSynthesizer.new }
  let(:account_id) { "a" * 32 }

  describe 'terraform synthesis' do
    it 'synthesizes basic R2 bucket without location' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_r2_bucket(:media, {
          account_id: "a" * 32,
          name: "media-assets"
        })
      end

      result = synthesizer.synthesis
      bucket = result[:resource][:cloudflare_r2_bucket][:media]

      expect(bucket).to include(
        account_id: account_id,
        name: "media-assets"
      )
      expect(bucket).not_to have_key(:location)
    end

    it 'synthesizes R2 bucket with Western North America location' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_r2_bucket(:cdn_assets, {
          account_id: "a" * 32,
          name: "cdn-assets",
          location: "wnam"
        })
      end

      result = synthesizer.synthesis
      bucket = result[:resource][:cloudflare_r2_bucket][:cdn_assets]

      expect(bucket[:name]).to eq("cdn-assets")
      expect(bucket[:location]).to eq("wnam")
    end

    it 'synthesizes R2 bucket with Western Europe location' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_r2_bucket(:user_uploads, {
          account_id: "a" * 32,
          name: "user-uploads-eu",
          location: "weur"
        })
      end

      result = synthesizer.synthesis
      bucket = result[:resource][:cloudflare_r2_bucket][:user_uploads]

      expect(bucket[:location]).to eq("weur")
    end

    it 'synthesizes R2 bucket with Asia-Pacific location' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_r2_bucket(:apac_data, {
          account_id: "a" * 32,
          name: "data-apac",
          location: "apac"
        })
      end

      result = synthesizer.synthesis
      bucket = result[:resource][:cloudflare_r2_bucket][:apac_data]

      expect(bucket[:location]).to eq("apac")
    end

    it 'synthesizes multiple R2 buckets for different purposes' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare

        cloudflare_r2_bucket(:images, {
          account_id: "a" * 32,
          name: "user-images",
          location: "wnam"
        })

        cloudflare_r2_bucket(:videos, {
          account_id: "a" * 32,
          name: "video-content",
          location: "wnam"
        })

        cloudflare_r2_bucket(:backups, {
          account_id: "a" * 32,
          name: "db-backups",
          location: "weur"
        })
      end

      result = synthesizer.synthesis
      buckets = result[:resource][:cloudflare_r2_bucket]

      expect(buckets).to have_key(:images)
      expect(buckets).to have_key(:videos)
      expect(buckets).to have_key(:backups)
      expect(buckets[:backups][:location]).to eq("weur")
    end

    it 'synthesizes R2 buckets for multi-region setup' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare

        # North America
        cloudflare_r2_bucket(:assets_na, {
          account_id: "a" * 32,
          name: "assets-north-america",
          location: "wnam"
        })

        # Europe
        cloudflare_r2_bucket(:assets_eu, {
          account_id: "a" * 32,
          name: "assets-europe",
          location: "weur"
        })

        # Asia-Pacific
        cloudflare_r2_bucket(:assets_apac, {
          account_id: "a" * 32,
          name: "assets-asia-pacific",
          location: "apac"
        })
      end

      result = synthesizer.synthesis
      buckets = result[:resource][:cloudflare_r2_bucket]

      expect(buckets[:assets_na][:location]).to eq("wnam")
      expect(buckets[:assets_eu][:location]).to eq("weur")
      expect(buckets[:assets_apac][:location]).to eq("apac")
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_r2_bucket(:test, {
          account_id: "a" * 32,
          name: "test-bucket"
        })
      end

      expect(ref.id).to eq("${cloudflare_r2_bucket.test.id}")
      expect(ref.outputs[:bucket_name]).to eq("${cloudflare_r2_bucket.test.name}")
      expect(ref.outputs[:location]).to eq("${cloudflare_r2_bucket.test.location}")
    end
  end

  describe 'resource composition' do
    it 'creates R2 buckets for complete storage infrastructure' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare

        # Public assets
        cloudflare_r2_bucket(:public_assets, {
          account_id: "a" * 32,
          name: "public-cdn-assets",
          location: "wnam"
        })

        # Private user data
        cloudflare_r2_bucket(:private_data, {
          account_id: "a" * 32,
          name: "private-user-data",
          location: "wnam"
        })

        # Logs and analytics
        cloudflare_r2_bucket(:logs, {
          account_id: "a" * 32,
          name: "application-logs"
        })
      end

      result = synthesizer.synthesis
      buckets = result[:resource][:cloudflare_r2_bucket]

      expect(buckets).to have_key(:public_assets)
      expect(buckets).to have_key(:private_data)
      expect(buckets).to have_key(:logs)
    end
  end
end
