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

require_relative 'dsl_builder/input_attachments'
require_relative 'dsl_builder/encoder_settings'
require_relative 'dsl_builder/destinations'
require_relative 'dsl_builder/configurations'

module Pangea
  module Resources
    module AWS
      module MediaLiveChannel
        # DSL builder for MediaLive Channel terraform blocks
        class DSLBuilder
          include InputAttachments
          include EncoderSettings
          include Destinations
          include Configurations

          attr_reader :attrs

          def initialize(channel_attrs)
            @attrs = channel_attrs
          end
        end
      end
    end
  end
end
