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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_cur_report_definition/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      def aws_cur_report_definition(name, attributes = {})
        cur_attrs = Types::CurReportDefinitionAttributes.new(attributes)
        
        resource(:aws_cur_report_definition, name) do
          report_name cur_attrs.report_name
          time_unit cur_attrs.time_unit
          format cur_attrs.format
          compression cur_attrs.compression
          s3_bucket cur_attrs.s3_bucket
          s3_prefix cur_attrs.s3_prefix if cur_attrs.s3_prefix
          s3_region cur_attrs.s3_region
          additional_schema_elements cur_attrs.additional_schema_elements if cur_attrs.additional_schema_elements
          additional_artifacts cur_attrs.additional_artifacts if cur_attrs.additional_artifacts
          refresh_closed_reports cur_attrs.refresh_closed_reports if cur_attrs.refresh_closed_reports
          report_versioning cur_attrs.report_versioning if cur_attrs.report_versioning
        end
        
        ResourceReference.new(
          type: 'aws_cur_report_definition',
          name: name,
          resource_attributes: cur_attrs.to_h,
          outputs: {
            arn: "${aws_cur_report_definition.#{name}.arn}",
            report_name: "${aws_cur_report_definition.#{name}.report_name}",
            s3_bucket: "${aws_cur_report_definition.#{name}.s3_bucket}",
            s3_prefix: "${aws_cur_report_definition.#{name}.s3_prefix}",
            is_hourly: cur_attrs.is_hourly?,
            has_additional_artifacts: cur_attrs.has_additional_artifacts?,
            supports_athena: cur_attrs.supports_athena?,
            estimated_monthly_size_gb: cur_attrs.estimated_monthly_size_gb
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)