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
require 'pangea/resources/aws_kinesis_video_stream/resource'

RSpec.describe 'aws_kinesis_video_stream synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic video stream with minimal configuration' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_video_stream(:camera, {
          name: 'security-camera-stream'
        })
      end

      result = synthesizer.synthesis
      stream = result[:resource][:aws_kinesis_video_stream][:camera]

      expect(stream[:name]).to eq('security-camera-stream')
      expect(stream[:data_retention_in_hours]).to eq(0)
      expect(stream[:media_type]).to eq('video/h264')
    end

    it 'synthesizes video stream with data retention' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_video_stream(:archive, {
          name: 'archive-stream',
          data_retention_in_hours: 168  # 7 days
        })
      end

      result = synthesizer.synthesis
      stream = result[:resource][:aws_kinesis_video_stream][:archive]

      expect(stream[:data_retention_in_hours]).to eq(168)
    end

    it 'synthesizes video stream with device name' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_video_stream(:iot_camera, {
          name: 'iot-camera-stream',
          device_name: 'front-door-camera'
        })
      end

      result = synthesizer.synthesis
      stream = result[:resource][:aws_kinesis_video_stream][:iot_camera]

      expect(stream[:device_name]).to eq('front-door-camera')
    end

    it 'synthesizes video stream with custom media type' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_video_stream(:h265_stream, {
          name: 'h265-camera-stream',
          media_type: 'video/h265'
        })
      end

      result = synthesizer.synthesis
      stream = result[:resource][:aws_kinesis_video_stream][:h265_stream]

      expect(stream[:media_type]).to eq('video/h265')
    end

    it 'synthesizes encrypted video stream' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_video_stream(:encrypted, {
          name: 'encrypted-stream',
          kms_key_id: 'alias/kinesis-video-key'
        })
      end

      result = synthesizer.synthesis
      stream = result[:resource][:aws_kinesis_video_stream][:encrypted]

      expect(stream[:kms_key_id]).to eq('alias/kinesis-video-key')
    end

    it 'synthesizes video stream with long retention period' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_video_stream(:long_retention, {
          name: 'long-retention-stream',
          data_retention_in_hours: 8760  # 1 year
        })
      end

      result = synthesizer.synthesis
      stream = result[:resource][:aws_kinesis_video_stream][:long_retention]

      expect(stream[:data_retention_in_hours]).to eq(8760)
    end

    it 'synthesizes video stream with tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_video_stream(:tagged, {
          name: 'tagged-stream',
          tags: { Environment: 'production', Location: 'building-a' }
        })
      end

      result = synthesizer.synthesis
      stream = result[:resource][:aws_kinesis_video_stream][:tagged]

      expect(stream[:tags][:Environment]).to eq('production')
      expect(stream[:tags][:Location]).to eq('building-a')
    end

    it 'synthesizes multiple video streams for different cameras' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS

        aws_kinesis_video_stream(:front_door, {
          name: 'front-door-camera',
          device_name: 'front-door-cam',
          data_retention_in_hours: 72
        })

        aws_kinesis_video_stream(:back_door, {
          name: 'back-door-camera',
          device_name: 'back-door-cam',
          data_retention_in_hours: 72
        })

        aws_kinesis_video_stream(:garage, {
          name: 'garage-camera',
          device_name: 'garage-cam',
          data_retention_in_hours: 24
        })
      end

      result = synthesizer.synthesis
      streams = result[:resource][:aws_kinesis_video_stream]

      expect(streams).to have_key(:front_door)
      expect(streams).to have_key(:back_door)
      expect(streams).to have_key(:garage)
      expect(streams[:garage][:data_retention_in_hours]).to eq(24)
    end

    it 'synthesizes audio stream' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_video_stream(:audio_stream, {
          name: 'audio-intercom',
          media_type: 'audio/aac',
          data_retention_in_hours: 24
        })
      end

      result = synthesizer.synthesis
      stream = result[:resource][:aws_kinesis_video_stream][:audio_stream]

      expect(stream[:media_type]).to eq('audio/aac')
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_video_stream(:test, {
          name: 'test-stream'
        })
      end

      expect(ref.outputs[:arn]).to eq('${aws_kinesis_video_stream.test.arn}')
      expect(ref.outputs[:name]).to eq('${aws_kinesis_video_stream.test.name}')
      expect(ref.outputs[:id]).to eq('${aws_kinesis_video_stream.test.id}')
      expect(ref.outputs[:version]).to eq('${aws_kinesis_video_stream.test.version}')
    end
  end

  describe 'terraform validation' do
    it 'produces valid terraform structure' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_video_stream(:test, {
          name: 'test-stream'
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result[:resource]).to be_a(Hash)
      expect(result[:resource][:aws_kinesis_video_stream]).to be_a(Hash)
      expect(result[:resource][:aws_kinesis_video_stream][:test]).to be_a(Hash)
    end
  end

  describe 'resource composition' do
    it 'creates complete video surveillance infrastructure' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS

        # Real-time streams (no retention)
        aws_kinesis_video_stream(:live_lobby, {
          name: 'live-lobby-stream',
          device_name: 'lobby-camera',
          data_retention_in_hours: 0
        })

        # Short-term archive streams
        aws_kinesis_video_stream(:archive_entrance, {
          name: 'archive-entrance-stream',
          device_name: 'entrance-camera',
          data_retention_in_hours: 168  # 7 days
        })

        # Long-term archive streams
        aws_kinesis_video_stream(:archive_vault, {
          name: 'archive-vault-stream',
          device_name: 'vault-camera',
          data_retention_in_hours: 8760,  # 1 year
          kms_key_id: 'alias/video-encryption-key'
        })
      end

      result = synthesizer.synthesis
      streams = result[:resource][:aws_kinesis_video_stream]

      expect(streams).to have_key(:live_lobby)
      expect(streams).to have_key(:archive_entrance)
      expect(streams).to have_key(:archive_vault)
      expect(streams[:live_lobby][:data_retention_in_hours]).to eq(0)
      expect(streams[:archive_vault][:kms_key_id]).to eq('alias/video-encryption-key')
    end
  end
end
