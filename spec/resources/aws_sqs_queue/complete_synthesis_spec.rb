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

# Load aws_sqs_queue resource and terraform-synthesizer for testing
require 'pangea/resources/aws_sqs_queue/resource'
require 'terraform-synthesizer'

RSpec.describe "aws_sqs_queue terraform synthesis" do
  let(:synthesizer) { TerraformSynthesizer.new }
  let(:dlq_arn) { "arn:aws:sqs:us-east-1:123456789012:my-dlq" }
  let(:kms_key_arn) { "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012" }

  # Test basic standard queue synthesis
  it "synthesizes basic standard queue correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sqs_queue(:notifications, {
        name: "app-notifications"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    queue_config = json_output.dig("resource", "aws_sqs_queue", "notifications")
    
    expect(queue_config["name"]).to eq("app-notifications")
    expect(queue_config["fifo_queue"]).to eq(false)
    expect(queue_config["visibility_timeout_seconds"]).to eq(30)
    expect(queue_config["message_retention_seconds"]).to eq(345600)
    expect(queue_config["max_message_size"]).to eq(262144)
    expect(queue_config["delay_seconds"]).to eq(0)
    expect(queue_config["receive_wait_time_seconds"]).to eq(0)
  end

  # Test FIFO queue synthesis
  it "synthesizes FIFO queue correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sqs_queue(:orders, {
        name: "orders.fifo",
        fifo_queue: true,
        content_based_deduplication: true,
        deduplication_scope: "messageGroup",
        fifo_throughput_limit: "perMessageGroupId"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    queue_config = json_output.dig("resource", "aws_sqs_queue", "orders")
    
    expect(queue_config["name"]).to eq("orders.fifo")
    expect(queue_config["fifo_queue"]).to eq(true)
    expect(queue_config["content_based_deduplication"]).to eq(true)
    expect(queue_config["deduplication_scope"]).to eq("messageGroup")
    expect(queue_config["fifo_throughput_limit"]).to eq("perMessageGroupId")
  end

  # Test KMS encrypted queue synthesis
  it "synthesizes KMS encrypted queue correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sqs_queue(:secure, {
        name: "secure-queue",
        kms_master_key_id: kms_key_arn,
        kms_data_key_reuse_period_seconds: 3600
      })
    end
    
    json_output = JSON.parse(terraform_output)
    queue_config = json_output.dig("resource", "aws_sqs_queue", "secure")
    
    expect(queue_config["name"]).to eq("secure-queue")
    expect(queue_config["kms_master_key_id"]).to eq(kms_key_arn)
    expect(queue_config["kms_data_key_reuse_period_seconds"]).to eq(3600)
    expect(queue_config).not_to have_key("sqs_managed_sse_enabled")
  end

  # Test SQS-managed SSE queue synthesis
  it "synthesizes SQS-managed SSE queue correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sqs_queue(:sse, {
        name: "sse-queue",
        sqs_managed_sse_enabled: true
      })
    end
    
    json_output = JSON.parse(terraform_output)
    queue_config = json_output.dig("resource", "aws_sqs_queue", "sse")
    
    expect(queue_config["name"]).to eq("sse-queue")
    expect(queue_config["sqs_managed_sse_enabled"]).to eq(true)
    expect(queue_config).not_to have_key("kms_master_key_id")
  end

  # Test queue with DLQ configuration synthesis
  it "synthesizes queue with dead letter queue correctly" do
    redrive_policy = {
      deadLetterTargetArn: dlq_arn,
      maxReceiveCount: 5
    }
    
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sqs_queue(:main, {
        name: "main-processing",
        redrive_policy: redrive_policy
      })
    end
    
    json_output = JSON.parse(terraform_output)
    queue_config = json_output.dig("resource", "aws_sqs_queue", "main")
    
    expect(queue_config["name"]).to eq("main-processing")
    
    parsed_redrive_policy = JSON.parse(queue_config["redrive_policy"])
    expect(parsed_redrive_policy["deadLetterTargetArn"]).to eq(dlq_arn)
    expect(parsed_redrive_policy["maxReceiveCount"]).to eq(5)
  end

  # Test queue with redrive allow policy synthesis
  it "synthesizes queue with redrive allow policy correctly" do
    source_queues = [
      "arn:aws:sqs:us-east-1:123456789012:source-1",
      "arn:aws:sqs:us-east-1:123456789012:source-2"
    ]
    
    redrive_allow_policy = {
      redrivePermission: "byQueue",
      sourceQueueArns: source_queues
    }
    
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sqs_queue(:dlq, {
        name: "restricted-dlq",
        redrive_allow_policy: redrive_allow_policy
      })
    end
    
    json_output = JSON.parse(terraform_output)
    queue_config = json_output.dig("resource", "aws_sqs_queue", "dlq")
    
    expect(queue_config["name"]).to eq("restricted-dlq")
    
    parsed_allow_policy = JSON.parse(queue_config["redrive_allow_policy"])
    expect(parsed_allow_policy["redrivePermission"]).to eq("byQueue")
    expect(parsed_allow_policy["sourceQueueArns"]).to eq(source_queues)
  end

  # Test long polling configuration synthesis
  it "synthesizes long polling queue correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sqs_queue(:polling, {
        name: "long-polling-queue",
        receive_wait_time_seconds: 20,
        visibility_timeout_seconds: 120
      })
    end
    
    json_output = JSON.parse(terraform_output)
    queue_config = json_output.dig("resource", "aws_sqs_queue", "polling")
    
    expect(queue_config["name"]).to eq("long-polling-queue")
    expect(queue_config["receive_wait_time_seconds"]).to eq(20)
    expect(queue_config["visibility_timeout_seconds"]).to eq(120)
  end

  # Test delay queue synthesis
  it "synthesizes delay queue correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sqs_queue(:delayed, {
        name: "delayed-processing",
        delay_seconds: 300,
        visibility_timeout_seconds: 600
      })
    end
    
    json_output = JSON.parse(terraform_output)
    queue_config = json_output.dig("resource", "aws_sqs_queue", "delayed")
    
    expect(queue_config["name"]).to eq("delayed-processing")
    expect(queue_config["delay_seconds"]).to eq(300)
    expect(queue_config["visibility_timeout_seconds"]).to eq(600)
  end

  # Test queue with access policy synthesis
  it "synthesizes queue with access policy correctly" do
    policy = JSON.generate({
      "Version" => "2012-10-17",
      "Statement" => [{
        "Effect" => "Allow",
        "Principal" => { "AWS" => "arn:aws:iam::123456789012:role/ProcessorRole" },
        "Action" => ["SQS:SendMessage", "SQS:ReceiveMessage"],
        "Resource" => "*"
      }]
    })
    
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sqs_queue(:policy_queue, {
        name: "policy-controlled-queue",
        policy: policy
      })
    end
    
    json_output = JSON.parse(terraform_output)
    queue_config = json_output.dig("resource", "aws_sqs_queue", "policy_queue")
    
    expect(queue_config["name"]).to eq("policy-controlled-queue")
    expect(queue_config["policy"]).to eq(policy)
  end

  # Test comprehensive queue configuration synthesis
  it "synthesizes comprehensive queue configuration correctly" do
    redrive_policy = {
      deadLetterTargetArn: dlq_arn,
      maxReceiveCount: 3
    }
    
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sqs_queue(:comprehensive, {
        name: "comprehensive-queue.fifo",
        fifo_queue: true,
        content_based_deduplication: true,
        deduplication_scope: "messageGroup",
        fifo_throughput_limit: "perMessageGroupId",
        visibility_timeout_seconds: 300,
        message_retention_seconds: 1209600,
        max_message_size: 65536,
        delay_seconds: 60,
        receive_wait_time_seconds: 20,
        kms_master_key_id: kms_key_arn,
        kms_data_key_reuse_period_seconds: 3600,
        redrive_policy: redrive_policy,
        tags: {
          Environment: "production",
          Service: "orders",
          Team: "platform"
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    queue_config = json_output.dig("resource", "aws_sqs_queue", "comprehensive")
    
    expect(queue_config["name"]).to eq("comprehensive-queue.fifo")
    expect(queue_config["fifo_queue"]).to eq(true)
    expect(queue_config["content_based_deduplication"]).to eq(true)
    expect(queue_config["deduplication_scope"]).to eq("messageGroup")
    expect(queue_config["fifo_throughput_limit"]).to eq("perMessageGroupId")
    expect(queue_config["visibility_timeout_seconds"]).to eq(300)
    expect(queue_config["message_retention_seconds"]).to eq(1209600)
    expect(queue_config["max_message_size"]).to eq(65536)
    expect(queue_config["delay_seconds"]).to eq(60)
    expect(queue_config["receive_wait_time_seconds"]).to eq(20)
    expect(queue_config["kms_master_key_id"]).to eq(kms_key_arn)
    expect(queue_config["kms_data_key_reuse_period_seconds"]).to eq(3600)
    
    parsed_redrive_policy = JSON.parse(queue_config["redrive_policy"])
    expect(parsed_redrive_policy["deadLetterTargetArn"]).to eq(dlq_arn)
    expect(parsed_redrive_policy["maxReceiveCount"]).to eq(3)
    
    expect(queue_config["tags"]).to eq({
      "Environment" => "production",
      "Service" => "orders",
      "Team" => "platform"
    })
  end

  # Test high-throughput pattern synthesis
  it "synthesizes high-throughput pattern correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sqs_queue(:high_throughput, {
        name: "high-throughput-queue",
        visibility_timeout_seconds: 120,
        message_retention_seconds: 86400,    # 1 day for fast processing
        receive_wait_time_seconds: 20,       # Long polling
        sqs_managed_sse_enabled: true
      })
    end
    
    json_output = JSON.parse(terraform_output)
    queue_config = json_output.dig("resource", "aws_sqs_queue", "high_throughput")
    
    expect(queue_config["name"]).to eq("high-throughput-queue")
    expect(queue_config["visibility_timeout_seconds"]).to eq(120)
    expect(queue_config["message_retention_seconds"]).to eq(86400)
    expect(queue_config["receive_wait_time_seconds"]).to eq(20)
    expect(queue_config["sqs_managed_sse_enabled"]).to eq(true)
  end

  # Test batch processing pattern synthesis
  it "synthesizes batch processing pattern correctly" do
    redrive_policy = {
      deadLetterTargetArn: dlq_arn,
      maxReceiveCount: 3
    }
    
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sqs_queue(:batch_processing, {
        name: "batch-processing",
        visibility_timeout_seconds: 900,     # 15 minutes for batch jobs
        message_retention_seconds: 1209600,  # 14 days retention
        max_message_size: 262144,            # Large messages
        redrive_policy: redrive_policy,
        kms_master_key_id: kms_key_arn
      })
    end
    
    json_output = JSON.parse(terraform_output)
    queue_config = json_output.dig("resource", "aws_sqs_queue", "batch_processing")
    
    expect(queue_config["name"]).to eq("batch-processing")
    expect(queue_config["visibility_timeout_seconds"]).to eq(900)
    expect(queue_config["message_retention_seconds"]).to eq(1209600)
    expect(queue_config["max_message_size"]).to eq(262144)
    expect(queue_config["kms_master_key_id"]).to eq(kms_key_arn)
    
    parsed_redrive_policy = JSON.parse(queue_config["redrive_policy"])
    expect(parsed_redrive_policy["deadLetterTargetArn"]).to eq(dlq_arn)
    expect(parsed_redrive_policy["maxReceiveCount"]).to eq(3)
  end

  # Test DLQ with source restrictions synthesis
  it "synthesizes DLQ with source restrictions correctly" do
    source_queues = [
      "arn:aws:sqs:us-east-1:123456789012:source-1",
      "arn:aws:sqs:us-east-1:123456789012:source-2"
    ]
    
    redrive_allow_policy = {
      redrivePermission: "byQueue",
      sourceQueueArns: source_queues
    }
    
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sqs_queue(:restricted_dlq, {
        name: "restricted-dlq",
        redrive_allow_policy: redrive_allow_policy
      })
    end
    
    json_output = JSON.parse(terraform_output)
    queue_config = json_output.dig("resource", "aws_sqs_queue", "restricted_dlq")
    
    expect(queue_config["name"]).to eq("restricted-dlq")
    
    parsed_allow_policy = JSON.parse(queue_config["redrive_allow_policy"])
    expect(parsed_allow_policy["redrivePermission"]).to eq("byQueue")
    expect(parsed_allow_policy["sourceQueueArns"]).to eq(source_queues)
  end

  # Test delay queue with custom timing synthesis
  it "synthesizes delay queue with custom timing correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sqs_queue(:scheduled, {
        name: "scheduled-tasks",
        delay_seconds: 600,                  # 10 minutes delay
        visibility_timeout_seconds: 1800,    # 30 minutes processing
        message_retention_seconds: 604800     # 7 days retention
      })
    end
    
    json_output = JSON.parse(terraform_output)
    queue_config = json_output.dig("resource", "aws_sqs_queue", "scheduled")
    
    expect(queue_config["name"]).to eq("scheduled-tasks")
    expect(queue_config["delay_seconds"]).to eq(600)
    expect(queue_config["visibility_timeout_seconds"]).to eq(1800)
    expect(queue_config["message_retention_seconds"]).to eq(604800)
  end

  # Test e-commerce order processing pattern synthesis
  it "synthesizes e-commerce order processing pattern correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sqs_queue(:ecommerce_orders, {
        name: "ecommerce-orders.fifo",
        fifo_queue: true,
        content_based_deduplication: true,
        deduplication_scope: "messageGroup",
        fifo_throughput_limit: "perMessageGroupId",
        visibility_timeout_seconds: 300,
        kms_master_key_id: kms_key_arn,
        tags: {
          Service: "ecommerce",
          DataClassification: "sensitive",
          Environment: "production"
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    queue_config = json_output.dig("resource", "aws_sqs_queue", "ecommerce_orders")
    
    expect(queue_config["name"]).to eq("ecommerce-orders.fifo")
    expect(queue_config["fifo_queue"]).to eq(true)
    expect(queue_config["content_based_deduplication"]).to eq(true)
    expect(queue_config["deduplication_scope"]).to eq("messageGroup")
    expect(queue_config["fifo_throughput_limit"]).to eq("perMessageGroupId")
    expect(queue_config["kms_master_key_id"]).to eq(kms_key_arn)
    expect(queue_config["tags"]["Service"]).to eq("ecommerce")
    expect(queue_config["tags"]["DataClassification"]).to eq("sensitive")
  end

  # Test microservices async communication pattern synthesis
  it "synthesizes microservices async pattern correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sqs_queue(:async_events, {
        name: "async-events",
        visibility_timeout_seconds: 60,
        receive_wait_time_seconds: 20,      # Long polling efficiency
        message_retention_seconds: 345600,  # 4 days
        sqs_managed_sse_enabled: true,
        tags: {
          Pattern: "async-communication",
          Environment: "production"
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    queue_config = json_output.dig("resource", "aws_sqs_queue", "async_events")
    
    expect(queue_config["name"]).to eq("async-events")
    expect(queue_config["visibility_timeout_seconds"]).to eq(60)
    expect(queue_config["receive_wait_time_seconds"]).to eq(20)
    expect(queue_config["message_retention_seconds"]).to eq(345600)
    expect(queue_config["sqs_managed_sse_enabled"]).to eq(true)
    expect(queue_config["tags"]["Pattern"]).to eq("async-communication")
  end

  # Test minimal queue configuration synthesis
  it "synthesizes minimal queue without optional fields" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sqs_queue(:minimal, {
        name: "minimal-queue"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    queue_config = json_output.dig("resource", "aws_sqs_queue", "minimal")
    
    expect(queue_config["name"]).to eq("minimal-queue")
    expect(queue_config["fifo_queue"]).to eq(false)
    expect(queue_config["visibility_timeout_seconds"]).to eq(30)
    expect(queue_config["message_retention_seconds"]).to eq(345600)
    expect(queue_config["max_message_size"]).to eq(262144)
    expect(queue_config["delay_seconds"]).to eq(0)
    expect(queue_config["receive_wait_time_seconds"]).to eq(0)
    
    # Optional fields should not be present when not specified
    expect(queue_config).not_to have_key("content_based_deduplication")
    expect(queue_config).not_to have_key("deduplication_scope")
    expect(queue_config).not_to have_key("fifo_throughput_limit")
    expect(queue_config).not_to have_key("kms_master_key_id")
    expect(queue_config).not_to have_key("sqs_managed_sse_enabled")
    expect(queue_config).not_to have_key("redrive_policy")
    expect(queue_config).not_to have_key("redrive_allow_policy")
    expect(queue_config).not_to have_key("policy")
  end

  # Test high-volume event processing synthesis
  it "synthesizes high-volume event processing correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sqs_queue(:high_volume, {
        name: "high-volume-events",
        visibility_timeout_seconds: 30,      # Fast processing
        message_retention_seconds: 172800,   # 2 days retention
        max_message_size: 262144,            # Maximum message size
        receive_wait_time_seconds: 20,       # Long polling
        sqs_managed_sse_enabled: true,
        tags: {
          Environment: "production",
          Tier: "processing",
          Volume: "high"
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    queue_config = json_output.dig("resource", "aws_sqs_queue", "high_volume")
    
    expect(queue_config["name"]).to eq("high-volume-events")
    expect(queue_config["visibility_timeout_seconds"]).to eq(30)
    expect(queue_config["message_retention_seconds"]).to eq(172800)
    expect(queue_config["max_message_size"]).to eq(262144)
    expect(queue_config["receive_wait_time_seconds"]).to eq(20)
    expect(queue_config["sqs_managed_sse_enabled"]).to eq(true)
    expect(queue_config["tags"]["Volume"]).to eq("high")
  end

  # Test enterprise compliance pattern synthesis
  it "synthesizes enterprise compliance pattern correctly" do
    redrive_policy = {
      deadLetterTargetArn: dlq_arn,
      maxReceiveCount: 3
    }
    
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sqs_queue(:enterprise, {
        name: "enterprise-queue",
        visibility_timeout_seconds: 600,
        message_retention_seconds: 1209600,  # Maximum retention
        kms_master_key_id: kms_key_arn,
        kms_data_key_reuse_period_seconds: 86400, # 24 hours
        redrive_policy: redrive_policy,
        tags: {
          Environment: "production",
          Compliance: "pci-dss",
          DataClassification: "restricted",
          Owner: "security-team"
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    queue_config = json_output.dig("resource", "aws_sqs_queue", "enterprise")
    
    expect(queue_config["name"]).to eq("enterprise-queue")
    expect(queue_config["visibility_timeout_seconds"]).to eq(600)
    expect(queue_config["message_retention_seconds"]).to eq(1209600)
    expect(queue_config["kms_master_key_id"]).to eq(kms_key_arn)
    expect(queue_config["kms_data_key_reuse_period_seconds"]).to eq(86400)
    expect(queue_config["tags"]["Compliance"]).to eq("pci-dss")
    expect(queue_config["tags"]["DataClassification"]).to eq("restricted")
    
    parsed_redrive_policy = JSON.parse(queue_config["redrive_policy"])
    expect(parsed_redrive_policy["deadLetterTargetArn"]).to eq(dlq_arn)
  end

  # Test DLQ only configuration synthesis  
  it "synthesizes dead letter queue only correctly" do
    redrive_allow_policy = {
      redrivePermission: "denyAll"
    }
    
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sqs_queue(:dlq_only, {
        name: "processing-dlq",
        message_retention_seconds: 1209600,  # 14 days for debugging
        redrive_allow_policy: redrive_allow_policy,
        tags: {
          Type: "dead-letter-queue",
          Purpose: "failure-analysis"
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    queue_config = json_output.dig("resource", "aws_sqs_queue", "dlq_only")
    
    expect(queue_config["name"]).to eq("processing-dlq")
    expect(queue_config["message_retention_seconds"]).to eq(1209600)
    expect(queue_config["tags"]["Type"]).to eq("dead-letter-queue")
    
    parsed_allow_policy = JSON.parse(queue_config["redrive_allow_policy"])
    expect(parsed_allow_policy["redrivePermission"]).to eq("denyAll")
  end

  # Test queue with comprehensive tags synthesis
  it "synthesizes queue with comprehensive tags correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_sqs_queue(:tagged, {
        name: "tagged-queue",
        tags: {
          Environment: "production",
          Service: "messaging",
          Team: "platform",
          CostCenter: "engineering",
          Owner: "devops-team",
          Project: "notification-system",
          Compliance: "sox"
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    queue_config = json_output.dig("resource", "aws_sqs_queue", "tagged")
    
    expect(queue_config["name"]).to eq("tagged-queue")
    expect(queue_config["tags"]).to eq({
      "Environment" => "production",
      "Service" => "messaging",
      "Team" => "platform",
      "CostCenter" => "engineering",
      "Owner" => "devops-team",
      "Project" => "notification-system",
      "Compliance" => "sox"
    })
  end
end