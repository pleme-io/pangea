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
require_relative 'incident_response/state_machine'
require_relative 'incident_response/lambdas'

module Pangea
  module Components
    module SiemSecurityPlatform
      # Incident response resources: Step Functions, response Lambdas
      module IncidentResponse
        include StateMachine
        include Lambdas

        def create_incident_response_resources(name, attrs, resources)
          return unless attrs.incident_response[:enable_automated_response]

          create_step_functions_state_machine(name, attrs, resources)
          create_playbook_executions(name, attrs, resources)
        end

        private

        def create_playbook_executions(name, attrs, resources)
          attrs.incident_response[:playbooks]&.each do |playbook|
            create_playbook_execution(name, playbook, attrs, resources)
          end
        end

        def create_playbook_execution(name, playbook, attrs, resources)
          playbook_name = component_resource_name(name, :playbook, playbook[:name])
          resources[:lambda_functions][:"playbook_#{playbook[:name]}"] = aws_lambda_function(playbook_name, {
            function_name: "siem-playbook-#{name}-#{playbook[:name]}",
            runtime: "python3.11",
            handler: "index.lambda_handler",
            role: create_lambda_execution_role(name, "playbook-#{playbook[:name]}", attrs, resources),
            timeout: playbook[:timeout] || 300,
            memory_size: 512,
            environment: {
              variables: {
                PLAYBOOK_CONFIG: JSON.generate(playbook),
                OPENSEARCH_ENDPOINT: resources[:opensearch_domain].endpoint
              }
            },
            code: { zip_file: generate_playbook_code(playbook) },
            tags: component_tags('siem_security_platform', name, attrs.tags)
          })
        end

        def generate_playbook_code(playbook)
          <<~PYTHON
            import json
            import os

            def lambda_handler(event, context):
                playbook = json.loads(os.environ['PLAYBOOK_CONFIG'])
                incident = event.get('incident', {})
                results = []
                for step in playbook.get('steps', []):
                    result = execute_step(step, {'incident': incident})
                    results.append(result)
                return {'statusCode': 200, 'results': results}

            def execute_step(step, context):
                return {'step': step['name'], 'status': 'completed'}
          PYTHON
        end
      end
    end
  end
end
