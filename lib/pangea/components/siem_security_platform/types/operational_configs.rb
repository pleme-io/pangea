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
      # ML model configuration entry
      class MlModelEntry < Dry::Struct
        transform_keys(&:to_sym)

        attribute :name, Types::String
        attribute :type, Types::String.enum('anomaly', 'classification', 'prediction', 'clustering')
        attribute :update_frequency, Types::String.enum('realtime', 'hourly', 'daily').default('hourly')
        attribute :training_data_days, Types::Integer.default(30)
      end

      # Compliance configuration
      class ComplianceConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :frameworks, Types::Array.of(
          Types::String.enum('soc2', 'iso27001', 'nist', 'pci-dss', 'hipaa', 'gdpr', 'ccpa')
        ).default(['soc2', 'iso27001'].freeze)
        attribute :enable_compliance_reporting, Types::Bool.default(true)
        attribute :report_schedule, Types::String.enum('daily', 'weekly', 'monthly').default('weekly')
        attribute :evidence_collection, Types::Bool.default(true)
        attribute :audit_trail_retention, Types::Integer.default(2555).constrained(gteq: 365)
      end

      # Analytics configuration
      class AnalyticsConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :enable_ueba, Types::Bool.default(true)
        attribute :enable_network_analytics, Types::Bool.default(true)
        attribute :enable_file_analytics, Types::Bool.default(true)
        attribute :ml_models, Types::Array.of(MlModelEntry).default([].freeze)
        attribute :enable_threat_hunting_queries, Types::Bool.default(true)
      end

      # Integration entry configuration
      class IntegrationEntry < Dry::Struct
        transform_keys(&:to_sym)

        attribute :name, Types::String
        attribute :type, Types::String.enum('ticketing', 'soar', 'threat_intel', 'cmdb', 'notification')
        attribute :endpoint, Types::String.optional
        attribute :api_key_secret_arn, Types::String.optional
        attribute :enabled, Types::Bool.default(true)
      end
    end
  end
end
