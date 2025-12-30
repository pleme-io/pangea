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

module Pangea
  module Resources
    module AWS
      module MediaLiveChannel
        class DSLBuilder
          # Input attachment DSL building for MediaLive Channel
          module InputAttachments
            def build_input_attachments(ctx)
              attrs.input_attachments.each do |input_attachment|
                ctx.input_attachments do
                  input_attachment_name input_attachment[:input_attachment_name]
                  input_id input_attachment[:input_id]
                  build_input_settings(self, input_attachment[:input_settings]) if input_attachment[:input_settings]
                end
              end
            end

            private

            def build_input_settings(ctx, settings)
              ctx.input_settings do
                build_audio_selectors(self, settings[:audio_selectors]) if settings[:audio_selectors]
                build_caption_selectors(self, settings[:caption_selectors]) if settings[:caption_selectors]
                apply_filter_settings(self, settings)
                build_network_input_settings(self, settings[:network_input_settings]) if settings[:network_input_settings]
                smpte2038_data_preference settings[:smpte2038_data_preference] if settings[:smpte2038_data_preference]
                source_end_behavior settings[:source_end_behavior] if settings[:source_end_behavior]
                build_video_selector(self, settings[:video_selector]) if settings[:video_selector]
              end
            end

            def apply_filter_settings(ctx, settings)
              ctx.deblock_filter settings[:deblock_filter] if settings[:deblock_filter]
              ctx.denoise_filter settings[:denoise_filter] if settings[:denoise_filter]
              ctx.filter_strength settings[:filter_strength] if settings[:filter_strength]
              ctx.input_filter settings[:input_filter] if settings[:input_filter]
            end

            def build_audio_selectors(ctx, audio_selectors)
              audio_selectors.each do |audio_selector|
                ctx.audio_selectors do
                  name audio_selector[:name]
                  build_audio_selector_settings(self, audio_selector[:selector_settings]) if audio_selector[:selector_settings]
                end
              end
            end

            def build_audio_selector_settings(ctx, settings)
              ctx.selector_settings do
                if settings[:audio_language_selection]
                  audio_language_selection do
                    language_code settings[:audio_language_selection][:language_code]
                    language_selection_policy settings[:audio_language_selection][:language_selection_policy] if settings[:audio_language_selection][:language_selection_policy]
                  end
                end

                if settings[:audio_pid_selection]
                  audio_pid_selection do
                    pid settings[:audio_pid_selection][:pid]
                  end
                end
              end
            end

            def build_caption_selectors(ctx, caption_selectors)
              caption_selectors.each do |caption_selector|
                ctx.caption_selectors do
                  name caption_selector[:name]
                  language_code caption_selector[:language_code] if caption_selector[:language_code]
                  selector_settings {} if caption_selector[:selector_settings]
                end
              end
            end

            def build_network_input_settings(ctx, network_settings)
              ctx.network_input_settings do
                if network_settings[:hls_input_settings]
                  hls_input_settings do
                    bandwidth network_settings[:hls_input_settings][:bandwidth] if network_settings[:hls_input_settings][:bandwidth]
                    buffer_segments network_settings[:hls_input_settings][:buffer_segments] if network_settings[:hls_input_settings][:buffer_segments]
                    retries network_settings[:hls_input_settings][:retries] if network_settings[:hls_input_settings][:retries]
                    retry_interval network_settings[:hls_input_settings][:retry_interval] if network_settings[:hls_input_settings][:retry_interval]
                  end
                end
                server_validation network_settings[:server_validation] if network_settings[:server_validation]
              end
            end

            def build_video_selector(ctx, video_selector)
              ctx.video_selector do
                color_space video_selector[:color_space] if video_selector[:color_space]
                color_space_usage video_selector[:color_space_usage] if video_selector[:color_space_usage]

                if video_selector[:selector_settings]
                  selector_settings do
                    if video_selector[:selector_settings][:video_selector_pid]
                      video_selector_pid do
                        pid video_selector[:selector_settings][:video_selector_pid][:pid]
                      end
                    end
                    if video_selector[:selector_settings][:video_selector_program_id]
                      video_selector_program_id do
                        program_id video_selector[:selector_settings][:video_selector_program_id][:program_id]
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
