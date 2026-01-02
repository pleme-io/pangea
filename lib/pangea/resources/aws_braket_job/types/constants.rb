# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # Instance types supported by AWS Braket Jobs
        BraketJobInstanceType = Resources::Types::String.enum(
          'ml.m5.large', 'ml.m5.xlarge', 'ml.m5.2xlarge', 'ml.m5.4xlarge',
          'ml.m5.12xlarge', 'ml.m5.24xlarge',
          'ml.c5.large', 'ml.c5.xlarge', 'ml.c5.2xlarge', 'ml.c5.4xlarge',
          'ml.c5.9xlarge', 'ml.c5.18xlarge',
          'ml.p3.2xlarge', 'ml.p3.8xlarge', 'ml.p3.16xlarge',
          'ml.g4dn.xlarge', 'ml.g4dn.2xlarge', 'ml.g4dn.4xlarge',
          'ml.g4dn.8xlarge', 'ml.g4dn.12xlarge', 'ml.g4dn.16xlarge'
        )

        # Cost estimates for Braket job instance types (USD per hour)
        module BraketJobCosts
          INSTANCE_COSTS = {
            'ml.m5.large' => 0.10, 'ml.m5.xlarge' => 0.20,
            'ml.m5.2xlarge' => 0.40, 'ml.m5.4xlarge' => 0.80,
            'ml.m5.12xlarge' => 2.40, 'ml.m5.24xlarge' => 4.80,
            'ml.c5.large' => 0.09, 'ml.c5.xlarge' => 0.17,
            'ml.c5.2xlarge' => 0.34, 'ml.c5.4xlarge' => 0.68,
            'ml.c5.9xlarge' => 1.53, 'ml.c5.18xlarge' => 3.06,
            'ml.p3.2xlarge' => 3.06, 'ml.p3.8xlarge' => 12.24,
            'ml.p3.16xlarge' => 24.48,
            'ml.g4dn.xlarge' => 0.526, 'ml.g4dn.2xlarge' => 0.752,
            'ml.g4dn.4xlarge' => 1.204, 'ml.g4dn.8xlarge' => 2.176,
            'ml.g4dn.12xlarge' => 3.912, 'ml.g4dn.16xlarge' => 4.352
          }.freeze

          def self.cost_for(instance_type)
            INSTANCE_COSTS[instance_type] || 1.0
          end
        end
      end
    end
  end
end
