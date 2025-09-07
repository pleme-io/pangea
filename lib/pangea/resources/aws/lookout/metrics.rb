# frozen_string_literal: true

module Pangea
  module Resources
    module AWS
      module Lookout
        # AWS Lookout for Metrics resources for business metrics anomaly detection
        # These resources monitor business and operational metrics to automatically detect
        # anomalies and provide insights into unusual patterns and trends.
        #
        # @see https://docs.aws.amazon.com/lookoutmetrics/
        module Metrics
          # Creates an AWS Lookout for Metrics Detector
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the detector
          # @option attributes [String] :anomaly_detector_name The name of the anomaly detector (required)
          # @option attributes [String] :anomaly_detector_description A description of the detector
          # @option attributes [Hash] :anomaly_detector_config Configuration for the detector (required)
          #   - :anomaly_detector_frequency [String] The frequency of detection ("PT5M", "PT10M", "PT1H", "P1D")
          # @option attributes [Hash<String, String>] :tags A map of tags to assign to the resource
          #
          # @example Basic business metrics detector
          #   aws_lookoutmetrics_detector(:revenue_anomaly_detector, {
          #     anomaly_detector_name: "daily-revenue-anomaly-detection",
          #     anomaly_detector_description: "Detects anomalies in daily revenue and transaction metrics",
          #     anomaly_detector_config: {
          #       anomaly_detector_frequency: "P1D"
          #     },
          #     tags: {
          #       BusinessUnit: "Finance",
          #       MetricType: "Revenue",
          #       DetectionFrequency: "Daily"
          #     }
          #   })
          #
          # @return [ResourceReference] Reference to the created detector
          def aws_lookoutmetrics_detector(name, attributes = {})
            resource = resource(:aws_lookoutmetrics_detector, name) do
              anomaly_detector_name attributes[:anomaly_detector_name] if attributes[:anomaly_detector_name]
              anomaly_detector_description attributes[:anomaly_detector_description] if attributes[:anomaly_detector_description]
              anomaly_detector_config attributes[:anomaly_detector_config] if attributes[:anomaly_detector_config]
              tags attributes[:tags] if attributes[:tags]
            end

            ResourceReference.new(
              type: 'aws_lookoutmetrics_detector',
              name: name,
              resource_attributes: attributes,
              outputs: {
                arn: "${aws_lookoutmetrics_detector.#{name}.arn}",
                anomaly_detector_name: "${aws_lookoutmetrics_detector.#{name}.anomaly_detector_name}",
                status: "${aws_lookoutmetrics_detector.#{name}.status}",
                creation_time: "${aws_lookoutmetrics_detector.#{name}.creation_time}",
                last_modification_time: "${aws_lookoutmetrics_detector.#{name}.last_modification_time}"
              }
            )
          end

          # Creates an AWS Lookout for Metrics Anomaly Detector
          #
          # @param name [Symbol] The unique name for this resource instance  
          # @param attributes [Hash] The configuration options for the anomaly detector
          # @option attributes [String] :anomaly_detector_name The name of the anomaly detector (required)
          # @option attributes [String] :anomaly_detector_description A description of the detector
          # @option attributes [Hash] :anomaly_detector_config Configuration for the detector (required)
          #   - :anomaly_detector_frequency [String] The frequency of detection
          # @option attributes [String] :kms_key_arn The KMS key ARN for encryption
          # @option attributes [Hash<String, String>] :tags A map of tags to assign to the resource
          #
          # @example E-commerce metrics anomaly detector
          #   aws_lookoutmetrics_anomaly_detector(:ecommerce_metrics_detector, {
          #     anomaly_detector_name: "ecommerce-business-metrics",
          #     anomaly_detector_description: "Monitors key e-commerce metrics for unusual patterns",
          #     anomaly_detector_config: {
          #       anomaly_detector_frequency: "PT1H"
          #     },
          #     kms_key_arn: ref(:aws_kms_key, :metrics_encryption, :arn),
          #     tags: {
          #       Platform: "Ecommerce",
          #       MonitoringType: "BusinessMetrics",
          #       Frequency: "Hourly",
          #       Team: "DataScience"
          #     }
          #   })
          #
          # @return [ResourceReference] Reference to the created anomaly detector
          def aws_lookoutmetrics_anomaly_detector(name, attributes = {})
            resource = resource(:aws_lookoutmetrics_anomaly_detector, name) do
              anomaly_detector_name attributes[:anomaly_detector_name] if attributes[:anomaly_detector_name]
              anomaly_detector_description attributes[:anomaly_detector_description] if attributes[:anomaly_detector_description]
              anomaly_detector_config attributes[:anomaly_detector_config] if attributes[:anomaly_detector_config]
              kms_key_arn attributes[:kms_key_arn] if attributes[:kms_key_arn]
              tags attributes[:tags] if attributes[:tags]
            end

            ResourceReference.new(
              type: 'aws_lookoutmetrics_anomaly_detector',
              name: name,
              resource_attributes: attributes,
              outputs: {
                arn: "${aws_lookoutmetrics_anomaly_detector.#{name}.arn}",
                anomaly_detector_name: "${aws_lookoutmetrics_anomaly_detector.#{name}.anomaly_detector_name}",
                status: "${aws_lookoutmetrics_anomaly_detector.#{name}.status}",
                creation_time: "${aws_lookoutmetrics_anomaly_detector.#{name}.creation_time}",
                last_modification_time: "${aws_lookoutmetrics_anomaly_detector.#{name}.last_modification_time}",
                failure_reason: "${aws_lookoutmetrics_anomaly_detector.#{name}.failure_reason}"
              }
            )
          end
        end
      end
    end
  end
end