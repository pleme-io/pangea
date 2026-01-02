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

      # Event store configuration for event sourcing
      class EventStoreConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :enabled, Types::Bool.default(true)
        attribute :table_name, Types::String
        attribute :stream_enabled, Types::Bool.default(true)
        attribute :ttl_days, Types::Integer.optional
        attribute :encryption_type, Types::String.default('KMS').enum('DEFAULT', 'KMS')
        attribute :kms_key_ref, Types::ResourceReference.optional
        attribute :point_in_time_recovery, Types::Bool.default(true)
        attribute :global_secondary_indexes, Types::Array.of(Types::Hash).default([].freeze)
      end
    end
  end
end
