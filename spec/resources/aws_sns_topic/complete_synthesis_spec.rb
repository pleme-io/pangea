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

# Load aws_sns_topic resource and terraform-synthesizer for testing
require 'pangea/resources/aws_sns_topic/resource'
require 'terraform-synthesizer'

RSpec.describe "aws_sns_topic terraform synthesis" do
  let(:synthesizer) { TerraformSynthesizer.new }
  let(:feedback_role_arn) { "arn:aws:iam::123456789012:role/sns-feedback-role" }
  let(:kms_key_arn) { "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012" }

  # Test basic standard topic synthesis
  it "synthesizes basic standard topic correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sns_topic(:notifications, {
        name: "app-notifications",
        display_name: "Application Notifications"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    topic_config = json_output.dig("resource", "aws_sns_topic", "notifications")
    
    expect(topic_config["name"]).to eq("app-notifications")
    expect(topic_config["display_name"]).to eq("Application Notifications")
    expect(topic_config["fifo_topic"]).to eq(false)
    expect(topic_config).not_to have_key("content_based_deduplication")
  end

  # Test FIFO topic synthesis
  it "synthesizes FIFO topic correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sns_topic(:orders, {
        name: "orders.fifo",
        fifo_topic: true,
        content_based_deduplication: true
      })
    end
    
    json_output = JSON.parse(terraform_output)
    topic_config = json_output.dig("resource", "aws_sns_topic", "orders")
    
    expect(topic_config["name"]).to eq("orders.fifo")
    expect(topic_config["fifo_topic"]).to eq(true)
    expect(topic_config["content_based_deduplication"]).to eq(true)
  end

  # Test encrypted topic synthesis
  it "synthesizes encrypted topic correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sns_topic(:secure, {
        name: "secure-notifications",
        kms_master_key_id: kms_key_arn
      })
    end
    
    json_output = JSON.parse(terraform_output)
    topic_config = json_output.dig("resource", "aws_sns_topic", "secure")
    
    expect(topic_config["name"]).to eq("secure-notifications")
    expect(topic_config["kms_master_key_id"]).to eq(kms_key_arn)
  end

  # Test topic with delivery policy synthesis
  it "synthesizes topic with delivery policy correctly" do
    delivery_policy = JSON.generate({
      "http" => {
        "defaultHealthyRetryPolicy" => {
          "minDelayTarget" => 20,
          "maxDelayTarget" => 20,
          "numRetries" => 3
        }
      }
    })
    
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sns_topic(:reliable, {
        name: "reliable-notifications",
        delivery_policy: delivery_policy
      })
    end
    
    json_output = JSON.parse(terraform_output)
    topic_config = json_output.dig("resource", "aws_sns_topic", "reliable")
    
    expect(topic_config["name"]).to eq("reliable-notifications")
    expect(topic_config["delivery_policy"]).to eq(delivery_policy)
  end

  # Test topic with access policy synthesis
  it "synthesizes topic with access policy correctly" do
    access_policy = JSON.generate({
      "Version" => "2012-10-17",
      "Statement" => [{
        "Effect" => "Allow",
        "Principal" => { "AWS" => "*" },
        "Action" => "SNS:Publish",
        "Resource" => "arn:aws:sns:us-east-1:123456789012:public-topic"
      }]
    })
    
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sns_topic(:public, {
        name: "public-topic",
        policy: access_policy
      })
    end
    
    json_output = JSON.parse(terraform_output)
    topic_config = json_output.dig("resource", "aws_sns_topic", "public")
    
    expect(topic_config["name"]).to eq("public-topic")
    expect(topic_config["policy"]).to eq(access_policy)
  end

  # Test topic with data protection policy synthesis
  it "synthesizes topic with data protection policy correctly" do
    data_protection_policy = JSON.generate({
      "Name" => "block-pii",
      "Description" => "Block sensitive data",
      "Statement" => [{
        "Sid" => "BlockCreditCards",
        "DataIdentifier" => ["arn:aws:dataprotection::aws:data-identifier/CreditCardNumber"],
        "Operation" => {
          "Deny" => {}
        }
      }]
    })
    
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sns_topic(:protected, {
        name: "protected-topic",
        message_data_protection_policy: data_protection_policy
      })
    end
    
    json_output = JSON.parse(terraform_output)
    topic_config = json_output.dig("resource", "aws_sns_topic", "protected")
    
    expect(topic_config["name"]).to eq("protected-topic")
    expect(topic_config["message_data_protection_policy"]).to eq(data_protection_policy)
  end

  # Test mobile push topic with application feedback synthesis
  it "synthesizes mobile push topic with application feedback correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sns_topic(:mobile_push, {
        name: "mobile-notifications",
        application_success_feedback_role_arn: feedback_role_arn,
        application_success_feedback_sample_rate: 100,
        application_failure_feedback_role_arn: feedback_role_arn
      })
    end
    
    json_output = JSON.parse(terraform_output)
    topic_config = json_output.dig("resource", "aws_sns_topic", "mobile_push")
    
    expect(topic_config["name"]).to eq("mobile-notifications")
    expect(topic_config["application_success_feedback_role_arn"]).to eq(feedback_role_arn)
    expect(topic_config["application_success_feedback_sample_rate"]).to eq(100)
    expect(topic_config["application_failure_feedback_role_arn"]).to eq(feedback_role_arn)
  end

  # Test webhook topic with HTTP feedback synthesis
  it "synthesizes webhook topic with HTTP feedback correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sns_topic(:webhooks, {
        name: "webhook-notifications",
        http_success_feedback_role_arn: feedback_role_arn,
        http_success_feedback_sample_rate: 50,
        http_failure_feedback_role_arn: feedback_role_arn
      })
    end
    
    json_output = JSON.parse(terraform_output)
    topic_config = json_output.dig("resource", "aws_sns_topic", "webhooks")
    
    expect(topic_config["name"]).to eq("webhook-notifications")
    expect(topic_config["http_success_feedback_role_arn"]).to eq(feedback_role_arn)
    expect(topic_config["http_success_feedback_sample_rate"]).to eq(50)
    expect(topic_config["http_failure_feedback_role_arn"]).to eq(feedback_role_arn)
  end

  # Test Lambda trigger topic synthesis
  it "synthesizes Lambda trigger topic correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sns_topic(:lambda_triggers, {
        name: "lambda-notifications",
        lambda_success_feedback_role_arn: feedback_role_arn,
        lambda_success_feedback_sample_rate: 25,
        lambda_failure_feedback_role_arn: feedback_role_arn
      })
    end
    
    json_output = JSON.parse(terraform_output)
    topic_config = json_output.dig("resource", "aws_sns_topic", "lambda_triggers")
    
    expect(topic_config["name"]).to eq("lambda-notifications")
    expect(topic_config["lambda_success_feedback_role_arn"]).to eq(feedback_role_arn)
    expect(topic_config["lambda_success_feedback_sample_rate"]).to eq(25)
    expect(topic_config["lambda_failure_feedback_role_arn"]).to eq(feedback_role_arn)
  end

  # Test SQS fan-out topic synthesis
  it "synthesizes SQS fan-out topic correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sns_topic(:fanout, {
        name: "event-fanout",
        sqs_success_feedback_role_arn: feedback_role_arn,
        sqs_failure_feedback_role_arn: feedback_role_arn
      })
    end
    
    json_output = JSON.parse(terraform_output)
    topic_config = json_output.dig("resource", "aws_sns_topic", "fanout")
    
    expect(topic_config["name"]).to eq("event-fanout")
    expect(topic_config["sqs_success_feedback_role_arn"]).to eq(feedback_role_arn)
    expect(topic_config["sqs_failure_feedback_role_arn"]).to eq(feedback_role_arn)
  end

  # Test analytics streaming topic synthesis
  it "synthesizes analytics streaming topic correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sns_topic(:analytics, {
        name: "analytics-events",
        firehose_success_feedback_role_arn: feedback_role_arn,
        firehose_success_feedback_sample_rate: 100,
        firehose_failure_feedback_role_arn: feedback_role_arn
      })
    end
    
    json_output = JSON.parse(terraform_output)
    topic_config = json_output.dig("resource", "aws_sns_topic", "analytics")
    
    expect(topic_config["name"]).to eq("analytics-events")
    expect(topic_config["firehose_success_feedback_role_arn"]).to eq(feedback_role_arn)
    expect(topic_config["firehose_success_feedback_sample_rate"]).to eq(100)
    expect(topic_config["firehose_failure_feedback_role_arn"]).to eq(feedback_role_arn)
  end

  # Test X-Ray tracing topic synthesis
  it "synthesizes X-Ray tracing topic correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sns_topic(:traced, {
        name: "traced-notifications",
        tracing_config: "Active"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    topic_config = json_output.dig("resource", "aws_sns_topic", "traced")
    
    expect(topic_config["name"]).to eq("traced-notifications")
    expect(topic_config["tracing_config"]).to eq("Active")
  end

  # Test comprehensive topic configuration synthesis
  it "synthesizes comprehensive topic configuration correctly" do
    delivery_policy = JSON.generate({ "http" => { "defaultHealthyRetryPolicy" => { "numRetries" => 5 } } })
    access_policy = JSON.generate({ "Version" => "2012-10-17", "Statement" => [] })
    
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sns_topic(:comprehensive, {
        name: "comprehensive-topic",
        display_name: "Comprehensive Topic Configuration",
        kms_master_key_id: kms_key_arn,
        delivery_policy: delivery_policy,
        policy: access_policy,
        tracing_config: "Active",
        lambda_success_feedback_role_arn: feedback_role_arn,
        lambda_failure_feedback_role_arn: feedback_role_arn,
        sqs_success_feedback_role_arn: feedback_role_arn,
        tags: {
          Environment: "production",
          Service: "messaging",
          Team: "platform"
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    topic_config = json_output.dig("resource", "aws_sns_topic", "comprehensive")
    
    expect(topic_config["name"]).to eq("comprehensive-topic")
    expect(topic_config["display_name"]).to eq("Comprehensive Topic Configuration")
    expect(topic_config["kms_master_key_id"]).to eq(kms_key_arn)
    expect(topic_config["delivery_policy"]).to eq(delivery_policy)
    expect(topic_config["policy"]).to eq(access_policy)
    expect(topic_config["tracing_config"]).to eq("Active")
    expect(topic_config["lambda_success_feedback_role_arn"]).to eq(feedback_role_arn)
    expect(topic_config["lambda_failure_feedback_role_arn"]).to eq(feedback_role_arn)
    expect(topic_config["sqs_success_feedback_role_arn"]).to eq(feedback_role_arn)
    expect(topic_config["tags"]).to eq({
      "Environment" => "production",
      "Service" => "messaging",
      "Team" => "platform"
    })
  end

  # Test auto-generated topic name synthesis
  it "synthesizes topic without name correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sns_topic(:auto_generated, {})
    end
    
    json_output = JSON.parse(terraform_output)
    topic_config = json_output.dig("resource", "aws_sns_topic", "auto_generated")
    
    expect(topic_config["fifo_topic"]).to eq(false)
    expect(topic_config).not_to have_key("name")
    expect(topic_config).not_to have_key("display_name")
  end

  # Test multi-protocol feedback synthesis
  it "synthesizes multi-protocol feedback correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sns_topic(:multi_feedback, {
        name: "multi-protocol-feedback",
        lambda_success_feedback_role_arn: feedback_role_arn,
        lambda_failure_feedback_role_arn: feedback_role_arn,
        http_success_feedback_role_arn: feedback_role_arn,
        sqs_failure_feedback_role_arn: feedback_role_arn,
        firehose_success_feedback_sample_rate: 75,
        firehose_success_feedback_role_arn: feedback_role_arn
      })
    end
    
    json_output = JSON.parse(terraform_output)
    topic_config = json_output.dig("resource", "aws_sns_topic", "multi_feedback")
    
    expect(topic_config["name"]).to eq("multi-protocol-feedback")
    expect(topic_config["lambda_success_feedback_role_arn"]).to eq(feedback_role_arn)
    expect(topic_config["lambda_failure_feedback_role_arn"]).to eq(feedback_role_arn)
    expect(topic_config["http_success_feedback_role_arn"]).to eq(feedback_role_arn)
    expect(topic_config["sqs_failure_feedback_role_arn"]).to eq(feedback_role_arn)
    expect(topic_config["firehose_success_feedback_sample_rate"]).to eq(75)
    expect(topic_config["firehose_success_feedback_role_arn"]).to eq(feedback_role_arn)
  end

  # Test FIFO topic with encryption and tracing synthesis
  it "synthesizes secure FIFO topic correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sns_topic(:secure_fifo, {
        name: "secure-orders.fifo",
        fifo_topic: true,
        content_based_deduplication: true,
        kms_master_key_id: kms_key_arn,
        tracing_config: "Active"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    topic_config = json_output.dig("resource", "aws_sns_topic", "secure_fifo")
    
    expect(topic_config["name"]).to eq("secure-orders.fifo")
    expect(topic_config["fifo_topic"]).to eq(true)
    expect(topic_config["content_based_deduplication"]).to eq(true)
    expect(topic_config["kms_master_key_id"]).to eq(kms_key_arn)
    expect(topic_config["tracing_config"]).to eq("Active")
  end

  # Test topic with comprehensive tags synthesis
  it "synthesizes topic with comprehensive tags correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sns_topic(:tagged, {
        name: "tagged-topic",
        tags: {
          Environment: "production",
          Service: "notifications",
          Team: "platform",
          CostCenter: "engineering",
          Owner: "devops-team",
          Project: "notification-system"
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    topic_config = json_output.dig("resource", "aws_sns_topic", "tagged")
    
    expect(topic_config["name"]).to eq("tagged-topic")
    expect(topic_config["tags"]).to eq({
      "Environment" => "production",
      "Service" => "notifications",
      "Team" => "platform",
      "CostCenter" => "engineering",
      "Owner" => "devops-team",
      "Project" => "notification-system"
    })
  end

  # Test topic with PassThrough tracing synthesis
  it "synthesizes topic with PassThrough tracing correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sns_topic(:passthrough, {
        name: "passthrough-topic",
        tracing_config: "PassThrough"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    topic_config = json_output.dig("resource", "aws_sns_topic", "passthrough")
    
    expect(topic_config["name"]).to eq("passthrough-topic")
    expect(topic_config["tracing_config"]).to eq("PassThrough")
  end

  # Test minimal topic synthesis (only required fields)
  it "synthesizes minimal topic without optional fields" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sns_topic(:minimal, {
        name: "minimal-topic"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    topic_config = json_output.dig("resource", "aws_sns_topic", "minimal")
    
    expect(topic_config["name"]).to eq("minimal-topic")
    expect(topic_config["fifo_topic"]).to eq(false)
    
    # Optional fields should not be present when not specified
    expect(topic_config).not_to have_key("display_name")
    expect(topic_config).not_to have_key("kms_master_key_id")
    expect(topic_config).not_to have_key("delivery_policy")
    expect(topic_config).not_to have_key("policy")
    expect(topic_config).not_to have_key("message_data_protection_policy")
    expect(topic_config).not_to have_key("tracing_config")
    expect(topic_config).not_to have_key("application_success_feedback_role_arn")
    expect(topic_config).not_to have_key("http_success_feedback_role_arn")
    expect(topic_config).not_to have_key("lambda_success_feedback_role_arn")
    expect(topic_config).not_to have_key("sqs_success_feedback_role_arn")
    expect(topic_config).not_to have_key("firehose_success_feedback_role_arn")
  end

  # Test enterprise messaging pattern synthesis
  it "synthesizes enterprise messaging pattern correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sns_topic(:enterprise, {
        name: "enterprise-events.fifo",
        display_name: "Enterprise Event Bus",
        fifo_topic: true,
        content_based_deduplication: true,
        kms_master_key_id: kms_key_arn,
        lambda_success_feedback_role_arn: feedback_role_arn,
        lambda_failure_feedback_role_arn: feedback_role_arn,
        sqs_success_feedback_role_arn: feedback_role_arn,
        sqs_failure_feedback_role_arn: feedback_role_arn,
        tracing_config: "Active",
        tags: {
          Environment: "production",
          Tier: "messaging",
          Compliance: "pci-dss"
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    topic_config = json_output.dig("resource", "aws_sns_topic", "enterprise")
    
    expect(topic_config["name"]).to eq("enterprise-events.fifo")
    expect(topic_config["display_name"]).to eq("Enterprise Event Bus")
    expect(topic_config["fifo_topic"]).to eq(true)
    expect(topic_config["content_based_deduplication"]).to eq(true)
    expect(topic_config["kms_master_key_id"]).to eq(kms_key_arn)
    expect(topic_config["lambda_success_feedback_role_arn"]).to eq(feedback_role_arn)
    expect(topic_config["lambda_failure_feedback_role_arn"]).to eq(feedback_role_arn)
    expect(topic_config["sqs_success_feedback_role_arn"]).to eq(feedback_role_arn)
    expect(topic_config["sqs_failure_feedback_role_arn"]).to eq(feedback_role_arn)
    expect(topic_config["tracing_config"]).to eq("Active")
    expect(topic_config["tags"]["Environment"]).to eq("production")
    expect(topic_config["tags"]["Tier"]).to eq("messaging")
    expect(topic_config["tags"]["Compliance"]).to eq("pci-dss")
  end

  # Test high-volume monitoring pattern synthesis
  it "synthesizes high-volume monitoring pattern correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sns_topic(:monitoring, {
        name: "system-monitoring",
        display_name: "System Health Monitoring",
        http_failure_feedback_role_arn: feedback_role_arn,
        lambda_failure_feedback_role_arn: feedback_role_arn,
        lambda_success_feedback_sample_rate: 10  # Low sample rate for high volume
      })
    end
    
    json_output = JSON.parse(terraform_output)
    topic_config = json_output.dig("resource", "aws_sns_topic", "monitoring")
    
    expect(topic_config["name"]).to eq("system-monitoring")
    expect(topic_config["display_name"]).to eq("System Health Monitoring")
    expect(topic_config["http_failure_feedback_role_arn"]).to eq(feedback_role_arn)
    expect(topic_config["lambda_failure_feedback_role_arn"]).to eq(feedback_role_arn)
    expect(topic_config["lambda_success_feedback_sample_rate"]).to eq(10)
  end

  # Test data compliance pattern synthesis
  it "synthesizes data compliance pattern correctly" do
    data_protection = JSON.generate({
      "Name" => "compliance-protection",
      "Description" => "Block PII and sensitive data",
      "Statement" => [
        {
          "Sid" => "BlockCreditCards",
          "DataIdentifier" => ["arn:aws:dataprotection::aws:data-identifier/CreditCardNumber"],
          "Operation" => { "Deny" => {} }
        },
        {
          "Sid" => "AuditSSN",
          "DataIdentifier" => ["arn:aws:dataprotection::aws:data-identifier/SocialSecurityNumber"],
          "Operation" => { "Audit" => { "FindingsDestination" => "cloudwatch-logs" } }
        }
      ]
    })
    
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sns_topic(:compliance, {
        name: "compliance-notifications",
        display_name: "Compliance Audit Events",
        kms_master_key_id: kms_key_arn,
        message_data_protection_policy: data_protection,
        tracing_config: "Active",
        tags: {
          Environment: "production",
          DataClassification: "sensitive",
          ComplianceFramework: "sox"
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    topic_config = json_output.dig("resource", "aws_sns_topic", "compliance")
    
    expect(topic_config["name"]).to eq("compliance-notifications")
    expect(topic_config["display_name"]).to eq("Compliance Audit Events")
    expect(topic_config["kms_master_key_id"]).to eq(kms_key_arn)
    expect(topic_config["message_data_protection_policy"]).to eq(data_protection)
    expect(topic_config["tracing_config"]).to eq("Active")
    expect(topic_config["tags"]["DataClassification"]).to eq("sensitive")
    expect(topic_config["tags"]["ComplianceFramework"]).to eq("sox")
  end
end