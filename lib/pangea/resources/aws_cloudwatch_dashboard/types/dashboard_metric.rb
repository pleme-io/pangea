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
      end
    end
  end
end
