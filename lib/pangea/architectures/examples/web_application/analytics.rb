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

require 'pangea'

# Example 6: Architecture Composition with Data Pipeline
template :web_app_with_analytics do
  include Pangea::Architectures

  web_app = web_application_architecture(:analytics_app, {
    domain_name: 'analytics-app.com',
    environment: 'production',
    instance_type: 't3.medium',
    auto_scaling: { min: 2, max: 8 },
    database_engine: 'postgresql',
    enable_caching: true
  })

  web_app.compose_with do |arch_ref|
    if defined?(Pangea::Architectures) && respond_to?(:data_lake_architecture)
      arch_ref.analytics = data_lake_architecture(:"#{arch_ref.name}_analytics", {
        vpc_ref: arch_ref.network.vpc,
        source_database_ref: arch_ref.database,
        processing_schedule: 'daily',
        retention_days: 365,
        data_sources: [
          {
            name: 'application_logs',
            type: 'cloudwatch_logs',
            log_group: "/aws/elasticbeanstalk/#{arch_ref.name}/var/log/eb-engine.log"
          },
          {
            name: 'database_exports',
            type: 'rds_snapshot',
            database_ref: arch_ref.database
          }
        ],
        analytics_tools: %w[athena quicksight redshift_serverless]
      })
    end

    arch_ref.streaming = {
      kinesis_stream: aws_kinesis_stream(:user_events, {
        name: "#{arch_ref.name}-user-events",
        shard_count: 2,
        retention_period: 24,
        shard_level_metrics: %w[IncomingRecords OutgoingRecords]
      }),
      kinesis_analytics: aws_kinesis_analytics_application(:behavior_analytics, {
        name: "#{arch_ref.name}-behavior-analytics",
        inputs: [{
          name_prefix: 'user_behavior_stream',
          kinesis_stream: {
            resource_arn: aws_kinesis_stream(:user_events).arn,
            role_arn: aws_iam_role(:kinesis_analytics_role).arn
          },
          schema: {
            record_columns: [
              { name: 'user_id', sql_type: 'VARCHAR(32)', mapping: '$.user_id' },
              { name: 'event_type', sql_type: 'VARCHAR(64)', mapping: '$.event_type' },
              { name: 'timestamp', sql_type: 'TIMESTAMP', mapping: '$.timestamp' }
            ],
            record_format: {
              record_format_type: 'JSON',
              mapping_parameters: {
                json_mapping_parameters: { record_row_path: '$' }
              }
            }
          }
        }]
      })
    }
  end

  output :web_application_url do
    value web_app.application_url
  end

  output :analytics_dashboard_url do
    value web_app.analytics&.dashboard_url
    description 'Data analytics dashboard'
  end

  output :streaming_analytics_endpoint do
    value web_app.streaming[:kinesis_analytics].name
    description 'Real-time analytics application'
  end

  output :comprehensive_monthly_cost do
    base_cost = web_app.estimated_monthly_cost
    analytics_cost = 150.0
    value base_cost + analytics_cost
    description 'Total cost including web app and analytics pipeline'
  end
end
