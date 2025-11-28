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
require 'pangea/resources/cloudflare_d1_database/resource'
require 'pangea/resources/cloudflare_d1_database/types'
require 'pangea/resources/cloudflare_worker_script/resource'
require 'pangea/resources/cloudflare_workers_kv_namespace/resource'
require 'pangea/resources/cloudflare_r2_bucket/resource'

RSpec.describe 'cloudflare_d1_database synthesis' do
  include Pangea::Resources::Cloudflare

  let(:synthesizer) { TerraformSynthesizer.new }
  let(:account_id) { "a" * 32 }

  describe 'terraform synthesis' do
    it 'synthesizes basic D1 database without location hint' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_d1_database(:users, {
          account_id: "a" * 32,
          name: "users-db"
        })
      end

      result = synthesizer.synthesis
      database = result[:resource][:cloudflare_d1_database][:users]

      expect(database).to include(
        account_id: account_id,
        name: "users-db"
      )
      expect(database).not_to have_key(:primary_location_hint)
    end

    it 'synthesizes D1 database with Western North America location' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_d1_database(:products, {
          account_id: "a" * 32,
          name: "products-production",
          primary_location_hint: "wnam"
        })
      end

      result = synthesizer.synthesis
      database = result[:resource][:cloudflare_d1_database][:products]

      expect(database[:name]).to eq("products-production")
      expect(database[:primary_location_hint]).to eq("wnam")
    end

    it 'synthesizes D1 database with Western Europe location for GDPR' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_d1_database(:eu_customers, {
          account_id: "a" * 32,
          name: "eu-customer-data",
          primary_location_hint: "weur"
        })
      end

      result = synthesizer.synthesis
      database = result[:resource][:cloudflare_d1_database][:eu_customers]

      expect(database[:primary_location_hint]).to eq("weur")
    end

    it 'synthesizes D1 database with Asia-Pacific location' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_d1_database(:apac_analytics, {
          account_id: "a" * 32,
          name: "apac-analytics",
          primary_location_hint: "apac"
        })
      end

      result = synthesizer.synthesis
      database = result[:resource][:cloudflare_d1_database][:apac_analytics]

      expect(database[:primary_location_hint]).to eq("apac")
    end

    it 'synthesizes multiple D1 databases for different environments' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare

        cloudflare_d1_database(:db_prod, {
          account_id: "a" * 32,
          name: "app-production",
          primary_location_hint: "wnam"
        })

        cloudflare_d1_database(:db_staging, {
          account_id: "a" * 32,
          name: "app-staging",
          primary_location_hint: "wnam"
        })

        cloudflare_d1_database(:db_dev, {
          account_id: "a" * 32,
          name: "app-development"
        })
      end

      result = synthesizer.synthesis
      databases = result[:resource][:cloudflare_d1_database]

      expect(databases).to have_key(:db_prod)
      expect(databases).to have_key(:db_staging)
      expect(databases).to have_key(:db_dev)
      expect(databases[:db_prod][:name]).to eq("app-production")
    end

    it 'synthesizes D1 databases for multi-region application' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare

        # North America
        cloudflare_d1_database(:db_na, {
          account_id: "a" * 32,
          name: "app-north-america",
          primary_location_hint: "wnam"
        })

        # Europe
        cloudflare_d1_database(:db_eu, {
          account_id: "a" * 32,
          name: "app-europe",
          primary_location_hint: "weur"
        })

        # Asia
        cloudflare_d1_database(:db_asia, {
          account_id: "a" * 32,
          name: "app-asia",
          primary_location_hint: "apac"
        })
      end

      result = synthesizer.synthesis
      databases = result[:resource][:cloudflare_d1_database]

      expect(databases[:db_na][:primary_location_hint]).to eq("wnam")
      expect(databases[:db_eu][:primary_location_hint]).to eq("weur")
      expect(databases[:db_asia][:primary_location_hint]).to eq("apac")
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_d1_database(:test, {
          account_id: "a" * 32,
          name: "test-db"
        })
      end

      expect(ref.id).to eq("${cloudflare_d1_database.test.id}")
      expect(ref.outputs[:database_id]).to eq("${cloudflare_d1_database.test.id}")
      expect(ref.outputs[:database_name]).to eq("${cloudflare_d1_database.test.name}")
      expect(ref.outputs[:version]).to eq("${cloudflare_d1_database.test.version}")
    end

    it 'enables database reference in worker scripts' do
      db_ref = nil

      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare

        # Create D1 database
        db_ref = cloudflare_d1_database(:app_db, {
          account_id: "a" * 32,
          name: "application-db"
        })

        # Create worker that uses the database
        cloudflare_worker_script(:api, {
          account_id: "a" * 32,
          name: "api-worker",
          content: "export default { async fetch() { return new Response('OK') } }",
          d1_database_bindings: [
            { name: "DB", database_id: db_ref.id }
          ]
        })
      end

      result = synthesizer.synthesis

      expect(result[:resource][:cloudflare_d1_database]).to have_key(:app_db)
      expect(result[:resource][:cloudflare_worker_script]).to have_key(:api)

      worker = result[:resource][:cloudflare_worker_script][:api]
      # Bindings are always Arrays in Terraform JSON format
      expect(worker[:d1_database_binding]).to be_an(Array)
      expect(worker[:d1_database_binding].length).to eq(1)
      expect(worker[:d1_database_binding][0][:name]).to eq("DB")
      expect(worker[:d1_database_binding][0][:database_id]).to eq("${cloudflare_d1_database.app_db.id}")
    end
  end

  describe 'resource composition' do
    it 'creates complete serverless stack with D1, Workers KV, and R2' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare

        # SQL database
        cloudflare_d1_database(:sql_db, {
          account_id: "a" * 32,
          name: "relational-data",
          primary_location_hint: "wnam"
        })

        # KV for caching
        cloudflare_workers_kv_namespace(:cache, {
          account_id: "a" * 32,
          title: "Edge Cache"
        })

        # R2 for object storage
        cloudflare_r2_bucket(:uploads, {
          account_id: "a" * 32,
          name: "user-uploads",
          location: "wnam"
        })
      end

      result = synthesizer.synthesis

      expect(result[:resource][:cloudflare_d1_database]).to have_key(:sql_db)
      expect(result[:resource][:cloudflare_workers_kv_namespace]).to have_key(:cache)
      expect(result[:resource][:cloudflare_r2_bucket]).to have_key(:uploads)
    end
  end
end
