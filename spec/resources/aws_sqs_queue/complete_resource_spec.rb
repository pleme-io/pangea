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

# Load aws_sqs_queue resource and types for testing
require 'pangea/resources/aws_sqs_queue/resource'
require 'pangea/resources/aws_sqs_queue/types'

RSpec.describe "aws_sqs_queue resource function" do
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
  let(:dlq_arn) { "arn:aws:sqs:us-east-1:123456789012:my-dlq" }
  let(:kms_key_arn) { "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012" }
  
  describe "SQSQueueAttributes validation" do
    it "accepts basic standard queue configuration" do
      attrs = Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
        name: "standard-queue"
      })
      
      expect(attrs.name).to eq("standard-queue")
      expect(attrs.fifo_queue).to eq(false)
      expect(attrs.queue_type).to eq("Standard")
      expect(attrs.is_fifo?).to eq(false)
      expect(attrs.visibility_timeout_seconds).to eq(30)
      expect(attrs.message_retention_seconds).to eq(345600) # 4 days
      expect(attrs.max_message_size).to eq(262144) # 256KB
      expect(attrs.delay_seconds).to eq(0)
      expect(attrs.receive_wait_time_seconds).to eq(0)
    end
    
    it "accepts FIFO queue configuration" do
      attrs = Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
        name: "orders.fifo",
        fifo_queue: true,
        content_based_deduplication: true,
        deduplication_scope: "messageGroup",
        fifo_throughput_limit: "perMessageGroupId"
      })
      
      expect(attrs.name).to eq("orders.fifo")
      expect(attrs.fifo_queue).to eq(true)
      expect(attrs.queue_type).to eq("FIFO")
      expect(attrs.is_fifo?).to eq(true)
      expect(attrs.content_based_deduplication).to eq(true)
      expect(attrs.deduplication_scope).to eq("messageGroup")
      expect(attrs.fifo_throughput_limit).to eq("perMessageGroupId")
    end
    
    it "accepts custom timeout and retention configuration" do
      attrs = Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
        name: "custom-queue",
        visibility_timeout_seconds: 300,      # 5 minutes
        message_retention_seconds: 1209600,   # 14 days max
        max_message_size: 65536,              # 64KB
        delay_seconds: 300,                   # 5 minutes delay
        receive_wait_time_seconds: 20         # Long polling enabled
      })
      
      expect(attrs.visibility_timeout_seconds).to eq(300)
      expect(attrs.message_retention_seconds).to eq(1209600)
      expect(attrs.max_message_size).to eq(65536)
      expect(attrs.delay_seconds).to eq(300)
      expect(attrs.receive_wait_time_seconds).to eq(20)
      expect(attrs.long_polling_enabled?).to eq(true)
      expect(attrs.is_delay_queue?).to eq(true)
    end
    
    it "accepts dead letter queue configuration" do
      attrs = Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
        name: "main-queue",
        redrive_policy: {
          deadLetterTargetArn: dlq_arn,
          maxReceiveCount: 5
        }
      })
      
      expect(attrs.redrive_policy[:deadLetterTargetArn]).to eq(dlq_arn)
      expect(attrs.redrive_policy[:maxReceiveCount]).to eq(5)
      expect(attrs.has_dlq?).to eq(true)
    end
    
    it "accepts redrive allow policy configuration" do
      source_queue_arns = [
        "arn:aws:sqs:us-east-1:123456789012:source-queue-1",
        "arn:aws:sqs:us-east-1:123456789012:source-queue-2"
      ]
      
      attrs = Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
        name: "dlq",
        redrive_allow_policy: {
          redrivePermission: "byQueue",
          sourceQueueArns: source_queue_arns
        }
      })
      
      expect(attrs.redrive_allow_policy[:redrivePermission]).to eq("byQueue")
      expect(attrs.redrive_allow_policy[:sourceQueueArns]).to eq(source_queue_arns)
      expect(attrs.allows_all_sources?).to eq(false)
    end
    
    it "accepts KMS encryption configuration" do
      attrs = Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
        name: "encrypted-queue",
        kms_master_key_id: kms_key_arn,
        kms_data_key_reuse_period_seconds: 3600  # 1 hour
      })
      
      expect(attrs.kms_master_key_id).to eq(kms_key_arn)
      expect(attrs.kms_data_key_reuse_period_seconds).to eq(3600)
      expect(attrs.is_encrypted?).to eq(true)
      expect(attrs.encryption_type).to eq("KMS")
    end
    
    it "accepts SQS-managed SSE configuration" do
      attrs = Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
        name: "sse-queue",
        sqs_managed_sse_enabled: true
      })
      
      expect(attrs.sqs_managed_sse_enabled).to eq(true)
      expect(attrs.is_encrypted?).to eq(true)
      expect(attrs.encryption_type).to eq("SQS-SSE")
    end
    
    it "accepts queue policy configuration" do
      policy = JSON.generate({
        "Version" => "2012-10-17",
        "Statement" => [{
          "Effect" => "Allow",
          "Principal" => { "AWS" => "*" },
          "Action" => "SQS:SendMessage",
          "Resource" => "*"
        }]
      })
      
      attrs = Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
        name: "public-queue",
        policy: policy
      })
      
      expect(attrs.policy).to eq(policy)
    end
    
    it "accepts comprehensive tags configuration" do
      tags = {
        Environment: "production",
        Service: "messaging",
        Team: "platform",
        CostCenter: "engineering"
      }
      
      attrs = Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
        name: "tagged-queue",
        tags: tags
      })
      
      expect(attrs.tags).to eq(tags)
    end
    
    it "validates FIFO queue name suffix" do
      expect {
        Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
          name: "invalid-fifo-name", # missing .fifo suffix
          fifo_queue: true
        })
      }.to raise_error(Dry::Struct::Error, /must end with '.fifo'/)
    end
    
    it "validates standard queue name cannot have FIFO suffix" do
      expect {
        Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
          name: "standard-queue.fifo", # cannot have .fifo suffix
          fifo_queue: false
        })
      }.to raise_error(Dry::Struct::Error, /cannot end with '.fifo'/)
    end
    
    it "validates content-based deduplication requires FIFO" do
      expect {
        Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
          name: "standard-queue",
          fifo_queue: false,
          content_based_deduplication: true # only valid for FIFO
        })
      }.to raise_error(Dry::Struct::Error, /only valid for FIFO queues/)
    end
    
    it "validates deduplication scope requires FIFO" do
      expect {
        Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
          name: "standard-queue",
          fifo_queue: false,
          deduplication_scope: "messageGroup" # only valid for FIFO
        })
      }.to raise_error(Dry::Struct::Error, /only valid for FIFO queues/)
    end
    
    it "validates FIFO throughput limit requires FIFO" do
      expect {
        Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
          name: "standard-queue",
          fifo_queue: false,
          fifo_throughput_limit: "perMessageGroupId" # only valid for FIFO
        })
      }.to raise_error(Dry::Struct::Error, /only valid for FIFO queues/)
    end
    
    it "validates byQueue redrive permission requires source queue ARNs" do
      expect {
        Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
          name: "dlq",
          redrive_allow_policy: {
            redrivePermission: "byQueue"
            # missing sourceQueueArns
          }
        })
      }.to raise_error(Dry::Struct::Error, /sourceQueueArns must be specified/)
    end
    
    it "validates mutual exclusion of KMS and SQS-managed encryption" do
      expect {
        Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
          name: "bad-encryption",
          kms_master_key_id: kms_key_arn,
          sqs_managed_sse_enabled: true
        })
      }.to raise_error(Dry::Struct::Error, /Cannot enable both KMS/)
    end
    
    it "validates visibility timeout range" do
      expect {
        Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
          name: "invalid-timeout",
          visibility_timeout_seconds: 50000 # exceeds 43200
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates message retention range" do
      expect {
        Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
          name: "invalid-retention",
          message_retention_seconds: 30 # less than 60 minimum
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates max message size range" do
      expect {
        Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
          name: "invalid-size",
          max_message_size: 500 # less than 1024 minimum
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates delay seconds range" do
      expect {
        Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
          name: "invalid-delay",
          delay_seconds: 1000 # exceeds 900
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates receive wait time range" do
      expect {
        Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
          name: "invalid-wait",
          receive_wait_time_seconds: 25 # exceeds 20
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates KMS data key reuse period range" do
      expect {
        Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
          name: "invalid-reuse",
          kms_master_key_id: kms_key_arn,
          kms_data_key_reuse_period_seconds: 30 # less than 60 minimum
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates max receive count range in redrive policy" do
      expect {
        Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
          name: "invalid-dlq",
          redrive_policy: {
            deadLetterTargetArn: dlq_arn,
            maxReceiveCount: 1001 # exceeds 1000
          }
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates deduplication scope enumeration" do
      expect {
        Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
          name: "orders.fifo",
          fifo_queue: true,
          deduplication_scope: "invalid" # not in enum
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates FIFO throughput limit enumeration" do
      expect {
        Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
          name: "orders.fifo",
          fifo_queue: true,
          fifo_throughput_limit: "invalid" # not in enum
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates redrive permission enumeration" do
      expect {
        Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
          name: "dlq",
          redrive_allow_policy: {
            redrivePermission: "invalid" # not in enum
          }
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "computes properties correctly for standard queue" do
      attrs = Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
        name: "basic-queue",
        visibility_timeout_seconds: 60,
        receive_wait_time_seconds: 10
      })
      
      expect(attrs.is_fifo?).to eq(false)
      expect(attrs.queue_type).to eq("Standard")
      expect(attrs.is_encrypted?).to eq(false)
      expect(attrs.encryption_type).to eq("None")
      expect(attrs.has_dlq?).to eq(false)
      expect(attrs.long_polling_enabled?).to eq(true)
      expect(attrs.is_delay_queue?).to eq(false)
      expect(attrs.allows_all_sources?).to eq(true)
    end
    
    it "computes properties correctly for encrypted FIFO queue" do
      attrs = Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
        name: "secure-orders.fifo",
        fifo_queue: true,
        content_based_deduplication: true,
        kms_master_key_id: kms_key_arn,
        delay_seconds: 60
      })
      
      expect(attrs.is_fifo?).to eq(true)
      expect(attrs.queue_type).to eq("FIFO")
      expect(attrs.is_encrypted?).to eq(true)
      expect(attrs.encryption_type).to eq("KMS")
      expect(attrs.is_delay_queue?).to eq(true)
    end
    
    it "computes properties correctly for DLQ configuration" do
      attrs = Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
        name: "processing-queue",
        redrive_policy: {
          deadLetterTargetArn: dlq_arn,
          maxReceiveCount: 3
        },
        redrive_allow_policy: {
          redrivePermission: "denyAll"
        }
      })
      
      expect(attrs.has_dlq?).to eq(true)
      expect(attrs.allows_all_sources?).to eq(false)
    end
    
    it "handles boundary values for all numeric constraints" do
      # Test minimum values
      attrs = Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
        name: "boundary-min",
        visibility_timeout_seconds: 0,
        message_retention_seconds: 60,      # minimum
        max_message_size: 1024,             # minimum
        delay_seconds: 0,
        receive_wait_time_seconds: 0,
        kms_master_key_id: kms_key_arn,
        kms_data_key_reuse_period_seconds: 60 # minimum
      })
      
      expect(attrs.visibility_timeout_seconds).to eq(0)
      expect(attrs.message_retention_seconds).to eq(60)
      expect(attrs.max_message_size).to eq(1024)
      expect(attrs.kms_data_key_reuse_period_seconds).to eq(60)
      
      # Test maximum values
      attrs_max = Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
        name: "boundary-max",
        visibility_timeout_seconds: 43200,   # maximum
        message_retention_seconds: 1209600,  # maximum
        max_message_size: 262144,            # maximum
        delay_seconds: 900,                  # maximum
        receive_wait_time_seconds: 20,       # maximum
        kms_master_key_id: kms_key_arn,
        kms_data_key_reuse_period_seconds: 86400 # maximum
      })
      
      expect(attrs_max.visibility_timeout_seconds).to eq(43200)
      expect(attrs_max.message_retention_seconds).to eq(1209600)
      expect(attrs_max.max_message_size).to eq(262144)
      expect(attrs_max.delay_seconds).to eq(900)
      expect(attrs_max.receive_wait_time_seconds).to eq(20)
      expect(attrs_max.kms_data_key_reuse_period_seconds).to eq(86400)
    end
  end
  
  describe "aws_sqs_queue function" do
    it "creates basic SQS queue resource reference" do
      result = test_instance.aws_sqs_queue(:notifications, {
        name: "app-notifications"
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.type).to eq('aws_sqs_queue')
      expect(result.name).to eq(:notifications)
    end
    
    it "returns SQS queue reference with terraform outputs" do
      result = test_instance.aws_sqs_queue(:events, {
        name: "event-queue"
      })
      
      expect(result.id).to eq("${aws_sqs_queue.events.id}")
      expect(result.arn).to eq("${aws_sqs_queue.events.arn}")
      expect(result.url).to eq("${aws_sqs_queue.events.url}")
      expect(result.name).to eq("${aws_sqs_queue.events.name}")
    end
    
    it "returns SQS queue reference with computed properties" do
      result = test_instance.aws_sqs_queue(:fifo_queue, {
        name: "orders.fifo",
        fifo_queue: true,
        content_based_deduplication: true,
        kms_master_key_id: kms_key_arn
      })
      
      expect(result.queue_type).to eq("FIFO")
      expect(result.is_fifo?).to eq(true)
      expect(result.is_encrypted?).to eq(true)
      expect(result.encryption_type).to eq("KMS")
      expect(result.has_dlq?).to eq(false)
      expect(result.long_polling_enabled?).to eq(false)
      expect(result.is_delay_queue?).to eq(false)
      expect(result.allows_all_sources?).to eq(true)
    end
    
    it "returns SQS queue reference with DLQ properties" do
      result = test_instance.aws_sqs_queue(:main_queue, {
        name: "main-processing",
        redrive_policy: {
          deadLetterTargetArn: dlq_arn,
          maxReceiveCount: 3
        },
        receive_wait_time_seconds: 20  # Long polling
      })
      
      expect(result.has_dlq?).to eq(true)
      expect(result.long_polling_enabled?).to eq(true)
      expect(result.allows_all_sources?).to eq(true)
    end
    
    it "returns SQS queue reference with DLQ source restriction" do
      result = test_instance.aws_sqs_queue(:dlq, {
        name: "dead-letter-queue",
        redrive_allow_policy: {
          redrivePermission: "denyAll"
        }
      })
      
      expect(result.allows_all_sources?).to eq(false)
      expect(result.has_dlq?).to eq(false)
    end
    
    it "returns SQS queue reference with delay queue configuration" do
      result = test_instance.aws_sqs_queue(:delayed, {
        name: "delayed-processing",
        delay_seconds: 300,  # 5 minutes
        sqs_managed_sse_enabled: true
      })
      
      expect(result.is_delay_queue?).to eq(true)
      expect(result.is_encrypted?).to eq(true)
      expect(result.encryption_type).to eq("SQS-SSE")
    end
    
    it "returns SQS queue reference with comprehensive configuration" do
      result = test_instance.aws_sqs_queue(:comprehensive, {
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
        redrive_policy: {
          deadLetterTargetArn: dlq_arn,
          maxReceiveCount: 5
        },
        tags: {
          Environment: "production",
          Service: "orders"
        }
      })
      
      expect(result.queue_type).to eq("FIFO")
      expect(result.is_fifo?).to eq(true)
      expect(result.is_encrypted?).to eq(true)
      expect(result.encryption_type).to eq("KMS")
      expect(result.has_dlq?).to eq(true)
      expect(result.long_polling_enabled?).to eq(true)
      expect(result.is_delay_queue?).to eq(true)
      expect(result.allows_all_sources?).to eq(true)
    end
  end
  
  describe "queue configuration patterns" do
    it "supports high-throughput standard queue pattern" do
      result = test_instance.aws_sqs_queue(:high_throughput, {
        name: "high-throughput-queue",
        visibility_timeout_seconds: 120,
        message_retention_seconds: 86400,    # 1 day for fast processing
        receive_wait_time_seconds: 20,       # Long polling for efficiency
        sqs_managed_sse_enabled: true
      })
      
      expect(result.queue_type).to eq("Standard")
      expect(result.long_polling_enabled?).to eq(true)
      expect(result.is_encrypted?).to eq(true)
      expect(result.encryption_type).to eq("SQS-SSE")
    end
    
    it "supports ordered processing FIFO pattern" do
      result = test_instance.aws_sqs_queue(:ordered, {
        name: "ordered-processing.fifo",
        fifo_queue: true,
        content_based_deduplication: true,
        deduplication_scope: "messageGroup",
        fifo_throughput_limit: "perMessageGroupId",
        visibility_timeout_seconds: 600 # 10 minutes for complex processing
      })
      
      expect(result.queue_type).to eq("FIFO")
      expect(result.is_fifo?).to eq(true)
    end
    
    it "supports batch processing pattern with DLQ" do
      dlq_result = test_instance.aws_sqs_queue(:batch_dlq, {
        name: "batch-processing-dlq"
      })
      
      result = test_instance.aws_sqs_queue(:batch_main, {
        name: "batch-processing",
        visibility_timeout_seconds: 900,     # 15 minutes for batch jobs
        message_retention_seconds: 1209600,  # 14 days retention
        redrive_policy: {
          deadLetterTargetArn: dlq_result.arn,
          maxReceiveCount: 3
        }
      })
      
      expect(result.has_dlq?).to eq(true)
    end
    
    it "supports delay queue pattern for scheduled processing" do
      result = test_instance.aws_sqs_queue(:scheduled, {
        name: "scheduled-tasks",
        delay_seconds: 900,                  # 15 minutes delay
        visibility_timeout_seconds: 1800,    # 30 minutes processing
        kms_master_key_id: kms_key_arn
      })
      
      expect(result.is_delay_queue?).to eq(true)
      expect(result.is_encrypted?).to eq(true)
      expect(result.encryption_type).to eq("KMS")
    end
    
    it "supports dead letter queue pattern with source restrictions" do
      source_queue_arns = [
        "arn:aws:sqs:us-east-1:123456789012:source-1",
        "arn:aws:sqs:us-east-1:123456789012:source-2"
      ]
      
      result = test_instance.aws_sqs_queue(:restricted_dlq, {
        name: "restricted-dlq",
        redrive_allow_policy: {
          redrivePermission: "byQueue",
          sourceQueueArns: source_queue_arns
        }
      })
      
      expect(result.allows_all_sources?).to eq(false)
    end
    
    it "supports secure messaging pattern with encryption and policies" do
      policy = JSON.generate({
        "Version" => "2012-10-17",
        "Statement" => [{
          "Effect" => "Allow",
          "Principal" => { "AWS" => "arn:aws:iam::123456789012:role/ProcessorRole" },
          "Action" => ["SQS:SendMessage", "SQS:ReceiveMessage"],
          "Resource" => "*"
        }]
      })
      
      result = test_instance.aws_sqs_queue(:secure, {
        name: "secure-queue",
        kms_master_key_id: kms_key_arn,
        kms_data_key_reuse_period_seconds: 3600,
        policy: policy
      })
      
      expect(result.is_encrypted?).to eq(true)
      expect(result.encryption_type).to eq("KMS")
    end
  end
  
  describe "validation edge cases" do
    it "allows denyAll redrive permission without source queues" do
      attrs = Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
        name: "deny-all-dlq",
        redrive_allow_policy: {
          redrivePermission: "denyAll"
          # sourceQueueArns not required for denyAll
        }
      })
      
      expect(attrs.redrive_allow_policy[:redrivePermission]).to eq("denyAll")
      expect(attrs.allows_all_sources?).to eq(false)
    end
    
    it "allows allowAll redrive permission without source queues" do
      attrs = Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
        name: "allow-all-dlq",
        redrive_allow_policy: {
          redrivePermission: "allowAll"
          # sourceQueueArns not required for allowAll
        }
      })
      
      expect(attrs.redrive_allow_policy[:redrivePermission]).to eq("allowAll")
      expect(attrs.allows_all_sources?).to eq(true)
    end
    
    it "handles nil redrive_allow_policy as allowAll" do
      attrs = Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
        name: "no-redrive-policy"
        # redrive_allow_policy defaults to nil
      })
      
      expect(attrs.redrive_allow_policy).to be_nil
      expect(attrs.allows_all_sources?).to eq(true) # nil means allowAll
    end
    
    it "accepts empty redrive policy hash" do
      attrs = Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
        name: "empty-redrive",
        redrive_policy: nil
      })
      
      expect(attrs.redrive_policy).to be_nil
      expect(attrs.has_dlq?).to eq(false)
    end
    
    it "accepts zero receive wait time (no long polling)" do
      attrs = Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
        name: "no-polling",
        receive_wait_time_seconds: 0
      })
      
      expect(attrs.receive_wait_time_seconds).to eq(0)
      expect(attrs.long_polling_enabled?).to eq(false)
    end
    
    it "accepts zero delay seconds (no delay)" do
      attrs = Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
        name: "no-delay",
        delay_seconds: 0
      })
      
      expect(attrs.delay_seconds).to eq(0)
      expect(attrs.is_delay_queue?).to eq(false)
    end
    
    it "validates byQueue requires non-empty source queue ARNs" do
      expect {
        Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
          name: "empty-sources",
          redrive_allow_policy: {
            redrivePermission: "byQueue",
            sourceQueueArns: [] # empty array not allowed
          }
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "handles FIFO queue with default scope and throughput" do
      attrs = Pangea::Resources::AWS::Types::SQSQueueAttributes.new({
        name: "defaults.fifo",
        fifo_queue: true
        # deduplication_scope and fifo_throughput_limit use defaults
      })
      
      expect(attrs.deduplication_scope).to eq("queue")
      expect(attrs.fifo_throughput_limit).to eq("perQueue")
    end
  end
  
  describe "real-world queue patterns" do
    it "supports e-commerce order processing pattern" do
      result = test_instance.aws_sqs_queue(:orders, {
        name: "order-processing.fifo",
        fifo_queue: true,
        content_based_deduplication: true,
        deduplication_scope: "messageGroup",       # Per customer ordering
        fifo_throughput_limit: "perMessageGroupId", # Higher throughput
        visibility_timeout_seconds: 300,            # 5 minutes processing
        kms_master_key_id: kms_key_arn,
        tags: {
          Service: "ecommerce",
          DataClassification: "sensitive"
        }
      })
      
      expect(result.is_fifo?).to eq(true)
      expect(result.is_encrypted?).to eq(true)
    end
    
    it "supports microservices async communication pattern" do
      result = test_instance.aws_sqs_queue(:async_events, {
        name: "async-events",
        visibility_timeout_seconds: 60,     # Quick processing
        receive_wait_time_seconds: 20,      # Long polling efficiency
        message_retention_seconds: 345600,  # 4 days retention
        sqs_managed_sse_enabled: true,      # Basic encryption
        tags: {
          Pattern: "async-communication",
          Environment: "production"
        }
      })
      
      expect(result.long_polling_enabled?).to eq(true)
      expect(result.encryption_type).to eq("SQS-SSE")
    end
    
    it "supports batch job processing with failure handling" do
      # Create DLQ first
      dlq_result = test_instance.aws_sqs_queue(:batch_dlq, {
        name: "batch-jobs-dlq",
        message_retention_seconds: 1209600  # 14 days for analysis
      })
      
      # Main queue with DLQ
      result = test_instance.aws_sqs_queue(:batch_jobs, {
        name: "batch-jobs",
        visibility_timeout_seconds: 3600,   # 1 hour for batch processing
        message_retention_seconds: 604800,  # 7 days
        max_message_size: 262144,           # Large messages for job data
        redrive_policy: {
          deadLetterTargetArn: dlq_result.arn,
          maxReceiveCount: 3
        },
        kms_master_key_id: kms_key_arn
      })
      
      expect(result.has_dlq?).to eq(true)
      expect(result.is_encrypted?).to eq(true)
    end
    
    it "supports high-frequency event processing with delay" do
      result = test_instance.aws_sqs_queue(:delayed_events, {
        name: "delayed-event-processing",
        delay_seconds: 300,                  # 5 minutes delay for rate limiting
        visibility_timeout_seconds: 180,     # 3 minutes processing
        receive_wait_time_seconds: 20,       # Long polling
        message_retention_seconds: 172800,   # 2 days retention
        sqs_managed_sse_enabled: true
      })
      
      expect(result.is_delay_queue?).to eq(true)
      expect(result.long_polling_enabled?).to eq(true)
      expect(result.encryption_type).to eq("SQS-SSE")
    end
  end
end