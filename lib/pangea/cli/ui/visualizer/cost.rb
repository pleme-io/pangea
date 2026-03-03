# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module CLI
    module UI
      class Visualizer
        module Cost
          def estimate_resource_cost(resource)
            # Simplified cost estimation based on resource type
            case resource[:type]
            when 'aws_instance'
              instance_costs = {
                't2.micro' => 8.50,
                't2.small' => 17.00,
                't2.medium' => 34.00,
                't3.micro' => 7.50,
                't3.small' => 15.00,
                't3.medium' => 30.00
              }
              instance_costs[resource[:instance_type]] || 50.00
            when 'aws_rds_cluster'
              100.00
            when 'aws_s3_bucket'
              5.00
            when 'aws_lambda_function'
              10.00
            else
              nil
            end
          end
        end
      end
    end
  end
end
