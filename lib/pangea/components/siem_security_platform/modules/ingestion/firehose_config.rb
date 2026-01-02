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
  module Components
    module SiemSecurityPlatform
      module Ingestion
        # Configuration builders for Firehose delivery streams
        module FirehoseConfig
          def build_firehose_config(name, source, attrs, resources, processor_arn)
            {
              name: "siem-#{name}-#{source[:name]}",
              destination: "opensearch",
              opensearch_configuration: build_opensearch_config(name, source, attrs, resources, processor_arn),
              tags: component_tags('siem_security_platform', name, attrs.tags.merge(LogSource: source[:name]))
            }
          end

          def build_opensearch_config(name, source, attrs, resources, processor_arn)
            {
              domain_arn: resources[:opensearch_domain].arn,
              index_name: "siem-#{source[:type]}",
              index_rotation_period: "OneDay",
              type_name: "_doc",
              role_arn: resources[:iam_roles][:"firehose_#{source[:name]}"].arn,
              buffering_hints: {
                interval_in_seconds: attrs.firehose_config[:buffer_interval],
                size_in_mbs: attrs.firehose_config[:buffer_size]
              },
              cloudwatch_logging_options: {
                enabled: true,
                log_group_name: "/aws/kinesisfirehose/siem-#{name}",
                log_stream_name: source[:name]
              },
              processing_configuration: processor_arn ? build_processing_config(processor_arn) : nil,
              s3_configuration: build_s3_config(source, attrs, resources),
              vpc_config: build_vpc_config(attrs, resources, source)
            }
          end

          def build_processing_config(processor_arn)
            {
              enabled: true,
              processors: [{
                type: "Lambda",
                parameters: [{ parameter_name: "LambdaArn", parameter_value: processor_arn }]
              }]
            }
          end

          def build_s3_config(source, attrs, resources)
            {
              bucket_arn: resources[:s3_buckets][:backup].arn,
              prefix: "#{source[:type]}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/",
              error_output_prefix: "#{attrs.firehose_config[:error_output_prefix]}#{source[:type]}/",
              compression_format: attrs.firehose_config[:compression_format],
              role_arn: resources[:iam_roles][:"firehose_#{source[:name]}"].arn
            }
          end

          def build_vpc_config(attrs, resources, source)
            {
              subnet_ids: attrs.subnet_refs,
              security_group_ids: [resources[:security_groups][:opensearch].id],
              role_arn: resources[:iam_roles][:"firehose_#{source[:name]}"].arn
            }
          end
        end
      end
    end
  end
end
