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
          # Analysis methods for IoT Thing Type
          module Analysis
            # IAM permissions required for this thing type
            def required_permissions
              permissions = %w[
                iot:CreateThingType
                iot:DescribeThingType
                iot:DeleteThingType
                iot:ListThingTypes
              ]

              if has_searchable_attributes?
                permissions.concat(%w[
                  iot:SearchIndex
                  iot:GetIndexingConfiguration
                ])
              end

              permissions << 'iot:ListTagsForResource' if tags.any?

              permissions.uniq.sort
            end

            # Estimated cost impact (qualitative)
            def cost_impact_analysis
              impact = {}

              # Base thing type has minimal cost
              impact[:thing_type_cost] = 'minimal'

              # Fleet indexing costs
              if has_searchable_attributes?
                impact[:indexing_cost] = 'low_to_medium'
                impact[:indexing_note] = 'Searchable attributes enable fleet indexing (charges apply per indexed thing)'
              else
                impact[:indexing_cost] = 'none'
              end

              # Things created with this type
              impact[:per_thing_cost] = 'standard'
              impact[:per_thing_note] = 'Each thing created with this type follows standard IoT Core pricing'

              impact
            end

            # Validate compatibility with existing thing types
            def compatibility_check(other_type_name)
              checks = {}

              # Name similarity check
              similarity_threshold = 0.7
              name_similarity = calculate_similarity(thing_type_name.downcase, other_type_name.downcase)

              if name_similarity > similarity_threshold
                checks[:name_conflict] = 'high'
                checks[:name_warning] = 'Thing type names are very similar, consider unique naming'
              else
                checks[:name_conflict] = 'none'
              end

              checks
            end

            private

            # Simple string similarity calculation
            def calculate_similarity(str1, str2)
              return 1.0 if str1 == str2

              max_length = [str1.length, str2.length].max
              return 0.0 if max_length == 0

              # Simple character-based similarity
              common_chars = 0
              str1.each_char.with_index do |char, i|
                common_chars += 1 if i < str2.length && str2[i] == char
              end

              common_chars.to_f / max_length
            end
          end
        end
      end
    end
  end
end
