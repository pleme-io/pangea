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
        # Environment-specific defaults and input coercion
        module Defaults
          ENVIRONMENT_CONFIGS = {
            'development' => {
              instance_type: 't3.micro',
              auto_scaling: { min: 1, max: 2, desired: 1 },
              database_instance_class: 'db.t3.micro',
              enable_caching: false,
              enable_cdn: false,
              high_availability: false
            },
            'staging' => {
              instance_type: 't3.small',
              auto_scaling: { min: 1, max: 4, desired: 2 },
              database_instance_class: 'db.t3.small',
              enable_caching: true,
              enable_cdn: false,
              high_availability: true
            },
            'production' => {
              instance_type: 't3.medium',
              auto_scaling: { min: 2, max: 10, desired: 3 },
              database_instance_class: 'db.r5.large',
              enable_caching: true,
              enable_cdn: true,
              high_availability: true
            }
          }.freeze

          module_function

          def compute_defaults_for_environment(environment)
            base_defaults = Pangea::Architectures::Types.defaults_for_environment(environment)
            web_app_defaults = ENVIRONMENT_CONFIGS.fetch(environment.to_s, {})

            base_defaults.merge(web_app_defaults)
          end

          def coerce_input(raw_attributes)
            # Apply environment-specific defaults
            if raw_attributes[:environment]
              defaults = compute_defaults_for_environment(raw_attributes[:environment])
              raw_attributes = defaults.merge(raw_attributes)
            end

            # Coerce types
            coerced = {}

            # Handle tags coercion
            coerced[:tags] = Pangea::Architectures::Types.coerce_tags(raw_attributes[:tags])

            # Handle auto scaling config coercion
            if raw_attributes[:auto_scaling]
              coerced[:auto_scaling] = Pangea::Architectures::Types.coerce_auto_scaling_config(
                raw_attributes[:auto_scaling]
              )
            end

            # Merge coerced values
            final_attributes = raw_attributes.merge(coerced)

            # Validate the final configuration
            Validation.validate_web_application_config(final_attributes)

            Input.new(final_attributes)
          end
        end
      end
    end
  end
end
