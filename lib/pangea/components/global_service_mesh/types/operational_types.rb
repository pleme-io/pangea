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
    module GlobalServiceMesh
      # Security configuration
      class SecurityConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :mtls_enabled, Types::Bool.default(true)
        attribute :tls_mode, Types::String.enum('STRICT', 'PERMISSIVE', 'DISABLED').default('STRICT')
        attribute :certificate_authority_arn, Types::String.optional
        attribute :service_auth_enabled, Types::Bool.default(true)
        attribute :rbac_enabled, Types::Bool.default(true)
        attribute :encryption_in_transit, Types::Bool.default(true)
        attribute :secrets_manager_integration, Types::Bool.default(true)
      end

      # Observability configuration
      class ObservabilityConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :xray_enabled, Types::Bool.default(true)
        attribute :cloudwatch_metrics_enabled, Types::Bool.default(true)
        attribute :access_logging_enabled, Types::Bool.default(true)
        attribute :envoy_stats_enabled, Types::Bool.default(true)
        attribute :custom_metrics_enabled, Types::Bool.default(false)
        attribute :distributed_tracing_sampling_rate, Types::Float.default(0.1)
        attribute :log_retention_days, Types::Integer.default(30)
      end
    end
  end
end
