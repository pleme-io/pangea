# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # SageMaker Endpoint Configuration instance types for inference
        SageMakerInferenceInstanceType = String.enum(
          # General purpose
          'ml.t2.medium', 'ml.t2.large', 'ml.t2.xlarge', 'ml.t2.2xlarge',
          'ml.m4.xlarge', 'ml.m4.2xlarge', 'ml.m4.4xlarge', 'ml.m4.10xlarge', 'ml.m4.16xlarge',
          'ml.m5.large', 'ml.m5.xlarge', 'ml.m5.2xlarge', 'ml.m5.4xlarge', 'ml.m5.12xlarge', 'ml.m5.24xlarge',
          'ml.m5d.large', 'ml.m5d.xlarge', 'ml.m5d.2xlarge', 'ml.m5d.4xlarge', 'ml.m5d.12xlarge', 'ml.m5d.24xlarge',
          # Compute optimized
          'ml.c4.large', 'ml.c4.xlarge', 'ml.c4.2xlarge', 'ml.c4.4xlarge', 'ml.c4.8xlarge',
          'ml.c5.large', 'ml.c5.xlarge', 'ml.c5.2xlarge', 'ml.c5.4xlarge', 'ml.c5.9xlarge', 'ml.c5.18xlarge',
          'ml.c5d.large', 'ml.c5d.xlarge', 'ml.c5d.2xlarge', 'ml.c5d.4xlarge', 'ml.c5d.9xlarge', 'ml.c5d.18xlarge',
          # Memory optimized
          'ml.r4.large', 'ml.r4.xlarge', 'ml.r4.2xlarge', 'ml.r4.4xlarge', 'ml.r4.8xlarge', 'ml.r4.16xlarge',
          'ml.r5.large', 'ml.r5.xlarge', 'ml.r5.2xlarge', 'ml.r5.4xlarge', 'ml.r5.12xlarge', 'ml.r5.24xlarge',
          'ml.r5d.large', 'ml.r5d.xlarge', 'ml.r5d.2xlarge', 'ml.r5d.4xlarge', 'ml.r5d.12xlarge', 'ml.r5d.24xlarge',
          # GPU instances
          'ml.p2.xlarge', 'ml.p2.8xlarge', 'ml.p2.16xlarge',
          'ml.p3.2xlarge', 'ml.p3.8xlarge', 'ml.p3.16xlarge',
          'ml.g4dn.xlarge', 'ml.g4dn.2xlarge', 'ml.g4dn.4xlarge', 'ml.g4dn.8xlarge', 'ml.g4dn.12xlarge', 'ml.g4dn.16xlarge',
          # Inference optimized
          'ml.inf1.xlarge', 'ml.inf1.2xlarge', 'ml.inf1.6xlarge', 'ml.inf1.24xlarge'
        )

        # SageMaker Production Variant configuration
        SageMakerProductionVariant = Hash.schema(
          variant_name: String.constrained(min_size: 1, max_size: 63, format: /\A[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9]\z/),
          model_name: String,
          initial_instance_count: Integer.constrained(gteq: 1, lteq: 1000),
          instance_type: SageMakerInferenceInstanceType,
          initial_variant_weight?: Float.constrained(gteq: 0.0, lteq: 1.0).default(1.0),
          accelerator_type?: String.enum('ml.eia1.medium', 'ml.eia1.large', 'ml.eia1.xlarge', 'ml.eia2.medium', 'ml.eia2.large', 'ml.eia2.xlarge').optional,
          core_dump_config?: Hash.schema(destination_s3_uri: String.constrained(format: /\As3:\/\//), kms_key_id?: String.optional).optional,
          serverless_config?: Hash.schema(memory_size_in_mb: Integer.constrained(gteq: 1024, lteq: 6144), max_concurrency: Integer.constrained(gteq: 1, lteq: 200)).optional
        ).constructor do |value|
          if value[:serverless_config] && value[:instance_type]
            unless %w[ml.m5.large ml.m5.xlarge ml.m5.2xlarge ml.m5.4xlarge ml.m5.12xlarge ml.m5.24xlarge].include?(value[:instance_type])
              raise Dry::Types::ConstraintError, 'Serverless inference only supports specific M5 instance types'
            end
          end

          if value[:accelerator_type] && value[:instance_type]
            incompatible_types = %w[ml.t2 ml.t3 ml.m4 ml.c4 ml.c5]
            if incompatible_types.any? { |type| value[:instance_type].start_with?(type) }
              raise Dry::Types::ConstraintError, "Accelerator type #{value[:accelerator_type]} not compatible with #{value[:instance_type]}"
            end
          end

          value
        end

        # SageMaker Endpoint Configuration data capture configuration
        SageMakerDataCaptureConfig = Hash.schema(
          enable_capture: Bool.default(false),
          initial_sampling_percentage: Integer.constrained(gteq: 0, lteq: 100),
          destination_s3_uri: String.constrained(format: /\As3:\/\//),
          kms_key_id?: String.optional,
          capture_options: Array.of(Hash.schema(capture_mode: String.enum('Input', 'Output'))).constrained(min_size: 1),
          capture_content_type_header?: Hash.schema(csv_content_types?: Array.of(String).optional, json_content_types?: Array.of(String).optional).optional
        )
      end
    end
  end
end
