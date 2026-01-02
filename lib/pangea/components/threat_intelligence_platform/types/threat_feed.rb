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

require 'dry-struct'
require 'pangea/components/types'

module Pangea
  module Components
    module ThreatIntelligencePlatform
      # Threat feed configuration
      class ThreatFeed < Dry::Struct
        transform_keys(&:to_sym)

        attribute :name, Types::String
        attribute? :description, Types::String.optional
        attribute? :feed_url, Types::String.optional
        attribute :feed_type, Types::String.enum('public', 'private', 'sharing_group')
        attribute :tlp_level, Types::String.enum('white', 'green', 'amber', 'red').default('amber')
        attribute? :sharing_enabled, Types::Bool.default(false)
        attribute? :auto_publish, Types::Bool.default(false)
        attribute? :tags, Types::Array.of(Types::String).default([].freeze)
      end
    end
  end
end
