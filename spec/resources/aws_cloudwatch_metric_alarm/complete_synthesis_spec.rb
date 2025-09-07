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
require 'json'

# Load aws_cloudwatch_metric_alarm resource and terraform-synthesizer for testing
require 'pangea/resources/aws_cloudwatch_metric_alarm/resource'
require 'terraform_synthesizer'

RSpec.describe "aws_cloudwatch_metric_alarm terraform synthesis" do
  let(:synthesizer) { TerraformSynthesizer.new }
  let(:sns_topic_arn) { "arn:aws:sns:us-east-1:123456789012:alerts" }

  # Test traditional metric alarm synthesis
  it "synthesizes traditional metric alarm correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_metric_alarm(:high_cpu, {
        alarm_name: "high-cpu-alarm",
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
    end
    
    json_output = JSON.parse(terraform_output)
    alarm_config = json_output.dig("resource", "aws_cloudwatch_metric_alarm", "high_cpu")
    
    expect(alarm_config["alarm_name"]).to eq("high-cpu-alarm")
    expect(alarm_config["alarm_description"]).to eq("Triggers when CPU exceeds 80%")
    expect(alarm_config["comparison_operator"]).to eq("GreaterThanThreshold")
    expect(alarm_config["evaluation_periods"]).to eq(2)
    expect(alarm_config["metric_name"]).to eq("CPUUtilization")
    expect(alarm_config["namespace"]).to eq("AWS/EC2")
    expect(alarm_config["period"]).to eq(300)
    expect(alarm_config["statistic"]).to eq("Average")
    expect(alarm_config["threshold"]).to eq(80.0)
    expect(alarm_config["alarm_actions"]).to eq([sns_topic_arn])
    expect(alarm_config["dimensions"]["InstanceId"]).to eq("i-1234567890abcdef0")
    expect(alarm_config["actions_enabled"]).to eq(true)
    expect(alarm_config["treat_missing_data"]).to eq("missing")
    expect(alarm_config).not_to have_key("metric_query")
  end

  # Test metric math alarm synthesis
  it "synthesizes metric math alarm correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_metric_alarm(:error_rate, {
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
              period: 60,
              stat: "Sum"
            }
          },
          {
            id: "m2",
            metric: {
              metric_name: "HTTPCode_Target_5XX_Count",
              namespace: "AWS/ApplicationELB",
              period: 60,
              stat: "Sum"
            }
          }
        ]
      })
    end
    
    json_output = JSON.parse(terraform_output)
    alarm_config = json_output.dig("resource", "aws_cloudwatch_metric_alarm", "error_rate")
    
    expect(alarm_config["alarm_name"]).to eq("high-error-rate")
    expect(alarm_config["comparison_operator"]).to eq("GreaterThanThreshold")
    expect(alarm_config["evaluation_periods"]).to eq(3)
    expect(alarm_config["threshold"]).to eq(5.0)
    expect(alarm_config).not_to have_key("metric_name")
    expect(alarm_config).not_to have_key("namespace")
    expect(alarm_config).not_to have_key("period")
    expect(alarm_config).not_to have_key("statistic")
    
    # Check metric query structure
    metric_queries = alarm_config["metric_query"]
    expect(metric_queries).to be_an(Array)
    expect(metric_queries.length).to eq(3)
    
    # Check expression query
    expression_query = metric_queries.find { |q| q["id"] == "error_rate" }
    expect(expression_query).not_to be_nil
    expect(expression_query["expression"]).to eq("(m2/m1)*100")
    expect(expression_query["label"]).to eq("Error Rate Percentage")
    expect(expression_query["return_data"]).to eq(true)
    expect(expression_query).not_to have_key("metric")
    
    # Check metric queries
    m1_query = metric_queries.find { |q| q["id"] == "m1" }
    expect(m1_query).not_to be_nil
    expect(m1_query).not_to have_key("expression")
    expect(m1_query["metric"]["metric_name"]).to eq("RequestCount")
    expect(m1_query["metric"]["namespace"]).to eq("AWS/ApplicationELB")
    expect(m1_query["metric"]["period"]).to eq(60)
    expect(m1_query["metric"]["stat"]).to eq("Sum")
  end

  # Test anomaly detection alarm synthesis
  it "synthesizes anomaly detection alarm correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_metric_alarm(:traffic_anomaly, {
        alarm_name: "unusual-traffic-pattern",
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
    end
    
    json_output = JSON.parse(terraform_output)
    alarm_config = json_output.dig("resource", "aws_cloudwatch_metric_alarm", "traffic_anomaly")
    
    expect(alarm_config["alarm_name"]).to eq("unusual-traffic-pattern")
    expect(alarm_config["comparison_operator"]).to eq("LessThanLowerOrGreaterThanUpperThreshold")
    expect(alarm_config["evaluation_periods"]).to eq(2)
    expect(alarm_config["threshold_metric_id"]).to eq("ad1")
    expect(alarm_config).not_to have_key("threshold")
    
    # Check metric query for anomaly detection
    metric_queries = alarm_config["metric_query"]
    ad_query = metric_queries.find { |q| q["id"] == "ad1" }
    expect(ad_query["expression"]).to eq("ANOMALY_DETECTION_BAND(m1, 2)")
  end

  # Test alarm with extended statistic synthesis
  it "synthesizes alarm with extended statistic correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_metric_alarm(:p95_latency, {
        alarm_name: "high-p95-latency",
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: 3,
        metric_name: "TargetResponseTime",
        namespace: "AWS/ApplicationELB",
        period: 300,
        extended_statistic: "p95",
        threshold: 2.0,
        alarm_actions: [sns_topic_arn]
      })
    end
    
    json_output = JSON.parse(terraform_output)
    alarm_config = json_output.dig("resource", "aws_cloudwatch_metric_alarm", "p95_latency")
    
    expect(alarm_config["alarm_name"]).to eq("high-p95-latency")
    expect(alarm_config["extended_statistic"]).to eq("p95")
    expect(alarm_config).not_to have_key("statistic")
    expect(alarm_config["threshold"]).to eq(2.0)
  end

  # Test alarm with datapoints_to_alarm synthesis
  it "synthesizes alarm with datapoints_to_alarm correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_metric_alarm(:datapoints_alarm, {
        alarm_name: "burst-detection",
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: 5,
        datapoints_to_alarm: 3,
        metric_name: "CPUUtilization",
        namespace: "AWS/EC2",
        period: 60,
        statistic: "Average",
        threshold: 90.0,
        alarm_actions: [sns_topic_arn]
      })
    end
    
    json_output = JSON.parse(terraform_output)
    alarm_config = json_output.dig("resource", "aws_cloudwatch_metric_alarm", "datapoints_alarm")
    
    expect(alarm_config["alarm_name"]).to eq("burst-detection")
    expect(alarm_config["evaluation_periods"]).to eq(5)
    expect(alarm_config["datapoints_to_alarm"]).to eq(3)
    expect(alarm_config["threshold"]).to eq(90.0)
  end

  # Test alarm with custom treat_missing_data synthesis
  it "synthesizes alarm with custom treat_missing_data correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_metric_alarm(:missing_data_alarm, {
        alarm_name: "intermittent-metric",
        comparison_operator: "LessThanThreshold",
        evaluation_periods: 3,
        metric_name: "CustomMetric",
        namespace: "MyApp/Metrics",
        period: 300,
        statistic: "Sum",
        threshold: 10.0,
        treat_missing_data: "ignore",
        alarm_actions: [sns_topic_arn]
      })
    end
    
    json_output = JSON.parse(terraform_output)
    alarm_config = json_output.dig("resource", "aws_cloudwatch_metric_alarm", "missing_data_alarm")
    
    expect(alarm_config["alarm_name"]).to eq("intermittent-metric")
    expect(alarm_config["treat_missing_data"]).to eq("ignore")
    expect(alarm_config["threshold"]).to eq(10.0)
  end

  # Test alarm with multiple action types synthesis
  it "synthesizes alarm with multiple action types correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_metric_alarm(:multi_action_alarm, {
        alarm_name: "comprehensive-monitoring",
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: 2,
        metric_name: "CPUUtilization",
        namespace: "AWS/EC2",
        period: 300,
        statistic: "Average",
        threshold: 80.0,
        alarm_actions: [
          "arn:aws:sns:us-east-1:123456789012:critical-alerts",
          "arn:aws:sns:us-east-1:123456789012:team-alerts"
        ],
        ok_actions: [
          "arn:aws:sns:us-east-1:123456789012:recovery-alerts"
        ],
        insufficient_data_actions: [
          "arn:aws:sns:us-east-1:123456789012:data-alerts"
        ]
      })
    end
    
    json_output = JSON.parse(terraform_output)
    alarm_config = json_output.dig("resource", "aws_cloudwatch_metric_alarm", "multi_action_alarm")
    
    expect(alarm_config["alarm_actions"]).to eq([
      "arn:aws:sns:us-east-1:123456789012:critical-alerts",
      "arn:aws:sns:us-east-1:123456789012:team-alerts"
    ])
    expect(alarm_config["ok_actions"]).to eq([
      "arn:aws:sns:us-east-1:123456789012:recovery-alerts"
    ])
    expect(alarm_config["insufficient_data_actions"]).to eq([
      "arn:aws:sns:us-east-1:123456789012:data-alerts"
    ])
  end

  # Test alarm with tags synthesis
  it "synthesizes alarm with tags correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_metric_alarm(:tagged_alarm, {
        alarm_name: "production-cpu-alarm",
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: 2,
        metric_name: "CPUUtilization",
        namespace: "AWS/EC2",
        period: 300,
        statistic: "Average",
        threshold: 80.0,
        tags: {
          Environment: "production",
          Service: "web-app",
          AlertType: "cpu",
          Severity: "warning"
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    alarm_config = json_output.dig("resource", "aws_cloudwatch_metric_alarm", "tagged_alarm")
    
    expect(alarm_config["alarm_name"]).to eq("production-cpu-alarm")
    
    # Check tags block
    tags_config = alarm_config["tags"]
    expect(tags_config).not_to be_nil
    expect(tags_config["Environment"]).to eq("production")
    expect(tags_config["Service"]).to eq("web-app")
    expect(tags_config["AlertType"]).to eq("cpu")
    expect(tags_config["Severity"]).to eq("warning")
  end

  # Test Auto Scaling trigger alarm synthesis
  it "synthesizes Auto Scaling trigger alarm correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_metric_alarm(:asg_scale_up, {
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
    end
    
    json_output = JSON.parse(terraform_output)
    alarm_config = json_output.dig("resource", "aws_cloudwatch_metric_alarm", "asg_scale_up")
    
    expect(alarm_config["alarm_name"]).to eq("asg-scale-up-trigger")
    expect(alarm_config["threshold"]).to eq(70.0)
    expect(alarm_config["dimensions"]["AutoScalingGroupName"]).to eq("web-server-asg")
    expect(alarm_config["alarm_actions"]).to include("arn:aws:autoscaling:us-east-1:123456789012:scalingPolicy:policy-id")
  end

  # Test RDS database alarm synthesis
  it "synthesizes RDS database alarm correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_metric_alarm(:rds_connections, {
        alarm_name: "database-connection-count",
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: 2,
        metric_name: "DatabaseConnections",
        namespace: "AWS/RDS",
        period: 300,
        statistic: "Average",
        threshold: 80,
        alarm_actions: [sns_topic_arn],
        dimensions: {
          DBInstanceIdentifier: "production-db"
        },
        treat_missing_data: "notBreaching"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    alarm_config = json_output.dig("resource", "aws_cloudwatch_metric_alarm", "rds_connections")
    
    expect(alarm_config["alarm_name"]).to eq("database-connection-count")
    expect(alarm_config["namespace"]).to eq("AWS/RDS")
    expect(alarm_config["metric_name"]).to eq("DatabaseConnections")
    expect(alarm_config["dimensions"]["DBInstanceIdentifier"]).to eq("production-db")
    expect(alarm_config["treat_missing_data"]).to eq("notBreaching")
  end

  # Test Lambda function alarm synthesis
  it "synthesizes Lambda function alarm correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_metric_alarm(:lambda_errors, {
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
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    alarm_config = json_output.dig("resource", "aws_cloudwatch_metric_alarm", "lambda_errors")
    
    expect(alarm_config["namespace"]).to eq("AWS/Lambda")
    expect(alarm_config["metric_name"]).to eq("Errors")
    expect(alarm_config["dimensions"]["FunctionName"]).to eq("data-processor")
    expect(alarm_config["threshold"]).to eq(5)
  end

  # Test DynamoDB alarm synthesis
  it "synthesizes DynamoDB alarm correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_metric_alarm(:dynamo_throttles, {
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
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    alarm_config = json_output.dig("resource", "aws_cloudwatch_metric_alarm", "dynamo_throttles")
    
    expect(alarm_config["namespace"]).to eq("AWS/DynamoDB")
    expect(alarm_config["metric_name"]).to eq("ThrottledRequests")
    expect(alarm_config["dimensions"]["TableName"]).to eq("user-sessions")
    expect(alarm_config["threshold"]).to eq(0)
  end

  # Test SQS queue alarm synthesis
  it "synthesizes SQS queue alarm correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_metric_alarm(:sqs_depth, {
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
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    alarm_config = json_output.dig("resource", "aws_cloudwatch_metric_alarm", "sqs_depth")
    
    expect(alarm_config["namespace"]).to eq("AWS/SQS")
    expect(alarm_config["metric_name"]).to eq("ApproximateNumberOfVisibleMessages")
    expect(alarm_config["dimensions"]["QueueName"]).to eq("processing-queue")
    expect(alarm_config["threshold"]).to eq(100)
  end

  # Test alarm without optional fields (should not appear in terraform)
  it "synthesizes minimal alarm without optional fields" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_metric_alarm(:minimal_alarm, {
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: 1,
        metric_name: "CPUUtilization",
        namespace: "AWS/EC2",
        period: 300,
        statistic: "Average",
        threshold: 80.0
      })
    end
    
    json_output = JSON.parse(terraform_output)
    alarm_config = json_output.dig("resource", "aws_cloudwatch_metric_alarm", "minimal_alarm")
    
    expect(alarm_config["comparison_operator"]).to eq("GreaterThanThreshold")
    expect(alarm_config["evaluation_periods"]).to eq(1)
    expect(alarm_config["metric_name"]).to eq("CPUUtilization")
    expect(alarm_config["namespace"]).to eq("AWS/EC2")
    expect(alarm_config["period"]).to eq(300)
    expect(alarm_config["statistic"]).to eq("Average")
    expect(alarm_config["threshold"]).to eq(80.0)
    expect(alarm_config["actions_enabled"]).to eq(true)
    expect(alarm_config["treat_missing_data"]).to eq("missing")
    
    # Optional fields should not appear
    expect(alarm_config).not_to have_key("alarm_name")
    expect(alarm_config).not_to have_key("alarm_description")
    expect(alarm_config).not_to have_key("alarm_actions")
    expect(alarm_config).not_to have_key("ok_actions")
    expect(alarm_config).not_to have_key("insufficient_data_actions")
    expect(alarm_config).not_to have_key("datapoints_to_alarm")
    expect(alarm_config).not_to have_key("tags")
  end

  # Test complex metric math with cross-service metrics synthesis
  it "synthesizes complex cross-service metric math alarm correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_metric_alarm(:end_to_end_latency, {
        alarm_name: "total-request-latency",
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: 3,
        threshold: 5000.0, # 5 seconds total
        metric_query: [
          {
            id: "total_latency",
            expression: "m1+m2+m3",
            label: "Total Request Latency (ms)",
            return_data: true
          },
          {
            id: "m1", # ALB latency
            metric: {
              metric_name: "TargetResponseTime",
              namespace: "AWS/ApplicationELB",
              period: 300,
              stat: "Average",
              dimensions: {
                LoadBalancer: "app/web-app/1234567890"
              }
            }
          },
          {
            id: "m2", # Lambda duration
            metric: {
              metric_name: "Duration",
              namespace: "AWS/Lambda",
              period: 300,
              stat: "Average",
              dimensions: {
                FunctionName: "request-processor"
              }
            }
          },
          {
            id: "m3", # RDS latency
            metric: {
              metric_name: "ReadLatency",
              namespace: "AWS/RDS",
              period: 300,
              stat: "Average",
              dimensions: {
                DBInstanceIdentifier: "production-db"
              }
            }
          }
        ]
      })
    end
    
    json_output = JSON.parse(terraform_output)
    alarm_config = json_output.dig("resource", "aws_cloudwatch_metric_alarm", "end_to_end_latency")
    
    expect(alarm_config["alarm_name"]).to eq("total-request-latency")
    expect(alarm_config["threshold"]).to eq(5000.0)
    
    metric_queries = alarm_config["metric_query"]
    expect(metric_queries.length).to eq(4)
    
    # Check expression query
    total_latency_query = metric_queries.find { |q| q["id"] == "total_latency" }
    expect(total_latency_query["expression"]).to eq("m1+m2+m3")
    expect(total_latency_query["label"]).to eq("Total Request Latency (ms)")
    expect(total_latency_query["return_data"]).to eq(true)
    
    # Check individual metric queries have correct dimensions
    alb_query = metric_queries.find { |q| q["id"] == "m1" }
    expect(alb_query["metric"]["namespace"]).to eq("AWS/ApplicationELB")
    expect(alb_query["metric"]["dimensions"]["LoadBalancer"]).to eq("app/web-app/1234567890")
    
    lambda_query = metric_queries.find { |q| q["id"] == "m2" }
    expect(lambda_query["metric"]["namespace"]).to eq("AWS/Lambda")
    expect(lambda_query["metric"]["dimensions"]["FunctionName"]).to eq("request-processor")
    
    rds_query = metric_queries.find { |q| q["id"] == "m3" }
    expect(rds_query["metric"]["namespace"]).to eq("AWS/RDS")
    expect(rds_query["metric"]["dimensions"]["DBInstanceIdentifier"]).to eq("production-db")
  end
  
  # Test alarm with evaluate_low_sample_count_percentile synthesis
  it "synthesizes alarm with evaluate_low_sample_count_percentile correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_metric_alarm(:low_sample_alarm, {
        alarm_name: "low-sample-percentile",
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: 2,
        metric_name: "TargetResponseTime",
        namespace: "AWS/ApplicationELB",
        period: 300,
        extended_statistic: "p99",
        threshold: 3.0,
        evaluate_low_sample_count_percentile: "evaluate",
        alarm_actions: [sns_topic_arn]
      })
    end
    
    json_output = JSON.parse(terraform_output)
    alarm_config = json_output.dig("resource", "aws_cloudwatch_metric_alarm", "low_sample_alarm")
    
    expect(alarm_config["alarm_name"]).to eq("low-sample-percentile")
    expect(alarm_config["extended_statistic"]).to eq("p99")
    expect(alarm_config["evaluate_low_sample_count_percentile"]).to eq("evaluate")
    expect(alarm_config["threshold"]).to eq(3.0)
  end
end