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
      Types = Pangea::Resources::Types

      # Primary region configuration
      class PrimaryRegionConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :region, Types::String
        attribute :vpc_ref, Types::ResourceReference.optional
        attribute :vpc_cidr, Types::String.default('10.0.0.0/16')
        attribute :availability_zones, Types::Array.of(Types::String).constrained(min_size: 2)
        attribute :critical_resources, Types::Array.of(Types::Hash).default([].freeze)
        attribute :backup_schedule, Types::String.default('cron(0 2 * * ? *)')
      end

      # DR region configuration
      class DRRegionConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :region, Types::String
        attribute :vpc_ref, Types::ResourceReference.optional
        attribute :vpc_cidr, Types::String.default('10.1.0.0/16')
        attribute :availability_zones, Types::Array.of(Types::String).constrained(min_size: 2)
        attribute :standby_resources, Types::Hash.default({}.freeze)
        attribute :activation_priority, Types::Integer.default(100)
      end
    end
  end
end
