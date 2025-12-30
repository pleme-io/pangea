# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Components
    module SecureS3BucketComponent
      # Monitoring and alarms configuration
      module Monitoring
        def configure_analytics(name, bucket_ref, component_attrs)
          return {} unless component_attrs.analytics.enabled && component_attrs.analytics.configurations.any?
          component_attrs.analytics.configurations.each_with_index.to_h do |config, index|
            ref = aws_s3_bucket_analytics_configuration(component_resource_name(name, :analytics, :"config#{index}"),
                                                        { bucket: bucket_ref.id, name: config[:name] || "analytics-config-#{index}" }.merge(config))
            [:"config#{index}", ref]
          end
        end

        def configure_inventory(name, bucket_ref, component_attrs)
          return {} unless component_attrs.inventory.enabled && component_attrs.inventory.configurations.any?
          component_attrs.inventory.configurations.each_with_index.to_h do |config, index|
            ref = aws_s3_bucket_inventory(component_resource_name(name, :inventory, :"config#{index}"),
                                          { bucket: bucket_ref.id, name: config[:name] || "inventory-config-#{index}" }.merge(config))
            [:"config#{index}", ref]
          end
        end

        def configure_alarms(name, bucket_ref, component_attrs, component_tag_set)
          return {} unless component_attrs.metrics.enabled
          alarms = {}
          alarms[:object_count] = create_object_count_alarm(name, bucket_ref, component_tag_set)
          alarms[:bucket_size] = create_bucket_size_alarm(name, bucket_ref, component_tag_set)
          alarms[:errors_4xx] = create_4xx_errors_alarm(name, bucket_ref, component_tag_set) if component_attrs.metrics.enable_request_metrics
          alarms
        end

        private

        def create_object_count_alarm(name, bucket_ref, component_tag_set)
          aws_cloudwatch_metric_alarm(component_resource_name(name, :alarm, :object_count), {
            alarm_name: "#{name}-s3-object-count-high", comparison_operator: 'GreaterThanThreshold', evaluation_periods: '1',
            metric_name: 'NumberOfObjects', namespace: 'AWS/S3', period: '86400', statistic: 'Average', threshold: '100000',
            alarm_description: 'S3 bucket has high number of objects', dimensions: { BucketName: bucket_ref.id, StorageType: 'AllStorageTypes' }, tags: component_tag_set
          })
        end

        def create_bucket_size_alarm(name, bucket_ref, component_tag_set)
          aws_cloudwatch_metric_alarm(component_resource_name(name, :alarm, :bucket_size), {
            alarm_name: "#{name}-s3-bucket-size-large", comparison_operator: 'GreaterThanThreshold', evaluation_periods: '1',
            metric_name: 'BucketSizeBytes', namespace: 'AWS/S3', period: '86400', statistic: 'Average', threshold: '107374182400',
            alarm_description: 'S3 bucket size is large', dimensions: { BucketName: bucket_ref.id, StorageType: 'StandardStorage' }, tags: component_tag_set
          })
        end

        def create_4xx_errors_alarm(name, bucket_ref, component_tag_set)
          aws_cloudwatch_metric_alarm(component_resource_name(name, :alarm, :errors_4xx), {
            alarm_name: "#{name}-s3-4xx-errors-high", comparison_operator: 'GreaterThanThreshold', evaluation_periods: '2',
            metric_name: '4xxErrors', namespace: 'AWS/S3', period: '300', statistic: 'Sum', threshold: '5',
            alarm_description: 'S3 bucket has high 4xx error rate', dimensions: { BucketName: bucket_ref.id }, tags: component_tag_set
          })
        end
      end
    end
  end
end
