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
  module CLI
    module Commands
      class EnhancedPlan
        # Plan generation and result display operations
        module PlanGeneration
          private

          def generate_plan_with_progress(templates, _namespace_entity)
            ui.section "Infrastructure Planning"

            plan_results = []

            templates.each do |template|
              result = generate_single_plan(template)
              plan_results << result
            end

            plan_results
          end

          def generate_single_plan(template)
            spinner = UI::Spinner.terraform_operation(:plan)
            spinner.update("Planning #{template[:name]} template")

            spinner.spin do
              sleep 1.5
              build_plan_result(template)
            end
          end

          def build_plan_result(template)
            actions = %i[create update delete replace]
            resource_types = %w[aws_vpc aws_subnet aws_instance aws_s3_bucket aws_rds_instance]

            resources = (1..template[:resources]).map do |i|
              {
                type: resource_types.sample,
                name: "resource_#{i}",
                action: actions.sample,
                reason: ['Configuration changed', 'New resource', 'Dependency update', 'AMI changed'].sample
              }
            end

            {
              template: template[:name],
              resources: resources,
              summary: resources.group_by { |r| r[:action] }.transform_values(&:count)
            }
          end

          def display_plan_results(plan_results)
            ui.section "Plan Results"

            total_summary = calculate_total_summary(plan_results)
            puts banner.operation_summary(:plan, total_summary)
            puts

            plan_results.each do |result|
              ui.say "\n  Template: #{ui.pastel.bright_white(result[:template])}"
              puts UI::Table.plan_summary(result[:resources])
            end

            show_cost_estimate(plan_results)
          end

          def calculate_total_summary(plan_results)
            plan_results.reduce({}) do |acc, result|
              result[:summary].each do |action, count|
                acc[action] = (acc[action] || 0) + count
              end
              acc
            end
          end
        end
      end
    end
  end
end
