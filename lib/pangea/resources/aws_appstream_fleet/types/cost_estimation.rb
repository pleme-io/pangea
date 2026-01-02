# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # Cost estimation methods for AppStream Fleet
        module AppstreamFleetCostEstimation
          INSTANCE_HOURLY_RATES = {
            /stream\.standard\.small/ => 0.08,
            /stream\.standard\.medium/ => 0.16,
            /stream\.standard\.large/ => 0.31,
            /stream\.compute\.large/ => 0.49,
            /stream\.compute\.xlarge/ => 0.87,
            /stream\.compute\.2xlarge/ => 1.74,
            /stream\.compute\.4xlarge/ => 3.48,
            /stream\.compute\.8xlarge/ => 6.96,
            /stream\.memory\.large/ => 0.56,
            /stream\.memory\.xlarge/ => 1.12,
            /stream\.memory\.2xlarge/ => 2.24,
            /stream\.memory\.4xlarge/ => 4.48,
            /stream\.memory\.8xlarge/ => 8.96,
            /stream\.graphics\.g4dn\.xlarge/ => 1.20,
            /stream\.graphics\.g4dn\.2xlarge/ => 1.93,
            /stream\.graphics\.g4dn\.4xlarge/ => 3.10,
            /stream\.graphics\.g4dn\.8xlarge/ => 5.59,
            /stream\.graphics\.g4dn\.12xlarge/ => 10.07,
            /stream\.graphics\.g4dn\.16xlarge/ => 11.17,
            /stream\.graphics-pro\.4xlarge/ => 3.78,
            /stream\.graphics-pro\.8xlarge/ => 7.56,
            /stream\.graphics-pro\.16xlarge/ => 15.12
          }.freeze

          DEFAULT_HOURLY_RATE = 0.16

          def estimated_monthly_cost
            hourly_rate = INSTANCE_HOURLY_RATES.find { |pattern, _| instance_type.match?(pattern) }&.last
            hourly_rate ||= DEFAULT_HOURLY_RATE

            if always_on?
              # Always-on fleets run 24/7
              hourly_rate * 730 * compute_capacity.desired_instances
            else
              # On-demand fleets - estimate 8 hours/day, 22 days/month
              hourly_rate * 8 * 22 * compute_capacity.desired_instances
            end
          end
        end
      end
    end
  end
end
