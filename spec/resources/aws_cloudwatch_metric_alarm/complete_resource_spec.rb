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


require 'spec_helper'

# Load aws_cloudwatch_metric_alarm resource and types for testing
require 'pangea/resources/aws_cloudwatch_metric_alarm/resource'
require 'pangea/resources/aws_cloudwatch_metric_alarm/types'

RSpec.describe "aws_cloudwatch_metric_alarm resource function" do
  # Create a test class that includes the AWS module and mocks terraform-synthesizer
  let(:test_class) do
    Class.new do
      include Pangea::Resources::AWS
      
      # Mock the terraform-synthesizer resource method
      def resource(type, name)
        @resources ||= {}
        resource_data = { type: type, name: name, attributes: {} }
        
        yield if block_given?
        
        @resources["#{type}.#{name}"] = resource_data
        resource_data
      end
      
      # Method missing to capture terraform attributes
      def method_missing(method_name, *args, &block)
        # Don't capture certain methods that might interfere
        return super if [:expect, :be_a, :eq].include?(method_name)
        # For terraform-synthesizer attribute calls, just return the value
        args.first if args.any?
      end
      
      def respond_to_missing?(method_name, include_private = false)
        true
      end
    end
  end
  
  let(:test_instance) { test_class.new }
  let(:sns_topic_arn) { "arn:aws:sns:us-east-1:123456789012:alerts" }
  
  describe "CloudWatchMetricAlarmAttributes validation" do
    it "accepts traditional metric alarm configuration" do
      attrs = Pangea::Resources::AWS::Types::CloudWatchMetricAlarmAttributes.new({
        alarm_name: "high-cpu-alarm",
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: 2,
        metric_name: "CPUUtilization",
        namespace: "AWS/EC2",
        period: 300,
        statistic: "Average",
        threshold: 80.0
      })
      
      expect(attrs.alarm_name).to eq("high-cpu-alarm")
      expect(attrs.comparison_operator).to eq("GreaterThanThreshold")
      expect(attrs.evaluation_periods).to eq(2)
      expect(attrs.metric_name).to eq("CPUUtilization")
      expect(attrs.namespace).to eq("AWS/EC2")
      expect(attrs.period).to eq(300)
      expect(attrs.statistic).to eq("Average")
      expect(attrs.threshold).to eq(80.0)
      expect(attrs.is_traditional_alarm?).to eq(true)
      expect(attrs.is_metric_math_alarm?).to eq(false)
    end
    
    it "accepts metric math alarm configuration" do
      attrs = Pangea::Resources::AWS::Types::CloudWatchMetricAlarmAttributes.new({
        alarm_name: "error-rate-alarm",
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: 3,
        threshold: 5.0,
        metric_query: [
          {
            id: "e1",
            expression: "m2/m1*100",
            label: "Error Rate",
            return_data: true
          },
          {
            id: "m1",
            metric: {
              metric_name: "RequestCount",
              namespace: "AWS/ApplicationELB",
              period: 60,
              stat: "Sum"
            }
          }
        ]
      })
      
      expect(attrs.alarm_name).to eq("error-rate-alarm")
      expect(attrs.comparison_operator).to eq("GreaterThanThreshold")
      expect(attrs.threshold).to eq(5.0)
      expect(attrs.metric_query.length).to eq(2)
      expect(attrs.is_metric_math_alarm?).to eq(true)
      expect(attrs.is_traditional_alarm?).to eq(false)
    end
    
    it "validates comparison operators" do
      valid_operators = [
        "GreaterThanThreshold",
        "GreaterThanOrEqualToThreshold",
        "LessThanThreshold",
        "LessThanOrEqualToThreshold",
        "LessThanLowerOrGreaterThanUpperThreshold",
        "LessThanLowerThreshold",
        "GreaterThanUpperThreshold"
      ]
      
      valid_operators.each do |operator|
        expect {
          Pangea::Resources::AWS::Types::CloudWatchMetricAlarmAttributes.new({
            comparison_operator: operator,
            evaluation_periods: 1,
            metric_name: "CPUUtilization",
            namespace: "AWS/EC2",
            period: 300,
            statistic: "Average",
            threshold: 80.0
          })
        }.not_to raise_error
      end
      
      expect {
        Pangea::Resources::AWS::Types::CloudWatchMetricAlarmAttributes.new({
          comparison_operator: "InvalidOperator",
          evaluation_periods: 1,
          metric_name: "CPUUtilization",
          namespace: "AWS/EC2",
          period: 300,
          statistic: "Average",
          threshold: 80.0
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
    
    it "validates statistics" do
      valid_statistics = ["SampleCount", "Average", "Sum", "Minimum", "Maximum"]
      
      valid_statistics.each do |stat|
        expect {
          Pangea::Resources::AWS::Types::CloudWatchMetricAlarmAttributes.new({
            comparison_operator: "GreaterThanThreshold",
            evaluation_periods: 1,
            metric_name: "CPUUtilization",
            namespace: "AWS/EC2",
            period: 300,
            statistic: stat,
            threshold: 80.0
          })
        }.not_to raise_error
      end
      
      expect {
        Pangea::Resources::AWS::Types::CloudWatchMetricAlarmAttributes.new({
          comparison_operator: "GreaterThanThreshold",
          evaluation_periods: 1,
          metric_name: "CPUUtilization",
          namespace: "AWS/EC2",
          period: 300,
          statistic: "InvalidStatistic",
          threshold: 80.0
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
    
    it "validates treat_missing_data options" do
      valid_options = ["breaching", "notBreaching", "ignore", "missing"]
      
      valid_options.each do |option|
        expect {
          Pangea::Resources::AWS::Types::CloudWatchMetricAlarmAttributes.new({
            comparison_operator: "GreaterThanThreshold",
            evaluation_periods: 1,
            metric_name: "CPUUtilization",
            namespace: "AWS/EC2",
            period: 300,
            statistic: "Average",
            threshold: 80.0,
            treat_missing_data: option
          })
        }.not_to raise_error
      end
    end
    
    it "accepts string keys in attributes hash" do
      attrs = Pangea::Resources::AWS::Types::CloudWatchMetricAlarmAttributes.new({
        "alarm_name" => "test-alarm",
        "comparison_operator" => "GreaterThanThreshold",
        "evaluation_periods" => 2,
        "metric_name" => "CPUUtilization",
        "namespace" => "AWS/EC2",
        "period" => 300,
        "statistic" => "Average",
        "threshold" => 80.0,
        "tags" => { "Environment" => "test" }
      })
      
      expect(attrs.alarm_name).to eq("test-alarm")
      expect(attrs.comparison_operator).to eq("GreaterThanThreshold")
      expect(attrs.tags[:Environment]).to eq("test")
    end
  end
  
  describe "traditional alarm validation" do
    it "requires metric_name and namespace for traditional alarms" do
      expect {
        Pangea::Resources::AWS::Types::CloudWatchMetricAlarmAttributes.new({
          comparison_operator: "GreaterThanThreshold",
          evaluation_periods: 1,
          period: 300,
          statistic: "Average",
          threshold: 80.0
          # Missing metric_name and namespace
        })
      }.to raise_error(Dry::Struct::Error, /Must specify either metric_query or metric_name/)
    end
    
    it "requires period and statistic for traditional alarms" do
      expect {
        Pangea::Resources::AWS::Types::CloudWatchMetricAlarmAttributes.new({
          comparison_operator: "GreaterThanThreshold",
          evaluation_periods: 1,
          metric_name: "CPUUtilization",
          namespace: "AWS/EC2",
          threshold: 80.0
          # Missing period and statistic
        })
      }.to raise_error(Dry::Struct::Error, /Traditional alarm requires/)
    end
    
    it "requires threshold for traditional alarms" do
      expect {
        Pangea::Resources::AWS::Types::CloudWatchMetricAlarmAttributes.new({
          comparison_operator: "GreaterThanThreshold",
          evaluation_periods: 1,
          metric_name: "CPUUtilization",
          namespace: "AWS/EC2",
          period: 300,
          statistic: "Average"
          # Missing threshold
        })
      }.to raise_error(Dry::Struct::Error, /Traditional alarm requires threshold/)
    end
    
    it "rejects both statistic and extended_statistic" do
      expect {
        Pangea::Resources::AWS::Types::CloudWatchMetricAlarmAttributes.new({
          comparison_operator: "GreaterThanThreshold",
          evaluation_periods: 1,
          metric_name: "CPUUtilization",
          namespace: "AWS/EC2",
          period: 300,
          statistic: "Average",
          extended_statistic: "p95", # Cannot have both
          threshold: 80.0
        })
      }.to raise_error(Dry::Struct::Error, /Cannot specify both statistic and extended_statistic/)
    end
  end
  
  describe "metric math alarm validation" do
    it "requires metric_query for metric math alarms" do
      expect {
        Pangea::Resources::AWS::Types::CloudWatchMetricAlarmAttributes.new({
          comparison_operator: "GreaterThanThreshold",
          evaluation_periods: 1,
          threshold: 5.0
          # Missing metric_query
        })
      }.to raise_error(Dry::Struct::Error, /Must specify either metric_query or metric_name/)
    end
    
    it "requires threshold or threshold_metric_id for metric math alarms" do
      expect {
        Pangea::Resources::AWS::Types::CloudWatchMetricAlarmAttributes.new({
          comparison_operator: "GreaterThanThreshold",
          evaluation_periods: 1,
          metric_query: [
            {
              id: "m1",
              metric: {
                metric_name: "CPUUtilization",
                namespace: "AWS/EC2",
                period: 300,
                stat: "Average"
              }
            }
          ]
          # Missing threshold or threshold_metric_id
        })
      }.to raise_error(Dry::Struct::Error, /requires either threshold or threshold_metric_id/)
    end
    
    it "rejects both threshold and threshold_metric_id" do
      expect {
        Pangea::Resources::AWS::Types::CloudWatchMetricAlarmAttributes.new({
          comparison_operator: "GreaterThanThreshold",
          evaluation_periods: 1,
          threshold: 5.0,
          threshold_metric_id: "m1", # Cannot have both
          metric_query: [
            {
              id: "m1",
              metric: {
                metric_name: "CPUUtilization",
                namespace: "AWS/EC2",
                period: 300,
                stat: "Average"
              }
            }
          ]
        })
      }.to raise_error(Dry::Struct::Error, /Cannot specify both threshold and threshold_metric_id/)
    end
    
    it "rejects both traditional and metric math configuration" do
      expect {
        Pangea::Resources::AWS::Types::CloudWatchMetricAlarmAttributes.new({
          comparison_operator: "GreaterThanThreshold",
          evaluation_periods: 1,
          # Traditional alarm config
          metric_name: "CPUUtilization",
          namespace: "AWS/EC2",
          period: 300,
          statistic: "Average",
          threshold: 80.0,
          # Metric math config (conflict)
          metric_query: [
            {
              id: "m1",
              expression: "AVG(METRICS())"
            }
          ]
        })
      }.to raise_error(Dry::Struct::Error, /Cannot specify both metric_query and metric_name/)
    end
  end
  
  describe "MetricQuery validation" do
    it "requires either expression or metric" do
      expect {
        Pangea::Resources::AWS::Types::MetricQuery.new({
          id: "q1"
          # Missing both expression and metric
        })
      }.to raise_error(Dry::Struct::Error, /must have either expression or metric/)
    end
    
    it "rejects both expression and metric" do
      expect {
        Pangea::Resources::AWS::Types::MetricQuery.new({
          id: "q1",
          expression: "AVG(m1)",
          metric: {
            metric_name: "CPUUtilization",
            namespace: "AWS/EC2",
            period: 300,
            stat: "Average"
          }
        })
      }.to raise_error(Dry::Struct::Error, /cannot have both expression and metric/)
    end
    
    it "accepts valid expression query" do
      query = Pangea::Resources::AWS::Types::MetricQuery.new({
        id: "e1",
        expression: "m2/m1*100",
        label: "Error Rate",
        return_data: true
      })
      
      expect(query.id).to eq("e1")
      expect(query.expression).to eq("m2/m1*100")
      expect(query.label).to eq("Error Rate")
      expect(query.return_data).to eq(true)
      expect(query.metric).to be_nil
    end
    
    it "accepts valid metric query" do
      query = Pangea::Resources::AWS::Types::MetricQuery.new({
        id: "m1",
        metric: {
          metric_name: "CPUUtilization",
          namespace: "AWS/EC2",
          period: 300,
          stat: "Average",
          dimensions: {
            InstanceId: "i-1234567890abcdef0"
          }
        }
      })
      
      expect(query.id).to eq("m1")
      expect(query.expression).to be_nil
      expect(query.metric[:metric_name]).to eq("CPUUtilization")
      expect(query.metric[:namespace]).to eq("AWS/EC2")
      expect(query.metric[:period]).to eq(300)
      expect(query.metric[:stat]).to eq("Average")
      expect(query.metric[:dimensions][:InstanceId]).to eq("i-1234567890abcdef0")
    end
  end
  
  describe "datapoints_to_alarm validation" do
    it "validates datapoints_to_alarm is not greater than evaluation_periods" do
      expect {
        Pangea::Resources::AWS::Types::CloudWatchMetricAlarmAttributes.new({
          comparison_operator: "GreaterThanThreshold",
          evaluation_periods: 2,
          datapoints_to_alarm: 3, # Greater than evaluation_periods
          metric_name: "CPUUtilization",
          namespace: "AWS/EC2",
          period: 300,
          statistic: "Average",
          threshold: 80.0
        })
      }.to raise_error(Dry::Struct::Error, /datapoints_to_alarm cannot be greater than evaluation_periods/)
    end
    
    it "accepts valid datapoints_to_alarm" do
      attrs = Pangea::Resources::AWS::Types::CloudWatchMetricAlarmAttributes.new({
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: 3,
        datapoints_to_alarm: 2, # Less than evaluation_periods
        metric_name: "CPUUtilization",
        namespace: "AWS/EC2",
        period: 300,
        statistic: "Average",
        threshold: 80.0
      })
      
      expect(attrs.datapoints_to_alarm).to eq(2)
      expect(attrs.evaluation_periods).to eq(3)
    end
  end
  
  describe "computed properties" do
    let(:traditional_alarm_attrs) do
      Pangea::Resources::AWS::Types::CloudWatchMetricAlarmAttributes.new({
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: 2,
        metric_name: "CPUUtilization",
        namespace: "AWS/EC2",
        period: 300,
        statistic: "Average",
        threshold: 80.0
      })
    end
    
    let(:metric_math_alarm_attrs) do
      Pangea::Resources::AWS::Types::CloudWatchMetricAlarmAttributes.new({
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: 3,
        threshold: 5.0,
        metric_query: [
          {
            id: "e1",
            expression: "m1*100",
            return_data: true
          }
        ]
      })
    end
    
    let(:anomaly_alarm_attrs) do
      Pangea::Resources::AWS::Types::CloudWatchMetricAlarmAttributes.new({
        comparison_operator: "LessThanLowerOrGreaterThanUpperThreshold",
        evaluation_periods: 2,
        threshold_metric_id: "ad1",
        metric_query: [
          {
            id: "ad1",
            expression: "ANOMALY_DETECTION_BAND(m1, 2)"
          }
        ]
      })
    end
    
    describe "#is_traditional_alarm?" do
      it "returns true for traditional alarms" do
        expect(traditional_alarm_attrs.is_traditional_alarm?).to eq(true)
      end
      
      it "returns false for metric math alarms" do
        expect(metric_math_alarm_attrs.is_traditional_alarm?).to eq(false)
      end
    end
    
    describe "#is_metric_math_alarm?" do
      it "returns false for traditional alarms" do
        expect(traditional_alarm_attrs.is_metric_math_alarm?).to eq(false)
      end
      
      it "returns true for metric math alarms" do
        expect(metric_math_alarm_attrs.is_metric_math_alarm?).to eq(true)
      end
    end
    
    describe "#uses_anomaly_detector?" do
      it "returns false for standard threshold alarms" do
        expect(traditional_alarm_attrs.uses_anomaly_detector?).to eq(false)
        expect(metric_math_alarm_attrs.uses_anomaly_detector?).to eq(false)
      end
      
      it "returns true for anomaly detection alarms" do
        expect(anomaly_alarm_attrs.uses_anomaly_detector?).to eq(true)
      end
    end
  end
  
  describe "aws_cloudwatch_metric_alarm function" do
    it "creates traditional metric alarm" do
      result = test_instance.aws_cloudwatch_metric_alarm(:cpu_alarm, {
        alarm_name: "high-cpu-usage",
        alarm_description: "Triggers when CPU exceeds 80%",
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: 2,
        metric_name: "CPUUtilization",
        namespace: "AWS/EC2",
        period: 300,
        statistic: "Average",
        threshold: 80.0,
        alarm_actions: [sns_topic_arn],
        dimensions: {
          InstanceId: "i-1234567890abcdef0"
        }
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.type).to eq('aws_cloudwatch_metric_alarm')
      expect(result.name).to eq(:cpu_alarm)
      expect(result.resource_attributes[:alarm_name]).to eq("high-cpu-usage")
      expect(result.resource_attributes[:comparison_operator]).to eq("GreaterThanThreshold")
      expect(result.resource_attributes[:metric_name]).to eq("CPUUtilization")
      expect(result.resource_attributes[:namespace]).to eq("AWS/EC2")
      expect(result.resource_attributes[:threshold]).to eq(80.0)
      expect(result.is_traditional_alarm?).to eq(true)
      expect(result.is_metric_math_alarm?).to eq(false)
    end
    
    it "creates metric math alarm" do
      result = test_instance.aws_cloudwatch_metric_alarm(:error_rate_alarm, {
        alarm_name: "high-error-rate",
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: 3,
        threshold: 5.0,
        metric_query: [
          {
            id: "error_rate",
            expression: "(m2/m1)*100",
            label: "Error Rate Percentage",
            return_data: true
          },
          {
            id: "m1",
            metric: {
              metric_name: "RequestCount",
              namespace: "AWS/ApplicationELB",
              period: 300,
              stat: "Sum"
            }
          },
          {
            id: "m2",
            metric: {
              metric_name: "HTTPCode_Target_5XX_Count",
              namespace: "AWS/ApplicationELB",
              period: 300,
              stat: "Sum"
            }
          }
        ],
        alarm_actions: [sns_topic_arn]
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.resource_attributes[:alarm_name]).to eq("high-error-rate")
      expect(result.resource_attributes[:metric_query].length).to eq(3)
      expect(result.is_metric_math_alarm?).to eq(true)
      expect(result.is_traditional_alarm?).to eq(false)
    end
    
    it "creates anomaly detection alarm" do
      result = test_instance.aws_cloudwatch_metric_alarm(:anomaly_alarm, {
        alarm_name: "traffic-anomaly",
        comparison_operator: "LessThanLowerOrGreaterThanUpperThreshold",
        evaluation_periods: 2,
        threshold_metric_id: "ad1",
        metric_query: [
          {
            id: "m1",
            metric: {
              metric_name: "RequestCount",
              namespace: "AWS/ApplicationELB",
              period: 300,
              stat: "Average"
            }
          },
          {
            id: "ad1",
            expression: "ANOMALY_DETECTION_BAND(m1, 2)"
          }
        ],
        alarm_actions: [sns_topic_arn]
      })
      
      expect(result.resource_attributes[:comparison_operator]).to eq("LessThanLowerOrGreaterThanUpperThreshold")
      expect(result.resource_attributes[:threshold_metric_id]).to eq("ad1")
      expect(result.uses_anomaly_detector?).to eq(true)
    end
    
    it "provides correct resource reference outputs" do
      result = test_instance.aws_cloudwatch_metric_alarm(:test_alarm, {
        alarm_name: "test-alarm",
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: 1,
        metric_name: "CPUUtilization",
        namespace: "AWS/EC2",
        period: 300,
        statistic: "Average",
        threshold: 80.0
      })
      
      expected_outputs = {
        id: "${aws_cloudwatch_metric_alarm.test_alarm.id}",
        arn: "${aws_cloudwatch_metric_alarm.test_alarm.arn}",
        alarm_name: "${aws_cloudwatch_metric_alarm.test_alarm.alarm_name}",
        alarm_description: "${aws_cloudwatch_metric_alarm.test_alarm.alarm_description}",
        comparison_operator: "${aws_cloudwatch_metric_alarm.test_alarm.comparison_operator}",
        evaluation_periods: "${aws_cloudwatch_metric_alarm.test_alarm.evaluation_periods}",
        metric_name: "${aws_cloudwatch_metric_alarm.test_alarm.metric_name}",
        namespace: "${aws_cloudwatch_metric_alarm.test_alarm.namespace}",
        period: "${aws_cloudwatch_metric_alarm.test_alarm.period}",
        statistic: "${aws_cloudwatch_metric_alarm.test_alarm.statistic}",
        threshold: "${aws_cloudwatch_metric_alarm.test_alarm.threshold}",
        treat_missing_data: "${aws_cloudwatch_metric_alarm.test_alarm.treat_missing_data}"
      }
      
      expect(result.outputs).to eq(expected_outputs)
    end
  end
  
  describe "integration scenarios" do
    it "creates EC2 instance CPU alarm" do
      result = test_instance.aws_cloudwatch_metric_alarm(:ec2_cpu, {
        alarm_name: "web-server-high-cpu",
        alarm_description: "CPU utilization is too high",
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: 2,
        metric_name: "CPUUtilization",
        namespace: "AWS/EC2",
        period: 300,
        statistic: "Average",
        threshold: 80.0,
        alarm_actions: [sns_topic_arn],
        dimensions: {
          InstanceId: "i-1234567890abcdef0"
        },
        treat_missing_data: "notBreaching",
        tags: {
          InstanceName: "web-server",
          AlertType: "cpu"
        }
      })
      
      expect(result.resource_attributes[:alarm_name]).to eq("web-server-high-cpu")
      expect(result.resource_attributes[:dimensions][:InstanceId]).to eq("i-1234567890abcdef0")
      expect(result.is_traditional_alarm?).to eq(true)
    end
    
    it "creates Auto Scaling Group alarm" do
      result = test_instance.aws_cloudwatch_metric_alarm(:asg_scale_up, {
        alarm_name: "asg-scale-up-trigger",
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: 1,
        metric_name: "CPUUtilization",
        namespace: "AWS/EC2",
        period: 300,
        statistic: "Average",
        threshold: 70.0,
        alarm_actions: ["arn:aws:autoscaling:us-east-1:123456789012:scalingPolicy:policy-id"],
        dimensions: {
          AutoScalingGroupName: "web-server-asg"
        },
        tags: {
          AutoScalingGroup: "web-server-asg",
          Action: "scale-up"
        }
      })
      
      expect(result.resource_attributes[:dimensions][:AutoScalingGroupName]).to eq("web-server-asg")
      expect(result.resource_attributes[:alarm_actions]).to include("arn:aws:autoscaling:us-east-1:123456789012:scalingPolicy:policy-id")
    end
    
    it "creates RDS database alarm" do
      result = test_instance.aws_cloudwatch_metric_alarm(:rds_cpu, {
        alarm_name: "database-high-cpu",
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: 3,
        metric_name: "CPUUtilization",
        namespace: "AWS/RDS",
        period: 300,
        statistic: "Average",
        threshold: 75.0,
        datapoints_to_alarm: 2,
        alarm_actions: [sns_topic_arn],
        dimensions: {
          DBInstanceIdentifier: "production-db"
        },
        treat_missing_data: "notBreaching",
        tags: {
          Database: "production-db",
          AlertType: "cpu",
          Severity: "warning"
        }
      })
      
      expect(result.resource_attributes[:namespace]).to eq("AWS/RDS")
      expect(result.resource_attributes[:dimensions][:DBInstanceIdentifier]).to eq("production-db")
      expect(result.resource_attributes[:datapoints_to_alarm]).to eq(2)
    end
    
    it "creates Application Load Balancer target response time alarm" do
      result = test_instance.aws_cloudwatch_metric_alarm(:alb_response_time, {
        alarm_name: "high-response-time",
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: 3,
        metric_name: "TargetResponseTime",
        namespace: "AWS/ApplicationELB",
        period: 60,
        statistic: "Average",
        threshold: 1.0,
        alarm_actions: [sns_topic_arn],
        dimensions: {
          LoadBalancer: "app/my-app-lb/50dc6c495c0c9188",
          TargetGroup: "targetgroup/my-targets/73e2d6bc24d8a067"
        },
        tags: {
          LoadBalancer: "my-app-lb",
          AlertType: "performance"
        }
      })
      
      expect(result.resource_attributes[:metric_name]).to eq("TargetResponseTime")
      expect(result.resource_attributes[:namespace]).to eq("AWS/ApplicationELB")
      expect(result.resource_attributes[:threshold]).to eq(1.0)
    end
    
    it "creates Lambda function error rate alarm" do
      result = test_instance.aws_cloudwatch_metric_alarm(:lambda_errors, {
        alarm_name: "lambda-error-rate",
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: 2,
        metric_name: "Errors",
        namespace: "AWS/Lambda",
        period: 300,
        statistic: "Sum",
        threshold: 5,
        alarm_actions: [sns_topic_arn],
        dimensions: {
          FunctionName: "data-processor"
        },
        tags: {
          Function: "data-processor",
          AlertType: "errors"
        }
      })
      
      expect(result.resource_attributes[:namespace]).to eq("AWS/Lambda")
      expect(result.resource_attributes[:metric_name]).to eq("Errors")
      expect(result.resource_attributes[:dimensions][:FunctionName]).to eq("data-processor")
    end
    
    it "creates SQS queue depth alarm" do
      result = test_instance.aws_cloudwatch_metric_alarm(:sqs_depth, {
        alarm_name: "queue-depth-high",
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: 1,
        metric_name: "ApproximateNumberOfVisibleMessages",
        namespace: "AWS/SQS",
        period: 300,
        statistic: "Average",
        threshold: 100,
        alarm_actions: [sns_topic_arn],
        dimensions: {
          QueueName: "processing-queue"
        },
        tags: {
          Queue: "processing-queue",
          AlertType: "capacity"
        }
      })
      
      expect(result.resource_attributes[:namespace]).to eq("AWS/SQS")
      expect(result.resource_attributes[:metric_name]).to eq("ApproximateNumberOfVisibleMessages")
      expect(result.resource_attributes[:threshold]).to eq(100)
    end
    
    it "creates DynamoDB throttling alarm" do
      result = test_instance.aws_cloudwatch_metric_alarm(:dynamo_throttles, {
        alarm_name: "table-throttled-requests",
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: 2,
        metric_name: "ThrottledRequests",
        namespace: "AWS/DynamoDB",
        period: 300,
        statistic: "Sum",
        threshold: 0,
        alarm_actions: [sns_topic_arn],
        dimensions: {
          TableName: "user-sessions"
        },
        treat_missing_data: "notBreaching",
        tags: {
          Table: "user-sessions",
          AlertType: "throttling"
        }
      })
      
      expect(result.resource_attributes[:namespace]).to eq("AWS/DynamoDB")
      expect(result.resource_attributes[:metric_name]).to eq("ThrottledRequests")
      expect(result.resource_attributes[:threshold]).to eq(0)
    end
  end
  
  describe "advanced alarm scenarios" do
    it "creates percentile-based alarm with extended statistic" do
      result = test_instance.aws_cloudwatch_metric_alarm(:p95_latency, {
        alarm_name: "high-p95-latency",
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: 3,
        metric_name: "TargetResponseTime",
        namespace: "AWS/ApplicationELB",
        period: 300,
        extended_statistic: "p95",
        threshold: 2.0,
        alarm_actions: [sns_topic_arn],
        dimensions: {
          LoadBalancer: "app/my-app-lb/50dc6c495c0c9188"
        }
      })
      
      expect(result.resource_attributes[:extended_statistic]).to eq("p95")
      expect(result.resource_attributes[:statistic]).to be_nil
    end
    
    it "creates composite metric math alarm for error rate calculation" do
      result = test_instance.aws_cloudwatch_metric_alarm(:composite_error_rate, {
        alarm_name: "application-error-rate-high",
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: 3,
        threshold: 1.0,
        datapoints_to_alarm: 2,
        metric_query: [
          {
            id: "error_rate",
            expression: "(m2/m1)*100",
            label: "Error Rate Percentage",
            return_data: true
          },
          {
            id: "m1",
            metric: {
              metric_name: "RequestCount",
              namespace: "AWS/ApplicationELB",
              period: 60,
              stat: "Sum",
              dimensions: {
                LoadBalancer: "app/web-app/1234567890"
              }
            }
          },
          {
            id: "m2",
            metric: {
              metric_name: "HTTPCode_Target_5XX_Count",
              namespace: "AWS/ApplicationELB",
              period: 60,
              stat: "Sum",
              dimensions: {
                LoadBalancer: "app/web-app/1234567890"
              }
            }
          }
        ],
        alarm_actions: [sns_topic_arn],
        tags: {
          MetricType: "error-rate",
          Calculation: "composite"
        }
      })
      
      expect(result.is_metric_math_alarm?).to eq(true)
      expect(result.resource_attributes[:metric_query].length).to eq(3)
      expect(result.resource_attributes[:datapoints_to_alarm]).to eq(2)
    end
    
    it "creates alarm with multiple actions" do
      result = test_instance.aws_cloudwatch_metric_alarm(:multi_action, {
        alarm_name: "critical-system-alarm",
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: 1,
        metric_name: "CPUUtilization",
        namespace: "AWS/EC2",
        period: 60,
        statistic: "Average",
        threshold: 95.0,
        alarm_actions: [
          "arn:aws:sns:us-east-1:123456789012:critical-alerts",
          "arn:aws:sns:us-east-1:123456789012:pager-duty"
        ],
        ok_actions: [
          "arn:aws:sns:us-east-1:123456789012:recovery-alerts"
        ],
        insufficient_data_actions: [
          "arn:aws:sns:us-east-1:123456789012:data-alerts"
        ],
        tags: {
          Severity: "critical",
          NotificationLevel: "multiple"
        }
      })
      
      expect(result.resource_attributes[:alarm_actions].length).to eq(2)
      expect(result.resource_attributes[:ok_actions].length).to eq(1)
      expect(result.resource_attributes[:insufficient_data_actions].length).to eq(1)
    end
    
    it "creates alarm with custom missing data treatment" do
      result = test_instance.aws_cloudwatch_metric_alarm(:missing_data, {
        alarm_name: "intermittent-metric-alarm",
        comparison_operator: "LessThanThreshold",
        evaluation_periods: 5,
        metric_name: "NetworkIn",
        namespace: "AWS/EC2",
        period: 300,
        statistic: "Sum",
        threshold: 1000000, # 1MB
        treat_missing_data: "ignore",
        alarm_actions: [sns_topic_arn],
        tags: {
          MetricPattern: "intermittent",
          MissingDataHandling: "ignore"
        }
      })
      
      expect(result.resource_attributes[:treat_missing_data]).to eq("ignore")
    end
  end
  
  describe "error handling" do
    it "rejects invalid comparison operator" do
      expect {
        test_instance.aws_cloudwatch_metric_alarm(:invalid_operator, {
          comparison_operator: "InvalidOperator",
          evaluation_periods: 1,
          metric_name: "CPUUtilization",
          namespace: "AWS/EC2",
          period: 300,
          statistic: "Average",
          threshold: 80.0
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
    
    it "rejects zero evaluation periods" do
      expect {
        test_instance.aws_cloudwatch_metric_alarm(:zero_periods, {
          comparison_operator: "GreaterThanThreshold",
          evaluation_periods: 0,
          metric_name: "CPUUtilization",
          namespace: "AWS/EC2",
          period: 300,
          statistic: "Average",
          threshold: 80.0
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
    
    it "rejects invalid statistic" do
      expect {
        test_instance.aws_cloudwatch_metric_alarm(:invalid_stat, {
          comparison_operator: "GreaterThanThreshold",
          evaluation_periods: 1,
          metric_name: "CPUUtilization",
          namespace: "AWS/EC2",
          period: 300,
          statistic: "InvalidStatistic",
          threshold: 80.0
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
    
    it "rejects invalid treat_missing_data option" do
      expect {
        test_instance.aws_cloudwatch_metric_alarm(:invalid_missing, {
          comparison_operator: "GreaterThanThreshold",
          evaluation_periods: 1,
          metric_name: "CPUUtilization",
          namespace: "AWS/EC2",
          period: 300,
          statistic: "Average",
          threshold: 80.0,
          treat_missing_data: "invalid_option"
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
    
    it "rejects datapoints_to_alarm greater than evaluation_periods" do
      expect {
        test_instance.aws_cloudwatch_metric_alarm(:invalid_datapoints, {
          comparison_operator: "GreaterThanThreshold",
          evaluation_periods: 2,
          datapoints_to_alarm: 3, # Greater than evaluation_periods
          metric_name: "CPUUtilization",
          namespace: "AWS/EC2",
          period: 300,
          statistic: "Average",
          threshold: 80.0
        })
      }.to raise_error(Dry::Struct::Error, /datapoints_to_alarm cannot be greater than evaluation_periods/)
    end
    
    it "rejects metric query with neither expression nor metric" do
      expect {
        test_instance.aws_cloudwatch_metric_alarm(:invalid_query, {
          comparison_operator: "GreaterThanThreshold",
          evaluation_periods: 1,
          threshold: 5.0,
          metric_query: [
            {
              id: "invalid"
              # Missing both expression and metric
            }
          ]
        })
      }.to raise_error(Dry::Struct::Error, /must have either expression or metric/)
    end
    
    it "rejects metric query with both expression and metric" do
      expect {
        test_instance.aws_cloudwatch_metric_alarm(:conflicting_query, {
          comparison_operator: "GreaterThanThreshold",
          evaluation_periods: 1,
          threshold: 5.0,
          metric_query: [
            {
              id: "conflicting",
              expression: "AVG(m1)",
              metric: {
                metric_name: "CPUUtilization",
                namespace: "AWS/EC2",
                period: 300,
                stat: "Average"
              }
            }
          ]
        })
      }.to raise_error(Dry::Struct::Error, /cannot have both expression and metric/)
    end
  end
  
  describe "alarm type detection" do
    it "correctly identifies traditional alarms" do
      result = test_instance.aws_cloudwatch_metric_alarm(:traditional, {
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: 1,
        metric_name: "CPUUtilization",
        namespace: "AWS/EC2",
        period: 300,
        statistic: "Average",
        threshold: 80.0
      })
      
      expect(result.is_traditional_alarm?).to eq(true)
      expect(result.is_metric_math_alarm?).to eq(false)
      expect(result.uses_anomaly_detector?).to eq(false)
    end
    
    it "correctly identifies metric math alarms" do
      result = test_instance.aws_cloudwatch_metric_alarm(:metric_math, {
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: 1,
        threshold: 5.0,
        metric_query: [
          {
            id: "m1",
            expression: "RATE(METRICS())"
          }
        ]
      })
      
      expect(result.is_metric_math_alarm?).to eq(true)
      expect(result.is_traditional_alarm?).to eq(false)
      expect(result.uses_anomaly_detector?).to eq(false)
    end
    
    it "correctly identifies anomaly detection alarms" do
      anomaly_operators = [
        "LessThanLowerOrGreaterThanUpperThreshold",
        "LessThanLowerThreshold",
        "GreaterThanUpperThreshold"
      ]
      
      anomaly_operators.each do |operator|
        result = test_instance.aws_cloudwatch_metric_alarm(:anomaly_test, {
          comparison_operator: operator,
          evaluation_periods: 2,
          threshold_metric_id: "ad1",
          metric_query: [
            {
              id: "ad1",
              expression: "ANOMALY_DETECTION_BAND(m1, 2)"
            }
          ]
        })
        
        expect(result.uses_anomaly_detector?).to eq(true)
      end
    end
  end
  
  describe "alarm action scenarios" do
    it "handles multiple alarm actions" do
      multiple_actions = [
        "arn:aws:sns:us-east-1:123456789012:critical-alerts",
        "arn:aws:sns:us-east-1:123456789012:team-alerts",
        "arn:aws:autoscaling:us-east-1:123456789012:scalingPolicy:scale-up"
      ]
      
      result = test_instance.aws_cloudwatch_metric_alarm(:multi_actions, {
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: 1,
        metric_name: "CPUUtilization",
        namespace: "AWS/EC2",
        period: 300,
        statistic: "Average",
        threshold: 80.0,
        alarm_actions: multiple_actions
      })
      
      expect(result.resource_attributes[:alarm_actions]).to eq(multiple_actions)
    end
    
    it "handles OK actions for recovery notifications" do
      result = test_instance.aws_cloudwatch_metric_alarm(:ok_actions, {
        comparison_operator: "LessThanThreshold",
        evaluation_periods: 2,
        metric_name: "CPUUtilization",
        namespace: "AWS/EC2",
        period: 300,
        statistic: "Average",
        threshold: 20.0,
        alarm_actions: ["arn:aws:sns:us-east-1:123456789012:low-cpu-alerts"],
        ok_actions: ["arn:aws:sns:us-east-1:123456789012:recovery-alerts"],
        tags: {
          AlertType: "low-utilization"
        }
      })
      
      expect(result.resource_attributes[:ok_actions]).to include("arn:aws:sns:us-east-1:123456789012:recovery-alerts")
    end
    
    it "handles insufficient data actions" do
      result = test_instance.aws_cloudwatch_metric_alarm(:insufficient_data, {
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: 3,
        metric_name: "CustomMetric",
        namespace: "MyApp/Custom",
        period: 300,
        statistic: "Average",
        threshold: 100.0,
        alarm_actions: [sns_topic_arn],
        insufficient_data_actions: ["arn:aws:sns:us-east-1:123456789012:data-alerts"],
        treat_missing_data: "ignore"
      })
      
      expect(result.resource_attributes[:insufficient_data_actions]).to include("arn:aws:sns:us-east-1:123456789012:data-alerts")
    end
  end
  
  describe "metric math scenarios" do
    it "creates complex metric math alarm with multiple metrics" do
      result = test_instance.aws_cloudwatch_metric_alarm(:complex_math, {
        alarm_name: "resource-utilization-composite",
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: 5,
        threshold: 80.0,
        datapoints_to_alarm: 3,
        metric_query: [
          {
            id: "utilization",
            expression: "(m1+m2+m3)/3",
            label: "Average Resource Utilization",
            return_data: true
          },
          {
            id: "m1",
            metric: {
              metric_name: "CPUUtilization",
              namespace: "AWS/EC2",
              period: 300,
              stat: "Average",
              dimensions: {
                InstanceId: "i-1234567890abcdef0"
              }
            }
          },
          {
            id: "m2",
            metric: {
              metric_name: "NetworkIn",
              namespace: "AWS/EC2",
              period: 300,
              stat: "Average",
              dimensions: {
                InstanceId: "i-1234567890abcdef0"
              }
            }
          },
          {
            id: "m3",
            metric: {
              metric_name: "DiskWriteBytes",
              namespace: "AWS/EC2",
              period: 300,
              stat: "Average",
              dimensions: {
                InstanceId: "i-1234567890abcdef0"
              }
            }
          }
        ],
        alarm_actions: [sns_topic_arn]
      })
      
      expect(result.is_metric_math_alarm?).to eq(true)
      expect(result.resource_attributes[:metric_query].length).to eq(4)
    end
    
    it "creates cross-service metric math alarm" do
      result = test_instance.aws_cloudwatch_metric_alarm(:cross_service, {
        alarm_name: "end-to-end-latency",
        comparison_operator: "GreaterThanThreshold", 
        evaluation_periods: 3,
        threshold: 5000.0, # 5 seconds total
        metric_query: [
          {
            id: "total_latency",
            expression: "m1+m2+m3",
            label: "Total End-to-End Latency",
            return_data: true
          },
          {
            id: "m1", # ALB latency
            metric: {
              metric_name: "TargetResponseTime",
              namespace: "AWS/ApplicationELB",
              period: 300,
              stat: "Average"
            }
          },
          {
            id: "m2", # Lambda duration
            metric: {
              metric_name: "Duration",
              namespace: "AWS/Lambda",
              period: 300,
              stat: "Average"
            }
          },
          {
            id: "m3", # RDS latency
            metric: {
              metric_name: "ReadLatency",
              namespace: "AWS/RDS",
              period: 300,
              stat: "Average"
            }
          }
        ]
      })
      
      expect(result.resource_attributes[:metric_query].length).to eq(4)
    end
  end
end