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
      end
    end
  end
end
