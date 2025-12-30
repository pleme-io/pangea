# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        SageMakerTrainingDataSource = Hash.schema(
          s3_data_source: Hash.schema(s3_data_type: String.enum('ManifestFile', 'S3Prefix', 'AugmentedManifestFile'),
                                       s3_uri: String.constrained(format: /\As3:\/\//),
                                       s3_data_distribution_type?: String.enum('FullyReplicated', 'ShardedByS3Key').default('FullyReplicated'),
                                       attribute_names?: Array.of(String).optional)
        )

        SageMakerTrainingInputDataConfig = Hash.schema(
          channel_name: String.constrained(min_size: 1, max_size: 64, format: /\A[a-zA-Z0-9\-]+\z/),
          data_source: SageMakerTrainingDataSource, content_type?: SageMakerTrainingContentType.optional,
          compression_type?: SageMakerTrainingCompressionType.default('None'), record_wrapper_type?: String.enum('None', 'RecordIO').default('None'),
          input_mode?: SageMakerTrainingInputMode.default('File'), shuffle_config?: Hash.schema(seed: Integer.constrained(gteq: 0, lteq: 4_294_967_295)).optional
        )

        SageMakerTrainingOutputDataConfig = Hash.schema(kms_key_id?: String.optional, s3_output_path: String.constrained(format: /\As3:\/\//))
        SageMakerTrainingResourceConfig = Hash.schema(instance_count: Integer.constrained(gteq: 1, lteq: 100), instance_type: SageMakerTrainingInstanceType,
                                                       volume_size_in_gb: Integer.constrained(gteq: 1, lteq: 16_384), volume_kms_key_id?: String.optional)
        SageMakerTrainingStoppingCondition = Hash.schema(max_runtime_in_seconds?: Integer.constrained(gteq: 1, lteq: 432_000).default(86_400))
        SageMakerTrainingVpcConfig = Hash.schema(security_group_ids: Array.of(String).constrained(min_size: 1, max_size: 5),
                                                  subnets: Array.of(String).constrained(min_size: 1, max_size: 16))
        SageMakerTrainingCheckpointConfig = Hash.schema(s3_uri: String.constrained(format: /\As3:\/\//), local_path?: String.default('/opt/ml/checkpoints'))
        SageMakerTrainingDebugHookConfig = Hash.schema(local_path?: String.default('/opt/ml/output/tensors'), s3_output_path: String.constrained(format: /\As3:\/\//),
                                                        hook_parameters?: Hash.map(String, String).optional, collection_configurations?: Array.of(Hash).optional)
        SageMakerTrainingProfilerConfig = Hash.schema(s3_output_path?: String.constrained(format: /\As3:\/\//).optional,
                                                       profiling_interval_in_milliseconds?: Integer.constrained(gteq: 100, lteq: 3_600_000).default(500),
                                                       profiling_parameters?: Hash.map(String, String).optional)
      end
    end
  end
end
