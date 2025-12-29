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
    module GlobalTrafficManager
      # Synthetic monitoring resources
      module Synthetic
        def create_synthetic_resources(name, attrs, resources, tags)
          return unless attrs.observability.synthetic_checks.any?

          synthetic_resources = {}
          create_canaries(name, attrs, tags, synthetic_resources)
          resources[:synthetic_monitoring] = synthetic_resources
        end

        private

        def create_canaries(name, attrs, tags, synthetic_resources)
          attrs.observability.synthetic_checks.each_with_index do |check, index|
            canary_ref = create_canary(name, attrs, check, index, tags)
            synthetic_resources["canary_#{index}".to_sym] = canary_ref
          end
        end

        def create_canary(name, attrs, check, index, tags)
          aws_synthetics_canary(
            component_resource_name(name, :canary, "check#{index}".to_sym),
            build_canary_config(name, attrs, check, index, tags)
          )
        end

        def build_canary_config(name, attrs, check, index, tags)
          {
            name: "#{name}-synthetic-#{index}",
            artifact_s3_location: "s3://#{attrs.performance.flow_logs_s3_bucket}/synthetics/",
            execution_role_arn: 'arn:aws:iam::ACCOUNT:role/CloudWatchSyntheticsRole',
            handler: check[:handler] || 'pageLoadBlueprint.handler',
            runtime_version: check[:runtime] || 'syn-nodejs-puppeteer-3.5',
            schedule: { expression: check[:schedule] || 'rate(5 minutes)' },
            run_config: build_run_config(attrs, check),
            success_retention_period_in_days: 31,
            failure_retention_period_in_days: 31,
            tags: tags.merge(CheckType: check[:type] || 'availability')
          }
        end

        def build_run_config(attrs, check)
          {
            timeout_in_seconds: check[:timeout] || 60,
            memory_in_mb: check[:memory] || 960,
            active_tracing: attrs.observability.distributed_tracing
          }
        end
      end
    end
  end
end
