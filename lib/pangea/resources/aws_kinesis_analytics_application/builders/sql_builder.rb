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
      module KinesisAnalyticsApplication
        module Builders
          # Builds the sql_application_configuration block for Kinesis Analytics
          module SqlBuilder
            extend self

            # Build the SQL application configuration block
            # @param context [Object] The DSL context for building Terraform blocks
            # @param sql_config [Hash] The SQL configuration hash
            def build(context, sql_config)
              return unless sql_config

              context.sql_application_configuration do
                build_inputs(self, sql_config[:inputs])
                build_outputs(self, sql_config[:outputs])
                build_reference_data_sources(self, sql_config[:reference_data_sources])
              end
            end

            private

            def build_inputs(context, inputs)
              return unless inputs

              inputs.each do |input_config|
                context.input do
                  name_prefix input_config[:name_prefix]
                  build_input_parallelism(self, input_config[:input_parallelism])
                  build_input_schema(self, input_config[:input_schema])
                  build_kinesis_input_sources(self, input_config)
                end
              end
            end

            def build_input_parallelism(context, parallelism)
              return unless parallelism

              context.input_parallelism do
                count parallelism[:count] if parallelism[:count]
              end
            end

            def build_input_schema(context, schema_config)
              context.input_schema do
                record_encoding schema_config[:record_encoding] if schema_config[:record_encoding]
                build_record_columns(self, schema_config[:record_columns])
                build_record_format(self, schema_config[:record_format])
              end
            end

            def build_kinesis_input_sources(context, input_config)
              if input_config[:kinesis_streams_input]
                context.kinesis_streams_input do
                  resource_arn input_config[:kinesis_streams_input][:resource_arn]
                end
              end

              return unless input_config[:kinesis_firehose_input]

              context.kinesis_firehose_input do
                resource_arn input_config[:kinesis_firehose_input][:resource_arn]
              end
            end

            def build_outputs(context, outputs)
              return unless outputs

              outputs.each do |output_config|
                context.output do
                  name output_config[:name]
                  build_destination_schema(self, output_config[:destination_schema])
                  build_output_destinations(self, output_config)
                end
              end
            end

            def build_destination_schema(context, schema)
              context.destination_schema do
                record_format_type schema[:record_format_type]
              end
            end

            def build_output_destinations(context, output_config)
              if output_config[:kinesis_streams_output]
                context.kinesis_streams_output do
                  resource_arn output_config[:kinesis_streams_output][:resource_arn]
                end
              end

              if output_config[:kinesis_firehose_output]
                context.kinesis_firehose_output do
                  resource_arn output_config[:kinesis_firehose_output][:resource_arn]
                end
              end

              return unless output_config[:lambda_output]

              context.lambda_output do
                resource_arn output_config[:lambda_output][:resource_arn]
              end
            end

            def build_reference_data_sources(context, ref_sources)
              return unless ref_sources

              ref_sources.each do |ref_source|
                context.reference_data_source do
                  table_name ref_source[:table_name]
                  build_reference_schema(self, ref_source[:reference_schema])
                  build_s3_reference_source(self, ref_source[:s3_reference_data_source])
                end
              end
            end

            def build_reference_schema(context, schema_config)
              context.reference_schema do
                record_encoding schema_config[:record_encoding] if schema_config[:record_encoding]
                build_record_columns(self, schema_config[:record_columns])
                build_record_format(self, schema_config[:record_format])
              end
            end

            def build_s3_reference_source(context, s3_source)
              return unless s3_source

              context.s3_reference_data_source do
                bucket_arn s3_source[:bucket_arn]
                file_key s3_source[:file_key]
              end
            end

            def build_record_columns(context, columns)
              columns.each do |column|
                context.record_column do
                  name column[:name]
                  sql_type column[:sql_type]
                  mapping column[:mapping] if column[:mapping]
                end
              end
            end

            def build_record_format(context, format_config)
              context.record_format do
                record_format_type format_config[:record_format_type]
                build_mapping_parameters(self, format_config[:mapping_parameters])
              end
            end

            def build_mapping_parameters(context, mapping_params)
              return unless mapping_params

              context.mapping_parameters do
                build_json_mapping(self, mapping_params[:json_mapping_parameters])
                build_csv_mapping(self, mapping_params[:csv_mapping_parameters])
              end
            end

            def build_json_mapping(context, json_params)
              return unless json_params

              context.json_mapping_parameters do
                record_row_path json_params[:record_row_path]
              end
            end

            def build_csv_mapping(context, csv_params)
              return unless csv_params

              context.csv_mapping_parameters do
                record_row_delimiter csv_params[:record_row_delimiter]
                record_column_delimiter csv_params[:record_column_delimiter]
              end
            end
          end
        end
      end
    end
  end
end
