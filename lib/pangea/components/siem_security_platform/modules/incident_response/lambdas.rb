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
      # Lambda functions for incident response
      module Lambdas
        def create_incident_classifier(name, attrs, resources)
          lambda_name = component_resource_name(name, :incident_classifier)
          lambda_fn = aws_lambda_function(lambda_name, {
            function_name: "siem-incident-classifier-#{name}",
            runtime: "python3.11",
            handler: "index.lambda_handler",
            role: create_lambda_execution_role(name, "incident-classifier", attrs, resources),
            timeout: 60,
            code: { zip_file: classifier_code },
            tags: component_tags('siem_security_platform', name, attrs.tags)
          })
          resources[:lambda_functions][:incident_classifier] = lambda_fn
          lambda_fn.arn
        end

        def create_isolation_lambda(name, attrs, resources)
          lambda_name = component_resource_name(name, :isolation)
          lambda_fn = aws_lambda_function(lambda_name, {
            function_name: "siem-isolation-#{name}",
            runtime: "python3.11",
            handler: "index.lambda_handler",
            role: create_isolation_role(name, attrs, resources),
            timeout: 300,
            code: { zip_file: isolation_code },
            tags: component_tags('siem_security_platform', name, attrs.tags)
          })
          resources[:lambda_functions][:isolation] = lambda_fn
          lambda_fn.arn
        end

        def create_forensics_lambda(name, attrs, resources)
          create_forensics_bucket(name, attrs, resources)
          lambda_name = component_resource_name(name, :forensics)
          lambda_fn = aws_lambda_function(lambda_name, {
            function_name: "siem-forensics-#{name}",
            runtime: "python3.11",
            handler: "index.lambda_handler",
            role: create_forensics_role(name, attrs, resources),
            timeout: 900,
            memory_size: 3008,
            environment: {
              variables: { FORENSICS_BUCKET: resources[:s3_buckets][:forensics].id }
            },
            code: { zip_file: forensics_code },
            tags: component_tags('siem_security_platform', name, attrs.tags)
          })
          resources[:lambda_functions][:forensics] = lambda_fn
          lambda_fn.arn
        end

        def create_response_lambda(name, attrs, resources)
          lambda_name = component_resource_name(name, :response)
          lambda_fn = aws_lambda_function(lambda_name, {
            function_name: "siem-response-#{name}",
            runtime: "python3.11",
            handler: "index.lambda_handler",
            role: create_lambda_execution_role(name, "response", attrs, resources),
            timeout: 300,
            code: { zip_file: response_code },
            tags: component_tags('siem_security_platform', name, attrs.tags)
          })
          resources[:lambda_functions][:response] = lambda_fn
          lambda_fn.arn
        end

        def create_ticketing_lambda(name, attrs, resources)
          lambda_name = component_resource_name(name, :ticketing)
          lambda_fn = aws_lambda_function(lambda_name, {
            function_name: "siem-ticketing-#{name}",
            runtime: "python3.11",
            handler: "index.lambda_handler",
            role: create_lambda_execution_role(name, "ticketing", attrs, resources),
            timeout: 60,
            environment: {
              variables: { TICKETING_INTEGRATION: JSON.generate(attrs.integrations.find { |i| i[:type] == 'ticketing' } || {}) }
            },
            code: { zip_file: ticketing_code },
            tags: component_tags('siem_security_platform', name, attrs.tags)
          })
          resources[:lambda_functions][:ticketing] = lambda_fn
          lambda_fn.arn
        end

        private

        def classifier_code
          <<~PYTHON
            import json
            def lambda_handler(event, context):
                incident = event.get('incident', {})
                indicators = incident.get('indicators', [])
                if any(ind.get('severity') == 'critical' for ind in indicators):
                    severity = 'critical'
                elif any(ind.get('severity') == 'high' for ind in indicators):
                    severity = 'high'
                elif any(ind.get('severity') == 'medium' for ind in indicators):
                    severity = 'medium'
                else:
                    severity = 'low'
                return {'severity': severity, 'incident': incident}
          PYTHON
        end

        def isolation_code
          <<~PYTHON
            import boto3
            def lambda_handler(event, context):
                action = event.get('action', 'isolate')
                resource = event.get('resource', {})
                return {'status': 'completed', 'action': action, 'resource': resource}
          PYTHON
        end

        def forensics_code
          <<~PYTHON
            import boto3
            import os
            def lambda_handler(event, context):
                incident = event.get('incident', {})
                bucket = os.environ['FORENSICS_BUCKET']
                return {'status': 'collected', 'bucket': bucket}
          PYTHON
        end

        def response_code
          <<~PYTHON
            def lambda_handler(event, context):
                severity = event.get('severity', 'low')
                incident = event.get('incident', {})
                return {'status': 'responded', 'severity': severity}
          PYTHON
        end

        def ticketing_code
          <<~PYTHON
            import json
            import os
            def lambda_handler(event, context):
                incident = event.get('incident', {})
                return {'status': 'ticket_created', 'incident_id': incident.get('id')}
          PYTHON
        end

        def create_isolation_role(name, attrs, resources)
          role_name = component_resource_name(name, :isolation_role)
          role = aws_iam_role(role_name, {
            name: role_name.to_s,
            assume_role_policy: lambda_assume_role_policy,
            tags: component_tags('siem_security_platform', name, attrs.tags)
          })
          attach_lambda_policies(role_name, role)
          resources[:iam_roles][:isolation] = role
          role.arn
        end

        def create_forensics_role(name, attrs, resources)
          role_name = component_resource_name(name, :forensics_role)
          role = aws_iam_role(role_name, {
            name: role_name.to_s,
            assume_role_policy: lambda_assume_role_policy,
            tags: component_tags('siem_security_platform', name, attrs.tags)
          })
          attach_lambda_policies(role_name, role)
          resources[:iam_roles][:forensics] = role
          role.arn
        end

        def create_forensics_bucket(name, attrs, resources)
          bucket_name = component_resource_name(name, :forensics_bucket)
          resources[:s3_buckets][:forensics] = create_secure_bucket(
            bucket_name,
            "siem-forensics-#{name}",
            attrs,
            resources
          )
        end
      end
    end
  end
end
