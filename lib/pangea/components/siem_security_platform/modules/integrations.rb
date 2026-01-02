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
      # External integrations: SOAR, threat intel, notifications
      module Integrations
        def create_integration_resources(name, attrs, resources)
          attrs.integrations.each do |integration|
            create_integration(name, integration, attrs, resources)
          end
        end

        private

        def create_integration(name, integration, attrs, resources)
          case integration[:type]
          when 'soar'
            create_soar_integration(name, integration, attrs, resources)
          when 'threat_intel'
            create_threat_intel_integration(name, integration, attrs, resources)
          when 'notification'
            create_notification_integration(name, integration, attrs, resources)
          end
        end

        def create_soar_integration(name, integration, attrs, resources)
          lambda_name = component_resource_name(name, :soar_integration, integration[:name])
          resources[:lambda_functions][:"soar_#{integration[:name]}"] = aws_lambda_function(lambda_name, {
            function_name: "siem-soar-#{name}-#{integration[:name]}",
            runtime: "python3.11",
            handler: "index.lambda_handler",
            role: create_lambda_execution_role(name, "soar-#{integration[:name]}", attrs, resources),
            timeout: 60,
            environment: {
              variables: {
                SOAR_ENDPOINT: integration[:endpoint],
                SOAR_API_KEY_SECRET: integration[:api_key_secret]
              }
            },
            code: { zip_file: soar_code },
            tags: component_tags('siem_security_platform', name, attrs.tags)
          })
        end

        def create_threat_intel_integration(name, integration, attrs, resources)
          # Threat intel integrations are handled by ThreatDetection module
        end

        def create_notification_integration(name, integration, attrs, resources)
          case integration[:channel]
          when 'slack'
            create_slack_integration(name, integration, attrs, resources)
          when 'pagerduty'
            create_pagerduty_integration(name, integration, attrs, resources)
          end
        end

        def create_slack_integration(name, integration, attrs, resources)
          lambda_name = component_resource_name(name, :slack_notifier, integration[:name])
          resources[:lambda_functions][:"slack_#{integration[:name]}"] = aws_lambda_function(lambda_name, {
            function_name: "siem-slack-#{name}-#{integration[:name]}",
            runtime: "python3.11",
            handler: "index.lambda_handler",
            role: create_lambda_execution_role(name, "slack-#{integration[:name]}", attrs, resources),
            timeout: 30,
            environment: {
              variables: {
                SLACK_WEBHOOK_SECRET: integration[:webhook_secret],
                SLACK_CHANNEL: integration[:channel_id]
              }
            },
            code: { zip_file: slack_code },
            tags: component_tags('siem_security_platform', name, attrs.tags)
          })

          # Subscribe to SNS alerts
          if resources[:sns_topics][:alerts]
            aws_sns_topic_subscription(:"#{lambda_name}_sub", {
              topic_arn: resources[:sns_topics][:alerts].arn,
              protocol: "lambda",
              endpoint: resources[:lambda_functions][:"slack_#{integration[:name]}"].arn
            })
          end
        end

        def create_pagerduty_integration(name, integration, attrs, resources)
          lambda_name = component_resource_name(name, :pagerduty_notifier, integration[:name])
          resources[:lambda_functions][:"pagerduty_#{integration[:name]}"] = aws_lambda_function(lambda_name, {
            function_name: "siem-pagerduty-#{name}-#{integration[:name]}",
            runtime: "python3.11",
            handler: "index.lambda_handler",
            role: create_lambda_execution_role(name, "pagerduty-#{integration[:name]}", attrs, resources),
            timeout: 30,
            environment: {
              variables: { PAGERDUTY_ROUTING_KEY_SECRET: integration[:routing_key_secret] }
            },
            code: { zip_file: pagerduty_code },
            tags: component_tags('siem_security_platform', name, attrs.tags)
          })
        end

        def soar_code
          <<~PYTHON
            import json
            import os
            import boto3
            import urllib3

            http = urllib3.PoolManager()

            def lambda_handler(event, context):
                endpoint = os.environ['SOAR_ENDPOINT']
                sm = boto3.client('secretsmanager')
                api_key = sm.get_secret_value(SecretId=os.environ['SOAR_API_KEY_SECRET'])['SecretString']
                response = http.request('POST', endpoint,
                    body=json.dumps(event),
                    headers={'Content-Type': 'application/json', 'Authorization': f'Bearer {api_key}'})
                return {'statusCode': response.status}
          PYTHON
        end

        def slack_code
          <<~PYTHON
            import json
            import os
            import boto3
            import urllib3

            http = urllib3.PoolManager()

            def lambda_handler(event, context):
                sm = boto3.client('secretsmanager')
                webhook = sm.get_secret_value(SecretId=os.environ['SLACK_WEBHOOK_SECRET'])['SecretString']
                message = event.get('Records', [{}])[0].get('Sns', {}).get('Message', '{}')
                alert = json.loads(message) if isinstance(message, str) else message
                payload = {
                    'channel': os.environ['SLACK_CHANNEL'],
                    'text': f"SIEM Alert: {alert.get('rule_name', 'Unknown')}",
                    'attachments': [{'color': 'danger', 'text': json.dumps(alert, indent=2)}]
                }
                http.request('POST', webhook, body=json.dumps(payload), headers={'Content-Type': 'application/json'})
                return {'statusCode': 200}
          PYTHON
        end

        def pagerduty_code
          <<~PYTHON
            import json
            import os
            import boto3
            import urllib3

            http = urllib3.PoolManager()

            def lambda_handler(event, context):
                sm = boto3.client('secretsmanager')
                routing_key = sm.get_secret_value(SecretId=os.environ['PAGERDUTY_ROUTING_KEY_SECRET'])['SecretString']
                message = event.get('Records', [{}])[0].get('Sns', {}).get('Message', '{}')
                alert = json.loads(message) if isinstance(message, str) else message
                payload = {
                    'routing_key': routing_key,
                    'event_action': 'trigger',
                    'payload': {
                        'summary': f"SIEM Alert: {alert.get('rule_name', 'Unknown')}",
                        'severity': alert.get('severity', 'warning'),
                        'source': 'siem'
                    }
                }
                http.request('POST', 'https://events.pagerduty.com/v2/enqueue',
                    body=json.dumps(payload), headers={'Content-Type': 'application/json'})
                return {'statusCode': 200}
          PYTHON
        end
      end
    end
  end
end
