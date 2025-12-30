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
require 'json'

module Pangea
  module Resources
    module AWS
      module Types
        # CloudWatch Dashboard resource attributes with validation
        class CloudWatchDashboardAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Required attributes
          attribute :dashboard_name, Resources::Types::String

          # Dashboard body can be provided as hash or JSON string
          attribute :dashboard_body, Resources::Types::Hash.optional.default(nil)
          attribute :dashboard_body_json, Resources::Types::String.optional.default(nil)

          # Dashboard widgets (alternative to dashboard_body)
          attribute :widgets, Resources::Types::Array.of(DashboardWidget).optional.default(nil)

          # Validate dashboard configuration
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            validate_dashboard_name(attrs[:dashboard_name]) if attrs[:dashboard_name]
            validate_body_configuration(attrs)
            validate_body_json(attrs[:dashboard_body_json]) if attrs[:dashboard_body_json]
            validate_widget_overlaps(attrs[:widgets]) if attrs[:widgets]

            super(attrs)
          end

          def self.validate_dashboard_name(name)
            raise Dry::Struct::Error, 'Dashboard name cannot be empty' if name.empty?

            if name.length > 255
              raise Dry::Struct::Error, 'Dashboard name cannot exceed 255 characters'
            end

            return if name.match?(/\A[a-zA-Z0-9_\-\.]+\z/)

            raise Dry::Struct::Error,
                  'Dashboard name can only contain alphanumeric characters, underscores, hyphens, and periods'
          end

          def self.validate_body_configuration(attrs)
            body_provided = !attrs[:dashboard_body].nil?
            body_json_provided = !attrs[:dashboard_body_json].nil?
            widgets_provided = attrs[:widgets] && !attrs[:widgets].empty?

            provided_count = [body_provided, body_json_provided, widgets_provided].count(true)

            if provided_count.zero?
              raise Dry::Struct::Error, 'Must provide one of: dashboard_body, dashboard_body_json, or widgets'
            end

            return unless provided_count > 1

            raise Dry::Struct::Error,
                  'Cannot provide more than one of: dashboard_body, dashboard_body_json, or widgets'
          end

          def self.validate_body_json(json_string)
            JSON.parse(json_string)
          rescue JSON::ParserError => e
            raise Dry::Struct::Error, "dashboard_body_json contains invalid JSON: #{e.message}"
          end

          # Validate that widgets don't overlap
          def self.validate_widget_overlaps(widgets)
            occupied_positions = Set.new

            widgets.each_with_index do |widget, index|
              (widget[:x]...(widget[:x] + widget[:width])).each do |x|
                (widget[:y]...(widget[:y] + widget[:height])).each do |y|
                  position = "#{x},#{y}"
                  if occupied_positions.include?(position)
                    raise Dry::Struct::Error,
                          "Widget at index #{index} overlaps with another widget at position (#{x}, #{y})"
                  end
                  occupied_positions.add(position)
                end
              end
            end
          end

          # Computed properties
          def widget_count
            return 0 if widgets.nil?

            widgets.length
          end

          def has_custom_body?
            !dashboard_body.nil? || !dashboard_body_json.nil?
          end

          def uses_widgets?
            !widgets.nil? && !widgets.empty?
          end

          def dashboard_grid_height
            return 0 if widgets.nil?

            widgets.map { |w| w.y + w.height }.max || 0
          end

          def estimated_monthly_cost_usd
            # CloudWatch dashboard pricing: $3 per dashboard per month
            # First 3 dashboards are free per account
            3.00
          end

          def generate_dashboard_body
            return dashboard_body if dashboard_body
            return JSON.parse(dashboard_body_json) if dashboard_body_json
            return nil if widgets.nil?

            { widgets: widgets.map(&:to_h) }
          end

          def to_h
            hash = { dashboard_name: dashboard_name }

            # Use appropriate body format
            if dashboard_body
              hash[:dashboard_body] = JSON.pretty_generate(dashboard_body)
            elsif dashboard_body_json
              hash[:dashboard_body] = dashboard_body_json
            elsif widgets
              hash[:dashboard_body] = JSON.pretty_generate({ widgets: widgets.map(&:to_h) })
            end

            hash
          end
        end
      end
    end
  end
end
