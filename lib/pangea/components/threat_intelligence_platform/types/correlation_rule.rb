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
      # Correlation rule configuration
      class CorrelationRule < Dry::Struct
        transform_keys(&:to_sym)

        attribute :name, Types::String
        attribute :description, Types::String
        attribute :rule_type, Types::String.enum('simple', 'complex', 'ml_based', 'graph_based')
        attribute :conditions, Types::Array.of(Types::Hash)
        attribute :actions, Types::Array.of(
          Types::String.enum('alert', 'enrich', 'block', 'investigate', 'share')
        ).default(['alert'].freeze)
        attribute :severity, Types::String.enum('critical', 'high', 'medium', 'low').default('medium')
        attribute? :enabled, Types::Bool.default(true)
      end
    end
  end
end
