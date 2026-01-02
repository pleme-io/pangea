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
    module MicroserviceDeployment
      # Container definition attributes
      class ContainerDefinition < Dry::Struct
        transform_keys(&:to_sym)

        attribute :name, Types::String
        attribute :image, Types::String
        attribute :cpu, Types::Integer.default(256)
        attribute :memory, Types::Integer.default(512)
        attribute :essential, Types::Bool.default(true)
        attribute :port_mappings, Types::Array.of(Types::Hash).default([].freeze)
        attribute :environment, Types::Array.of(Types::Hash).default([].freeze)
        attribute :secrets, Types::Array.of(Types::Hash).default([].freeze)
        attribute :health_check, Types::Hash.default({}.freeze)
        attribute :log_configuration, Types::Hash.default({}.freeze)
        attribute :depends_on, Types::Array.of(Types::Hash).default([].freeze)
        attribute :ulimits, Types::Array.of(Types::Hash).default([].freeze)
        attribute :mount_points, Types::Array.of(Types::Hash).default([].freeze)
        attribute :volume_from, Types::Array.of(Types::Hash).default([].freeze)
      end
    end
  end
end
