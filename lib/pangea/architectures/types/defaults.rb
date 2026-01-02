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

module Pangea
  module Architectures
    module Types
      # Default configurations for common scenarios
      DEVELOPMENT_DEFAULTS = {
        environment: 'development',
        high_availability: false,
        auto_scaling: { min: 1, max: 2, desired: 1 },
        monitoring: { detailed_monitoring: false },
        backup: { retention_days: 1 },
        security: { enable_waf: false, enable_ddos_protection: false }
      }.freeze

      STAGING_DEFAULTS = {
        environment: 'staging',
        high_availability: false,
        auto_scaling: { min: 1, max: 3, desired: 1 },
        monitoring: { detailed_monitoring: true },
        backup: { retention_days: 3 },
        security: { enable_waf: false, enable_ddos_protection: false }
      }.freeze

      PRODUCTION_DEFAULTS = {
        environment: 'production',
        high_availability: true,
        auto_scaling: { min: 2, max: 10, desired: 2 },
        monitoring: { detailed_monitoring: true, enable_alerting: true },
        backup: { retention_days: 30, cross_region_backup: true },
        security: { enable_waf: true, enable_ddos_protection: true }
      }.freeze

      def self.defaults_for_environment(environment)
        case environment.to_s
        when 'development'
          DEVELOPMENT_DEFAULTS
        when 'staging'
          STAGING_DEFAULTS
        when 'production'
          PRODUCTION_DEFAULTS
        else
          DEVELOPMENT_DEFAULTS
        end
      end
    end
  end
end
