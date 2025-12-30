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
    module DisasterRecoveryPilotLight
      # Make Types available in this namespace
      Types = Pangea::Resources::Types unless const_defined?(:Types)

      # Critical data configuration
      class CriticalDataConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :databases, Types::Array.of(Types::Hash).default([].freeze)
        attribute :s3_buckets, Types::Array.of(Types::String).default([].freeze)
        attribute :efs_filesystems, Types::Array.of(Types::String).default([].freeze)
        attribute :backup_retention_days, Types::Integer.default(7)
        attribute :cross_region_backup, Types::Bool.default(true)
        attribute :point_in_time_recovery, Types::Bool.default(true)
      end

      # Pilot light resources configuration
      class PilotLightConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :minimal_compute, Types::Bool.default(true)
        attribute :database_replicas, Types::Bool.default(true)
        attribute :data_sync_interval, Types::Integer.default(300)
        attribute :standby_instance_type, Types::String.default('t3.small')
        attribute :auto_scaling_min, Types::Integer.default(0)
        attribute :auto_scaling_max, Types::Integer.default(10)
      end
    end
  end
end
