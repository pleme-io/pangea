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
    module WebApplicationArchitecture
      module Types
        # Web Application output type definition
        Output = Hash.schema(
          # Architecture reference
          architecture_reference: InstanceOf(Pangea::Architectures::ArchitectureReference),

          # Primary outputs
          application_url: String.optional,
          load_balancer_dns: String.optional,
          database_endpoint: String.optional,

          # Optional outputs
          cdn_domain: String.optional,
          monitoring_dashboard_url: String.optional,

          # Cost and capabilities
          estimated_monthly_cost: Float,
          capabilities: Hash.schema(
            high_availability: Bool,
            auto_scaling: Bool,
            caching: Bool,
            cdn: Bool,
            ssl_termination: Bool,
            monitoring: Bool,
            backup: Bool
          )
        )
      end
    end
  end
end
