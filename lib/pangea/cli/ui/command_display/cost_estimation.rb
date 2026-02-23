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
    module UI
      module CommandDisplay
        # Cost estimation display utilities
        module CostEstimation
          # Estimated monthly costs per resource type (USD)
          RESOURCE_COSTS = {
            'aws_route53_zone' => 0.50,
            'aws_route53_record' => 0.001,
            'aws_s3_bucket' => 5.00,
            'aws_lambda_function' => 10.00,
            'aws_rds_cluster' => 100.00,
            'aws_db_instance' => 100.00,
            'aws_ec2_instance' => 50.00,
            'aws_instance' => 50.00,
            'aws_ecs_service' => 30.00,
            'aws_eks_cluster' => 200.00
          }.freeze

          DEFAULT_RESOURCE_COST = 1.00

          # Display cost estimation
          def display_cost_estimation(resources)
            estimated_cost = estimate_monthly_cost(resources)
            return if estimated_cost.zero?

            formatter.subsection_header('Cost Estimation', icon: :info)

            formatter.kv_pair(
              'Estimated monthly cost',
              Boreal.paint("$#{estimated_cost}/month", :primary)
            )

            formatter.blank_line
            puts Boreal.paint(
              'Note: This is a rough estimate. Actual costs may vary based on usage.', :muted
            )
            formatter.blank_line
          end

          private

          def estimate_monthly_cost(resources)
            total = 0.0

            resources.each do |resource|
              resource_type = extract_resource_type(resource)
              total += RESOURCE_COSTS.fetch(resource_type, DEFAULT_RESOURCE_COST)
            end

            total.round(2)
          end

          def extract_resource_type(resource)
            if resource.is_a?(Hash)
              resource[:type]
            else
              resource.to_s.split('.').first
            end
          end
        end
      end
    end
  end
end
