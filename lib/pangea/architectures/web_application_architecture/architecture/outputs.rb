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
      class Architecture
        # Output calculation methods
        module Outputs
          def calculate_outputs(name, attributes, components, resources)
            outputs = {}
            add_url_outputs(outputs, attributes, components)
            add_endpoint_outputs(outputs, components)
            add_monitoring_output(outputs, components)
            outputs[:estimated_monthly_cost] = calculate_monthly_cost(components, resources)
            outputs[:capabilities] = calculate_capabilities(attributes, components, resources)
            outputs
          end

          private

          def add_url_outputs(outputs, attributes, components)
            if attributes[:domain_name]
              outputs[:application_url] = "https://#{attributes[:domain_name]}"
            elsif components[:load_balancer]&.respond_to?(:dns_name)
              outputs[:application_url] = "https://#{components[:load_balancer].dns_name}"
            end

            return unless components[:load_balancer]&.respond_to?(:dns_name)

            outputs[:load_balancer_dns] = components[:load_balancer].dns_name
          end

          def add_endpoint_outputs(outputs, components)
            outputs[:database_endpoint] = components[:database].endpoint if components[:database]&.respond_to?(:endpoint)
            outputs[:cdn_domain] = components[:cdn].domain_name if components[:cdn]&.respond_to?(:domain_name)
          end

          def add_monitoring_output(outputs, components)
            return unless components[:monitoring]&.dig(:dashboard)

            outputs[:monitoring_dashboard_url] = components[:monitoring][:dashboard][:url]
          end

          def calculate_capabilities(attributes, components, resources)
            {
              high_availability: has_high_availability?(components),
              auto_scaling: has_auto_scaling?(components),
              caching: components.key?(:cache),
              cdn: components.key?(:cdn),
              ssl_termination: attributes[:ssl_certificate_arn] || resources[:ssl_certificate],
              monitoring: components[:monitoring]&.any?,
              backup: has_backup_strategy?(components)
            }
          end
        end
      end
    end
  end
end
