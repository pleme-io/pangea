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
          # Destinations DSL building for MediaLive Channel
          module Destinations
            def build_destinations(ctx)
              attrs.destinations.each do |destination|
                ctx.destinations do
                  id destination[:id]
                  build_media_package_settings(self, destination[:media_package_settings]) if destination[:media_package_settings]
                  build_multiplex_settings(self, destination[:multiplex_settings]) if destination[:multiplex_settings]
                  build_destination_settings(self, destination[:settings]) if destination[:settings]
                end
              end
            end

            private

            def build_media_package_settings(ctx, mp_settings)
              mp_settings.each do |mp_setting|
                ctx.media_package_settings do
                  channel_id mp_setting[:channel_id]
                end
              end
            end

            def build_multiplex_settings(ctx, multiplex)
              ctx.multiplex_settings do
                multiplex_id multiplex[:multiplex_id]
                program_name multiplex[:program_name]
              end
            end

            def build_destination_settings(ctx, settings)
              settings.each do |setting|
                ctx.settings do
                  password_param setting[:password_param] if setting[:password_param]
                  stream_name setting[:stream_name] if setting[:stream_name]
                  url setting[:url] if setting[:url]
                  username setting[:username] if setting[:username]
                end
              end
            end
          end
        end
      end
    end
  end
end
