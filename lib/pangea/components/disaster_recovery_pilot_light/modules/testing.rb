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
    module DisasterRecoveryPilotLight
      # DR testing infrastructure
      module Testing
        def create_testing_infrastructure(name, attrs, resources, tags)
          testing_resources = {}

          testing_resources[:lambda] = create_test_lambda(name, attrs, resources, tags)
          testing_resources[:schedule] = create_test_schedule(name, attrs, tags)
          testing_resources[:target] = create_test_target(name, testing_resources)
          testing_resources[:results_bucket] = create_results_bucket(name, tags)

          testing_resources
        end

        private

        def create_test_lambda(name, attrs, resources, tags)
          aws_lambda_function(
            component_resource_name(name, :test_lambda),
            {
              function_name: "#{name}-dr-test-executor",
              role: resources[:activation][:role].arn,
              handler: "index.handler",
              runtime: "python3.9",
              timeout: 900,
              memory_size: 1024,
              environment: {
                variables: {
                  TEST_SCENARIOS: attrs.testing.test_scenarios.join(','),
                  ROLLBACK_ENABLED: attrs.testing.rollback_after_test.to_s,
                  TEST_DATA_SUBSET: attrs.testing.test_data_subset.to_s,
                  STATE_MACHINE_ARN: resources[:activation][:state_machine].arn
                }
              },
              code: { zip_file: generate_test_lambda_code(attrs) },
              tags: tags
            }
          )
        end

        def create_test_schedule(name, attrs, tags)
          aws_cloudwatch_event_rule(
            component_resource_name(name, :test_schedule),
            {
              name: "#{name}-dr-test-schedule",
              description: "Scheduled DR testing",
              schedule_expression: attrs.testing.test_schedule,
              tags: tags
            }
          )
        end

        def create_test_target(name, testing_resources)
          aws_cloudwatch_event_target(
            component_resource_name(name, :test_target),
            {
              rule: testing_resources[:schedule].name,
              target_id: "1",
              arn: testing_resources[:lambda].arn
            }
          )
        end

        def create_results_bucket(name, tags)
          aws_s3_bucket(
            component_resource_name(name, :test_results_bucket),
            {
              bucket: "#{name}-dr-test-results",
              tags: tags
            }
          )
        end
      end
    end
  end
end
