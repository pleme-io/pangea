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
      # Builder methods for S3-related Firehose destination configurations
      module FirehoseS3Builders
        private

        def build_s3_configuration(builder, s3_config)
          builder.s3_configuration do
            role_arn s3_config[:role_arn]
            bucket_arn s3_config[:bucket_arn]
            prefix s3_config[:prefix] if s3_config[:prefix]
            error_output_prefix s3_config[:error_output_prefix] if s3_config[:error_output_prefix]
            buffer_size s3_config[:buffer_size] if s3_config[:buffer_size]
            buffer_interval s3_config[:buffer_interval] if s3_config[:buffer_interval]
            compression_format s3_config[:compression_format] if s3_config[:compression_format]

            build_encryption_configuration(self, s3_config[:encryption_configuration]) if s3_config[:encryption_configuration]
            build_cloudwatch_logging(self, s3_config[:cloudwatch_logging_options]) if s3_config[:cloudwatch_logging_options]
          end
        end

        def build_encryption_configuration(builder, enc_config)
          builder.encryption_configuration do
            if enc_config[:no_encryption_config]
              no_encryption_config enc_config[:no_encryption_config]
            elsif enc_config[:kms_encryption_config]
              kms_encryption_config do
                aws_kms_key_arn enc_config[:kms_encryption_config][:aws_kms_key_arn]
              end
            end
          end
        end

        def build_cloudwatch_logging(builder, log_config)
          builder.cloudwatch_logging_options do
            enabled log_config[:enabled] if log_config.key?(:enabled)
            log_group_name log_config[:log_group_name] if log_config[:log_group_name]
            log_stream_name log_config[:log_stream_name] if log_config[:log_stream_name]
          end
        end

        def build_extended_s3_configuration(builder, es3_config)
          builder.extended_s3_configuration do
            role_arn es3_config[:role_arn]
            bucket_arn es3_config[:bucket_arn]
            prefix es3_config[:prefix] if es3_config[:prefix]
            error_output_prefix es3_config[:error_output_prefix] if es3_config[:error_output_prefix]
            buffer_size es3_config[:buffer_size] if es3_config[:buffer_size]
            buffer_interval es3_config[:buffer_interval] if es3_config[:buffer_interval]
            compression_format es3_config[:compression_format] if es3_config[:compression_format]
            s3_backup_mode es3_config[:s3_backup_mode] if es3_config[:s3_backup_mode]

            build_data_format_conversion(self, es3_config[:data_format_conversion_configuration]) if es3_config[:data_format_conversion_configuration]
            build_processing_configuration(self, es3_config[:processing_configuration]) if es3_config[:processing_configuration]
            build_cloudwatch_logging(self, es3_config[:cloudwatch_logging_options]) if es3_config[:cloudwatch_logging_options]
          end
        end

        def build_data_format_conversion(builder, df_config)
          builder.data_format_conversion_configuration do
            enabled df_config[:enabled]

            if df_config[:output_format_configuration]
              output_format_configuration do
                if df_config[:output_format_configuration][:serializer]
                  serializer do
                    ser_config = df_config[:output_format_configuration][:serializer]
                    parquet_ser_de({}) if ser_config[:parquet_ser_de]
                    orc_ser_de({}) if ser_config[:orc_ser_de]
                  end
                end
              end
            end

            build_schema_configuration(self, df_config[:schema_configuration]) if df_config[:schema_configuration]
          end
        end

        def build_schema_configuration(builder, schema_config)
          builder.schema_configuration do
            database_name schema_config[:database_name]
            table_name schema_config[:table_name]
            role_arn schema_config[:role_arn]
            region schema_config[:region] if schema_config[:region]
            catalog_id schema_config[:catalog_id] if schema_config[:catalog_id]
            version_id schema_config[:version_id] if schema_config[:version_id]
          end
        end

        def build_processing_configuration(builder, proc_config)
          builder.processing_configuration do
            enabled proc_config[:enabled]

            proc_config[:processors]&.each do |processor|
              processors do
                type processor[:type]
                processor[:parameters]&.each do |param|
                  parameters do
                    parameter_name param[:parameter_name]
                    parameter_value param[:parameter_value]
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
