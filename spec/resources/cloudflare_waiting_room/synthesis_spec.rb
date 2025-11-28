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
require 'pangea/resources/cloudflare_waiting_room/resource'
require 'pangea/resources/cloudflare_waiting_room/types'

RSpec.describe 'cloudflare_waiting_room synthesis' do
  include Pangea::Resources::Cloudflare

  let(:synthesizer) { TerraformSynthesizer.new }
  let(:zone_id) { "023e105f4ecef8ad9ca31a8372d0c353" }

  describe 'basic waiting room' do
    it 'synthesizes minimal waiting room' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_waiting_room(:shop, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          host: "shop.example.com",
          name: "shop_queue",
          new_users_per_minute: 200,
          total_active_users: 300
        })
      end

      result = synthesizer.synthesis
      wr = result[:resource][:cloudflare_waiting_room][:shop]

      expect(wr[:zone_id]).to eq(zone_id)
      expect(wr[:host]).to eq("shop.example.com")
      expect(wr[:name]).to eq("shop_queue")
      expect(wr[:new_users_per_minute]).to eq(200)
      expect(wr[:total_active_users]).to eq(300)
    end

    it 'synthesizes with path' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_waiting_room(:checkout, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          host: "shop.example.com",
          path: "/checkout",
          name: "checkout_queue",
          new_users_per_minute: 500,
          total_active_users: 1000
        })
      end

      result = synthesizer.synthesis
      wr = result[:resource][:cloudflare_waiting_room][:checkout]

      expect(wr[:path]).to eq("/checkout")
    end
  end

  describe 'queueing methods' do
    it 'synthesizes with FIFO queueing' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_waiting_room(:fifo_queue, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          host: "example.com",
          name: "fifo_test",
          new_users_per_minute: 300,
          total_active_users: 500,
          queueing_method: "fifo"
        })
      end

      result = synthesizer.synthesis
      wr = result[:resource][:cloudflare_waiting_room][:fifo_queue]

      expect(wr[:queueing_method]).to eq("fifo")
    end

    it 'synthesizes with random queueing' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_waiting_room(:random_queue, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          host: "example.com",
          name: "random_test",
          new_users_per_minute: 300,
          total_active_users: 500,
          queueing_method: "random"
        })
      end

      result = synthesizer.synthesis
      wr = result[:resource][:cloudflare_waiting_room][:random_queue]

      expect(wr[:queueing_method]).to eq("random")
    end

    it 'synthesizes with queue_all enabled' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_waiting_room(:queue_all, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          host: "example.com",
          name: "queue_all_test",
          new_users_per_minute: 300,
          total_active_users: 500,
          queue_all: true
        })
      end

      result = synthesizer.synthesis
      wr = result[:resource][:cloudflare_waiting_room][:queue_all]

      expect(wr[:queue_all]).to be true
    end
  end

  describe 'session configuration' do
    it 'synthesizes with session duration' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_waiting_room(:with_session, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          host: "example.com",
          name: "session_test",
          new_users_per_minute: 300,
          total_active_users: 500,
          session_duration: 10,
          disable_session_renewal: false
        })
      end

      result = synthesizer.synthesis
      wr = result[:resource][:cloudflare_waiting_room][:with_session]

      expect(wr[:session_duration]).to eq(10)
      expect(wr[:disable_session_renewal]).to be false
    end
  end

  describe 'cookie attributes' do
    it 'synthesizes with cookie configuration' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_waiting_room(:with_cookies, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          host: "example.com",
          name: "cookie_test",
          new_users_per_minute: 300,
          total_active_users: 500,
          cookie_attributes: {
            samesite: "lax",
            secure: "always"
          }
        })
      end

      result = synthesizer.synthesis
      wr = result[:resource][:cloudflare_waiting_room][:with_cookies]

      expect(wr[:cookie_attributes][:samesite]).to eq("lax")
      expect(wr[:cookie_attributes][:secure]).to eq("always")
    end
  end

  describe 'advanced configuration' do
    it 'synthesizes fully configured waiting room' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_waiting_room(:advanced, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          host: "shop.example.com",
          path: "/sale",
          name: "flash_sale",
          description: "Flash sale waiting room",
          new_users_per_minute: 1000,
          total_active_users: 5000,
          queueing_method: "fifo",
          session_duration: 15,
          json_response_enabled: true,
          queueing_status_code: 202,
          cookie_attributes: {
            samesite: "strict",
            secure: "always"
          }
        })
      end

      result = synthesizer.synthesis
      wr = result[:resource][:cloudflare_waiting_room][:advanced]

      expect(wr).to include(
        zone_id: zone_id,
        host: "shop.example.com",
        path: "/sale",
        name: "flash_sale",
        description: "Flash sale waiting room",
        new_users_per_minute: 1000,
        total_active_users: 5000,
        queueing_method: "fifo",
        session_duration: 15,
        json_response_enabled: true,
        queueing_status_code: 202
      )
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_waiting_room(:test, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          host: "example.com",
          name: "test_queue",
          new_users_per_minute: 200,
          total_active_users: 300
        })
      end

      expect(ref.id).to eq("${cloudflare_waiting_room.test.id}")
    end
  end

  describe 'validation' do
    it 'rejects too low new_users_per_minute' do
      expect {
        Cloudflare::Types::WaitingRoomAttributes.new(
          zone_id: zone_id,
          host: "example.com",
          name: "test",
          new_users_per_minute: 100,  # Too low
          total_active_users: 300
        )
      }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'rejects invalid queueing_method' do
      expect {
        Cloudflare::Types::WaitingRoomAttributes.new(
          zone_id: zone_id,
          host: "example.com",
          name: "test",
          new_users_per_minute: 200,
          total_active_users: 300,
          queueing_method: "invalid"
        )
      }.to raise_error(Dry::Types::ConstraintError)
    end
  end
end
