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
      module Types
        class KinesisAnalyticsApplicationAttributes
          # SQL Application Configuration types for Kinesis Analytics
          module SqlConfigs
            SQL_TYPES = %w[BOOLEAN INTEGER BIGINT DOUBLE DECIMAL VARCHAR CHAR TIMESTAMP DATE TIME].freeze

            RecordColumn = Hash.schema(
              name: String.constrained(min_size: 1, max_size: 256),
              sql_type: String.enum(*SQL_TYPES),
              mapping?: String.optional
            )

            JsonMappingParameters = Hash.schema(
              record_row_path: String
            )

            CsvMappingParameters = Hash.schema(
              record_row_delimiter: String.constrained(min_size: 1, max_size: 1024),
              record_column_delimiter: String.constrained(min_size: 1, max_size: 1024)
            )

            MappingParameters = Hash.schema(
              json_mapping_parameters?: JsonMappingParameters.optional,
              csv_mapping_parameters?: CsvMappingParameters.optional
            )

            RecordFormat = Hash.schema(
              record_format_type: String.enum('JSON', 'CSV'),
              mapping_parameters?: MappingParameters.optional
            )

            InputSchema = Hash.schema(
              record_columns: Array.of(RecordColumn).constrained(min_size: 1, max_size: 1000),
              record_format: RecordFormat,
              record_encoding?: String.enum('UTF-8').optional
            )

            KinesisStreamsInput = Hash.schema(resource_arn: String)
            KinesisFirehoseInput = Hash.schema(resource_arn: String)

            InputConfig = Hash.schema(
              name_prefix: String.constrained(min_size: 1, max_size: 32),
              input_parallelism?: Hash.schema(count?: Integer.constrained(gteq: 1, lteq: 64).optional).optional,
              input_schema: InputSchema,
              kinesis_streams_input?: KinesisStreamsInput.optional,
              kinesis_firehose_input?: KinesisFirehoseInput.optional
            )

            DestinationSchema = Hash.schema(
              record_format_type: String.enum('JSON', 'CSV')
            )

            OutputConfig = Hash.schema(
              name: String.constrained(min_size: 1, max_size: 32),
              destination_schema: DestinationSchema,
              kinesis_streams_output?: Hash.schema(resource_arn: String).optional,
              kinesis_firehose_output?: Hash.schema(resource_arn: String).optional,
              lambda_output?: Hash.schema(resource_arn: String).optional
            )

            ReferenceRecordColumn = Hash.schema(
              name: String,
              sql_type: String,
              mapping?: String.optional
            )

            ReferenceRecordFormat = Hash.schema(
              record_format_type: String.enum('JSON', 'CSV'),
              mapping_parameters?: Hash.optional
            )

            ReferenceSchema = Hash.schema(
              record_columns: Array.of(ReferenceRecordColumn),
              record_format: ReferenceRecordFormat,
              record_encoding?: String.enum('UTF-8').optional
            )

            ReferenceDataSource = Hash.schema(
              table_name: String.constrained(min_size: 1, max_size: 32),
              reference_schema: ReferenceSchema,
              s3_reference_data_source?: Hash.schema(bucket_arn: String, file_key: String).optional
            )

            SqlApplicationConfiguration = Hash.schema(
              inputs?: Array.of(InputConfig).optional,
              outputs?: Array.of(OutputConfig).optional,
              reference_data_sources?: Array.of(ReferenceDataSource).optional
            )
          end
        end
      end
    end
  end
end
