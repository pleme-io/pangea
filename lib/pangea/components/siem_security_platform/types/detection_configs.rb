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
    module SiemSecurityPlatform
      # Anomaly detector configuration
      class AnomalyDetectorEntry < Dry::Struct
        transform_keys(&:to_sym)

        attribute :name, Types::String
        attribute :type, Types::String.enum('statistical', 'machine_learning', 'pattern_based')
        attribute :sensitivity, Types::String.enum('low', 'medium', 'high').default('medium')
        attribute :baseline_period, Types::Integer.default(7)
      end

      # Threat intelligence feed configuration
      class ThreatIntelFeedEntry < Dry::Struct
        transform_keys(&:to_sym)

        attribute :name, Types::String
        attribute :type, Types::String.enum('ip_reputation', 'domain_reputation', 'file_hash', 'indicators')
        attribute :source_url, Types::String.optional
        attribute :update_frequency, Types::Integer.default(3600)
        attribute :enabled, Types::Bool.default(true)
      end

      # Security correlation rule entry
      class CorrelationRuleEntry < Dry::Struct
        transform_keys(&:to_sym)

        attribute :name, Types::String
        attribute :description, Types::String
        attribute :severity, Types::String.enum('critical', 'high', 'medium', 'low', 'info').default('medium')
        attribute :rule_type, Types::String.enum('threshold', 'pattern', 'anomaly', 'sequence', 'statistical')
        attribute :conditions, Types::Array.of(Types::Hash).constrained(min_size: 1)
        attribute :time_window, Types::Integer.default(300)
        attribute :threshold, Types::Integer.optional
        attribute :actions, Types::Array.of(
          Types::String.enum('alert', 'block', 'isolate', 'investigate', 'notify', 'custom')
        ).default(['alert'].freeze)
        attribute :enabled, Types::Bool.default(true)
      end

      # Threat detection configuration
      class ThreatDetectionConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :enable_ml_detection, Types::Bool.default(true)
        attribute :anomaly_detectors, Types::Array.of(AnomalyDetectorEntry).default([].freeze)
        attribute :threat_intel_feeds, Types::Array.of(ThreatIntelFeedEntry).default([].freeze)
        attribute :enable_behavior_analytics, Types::Bool.default(true)
        attribute :enable_entity_analytics, Types::Bool.default(true)
      end
    end
  end
end
