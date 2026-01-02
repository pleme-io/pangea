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
      # Response playbook entry
      class PlaybookEntry < Dry::Struct
        transform_keys(&:to_sym)

        attribute :name, Types::String
        attribute :trigger, Types::String
        attribute :severity_threshold, Types::String.enum('critical', 'high', 'medium', 'low')
        attribute :steps, Types::Array.of(Types::Hash)
        attribute :notification_channels, Types::Array.of(Types::String).default([].freeze)
        attribute :escalation_policy, Types::String.optional
      end

      # Incident response configuration
      class IncidentResponseConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :enable_automated_response, Types::Bool.default(true)
        attribute :playbooks, Types::Array.of(PlaybookEntry).default([].freeze)
        attribute :enable_case_management, Types::Bool.default(true)
        attribute :enable_forensics_collection, Types::Bool.default(true)
        attribute :retention_days, Types::Integer.default(90).constrained(gteq: 1, lteq: 3653)
      end

      # Dashboard entry configuration
      class DashboardEntry < Dry::Struct
        transform_keys(&:to_sym)

        attribute :name, Types::String
        attribute :type, Types::String.enum(
          'security_overview', 'threat_hunting', 'compliance', 'incident_response', 'custom'
        )
        attribute :refresh_interval, Types::Integer.default(300)
        attribute :widgets, Types::Array.of(Types::Hash).default([].freeze)
        attribute :access_control, Types::Hash.default({}.freeze)
      end

      # Default dashboards
      DEFAULT_DASHBOARDS = [
        DashboardEntry.new(name: 'Security Overview', type: 'security_overview'),
        DashboardEntry.new(name: 'Threat Hunting', type: 'threat_hunting'),
        DashboardEntry.new(name: 'Compliance', type: 'compliance'),
        DashboardEntry.new(name: 'Incident Response', type: 'incident_response')
      ].freeze
    end
  end
end
