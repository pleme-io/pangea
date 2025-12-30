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
    module MySqlDatabaseComponent
      # CloudWatch alarm creation methods for MySQL component
      module Monitoring
        # Create all CloudWatch alarms for the RDS instance
        def create_cloudwatch_alarms(name, db_instance_ref, component_tag_set)
          {
            cpu_high: create_cpu_alarm(name, db_instance_ref, component_tag_set),
            connections_high: create_connections_alarm(name, db_instance_ref, component_tag_set),
            storage_low: create_storage_alarm(name, db_instance_ref, component_tag_set),
            read_latency: create_read_latency_alarm(name, db_instance_ref, component_tag_set),
            write_latency: create_write_latency_alarm(name, db_instance_ref, component_tag_set)
          }
        end

        private

        def create_cpu_alarm(name, db_instance_ref, component_tag_set)
          aws_cloudwatch_metric_alarm(component_resource_name(name, :alarm, :cpu_high), {
            alarm_name: "#{name}-rds-cpu-utilization-high",
            comparison_operator: "GreaterThanThreshold",
            evaluation_periods: "2",
            metric_name: "CPUUtilization",
            namespace: "AWS/RDS",
            period: "300",
            statistic: "Average",
            threshold: "80.0",
            alarm_description: "RDS instance CPU utilization is high",
            dimensions: {
              DBInstanceIdentifier: db_instance_ref.identifier
            },
            tags: component_tag_set
          })
        end

        def create_connections_alarm(name, db_instance_ref, component_tag_set)
          aws_cloudwatch_metric_alarm(component_resource_name(name, :alarm, :connections_high), {
            alarm_name: "#{name}-rds-connections-high",
            comparison_operator: "GreaterThanThreshold",
            evaluation_periods: "2",
            metric_name: "DatabaseConnections",
            namespace: "AWS/RDS",
            period: "300",
            statistic: "Average",
            threshold: "80",
            alarm_description: "RDS instance has high number of connections",
            dimensions: {
              DBInstanceIdentifier: db_instance_ref.identifier
            },
            tags: component_tag_set
          })
        end

        def create_storage_alarm(name, db_instance_ref, component_tag_set)
          aws_cloudwatch_metric_alarm(component_resource_name(name, :alarm, :storage_low), {
            alarm_name: "#{name}-rds-free-storage-low",
            comparison_operator: "LessThanThreshold",
            evaluation_periods: "1",
            metric_name: "FreeStorageSpace",
            namespace: "AWS/RDS",
            period: "300",
            statistic: "Average",
            threshold: "2000000000", # 2GB in bytes
            alarm_description: "RDS instance is running low on storage",
            dimensions: {
              DBInstanceIdentifier: db_instance_ref.identifier
            },
            tags: component_tag_set
          })
        end

        def create_read_latency_alarm(name, db_instance_ref, component_tag_set)
          aws_cloudwatch_metric_alarm(component_resource_name(name, :alarm, :read_latency), {
            alarm_name: "#{name}-rds-read-latency-high",
            comparison_operator: "GreaterThanThreshold",
            evaluation_periods: "2",
            metric_name: "ReadLatency",
            namespace: "AWS/RDS",
            period: "300",
            statistic: "Average",
            threshold: "0.2",
            alarm_description: "RDS read latency is high",
            dimensions: {
              DBInstanceIdentifier: db_instance_ref.identifier
            },
            tags: component_tag_set
          })
        end

        def create_write_latency_alarm(name, db_instance_ref, component_tag_set)
          aws_cloudwatch_metric_alarm(component_resource_name(name, :alarm, :write_latency), {
            alarm_name: "#{name}-rds-write-latency-high",
            comparison_operator: "GreaterThanThreshold",
            evaluation_periods: "2",
            metric_name: "WriteLatency",
            namespace: "AWS/RDS",
            period: "300",
            statistic: "Average",
            threshold: "0.2",
            alarm_description: "RDS write latency is high",
            dimensions: {
              DBInstanceIdentifier: db_instance_ref.identifier
            },
            tags: component_tag_set
          })
        end
      end
    end
  end
end
