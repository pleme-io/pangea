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
require_relative 'processing/code_generators'

module Pangea
  module Components
    module SiemSecurityPlatform
      # Processing resources: Lambda functions for data transformation
      module Processing
        include CodeGenerators

        def create_processing_resources(name, attrs, resources)
          create_processing_lambdas(name, attrs, resources)
        end

        private

        def create_stream_processor(name, source, attrs, resources)
          processor_name = component_resource_name(name, :processor, source[:name])

          lambda_function = aws_lambda_function(processor_name, {
            function_name: "siem-processor-#{name}-#{source[:name]}",
            runtime: "python3.11",
            handler: "index.lambda_handler",
            role: create_lambda_execution_role(name, "processor-#{source[:name]}", attrs, resources),
            timeout: 300,
            memory_size: 512,
            environment: { variables: processor_env_vars(source, resources) },
            code: { zip_file: generate_processor_code(source) },
            tags: component_tags('siem_security_platform', name, attrs.tags)
          })

          resources[:lambda_functions][:"processor_#{source[:name]}"] = lambda_function
          lambda_function.arn
        end

        def processor_env_vars(source, resources)
          {
            LOG_SOURCE_TYPE: source[:type],
            LOG_FORMAT: source[:format],
            ENABLE_ENRICHMENT: source[:enrichment].to_s,
            THREAT_INTEL_TABLE: resources[:dynamodb_tables]&.dig(:threat_intel)&.name || ""
          }
        end

        def create_processing_lambdas(name, attrs, resources)
          create_correlation_lambda(name, attrs, resources)
          create_ml_detection_lambda(name, attrs, resources) if attrs.threat_detection[:enable_ml_detection]
        end

        def create_correlation_lambda(name, attrs, resources)
          lambda_name = component_resource_name(name, :correlation_lambda)
          resources[:lambda_functions][:correlation] = aws_lambda_function(lambda_name, {
            function_name: "siem-correlation-#{name}",
            runtime: "python3.11",
            handler: "index.lambda_handler",
            role: create_lambda_execution_role(name, "correlation", attrs, resources),
            timeout: 900,
            memory_size: 3008,
            environment: {
              variables: {
                OPENSEARCH_ENDPOINT: resources[:opensearch_domain].endpoint,
                CORRELATION_RULES: JSON.generate(attrs.correlation_rules),
                SNS_TOPIC_ARN: create_alert_topic(name, attrs, resources)
              }
            },
            code: { zip_file: generate_correlation_engine_code },
            tags: component_tags('siem_security_platform', name, attrs.tags)
          })
        end

        def create_ml_detection_lambda(name, attrs, resources)
          lambda_name = component_resource_name(name, :ml_detection_lambda)
          resources[:lambda_functions][:ml_detection] = aws_lambda_function(lambda_name, {
            function_name: "siem-ml-detection-#{name}",
            runtime: "python3.11",
            handler: "index.lambda_handler",
            role: create_lambda_execution_role(name, "ml-detection", attrs, resources),
            timeout: 900,
            memory_size: 3008,
            environment: {
              variables: {
                OPENSEARCH_ENDPOINT: resources[:opensearch_domain].endpoint,
                ANOMALY_DETECTORS: JSON.generate(attrs.threat_detection[:anomaly_detectors]),
                ENABLE_BEHAVIOR_ANALYTICS: attrs.threat_detection[:enable_behavior_analytics].to_s
              }
            },
            code: { zip_file: generate_ml_detection_code },
            tags: component_tags('siem_security_platform', name, attrs.tags)
          })
        end

        def create_lambda_execution_role(name, function_type, attrs, resources)
          role_name = component_resource_name(name, :lambda_role, function_type)
          role = aws_iam_role(role_name, {
            name: role_name.to_s,
            assume_role_policy: lambda_assume_role_policy,
            tags: component_tags('siem_security_platform', name, attrs.tags)
          })

          attach_lambda_policies(role_name, role)
          create_lambda_custom_policy(role_name, role, resources)

          resources[:iam_roles][function_type.to_sym] = role
          role.arn
        end

        def lambda_assume_role_policy
          JSON.pretty_generate({
            Version: "2012-10-17",
            Statement: [{
              Action: "sts:AssumeRole",
              Effect: "Allow",
              Principal: { Service: "lambda.amazonaws.com" }
            }]
          })
        end

        def attach_lambda_policies(role_name, role)
          aws_iam_role_policy_attachment(:"#{role_name}_basic", {
            role: role.name,
            policy_arn: "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
          })

          aws_iam_role_policy_attachment(:"#{role_name}_vpc", {
            role: role.name,
            policy_arn: "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
          })
        end

        def create_lambda_custom_policy(role_name, role, resources)
          aws_iam_role_policy(:"#{role_name}_custom", {
            role: role.id,
            policy: lambda_custom_policy(resources)
          })
        end

        def lambda_custom_policy(resources)
          JSON.pretty_generate({
            Version: "2012-10-17",
            Statement: [
              { Effect: "Allow", Action: %w[es:ESHttpPost es:ESHttpGet],
                Resource: "#{resources[:opensearch_domain].arn}/*" },
              { Effect: "Allow", Action: %w[dynamodb:GetItem dynamodb:Query dynamodb:Scan],
                Resource: "arn:aws:dynamodb:*:*:table/siem-*" },
              { Effect: "Allow", Action: ["kms:Decrypt"], Resource: resources[:kms_keys][:main].arn },
              { Effect: "Allow", Action: ["sns:Publish"], Resource: "arn:aws:sns:*:*:siem-*" }
            ]
          })
        end

        def create_alert_topic(name, attrs, resources)
          return resources[:sns_topics][:alerts].arn if resources[:sns_topics][:alerts]

          topic_name = component_resource_name(name, :alert_topic)
          topic = aws_sns_topic(topic_name, {
            name: "siem-alerts-#{name}",
            kms_master_key_id: resources[:kms_keys][:main].id,
            tags: component_tags('siem_security_platform', name, attrs.tags)
          })
          resources[:sns_topics][:alerts] = topic
          topic.arn
        end
      end
    end
  end
end
