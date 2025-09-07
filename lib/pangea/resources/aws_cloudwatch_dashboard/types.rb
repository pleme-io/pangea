# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'
require 'json'

module Pangea
  module Resources
    module AWS
      module Types
        # Widget metric configuration
        class DashboardMetric < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :namespace, Resources::Types::String
          attribute :metric_name, Resources::Types::String
          attribute :dimensions, Resources::Types::Hash.default({}.freeze)
          attribute :stat, Resources::Types::String.default('Average').enum(
            'Average', 'Maximum', 'Minimum', 'SampleCount', 'Sum',
            'p50', 'p90', 'p95', 'p99', 'p99.9'
          )
          attribute :period, Resources::Types::Integer.default(300).constrained(gteq: 60)
          attribute :region, Resources::Types::String.optional.default(nil)
          attribute :label, Resources::Types::String.optional.default(nil)
          
          def to_h
            hash = {
              namespace: namespace,
              metricName: metric_name,
              dimensions: dimensions,
              stat: stat,
              period: period
            }
            
            hash[:region] = region if region
            hash[:label] = label if label
            
            hash.compact
          end
        end
        
        # Widget properties for different widget types
        class DashboardWidgetProperties < Dry::Struct
          transform_keys(&:to_sym)
          
          # Metric widget properties
          attribute :metrics, Resources::Types::Array.of(Resources::Types::Array).optional.default(nil)
          attribute :view, Resources::Types::String.optional.default(nil).enum(
            'timeSeries', 'singleValue', 'pie', 'bar', 'number', nil
          )
          attribute :stacked, Resources::Types::Bool.optional.default(nil)
          attribute :region, Resources::Types::String.optional.default(nil)
          attribute :title, Resources::Types::String.optional.default(nil)
          attribute :period, Resources::Types::Integer.optional.default(nil).constrained(gteq: 60)
          attribute :stat, Resources::Types::String.optional.default(nil)
          attribute :yaxis, Resources::Types::Hash.optional.default(nil)
          
          # Text widget properties
          attribute :markdown, Resources::Types::String.optional.default(nil)
          
          # Log widget properties
          attribute :query, Resources::Types::String.optional.default(nil)
          attribute :source, Resources::Types::String.optional.default(nil)
          attribute :log_group, Resources::Types::String.optional.default(nil)
          
          def to_h
            hash = {}
            
            # Metric widget properties
            hash[:metrics] = metrics if metrics
            hash[:view] = view if view
            hash[:stacked] = stacked unless stacked.nil?
            hash[:region] = region if region
            hash[:title] = title if title
            hash[:period] = period if period
            hash[:stat] = stat if stat
            hash[:yAxis] = yaxis if yaxis
            
            # Text widget properties
            hash[:markdown] = markdown if markdown
            
            # Log widget properties
            hash[:query] = query if query
            hash[:source] = source if source
            hash[:logGroup] = log_group if log_group
            
            hash.compact
          end
        end
        
        # Dashboard widget configuration
        class DashboardWidget < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :type, Resources::Types::String.enum(
            'metric', 'text', 'log', 'number', 'explorer'
          )
          attribute :x, Resources::Types::Integer.constrained(gteq: 0, lt: 24)
          attribute :y, Resources::Types::Integer.constrained(gteq: 0)
          attribute :width, Resources::Types::Integer.constrained(gteq: 1, lteq: 24)
          attribute :height, Resources::Types::Integer.constrained(gteq: 1)
          attribute :properties, DashboardWidgetProperties
          
          # Validate widget configuration
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate x + width doesn't exceed 24 (grid width)
            if attrs[:x] && attrs[:width] && (attrs[:x] + attrs[:width] > 24)
              raise Dry::Struct::Error, "Widget x position (#{attrs[:x]}) + width (#{attrs[:width]}) cannot exceed 24"
            end
            
            # Validate type-specific properties
            if attrs[:type] && attrs[:properties]
              case attrs[:type]
              when 'metric', 'number', 'explorer'
                if !attrs[:properties][:metrics] && !attrs[:properties][:query]
                  raise Dry::Struct::Error, "Metric widgets require either metrics or query property"
                end
              when 'text'
                unless attrs[:properties][:markdown]
                  raise Dry::Struct::Error, "Text widgets require markdown property"
                end
              when 'log'
                unless attrs[:properties][:query] && attrs[:properties][:source]
                  raise Dry::Struct::Error, "Log widgets require both query and source properties"
                end
              end
            end
            
            super(attrs)
          end
          
          def to_h
            {
              type: type,
              x: x,
              y: y,
              width: width,
              height: height,
              properties: properties.to_h
            }
          end
        end
        
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
            
            # Validate dashboard name
            if attrs[:dashboard_name]
              name = attrs[:dashboard_name]
              
              if name.empty?
                raise Dry::Struct::Error, "Dashboard name cannot be empty"
              end
              
              if name.length > 255
                raise Dry::Struct::Error, "Dashboard name cannot exceed 255 characters"
              end
              
              # CloudWatch dashboard name pattern
              unless name.match?(/\A[a-zA-Z0-9_\-\.]+\z/)
                raise Dry::Struct::Error, "Dashboard name can only contain alphanumeric characters, underscores, hyphens, and periods"
              end
            end
            
            # Validate that exactly one of dashboard_body, dashboard_body_json, or widgets is provided
            body_provided = !attrs[:dashboard_body].nil?
            body_json_provided = !attrs[:dashboard_body_json].nil?
            widgets_provided = attrs[:widgets] && !attrs[:widgets].empty?
            
            provided_count = [body_provided, body_json_provided, widgets_provided].count(true)
            
            if provided_count == 0
              raise Dry::Struct::Error, "Must provide one of: dashboard_body, dashboard_body_json, or widgets"
            end
            
            if provided_count > 1
              raise Dry::Struct::Error, "Cannot provide more than one of: dashboard_body, dashboard_body_json, or widgets"
            end
            
            # Validate JSON if dashboard_body_json is provided
            if attrs[:dashboard_body_json]
              begin
                JSON.parse(attrs[:dashboard_body_json])
              rescue JSON::ParserError => e
                raise Dry::Struct::Error, "dashboard_body_json contains invalid JSON: #{e.message}"
              end
            end
            
            # Validate widget overlaps if widgets are provided
            if attrs[:widgets]
              validate_widget_overlaps(attrs[:widgets])
            end
            
            super(attrs)
          end
          
          # Validate that widgets don't overlap
          def self.validate_widget_overlaps(widgets)
            occupied_positions = Set.new
            
            widgets.each_with_index do |widget, index|
              (widget[:x]...(widget[:x] + widget[:width])).each do |x|
                (widget[:y]...(widget[:y] + widget[:height])).each do |y|
                  position = "#{x},#{y}"
                  if occupied_positions.include?(position)
                    raise Dry::Struct::Error, "Widget at index #{index} overlaps with another widget at position (#{x}, #{y})"
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
            
            {
              widgets: widgets.map(&:to_h)
            }
          end
          
          def to_h
            hash = {
              dashboard_name: dashboard_name
            }
            
            # Use appropriate body format
            if dashboard_body
              hash[:dashboard_body] = JSON.pretty_generate(dashboard_body)
            elsif dashboard_body_json
              hash[:dashboard_body] = dashboard_body_json
            elsif widgets
              hash[:dashboard_body] = JSON.pretty_generate({
                widgets: widgets.map(&:to_h)
              })
            end
            
            hash
          end
        end
      end
    end
  end
end