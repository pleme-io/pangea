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
      # Python code generators for Lambda functions
      module CodeGenerators
        def generate_processor_code(_source)
          <<~PYTHON
            import json
            import base64
            import os
            from datetime import datetime

            def lambda_handler(event, context):
                output_records = []
                for record in event['records']:
                    payload = base64.b64decode(record['data']).decode('utf-8')
                    try:
                        parsed_data = parse_log_data(payload, os.environ['LOG_FORMAT'])
                        parsed_data['@timestamp'] = datetime.utcnow().isoformat()
                        parsed_data['log_source'] = os.environ['LOG_SOURCE_TYPE']
                        if os.environ.get('ENABLE_ENRICHMENT', 'false').lower() == 'true':
                            parsed_data = enrich_data(parsed_data)
                        parsed_data = normalize_fields(parsed_data)
                        output_data = json.dumps(parsed_data) + '\\n'
                        output_records.append({
                            'recordId': record['recordId'],
                            'result': 'Ok',
                            'data': base64.b64encode(output_data.encode('utf-8')).decode('utf-8')
                        })
                    except Exception:
                        output_records.append({
                            'recordId': record['recordId'],
                            'result': 'ProcessingFailed',
                            'data': record['data']
                        })
                return {'records': output_records}

            def parse_log_data(data, format_type):
                if format_type == 'json':
                    return json.loads(data)
                return {'raw_data': data}

            def enrich_data(data):
                return data

            def normalize_fields(data):
                field_mappings = {'src_ip': 'source_ip', 'dst_ip': 'destination_ip'}
                for old_field, new_field in field_mappings.items():
                    if old_field in data:
                        data[new_field] = data.pop(old_field)
                return data
          PYTHON
        end

        def generate_correlation_engine_code
          <<~PYTHON
            import json
            import boto3
            import os
            from opensearchpy import OpenSearch
            from datetime import datetime

            def lambda_handler(event, context):
                es = OpenSearch(
                    hosts=[{'host': os.environ['OPENSEARCH_ENDPOINT'], 'port': 443}],
                    use_ssl=True, verify_certs=True
                )
                rules = json.loads(os.environ['CORRELATION_RULES'])
                alerts = []
                for rule in rules:
                    if rule.get('enabled', True):
                        matches = evaluate_rule(es, rule)
                        if matches:
                            alert = create_alert(rule, matches)
                            alerts.append(alert)
                            send_alert(alert)
                return {'statusCode': 200, 'body': json.dumps({'alerts': len(alerts)})}

            def evaluate_rule(es, rule):
                if rule['rule_type'] == 'threshold':
                    return evaluate_threshold_rule(es, rule)
                return []

            def evaluate_threshold_rule(es, rule):
                time_window = rule.get('time_window', 300)
                query = {'query': {'bool': {'filter': {'range': {'@timestamp': {'gte': f'now-{time_window}s'}}}}}}
                response = es.search(index='siem-*', body=query, size=0)
                doc_count = response['hits']['total']['value']
                threshold = rule.get('threshold', 10)
                if doc_count >= threshold:
                    return [{'count': doc_count, 'threshold': threshold}]
                return []

            def create_alert(rule, matches):
                return {
                    'rule_name': rule['name'],
                    'severity': rule['severity'],
                    'matches': len(matches),
                    'timestamp': datetime.utcnow().isoformat()
                }

            def send_alert(alert):
                sns = boto3.client('sns')
                sns.publish(
                    TopicArn=os.environ['SNS_TOPIC_ARN'],
                    Message=json.dumps(alert),
                    Subject=f"SIEM Alert: {alert['rule_name']}"
                )
          PYTHON
        end

        def generate_ml_detection_code
          <<~PYTHON
            import json
            import os
            from opensearchpy import OpenSearch
            from datetime import datetime

            def lambda_handler(event, context):
                es = OpenSearch(
                    hosts=[{'host': os.environ['OPENSEARCH_ENDPOINT'], 'port': 443}],
                    use_ssl=True, verify_certs=True
                )
                detectors = json.loads(os.environ['ANOMALY_DETECTORS'])
                results = []
                for detector in detectors:
                    if detector.get('enabled', True):
                        anomalies = run_anomaly_detection(es, detector)
                        results.extend(anomalies)
                if os.environ.get('ENABLE_BEHAVIOR_ANALYTICS', 'false').lower() == 'true':
                    results.extend(run_behavior_analytics(es))
                return {'statusCode': 200, 'body': json.dumps({'anomalies': len(results)})}

            def run_anomaly_detection(es, detector):
                return []

            def run_behavior_analytics(es):
                return []
          PYTHON
        end
      end
    end
  end
end
