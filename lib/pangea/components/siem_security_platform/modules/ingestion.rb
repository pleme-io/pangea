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

require_relative 'ingestion/iam_policies'
require_relative 'ingestion/firehose_config'

module Pangea
  module Components
    module SiemSecurityPlatform
      # Ingestion resources: Firehose streams, log subscriptions
      module Ingestion
        include IamPolicies
        include FirehoseConfig

        def create_ingestion_resources(name, attrs, resources)
          attrs.log_sources.each do |source|
            create_firehose_stream(name, source, attrs, resources)
          end
        end

        private

        def create_firehose_stream(name, source, attrs, resources)
          stream_name = component_resource_name(name, :firehose, source[:name])
          role_name = component_resource_name(name, :firehose_role, source[:name])

          resources[:iam_roles][:"firehose_#{source[:name]}"] = create_firehose_role(
            role_name, attrs, resources
          )

          processor_arn = nil
          if attrs.firehose_config[:enable_data_transformation] || source[:transformation]
            processor_arn = create_stream_processor(name, source, attrs, resources)
          end

          resources[:firehose_streams][source[:name]] = aws_kinesis_firehose_delivery_stream(
            stream_name,
            build_firehose_config(name, source, attrs, resources, processor_arn)
          )

          configure_log_source_subscription(name, source, attrs, resources)
        end

        def configure_log_source_subscription(name, source, attrs, resources)
          case source[:type]
          when 'cloudwatch'
            configure_cloudwatch_subscription(name, source, attrs, resources) if source[:log_group_name]
          when 's3_access'
            configure_s3_logging(name, source, resources) if source[:s3_bucket]
          end
        end

        def configure_cloudwatch_subscription(name, source, attrs, resources)
          aws_cloudwatch_log_subscription_filter(:"#{name}_#{source[:name]}_subscription", {
            name: "siem-#{name}-#{source[:name]}",
            log_group_name: source[:log_group_name],
            filter_pattern: "",
            destination_arn: resources[:firehose_streams][source[:name]].arn,
            role_arn: create_logs_role(name, source[:name], attrs, resources)
          })
        end

        def configure_s3_logging(name, source, resources)
          aws_s3_bucket_logging(:"#{name}_#{source[:name]}_logging", {
            bucket: source[:s3_bucket],
            target_bucket: resources[:s3_buckets][:backup].id,
            target_prefix: "s3-access-logs/#{source[:s3_bucket]}/"
          })
        end
      end
    end
  end
end
