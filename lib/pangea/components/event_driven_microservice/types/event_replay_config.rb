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
require 'pangea/resources/types'

module Pangea
  module Components
    module EventDrivenMicroservice
      # Make Types available in this namespace
      Types = Pangea::Resources::Types unless const_defined?(:Types)

      # Event replay configuration
      class EventReplayConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :enabled, Types::Bool.default(true)
        attribute :snapshot_enabled, Types::Bool.default(true)
        attribute :snapshot_frequency, Types::Integer.default(100) # events
        attribute :replay_dead_letter_queue_ref, Types::ResourceReference.optional
      end
    end
  end
end
