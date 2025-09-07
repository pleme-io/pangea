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


require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # CUR report time units
        CurTimeUnit = String.enum('HOURLY', 'DAILY', 'MONTHLY')
        
        # CUR report formats
        CurFormat = String.enum('textORcsv', 'Parquet', 'ORC')
        
        # CUR compression types
        CurCompression = String.enum('ZIP', 'GZIP', 'Parquet')
        
        # CUR versioning
        CurVersioning = String.enum('CREATE_NEW_REPORT', 'OVERWRITE_REPORT')
        
        # Additional schema elements
        CurSchemaElement = String.enum(
          'RESOURCES', 'SPLIT_COST_ALLOCATION_DATA', 'MANUAL_DISCOUNT_COMPATIBILITY'
        )
        
        class CurReportDefinitionAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :report_name, String.constrained(format: /\A[a-zA-Z0-9_\-\.]{1,256}\z/)
          attribute :time_unit, CurTimeUnit
          attribute :format, CurFormat
          attribute :compression, CurCompression
          attribute :s3_bucket, String.constrained(format: /\A[a-z0-9][a-z0-9\-\.]{1,61}[a-z0-9]\z/)
          attribute :s3_prefix?, String.constrained(max_size: 256).optional
          attribute :s3_region, AwsRegion
          attribute :additional_schema_elements?, Array.of(CurSchemaElement).optional
          attribute :additional_artifacts?, Array.of(String.enum('REDSHIFT', 'QUICKSIGHT', 'ATHENA')).optional
          attribute :refresh_closed_reports?, Bool.default(true).optional
          attribute :report_versioning?, CurVersioning.default('CREATE_NEW_REPORT').optional
          attribute :tags?, AwsTags.optional
          
          def is_hourly?
            time_unit == 'HOURLY'
          end
          
          def has_additional_artifacts?
            additional_artifacts && !additional_artifacts.empty?
          end
          
          def supports_athena?
            additional_artifacts&.include?('ATHENA')
          end
          
          def estimated_monthly_size_gb
            case time_unit
            when 'HOURLY' then 50
            when 'DAILY' then 25
            when 'MONTHLY' then 10
            end
          end
        end
      end
    end
  end
end