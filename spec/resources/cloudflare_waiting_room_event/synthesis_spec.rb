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
require 'pangea/resources/cloudflare_waiting_room_event/resource'
require 'pangea/resources/cloudflare_waiting_room_event/types'

RSpec.describe 'cloudflare_waiting_room_event synthesis' do
  include Pangea::Resources::Cloudflare

  let(:synthesizer) { TerraformSynthesizer.new }
  let(:zone_id) { "023e105f4ecef8ad9ca31a8372d0c353" }
  let(:waiting_room_id) { "699d98642c564d2e855e9661899b7252" }

  describe 'basic event' do
    it 'synthesizes minimal event' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_waiting_room_event(:sale, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          waiting_room_id: "699d98642c564d2e855e9661899b7252",
          name: "flash_sale",
          event_start_time: "2025-11-15T12:00:00Z",
          event_end_time: "2025-11-15T14:00:00Z"
        })
      end

      result = synthesizer.synthesis
      event = result[:resource][:cloudflare_waiting_room_event][:sale]

      expect(event[:zone_id]).to eq(zone_id)
      expect(event[:waiting_room_id]).to eq(waiting_room_id)
      expect(event[:name]).to eq("flash_sale")
      expect(event[:event_start_time]).to eq("2025-11-15T12:00:00Z")
      expect(event[:event_end_time]).to eq("2025-11-15T14:00:00Z")
    end
  end

  describe 'event with overrides' do
    it 'synthesizes event with capacity overrides' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_waiting_room_event(:high_traffic, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          waiting_room_id: "699d98642c564d2e855e9661899b7252",
          name: "high_traffic_event",
          event_start_time: "2025-11-15T12:00:00Z",
          event_end_time: "2025-11-15T14:00:00Z",
          new_users_per_minute: 1000,
          total_active_users: 5000
        })
      end

      result = synthesizer.synthesis
      event = result[:resource][:cloudflare_waiting_room_event][:high_traffic]

      expect(event[:new_users_per_minute]).to eq(1000)
      expect(event[:total_active_users]).to eq(5000)
    end

    it 'synthesizes event with queueing method override' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_waiting_room_event(:random_queue, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          waiting_room_id: "699d98642c564d2e855e9661899b7252",
          name: "random_event",
          event_start_time: "2025-11-15T12:00:00Z",
          event_end_time: "2025-11-15T14:00:00Z",
          queueing_method: "random"
        })
      end

      result = synthesizer.synthesis
      event = result[:resource][:cloudflare_waiting_room_event][:random_queue]

      expect(event[:queueing_method]).to eq("random")
    end
  end

  describe 'prequeue functionality' do
    it 'synthesizes event with prequeue' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_waiting_room_event(:webinar, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          waiting_room_id: "699d98642c564d2e855e9661899b7252",
          name: "webinar_event",
          event_start_time: "2025-11-20T14:00:00Z",
          event_end_time: "2025-11-20T16:00:00Z",
          prequeue_start_time: "2025-11-20T13:30:00Z"
        })
      end

      result = synthesizer.synthesis
      event = result[:resource][:cloudflare_waiting_room_event][:webinar]

      expect(event[:prequeue_start_time]).to eq("2025-11-20T13:30:00Z")
    end

    it 'synthesizes event with shuffle enabled' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_waiting_room_event(:shuffle_event, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          waiting_room_id: "699d98642c564d2e855e9661899b7252",
          name: "shuffle_test",
          event_start_time: "2025-11-20T14:00:00Z",
          event_end_time: "2025-11-20T16:00:00Z",
          prequeue_start_time: "2025-11-20T13:30:00Z",
          shuffle_at_event_start: true
        })
      end

      result = synthesizer.synthesis
      event = result[:resource][:cloudflare_waiting_room_event][:shuffle_event]

      expect(event[:shuffle_at_event_start]).to be true
    end
  end

  describe 'fully configured event' do
    it 'synthesizes event with all options' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_waiting_room_event(:complete, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          waiting_room_id: "699d98642c564d2e855e9661899b7252",
          name: "complete_event",
          description: "Fully configured event",
          event_start_time: "2025-11-20T14:00:00Z",
          event_end_time: "2025-11-20T16:00:00Z",
          prequeue_start_time: "2025-11-20T13:30:00Z",
          new_users_per_minute: 1000,
          total_active_users: 5000,
          queueing_method: "fifo",
          session_duration: 15,
          disable_session_renewal: false,
          shuffle_at_event_start: true
        })
      end

      result = synthesizer.synthesis
      event = result[:resource][:cloudflare_waiting_room_event][:complete]

      expect(event).to include(
        zone_id: zone_id,
        waiting_room_id: waiting_room_id,
        name: "complete_event",
        description: "Fully configured event",
        new_users_per_minute: 1000,
        total_active_users: 5000,
        queueing_method: "fifo",
        session_duration: 15,
        shuffle_at_event_start: true
      )
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_waiting_room_event(:test, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          waiting_room_id: "699d98642c564d2e855e9661899b7252",
          name: "test_event",
          event_start_time: "2025-11-15T12:00:00Z",
          event_end_time: "2025-11-15T14:00:00Z"
        })
      end

      expect(ref.id).to eq("${cloudflare_waiting_room_event.test.id}")
    end
  end

  describe 'validation' do
    it 'rejects event_end_time before event_start_time' do
      expect {
        Cloudflare::Types::WaitingRoomEventAttributes.new(
          zone_id: zone_id,
          waiting_room_id: waiting_room_id,
          name: "invalid",
          event_start_time: "2025-11-15T14:00:00Z",
          event_end_time: "2025-11-15T12:00:00Z"  # Before start
        )
      }.to raise_error(Dry::Struct::Error, /event_end_time must be after/)
    end

    it 'rejects prequeue_start_time after event_start_time' do
      expect {
        Cloudflare::Types::WaitingRoomEventAttributes.new(
          zone_id: zone_id,
          waiting_room_id: waiting_room_id,
          name: "invalid",
          event_start_time: "2025-11-15T12:00:00Z",
          event_end_time: "2025-11-15T14:00:00Z",
          prequeue_start_time: "2025-11-15T13:00:00Z"  # After event start
        )
      }.to raise_error(Dry::Struct::Error, /prequeue_start_time must be before/)
    end

    it 'rejects invalid ISO 8601 timestamp format' do
      expect {
        Cloudflare::Types::WaitingRoomEventAttributes.new(
          zone_id: zone_id,
          waiting_room_id: waiting_room_id,
          name: "invalid",
          event_start_time: "2025-11-15 12:00:00",  # Invalid format
          event_end_time: "2025-11-15T14:00:00Z"
        )
      }.to raise_error(Dry::Types::ConstraintError)
    end
  end

  describe 'helper methods' do
    it 'identifies event with prequeue' do
      attrs = Cloudflare::Types::WaitingRoomEventAttributes.new(
        zone_id: zone_id,
        waiting_room_id: waiting_room_id,
        name: "test",
        event_start_time: "2025-11-20T14:00:00Z",
        event_end_time: "2025-11-20T16:00:00Z",
        prequeue_start_time: "2025-11-20T13:30:00Z"
      )

      expect(attrs.has_prequeue?).to be true
    end

    it 'identifies event without prequeue' do
      attrs = Cloudflare::Types::WaitingRoomEventAttributes.new(
        zone_id: zone_id,
        waiting_room_id: waiting_room_id,
        name: "test",
        event_start_time: "2025-11-20T14:00:00Z",
        event_end_time: "2025-11-20T16:00:00Z"
      )

      expect(attrs.has_prequeue?).to be false
    end

    it 'identifies shuffle setting' do
      attrs = Cloudflare::Types::WaitingRoomEventAttributes.new(
        zone_id: zone_id,
        waiting_room_id: waiting_room_id,
        name: "test",
        event_start_time: "2025-11-20T14:00:00Z",
        event_end_time: "2025-11-20T16:00:00Z",
        shuffle_at_event_start: true
      )

      expect(attrs.shuffles_prequeue?).to be true
    end
  end
end
