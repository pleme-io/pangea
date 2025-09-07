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

module Pangea
  module Resources
    module AWS
      module Types
        # Metric transformation configuration
        class MetricTransformation < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :name, Resources::Types::String
          attribute :namespace, Resources::Types::String
          attribute :value, Resources::Types::String
          attribute :default_value, Resources::Types::Float.optional.default(nil)
          attribute :dimensions, Resources::Types::Hash.default({}.freeze)
          attribute :unit, Resources::Types::String.optional.default(nil).enum(
            'None', 'Seconds', 'Microseconds', 'Milliseconds', 'Bytes', 'Kilobytes', 
            'Megabytes', 'Gigabytes', 'Terabytes', 'Bits', 'Kilobits', 'Megabits', 
            'Gigabits', 'Terabits', 'Percent', 'Count', 'Bytes/Second', 
            'Kilobytes/Second', 'Megabytes/Second', 'Gigabytes/Second', 
            'Terabytes/Second', 'Bits/Second', 'Kilobits/Second', 'Megabits/Second', 
            'Gigabits/Second', 'Terabits/Second', 'Count/Second', nil
          )
          
          def to_h
            hash = {
              name: name,
              namespace: namespace,
              value: value
            }
            
            hash[:default_value] = default_value if default_value
            hash[:dimensions] = dimensions if dimensions.any?
            hash[:unit] = unit if unit
            
            hash.compact
          end
        end
        
        # CloudWatch Log Metric Filter resource attributes with validation
        class CloudWatchLogMetricFilterAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :name, Resources::Types::String
          attribute :log_group_name, Resources::Types::String
          attribute :pattern, Resources::Types::String
          attribute :metric_transformation, MetricTransformation
          
          # Validate filter pattern and metric configuration
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate name format
            if attrs[:name] && !attrs[:name].match?(/^[\.\-_#A-Za-z0-9]+$/)
              raise Dry::Struct::Error, "name must contain only alphanumeric characters, periods, hyphens, underscores, and hash"
            end
            
            # Validate pattern is not empty
            if attrs[:pattern] && attrs[:pattern].strip.empty?
              raise Dry::Struct::Error, "pattern cannot be empty"
            end
            
            # Convert metric_transformation to MetricTransformation if needed
            if attrs[:metric_transformation] && !attrs[:metric_transformation].is_a?(MetricTransformation)
              attrs[:metric_transformation] = MetricTransformation.new(attrs[:metric_transformation])
            end
            
            # Validate metric value syntax
            if attrs[:metric_transformation]
              value = attrs[:metric_transformation][:value] || attrs[:metric_transformation].value
              if value && !value.match?(/^\$?[\w\.\[\]]+$/)
                raise Dry::Struct::Error, "metric_transformation.value must be a valid metric value expression"
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def pattern_type
            case pattern
            when /^\[/ then :space_delimited
            when /\{.*\}/ then :json
            when /\w+\s*=\s*/ then :key_value
            else :text
            end
          end
          
          def extracts_numeric_value?
            metric_transformation.value.start_with?('$')
          end
          
          def has_dimensions?
            metric_transformation.dimensions.any?
          end
          
          def has_default_value?
            !metric_transformation.default_value.nil?
          end
          
          def metric_namespace
            metric_transformation.namespace
          end
          
          def metric_name
            metric_transformation.name
          end
          
          def to_h
            {
              name: name,
              log_group_name: log_group_name,
              pattern: pattern,
              metric_transformation: metric_transformation.to_h
            }
          end
        end
      end
    end
  end
end