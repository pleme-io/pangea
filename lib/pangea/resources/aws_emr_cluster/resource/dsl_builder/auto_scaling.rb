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
      module EmrCluster
        class DSLBuilder
          # Auto scaling policy building methods for EMR clusters
          module AutoScaling
            def build_auto_scaling_policy(ctx, asp)
              return unless asp

              builder = self
              ctx.auto_scaling_policy do
                constraints do
                  constraints_config = asp[:constraints]
                  min_capacity constraints_config[:min_capacity]
                  max_capacity constraints_config[:max_capacity]
                end
                asp[:rules].each { |rule| builder.send(:build_scaling_rule, self, rule) }
              end
            end

            private

            def build_scaling_rule(ctx, rule)
              builder = self
              ctx.rules do
                name rule[:name]
                description rule[:description] if rule[:description]
                builder.send(:build_scaling_action, self, rule[:action])
                builder.send(:build_scaling_trigger, self, rule[:trigger])
              end
            end

            def build_scaling_action(ctx, action_config)
              ctx.action do
                market action_config[:market] if action_config[:market]
                simple_scaling_policy_configuration do
                  sspc = action_config[:simple_scaling_policy_configuration]
                  adjustment_type sspc[:adjustment_type] if sspc[:adjustment_type]
                  scaling_adjustment sspc[:scaling_adjustment]
                  cool_down sspc[:cool_down] if sspc[:cool_down]
                end
              end
            end

            def build_scaling_trigger(ctx, trigger)
              ctx.trigger do
                cloud_watch_alarm_definition do
                  cwad = trigger[:cloud_watch_alarm_definition]
                  comparison_operator cwad[:comparison_operator]
                  evaluation_periods cwad[:evaluation_periods]
                  metric_name cwad[:metric_name]
                  namespace cwad[:namespace]
                  period cwad[:period]
                  statistic cwad[:statistic] if cwad[:statistic]
                  threshold cwad[:threshold]
                  unit cwad[:unit] if cwad[:unit]
                  build_dimensions(self, cwad[:dimensions])
                end
              end
            end

            def build_dimensions(ctx, dimensions)
              return unless dimensions&.any?

              ctx.dimensions do
                dimensions.each do |dim_key, dim_value|
                  public_send(dim_key.gsub(/[^a-zA-Z0-9_]/, '_').downcase, dim_value)
                end
              end
            end
          end
        end
      end
    end
  end
end
