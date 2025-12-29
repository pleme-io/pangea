# frozen_string_literal: true

module Pangea
  module Architectures
    module Patterns
      module DataProcessing
        # Monitoring tier for data lake
        module Monitoring
          def create_data_monitoring_tier(name, arch_ref, data_attrs, base_tags)
            {
              dashboard: create_data_dashboard(name, arch_ref, data_attrs),
              data_freshness_alarm: create_data_freshness_alarm(name, arch_ref)
            }
          end

          private

          def create_data_dashboard(name, arch_ref, data_attrs)
            aws_cloudwatch_dashboard(
              architecture_resource_name(name, :data_dashboard),
              dashboard_name: "#{name.to_s.tr('_', '-')}-DataLake-Dashboard",
              dashboard_body: generate_data_dashboard_body(name, arch_ref, data_attrs)
            )
          end

          def create_data_freshness_alarm(name, arch_ref)
            aws_cloudwatch_metric_alarm(
              architecture_resource_name(name, :data_freshness_alarm),
              alarm_name: "#{name}-data-freshness",
              comparison_operator: 'LessThanThreshold',
              evaluation_periods: '2',
              metric_name: 'IncomingRecords',
              namespace: 'AWS/Kinesis',
              period: '300',
              statistic: 'Sum',
              threshold: '1',
              alarm_description: "Data freshness alarm for #{name}",
              alarm_actions: [],
              dimensions: {
                StreamName: arch_ref.compute[:ingestion][:kinesis_stream]&.name
              }
            )
          end

          def generate_data_dashboard_body(name, arch_ref, _data_attrs)
            jsonencode({
              widgets: [{
                type: 'metric',
                properties: {
                  metrics: [
                    ['AWS/S3', 'BucketSizeBytes', 'BucketName', arch_ref.storage[:raw_bucket].bucket, 'StorageType', 'StandardStorage'],
                    ['AWS/S3', 'BucketSizeBytes', 'BucketName', arch_ref.storage[:processed_bucket].bucket, 'StorageType', 'StandardStorage']
                  ],
                  period: 86_400,
                  stat: 'Average',
                  region: 'us-east-1',
                  title: 'Data Lake Storage Usage'
                }
              }]
            })
          end
        end
      end
    end
  end
end
