# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS Braket Job resources
        class BraketJobAttributes < Dry::Struct
          transform_keys(&:to_sym)
          include BraketJobInstanceMethods

          # Required attributes
          attribute :job_name, Resources::Types::String
          attribute :role_arn, Resources::Types::String

          attribute :algorithm_specification, Resources::Types::Hash.schema(
            script_mode_config: Resources::Types::Hash.schema(
              entry_point: Resources::Types::String,
              s3_uri: Resources::Types::String,
              compression_type?: Resources::Types::String.enum('NONE', 'GZIP').optional
            )
          )

          attribute :device_config, Resources::Types::Hash.schema(
            device: Resources::Types::String
          )

          attribute :instance_config, Resources::Types::Hash.schema(
            instance_type: BraketJobInstanceType,
            volume_size_in_gb: Resources::Types::Integer,
            instance_count?: Resources::Types::Integer.constrained(gteq: 1).optional
          )

          attribute :output_data_config, Resources::Types::Hash.schema(
            s3_path: Resources::Types::String,
            kms_key_id?: Resources::Types::String.optional
          )

          attribute :stopping_condition, Resources::Types::Hash.schema(
            max_runtime_in_seconds: Resources::Types::Integer.constrained(gteq: 1, lteq: 2_592_000)
          )

          # Optional attributes
          attribute? :checkpoint_config, Resources::Types::Hash.schema(
            s3_uri: Resources::Types::String,
            local_path?: Resources::Types::String.optional
          ).optional

          attribute? :hyper_parameters, Resources::Types::Hash.map(
            Resources::Types::String, Resources::Types::String
          ).optional

          attribute? :input_data_config, Resources::Types::Array.of(
            Resources::Types::Hash.schema(
              channel_name: Resources::Types::String,
              data_source: Resources::Types::Hash.schema(
                s3_data_source: Resources::Types::Hash.schema(
                  s3_uri: Resources::Types::String,
                  s3_data_type?: Resources::Types::String.enum('ManifestFile', 'S3Prefix').optional
                )
              ),
              content_type?: Resources::Types::String.optional,
              compression_type?: Resources::Types::String.enum('None', 'Gzip').optional,
              record_wrapper_type?: Resources::Types::String.enum('None', 'RecordIO').optional
            )
          ).optional

          attribute? :tags, Resources::Types::AwsTags

          def self.new(attributes = {})
            attrs = super(attributes)
            BraketJobValidation.validate(attrs)
            attrs
          end
        end
      end
    end
  end
end
