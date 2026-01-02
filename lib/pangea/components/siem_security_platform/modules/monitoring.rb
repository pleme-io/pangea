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
      # Monitoring resources: CloudWatch alarms, dashboards
      module Monitoring
        def create_monitoring_resources(name, attrs, resources)
          create_siem_alarms(name, attrs, resources)
          create_dashboards(name, attrs, resources)
        end

        private

        def create_siem_alarms(name, attrs, resources)
          create_opensearch_alarms(name, attrs, resources)
          create_firehose_alarms(name, attrs, resources)
          create_lambda_alarms(name, attrs, resources)
        end

        def create_opensearch_alarms(name, attrs, resources)
          alarm_name = component_resource_name(name, :opensearch_cluster_alarm)
          resources[:alarms][:opensearch_cluster] = aws_cloudwatch_metric_alarm(alarm_name, {
            alarm_name: "siem-opensearch-cluster-#{name}",
            comparison_operator: "LessThanThreshold",
            evaluation_periods: 3,
            metric_name: "ClusterStatus.green",
            namespace: "AWS/ES",
            period: 60,
            statistic: "Minimum",
            threshold: 1,
            alarm_description: "OpenSearch cluster health is not green",
            alarm_actions: [resources[:sns_topics][:alerts]&.arn].compact,
            dimensions: { DomainName: attrs.opensearch_config[:domain_name] },
            tags: component_tags('siem_security_platform', name, attrs.tags)
          })

          storage_alarm_name = component_resource_name(name, :opensearch_storage_alarm)
          resources[:alarms][:opensearch_storage] = aws_cloudwatch_metric_alarm(storage_alarm_name, {
            alarm_name: "siem-opensearch-storage-#{name}",
            comparison_operator: "LessThanThreshold",
            evaluation_periods: 1,
            metric_name: "FreeStorageSpace",
            namespace: "AWS/ES",
            period: 300,
            statistic: "Minimum",
            threshold: attrs.monitoring_config[:storage_threshold_gb] * 1024,
            alarm_description: "OpenSearch storage is running low",
            alarm_actions: [resources[:sns_topics][:alerts]&.arn].compact,
            dimensions: { DomainName: attrs.opensearch_config[:domain_name] },
            tags: component_tags('siem_security_platform', name, attrs.tags)
          })
        end

        def create_firehose_alarms(name, attrs, resources)
          resources[:firehose_streams].each do |stream_name, stream|
            alarm_name = component_resource_name(name, :firehose_alarm, stream_name)
            resources[:alarms][:"firehose_#{stream_name}"] = aws_cloudwatch_metric_alarm(alarm_name, {
              alarm_name: "siem-firehose-errors-#{name}-#{stream_name}",
              comparison_operator: "GreaterThanThreshold",
              evaluation_periods: 3,
              metric_name: "DeliveryToOpenSearch.Errors",
              namespace: "AWS/Firehose",
              period: 300,
              statistic: "Sum",
              threshold: attrs.monitoring_config[:firehose_error_threshold],
              alarm_description: "Firehose delivery errors detected",
              alarm_actions: [resources[:sns_topics][:alerts]&.arn].compact,
              dimensions: { DeliveryStreamName: "siem-#{name}-#{stream_name}" },
              tags: component_tags('siem_security_platform', name, attrs.tags)
            })
          end
        end

        def create_lambda_alarms(name, attrs, resources)
          resources[:lambda_functions].each do |function_name, function|
            alarm_name = component_resource_name(name, :lambda_alarm, function_name)
            resources[:alarms][:"lambda_#{function_name}"] = aws_cloudwatch_metric_alarm(alarm_name, {
              alarm_name: "siem-lambda-errors-#{name}-#{function_name}",
              comparison_operator: "GreaterThanThreshold",
              evaluation_periods: 3,
              metric_name: "Errors",
              namespace: "AWS/Lambda",
              period: 300,
              statistic: "Sum",
              threshold: attrs.monitoring_config[:lambda_error_threshold],
              alarm_description: "Lambda function errors detected",
              alarm_actions: [resources[:sns_topics][:alerts]&.arn].compact,
              dimensions: { FunctionName: function.function_name },
              tags: component_tags('siem_security_platform', name, attrs.tags)
            })
          end
        end

        def create_dashboards(name, attrs, resources)
          return unless attrs.dashboards[:enabled]

          dashboard_lambda = component_resource_name(name, :dashboard_config)
          resources[:lambda_functions][:dashboard_config] = aws_lambda_function(dashboard_lambda, {
            function_name: "siem-dashboard-config-#{name}",
            runtime: "python3.11",
            handler: "index.lambda_handler",
            role: create_lambda_execution_role(name, "dashboard-config", attrs, resources),
            timeout: 300,
            environment: {
              variables: {
                OPENSEARCH_ENDPOINT: resources[:opensearch_domain].endpoint,
                DASHBOARD_CONFIG: JSON.generate(attrs.dashboards)
              }
            },
            code: { zip_file: dashboard_code },
            tags: component_tags('siem_security_platform', name, attrs.tags)
          })
        end

        def dashboard_code
          <<~PYTHON
            import json
            import os
            from opensearchpy import OpenSearch

            def lambda_handler(event, context):
                es = OpenSearch(
                    hosts=[{'host': os.environ['OPENSEARCH_ENDPOINT'], 'port': 443}],
                    use_ssl=True, verify_certs=True
                )
                config = json.loads(os.environ['DASHBOARD_CONFIG'])
                for dashboard in config.get('dashboards', []):
                    create_dashboard(es, dashboard)
                return {'statusCode': 200, 'body': 'Dashboards configured'}

            def create_dashboard(es, dashboard):
                pass
          PYTHON
        end
      end
    end
  end
end
