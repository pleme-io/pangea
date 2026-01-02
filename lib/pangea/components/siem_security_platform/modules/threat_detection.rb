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
      # Threat detection resources: DynamoDB, threat intel feeds
      module ThreatDetection
        def create_threat_detection_resources(name, attrs, resources)
          create_threat_intel_infrastructure(name, attrs, resources)
        end

        private

        def create_threat_intel_infrastructure(name, attrs, resources)
          feeds = attrs.threat_detection[:threat_intel_feeds]
          return unless feeds&.any?

          create_threat_intel_table(name, attrs, resources)
          create_threat_intel_updater(name, attrs, resources)
          schedule_threat_intel_updates(name, feeds, attrs, resources)
        end

        def create_threat_intel_table(name, attrs, resources)
          table_name = component_resource_name(name, :threat_intel_table)
          resources[:dynamodb_tables] ||= {}
          resources[:dynamodb_tables][:threat_intel] = aws_dynamodb_table(table_name, {
            name: "siem-threat-intel-#{name}",
            billing_mode: "PAY_PER_REQUEST",
            attribute: [
              { name: "indicator", type: "S" },
              { name: "indicator_type", type: "S" }
            ],
            hash_key: "indicator",
            range_key: "indicator_type",
            global_secondary_index: [{
              name: "TypeIndex",
              hash_key: "indicator_type",
              projection_type: "ALL"
            }],
            point_in_time_recovery: { enabled: true },
            server_side_encryption: {
              enabled: true,
              kms_key_id: resources[:kms_keys][:main].id
            },
            tags: component_tags('siem_security_platform', name, attrs.tags)
          })
        end

        def create_threat_intel_updater(name, attrs, resources)
          lambda_name = component_resource_name(name, :threat_intel_updater)
          resources[:lambda_functions][:threat_intel_updater] = aws_lambda_function(lambda_name, {
            function_name: "siem-threat-intel-updater-#{name}",
            runtime: "python3.11",
            handler: "index.lambda_handler",
            role: create_lambda_execution_role(name, "threat-intel-updater", attrs, resources),
            timeout: 900,
            memory_size: 1024,
            environment: {
              variables: {
                THREAT_INTEL_TABLE: resources[:dynamodb_tables][:threat_intel].name,
                THREAT_FEEDS: JSON.generate(attrs.threat_detection[:threat_intel_feeds])
              }
            },
            code: { zip_file: generate_threat_intel_updater_code },
            tags: component_tags('siem_security_platform', name, attrs.tags)
          })
        end

        def schedule_threat_intel_updates(name, feeds, attrs, resources)
          feeds.each do |feed|
            rule_name = component_resource_name(name, :threat_intel_rule, feed[:name])
            rule = aws_cloudwatch_event_rule(rule_name, {
              name: "siem-threat-intel-#{name}-#{feed[:name]}",
              description: "Update threat intelligence feed: #{feed[:name]}",
              schedule_expression: "rate(#{feed[:update_frequency] / 60} minutes)",
              tags: component_tags('siem_security_platform', name, attrs.tags)
            })

            aws_cloudwatch_event_target(:"#{rule_name}_target", {
              rule: rule.name,
              arn: resources[:lambda_functions][:threat_intel_updater].arn,
              input: JSON.generate({ feed: feed })
            })

            resources[:event_rules][:"threat_intel_#{feed[:name]}"] = rule
          end
        end

        def generate_threat_intel_updater_code
          <<~PYTHON
            import json
            import boto3
            import os
            from datetime import datetime

            dynamodb = boto3.resource('dynamodb')

            def lambda_handler(event, context):
                table = dynamodb.Table(os.environ['THREAT_INTEL_TABLE'])
                feed = event.get('feed', {})
                indicators = fetch_threat_feed(feed)
                with table.batch_writer() as batch:
                    for indicator in indicators:
                        batch.put_item(Item={
                            'indicator': indicator['value'],
                            'indicator_type': indicator['type'],
                            'severity': indicator.get('severity', 'medium'),
                            'source': feed['name'],
                            'last_seen': datetime.utcnow().isoformat()
                        })
                return {'statusCode': 200, 'body': json.dumps({'indicators': len(indicators)})}

            def fetch_threat_feed(feed):
                return []
          PYTHON
        end
      end
    end
  end
end
