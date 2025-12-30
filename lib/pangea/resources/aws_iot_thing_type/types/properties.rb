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
          # Property accessor methods for IoT Thing Type
          module Properties
            # Check if thing type has description
            def has_description?
              thing_type_properties&.dig(:description) && !thing_type_properties[:description].empty?
            end

            # Get description or default
            def description_text
              thing_type_properties&.dig(:description) || "IoT Thing Type: #{thing_type_name}"
            end

            # Check if thing type has searchable attributes
            def has_searchable_attributes?
              thing_type_properties&.dig(:searchable_attributes) &&
                thing_type_properties[:searchable_attributes].any?
            end

            # Get searchable attributes list
            def searchable_attributes_list
              thing_type_properties&.dig(:searchable_attributes) || []
            end

            # Count searchable attributes
            def searchable_attribute_count
              searchable_attributes_list.length
            end

            # Generate thing type ARN pattern
            def thing_type_arn_pattern(region, account_id)
              "arn:aws:iot:#{region}:#{account_id}:thingtype/#{thing_type_name}"
            end

            # Check if optimized for fleet indexing
            def fleet_indexing_optimized?
              has_searchable_attributes? && has_description?
            end
          end
        end
      end
    end
  end
end
