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
  module Resources
    module AWS
      module Types
        class IotThingTypeAttributes
          # Recommendation methods for IoT Thing Type
          module Recommendations
            # Get recommended attributes for things of this type
            def recommended_thing_attributes
              recommendations = []

              # Basic device information
              recommendations.concat(%w[model manufacturer serial_number firmware_version])

              # Location and deployment
              recommendations.concat(%w[location installation_date]) unless searchable_attributes_list.include?('location')

              # Operational data
              recommendations.concat(%w[last_maintenance next_maintenance status])

              # Include searchable attributes as recommended
              recommendations.concat(searchable_attributes_list)

              recommendations.uniq.sort
            end

            # Security and compliance recommendations
            def security_recommendations
              recommendations = []

              recommendations << 'Add description for better organization' unless has_description?
              recommendations << 'Define searchable attributes for fleet indexing' unless has_searchable_attributes?

              # Check for common naming patterns
              unless thing_type_name.match?(/\A[A-Z][a-zA-Z0-9_]*\z/)
                recommendations << 'Use PascalCase naming convention for thing types'
              end

              # Recommend descriptive naming
              recommendations << 'Consider more descriptive thing type names' if thing_type_name.length < 5

              recommendations
            end
          end
        end
      end
    end
  end
end
