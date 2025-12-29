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

require 'json'

module Pangea
  module Components
    module SiemSecurityPlatform
      # Ingestion resources: Firehose streams, log subscriptions
      module Ingestion
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

        def create_firehose_role(role_name, attrs, resources)
          role = aws_iam_role(role_name, {
            name: role_name.to_s,
            assume_role_policy: firehose_assume_role_policy,
            tags: component_tags('siem_security_platform', role_name, attrs.tags)
          })

          aws_iam_role_policy(:"#{role_name}_policy", {
            role: role.id,
            policy: firehose_role_policy(resources)
          })

          role
        end

        def firehose_assume_role_policy
          JSON.pretty_generate({
            Version: "2012-10-17",
            Statement: [{
              Action: "sts:AssumeRole",
              Effect: "Allow",
              Principal: { Service: "firehose.amazonaws.com" }
            }]
          })
        end

        def firehose_role_policy(resources)
          JSON.pretty_generate({
            Version: "2012-10-17",
            Statement: [
              { Effect: "Allow", Action: %w[es:ESHttpPost es:ESHttpPut],
                Resource: [resources[:opensearch_domain].arn, "#{resources[:opensearch_domain].arn}/*"] },
              { Effect: "Allow", Action: %w[s3:GetObject s3:PutObject],
                Resource: "#{resources[:s3_buckets][:backup].arn}/*" },
              { Effect: "Allow", Action: %w[kms:Decrypt kms:GenerateDataKey],
                Resource: resources[:kms_keys][:main].arn },
              { Effect: "Allow", Action: %w[logs:CreateLogGroup logs:CreateLogStream logs:PutLogEvents],
                Resource: "*" },
              { Effect: "Allow", Action: ["lambda:InvokeFunction"],
                Resource: "arn:aws:lambda:*:*:function:siem-*" }
            ]
          })
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

        def create_logs_role(name, source_name, attrs, resources)
          role_name = component_resource_name(name, :logs_role, source_name)
          role = aws_iam_role(role_name, {
            name: role_name.to_s,
            assume_role_policy: logs_assume_role_policy,
            tags: component_tags('siem_security_platform', name, attrs.tags)
          })

          aws_iam_role_policy(:"#{role_name}_policy", {
            role: role.id,
            policy: logs_role_policy(resources, source_name)
          })

          role.arn
        end

        def logs_assume_role_policy
          JSON.pretty_generate({
            Version: "2012-10-17",
            Statement: [{
              Action: "sts:AssumeRole",
              Effect: "Allow",
              Principal: { Service: "logs.amazonaws.com" }
            }]
          })
        end

        def logs_role_policy(resources, source_name)
          JSON.pretty_generate({
            Version: "2012-10-17",
            Statement: [{
              Effect: "Allow",
              Action: %w[firehose:PutRecord firehose:PutRecordBatch],
              Resource: resources[:firehose_streams][source_name].arn
            }]
          })
        end
      end
    end
  end
end
