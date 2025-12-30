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
          # Template generation methods for IoT Thing Type
          module Templates
            # Generate example thing configuration for this type
            def example_thing_configuration
              example_attrs = {}

              # Add recommended attributes with example values
              recommended_thing_attributes.each do |attr|
                example_attrs[attr.to_sym] = example_value_for_attribute(attr)
              end

              {
                thing_name: "#{thing_type_name.downcase.gsub(/[^a-z0-9]/, '_')}_001",
                thing_type_name: thing_type_name,
                attribute_payload: {
                  attributes: example_attrs
                }
              }
            end

            private

            def example_value_for_attribute(attr)
              case attr
              when 'model'
                "#{thing_type_name}_v1"
              when 'manufacturer'
                'ACME Corp'
              when 'serial_number'
                'SN001234'
              when 'firmware_version'
                '1.0.0'
              when 'location'
                'facility_01'
              when 'installation_date'
                '2024-01-01'
              when 'status'
                'active'
              else
                'example_value'
              end
            end
          end
        end
      end
    end
  end
end
