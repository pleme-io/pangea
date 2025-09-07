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

# Load aws_sns_topic resource and types for testing
require 'pangea/resources/aws_sns_topic/resource'
require 'pangea/resources/aws_sns_topic/types'

RSpec.describe "aws_sns_topic resource function" do
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
  let(:feedback_role_arn) { "arn:aws:iam::123456789012:role/sns-feedback-role" }
  let(:kms_key_arn) { "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012" }
  
  describe "SNSTopicAttributes validation" do
    it "accepts basic standard topic configuration" do
      attrs = Pangea::Resources::AWS::Types::SNSTopicAttributes.new({
        name: "notifications"
      })
      
      expect(attrs.name).to eq("notifications")
      expect(attrs.fifo_topic).to eq(false)
      expect(attrs.content_based_deduplication).to eq(false)
      expect(attrs.is_fifo?).to eq(false)
      expect(attrs.topic_type).to eq("Standard")
    end
    
    it "accepts FIFO topic configuration" do
      attrs = Pangea::Resources::AWS::Types::SNSTopicAttributes.new({
        name: "orders.fifo",
        fifo_topic: true,
        content_based_deduplication: true
      })
      
      expect(attrs.name).to eq("orders.fifo")
      expect(attrs.fifo_topic).to eq(true)
      expect(attrs.content_based_deduplication).to eq(true)
      expect(attrs.is_fifo?).to eq(true)
      expect(attrs.topic_type).to eq("FIFO")
    end
    
    it "accepts topic without name (auto-generated)" do
      attrs = Pangea::Resources::AWS::Types::SNSTopicAttributes.new({})
      
      expect(attrs.name).to be_nil
      expect(attrs.fifo_topic).to eq(false)
      expect(attrs.topic_type).to eq("Standard")
    end
    
    it "accepts topic with display name" do
      attrs = Pangea::Resources::AWS::Types::SNSTopicAttributes.new({
        name: "alerts",
        display_name: "Critical Alerts Topic"
      })
      
      expect(attrs.display_name).to eq("Critical Alerts Topic")
    end
    
    it "accepts KMS encryption configuration" do
      attrs = Pangea::Resources::AWS::Types::SNSTopicAttributes.new({
        name: "encrypted-topic",
        kms_master_key_id: kms_key_arn
      })
      
      expect(attrs.kms_master_key_id).to eq(kms_key_arn)
      expect(attrs.is_encrypted?).to eq(true)
    end
    
    it "accepts delivery policy configuration" do
      delivery_policy = JSON.generate({
        "http" => {
          "defaultHealthyRetryPolicy" => {
            "minDelayTarget" => 20,
            "maxDelayTarget" => 20,
            "numRetries" => 3
          }
        }
      })
      
      attrs = Pangea::Resources::AWS::Types::SNSTopicAttributes.new({
        name: "reliable-topic",
        delivery_policy: delivery_policy
      })
      
      expect(attrs.delivery_policy).to eq(delivery_policy)
      expect(attrs.has_delivery_policy?).to eq(true)
    end
    
    it "accepts access policy configuration" do
      access_policy = JSON.generate({
        "Version" => "2012-10-17",
        "Statement" => [{
          "Effect" => "Allow",
          "Principal" => { "AWS" => "*" },
          "Action" => "SNS:Publish",
          "Resource" => "arn:aws:sns:us-east-1:123456789012:my-topic"
        }]
      })
      
      attrs = Pangea::Resources::AWS::Types::SNSTopicAttributes.new({
        name: "public-topic",
        policy: access_policy
      })
      
      expect(attrs.policy).to eq(access_policy)
      expect(attrs.has_access_policy?).to eq(true)
    end
    
    it "accepts message data protection policy" do
      data_protection_policy = JSON.generate({
        "Name" => "block-pii",
        "Description" => "Block PII data",
        "Statement" => [{
          "Sid" => "BlockCreditCards",
          "DataIdentifier" => ["arn:aws:dataprotection::aws:data-identifier/CreditCardNumber"],
          "Operation" => {
            "Deny" => {}
          }
        }]
      })
      
      attrs = Pangea::Resources::AWS::Types::SNSTopicAttributes.new({
        name: "protected-topic",
        message_data_protection_policy: data_protection_policy
      })
      
      expect(attrs.message_data_protection_policy).to eq(data_protection_policy)
      expect(attrs.has_data_protection?).to eq(true)
    end
    
    it "accepts application feedback configuration" do
      attrs = Pangea::Resources::AWS::Types::SNSTopicAttributes.new({
        name: "mobile-push",
        application_success_feedback_role_arn: feedback_role_arn,
        application_success_feedback_sample_rate: 100,
        application_failure_feedback_role_arn: feedback_role_arn
      })
      
      expect(attrs.application_success_feedback_role_arn).to eq(feedback_role_arn)
      expect(attrs.application_success_feedback_sample_rate).to eq(100)
      expect(attrs.application_failure_feedback_role_arn).to eq(feedback_role_arn)
      expect(attrs.has_feedback_enabled?).to eq(true)
      expect(attrs.feedback_protocols).to include("application")
    end
    
    it "accepts HTTP feedback configuration" do
      attrs = Pangea::Resources::AWS::Types::SNSTopicAttributes.new({
        name: "webhook-topic",
        http_success_feedback_role_arn: feedback_role_arn,
        http_success_feedback_sample_rate: 50,
        http_failure_feedback_role_arn: feedback_role_arn
      })
      
      expect(attrs.http_success_feedback_role_arn).to eq(feedback_role_arn)
      expect(attrs.http_success_feedback_sample_rate).to eq(50)
      expect(attrs.has_feedback_enabled?).to eq(true)
      expect(attrs.feedback_protocols).to include("http")
    end
    
    it "accepts Lambda feedback configuration" do
      attrs = Pangea::Resources::AWS::Types::SNSTopicAttributes.new({
        name: "lambda-triggers",
        lambda_success_feedback_role_arn: feedback_role_arn,
        lambda_success_feedback_sample_rate: 25,
        lambda_failure_feedback_role_arn: feedback_role_arn
      })
      
      expect(attrs.lambda_success_feedback_role_arn).to eq(feedback_role_arn)
      expect(attrs.lambda_success_feedback_sample_rate).to eq(25)
      expect(attrs.has_feedback_enabled?).to eq(true)
      expect(attrs.feedback_protocols).to include("lambda")
    end
    
    it "accepts SQS feedback configuration" do
      attrs = Pangea::Resources::AWS::Types::SNSTopicAttributes.new({
        name: "queue-fanout",
        sqs_success_feedback_role_arn: feedback_role_arn,
        sqs_success_feedback_sample_rate: 75,
        sqs_failure_feedback_role_arn: feedback_role_arn
      })
      
      expect(attrs.sqs_success_feedback_role_arn).to eq(feedback_role_arn)
      expect(attrs.sqs_success_feedback_sample_rate).to eq(75)
      expect(attrs.has_feedback_enabled?).to eq(true)
      expect(attrs.feedback_protocols).to include("sqs")
    end
    
    it "accepts Firehose feedback configuration" do
      attrs = Pangea::Resources::AWS::Types::SNSTopicAttributes.new({
        name: "analytics-stream",
        firehose_success_feedback_role_arn: feedback_role_arn,
        firehose_success_feedback_sample_rate: 100,
        firehose_failure_feedback_role_arn: feedback_role_arn
      })
      
      expect(attrs.firehose_success_feedback_role_arn).to eq(feedback_role_arn)
      expect(attrs.firehose_success_feedback_sample_rate).to eq(100)
      expect(attrs.has_feedback_enabled?).to eq(true)
      expect(attrs.feedback_protocols).to include("firehose")
    end
    
    it "accepts X-Ray tracing configuration" do
      attrs = Pangea::Resources::AWS::Types::SNSTopicAttributes.new({
        name: "traced-topic",
        tracing_config: "Active"
      })
      
      expect(attrs.tracing_config).to eq("Active")
      expect(attrs.tracing_enabled?).to eq(true)
    end
    
    it "accepts comprehensive tags configuration" do
      tags = {
        Environment: "production",
        Service: "notifications",
        Team: "platform",
        CostCenter: "engineering"
      }
      
      attrs = Pangea::Resources::AWS::Types::SNSTopicAttributes.new({
        name: "tagged-topic",
        tags: tags
      })
      
      expect(attrs.tags).to eq(tags)
    end
    
    it "accepts multiple feedback protocols simultaneously" do
      attrs = Pangea::Resources::AWS::Types::SNSTopicAttributes.new({
        name: "multi-feedback",
        lambda_success_feedback_role_arn: feedback_role_arn,
        lambda_failure_feedback_role_arn: feedback_role_arn,
        http_success_feedback_role_arn: feedback_role_arn,
        sqs_failure_feedback_role_arn: feedback_role_arn
      })
      
      expect(attrs.has_feedback_enabled?).to eq(true)
      expect(attrs.feedback_protocols).to include("lambda", "http", "sqs")
      expect(attrs.feedback_protocols.size).to eq(3)
    end
    
    it "validates FIFO topic name suffix" do
      expect {
        Pangea::Resources::AWS::Types::SNSTopicAttributes.new({
          name: "invalid-fifo-name", # missing .fifo suffix
          fifo_topic: true
        })
      }.to raise_error(Dry::Struct::Error, /must end with '.fifo'/)
    end
    
    it "validates standard topic name cannot have FIFO suffix" do
      expect {
        Pangea::Resources::AWS::Types::SNSTopicAttributes.new({
          name: "standard-topic.fifo", # cannot have .fifo suffix
          fifo_topic: false
        })
      }.to raise_error(Dry::Struct::Error, /cannot end with '.fifo'/)
    end
    
    it "validates content-based deduplication requires FIFO" do
      expect {
        Pangea::Resources::AWS::Types::SNSTopicAttributes.new({
          name: "standard-topic",
          fifo_topic: false,
          content_based_deduplication: true # only valid for FIFO
        })
      }.to raise_error(Dry::Struct::Error, /only valid for FIFO topics/)
    end
    
    it "validates delivery policy must be valid JSON" do
      expect {
        Pangea::Resources::AWS::Types::SNSTopicAttributes.new({
          name: "policy-topic",
          delivery_policy: "invalid json content"
        })
      }.to raise_error(Dry::Struct::Error, /delivery_policy must be valid JSON/)
    end
    
    it "validates access policy must be valid JSON" do
      expect {
        Pangea::Resources::AWS::Types::SNSTopicAttributes.new({
          name: "access-topic",
          policy: "{ invalid json }"
        })
      }.to raise_error(Dry::Struct::Error, /policy must be valid JSON/)
    end
    
    it "validates data protection policy must be valid JSON" do
      expect {
        Pangea::Resources::AWS::Types::SNSTopicAttributes.new({
          name: "protected-topic",
          message_data_protection_policy: "not json"
        })
      }.to raise_error(Dry::Struct::Error, /message_data_protection_policy must be valid JSON/)
    end
    
    it "validates sample rate requires role ARN" do
      expect {
        Pangea::Resources::AWS::Types::SNSTopicAttributes.new({
          name: "feedback-topic",
          lambda_success_feedback_sample_rate: 50
          # missing lambda_success_feedback_role_arn
        })
      }.to raise_error(Dry::Struct::Error, /requires.*role_arn/)
    end
    
    it "validates feedback sample rate range" do
      expect {
        Pangea::Resources::AWS::Types::SNSTopicAttributes.new({
          name: "rate-topic",
          http_success_feedback_role_arn: feedback_role_arn,
          http_success_feedback_sample_rate: 150 # too high
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates tracing configuration enumeration" do
      expect {
        Pangea::Resources::AWS::Types::SNSTopicAttributes.new({
          name: "tracing-topic",
          tracing_config: "InvalidMode" # not in enum
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "computes properties correctly for standard topic" do
      attrs = Pangea::Resources::AWS::Types::SNSTopicAttributes.new({
        name: "standard-topic",
        display_name: "Standard Notifications"
      })
      
      expect(attrs.is_fifo?).to eq(false)
      expect(attrs.topic_type).to eq("Standard")
      expect(attrs.is_encrypted?).to eq(false)
      expect(attrs.has_delivery_policy?).to eq(false)
      expect(attrs.has_access_policy?).to eq(false)
      expect(attrs.has_data_protection?).to eq(false)
      expect(attrs.has_feedback_enabled?).to eq(false)
      expect(attrs.tracing_enabled?).to eq(false)
      expect(attrs.feedback_protocols).to eq([])
    end
    
    it "computes properties correctly for encrypted FIFO topic" do
      attrs = Pangea::Resources::AWS::Types::SNSTopicAttributes.new({
        name: "secure-orders.fifo",
        fifo_topic: true,
        content_based_deduplication: true,
        kms_master_key_id: kms_key_arn,
        tracing_config: "Active"
      })
      
      expect(attrs.is_fifo?).to eq(true)
      expect(attrs.topic_type).to eq("FIFO")
      expect(attrs.is_encrypted?).to eq(true)
      expect(attrs.tracing_enabled?).to eq(true)
    end
  end
  
  describe "aws_sns_topic function" do
    it "creates basic SNS topic resource reference" do
      result = test_instance.aws_sns_topic(:notifications, {
        name: "app-notifications"
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.type).to eq('aws_sns_topic')
      expect(result.name).to eq(:notifications)
    end
    
    it "returns SNS topic reference with terraform outputs" do
      result = test_instance.aws_sns_topic(:alerts, {
        name: "critical-alerts",
        display_name: "Critical System Alerts"
      })
      
      expect(result.id).to eq("${aws_sns_topic.alerts.id}")
      expect(result.arn).to eq("${aws_sns_topic.alerts.arn}")
      expect(result.name).to eq("${aws_sns_topic.alerts.name}")
      expect(result.owner).to eq("${aws_sns_topic.alerts.owner}")
      expect(result.beginning_archive_time).to eq("${aws_sns_topic.alerts.beginning_archive_time}")
    end
    
    it "returns SNS topic reference with computed properties" do
      result = test_instance.aws_sns_topic(:fifo_topic, {
        name: "orders.fifo",
        fifo_topic: true,
        content_based_deduplication: true,
        kms_master_key_id: kms_key_arn
      })
      
      expect(result.is_fifo?).to eq(true)
      expect(result.topic_type).to eq("FIFO")
      expect(result.is_encrypted?).to eq(true)
      expect(result.has_delivery_policy?).to eq(false)
      expect(result.has_access_policy?).to eq(false)
      expect(result.has_data_protection?).to eq(false)
      expect(result.has_feedback_enabled?).to eq(false)
      expect(result.tracing_enabled?).to eq(false)
    end
    
    it "returns SNS topic reference with feedback properties" do
      result = test_instance.aws_sns_topic(:monitored_topic, {
        name: "monitored-notifications",
        lambda_success_feedback_role_arn: feedback_role_arn,
        lambda_success_feedback_sample_rate: 100,
        lambda_failure_feedback_role_arn: feedback_role_arn,
        http_failure_feedback_role_arn: feedback_role_arn
      })
      
      expect(result.has_feedback_enabled?).to eq(true)
      expect(result.feedback_protocols).to include("lambda", "http")
      expect(result.feedback_protocols.size).to eq(2)
    end
    
    it "returns SNS topic reference with tracing enabled" do
      result = test_instance.aws_sns_topic(:traced_topic, {
        name: "x-ray-traced",
        tracing_config: "Active"
      })
      
      expect(result.tracing_enabled?).to eq(true)
    end
    
    it "returns SNS topic reference with comprehensive configuration" do
      delivery_policy = JSON.generate({ "http" => { "defaultHealthyRetryPolicy" => { "numRetries" => 5 } } })
      access_policy = JSON.generate({ "Version" => "2012-10-17", "Statement" => [] })
      
      result = test_instance.aws_sns_topic(:comprehensive, {
        name: "comprehensive-topic",
        display_name: "Comprehensive Topic Configuration",
        kms_master_key_id: kms_key_arn,
        delivery_policy: delivery_policy,
        policy: access_policy,
        tracing_config: "Active",
        lambda_success_feedback_role_arn: feedback_role_arn,
        sqs_failure_feedback_role_arn: feedback_role_arn,
        tags: {
          Environment: "production",
          Service: "messaging"
        }
      })
      
      expect(result.is_encrypted?).to eq(true)
      expect(result.has_delivery_policy?).to eq(true)
      expect(result.has_access_policy?).to eq(true)
      expect(result.has_feedback_enabled?).to eq(true)
      expect(result.tracing_enabled?).to eq(true)
      expect(result.feedback_protocols).to include("lambda", "sqs")
    end
  end
  
  describe "topic configuration patterns" do
    it "supports mobile push notifications pattern" do
      result = test_instance.aws_sns_topic(:mobile_push, {
        name: "mobile-notifications",
        display_name: "Mobile Push Notifications",
        application_success_feedback_role_arn: feedback_role_arn,
        application_success_feedback_sample_rate: 100,
        application_failure_feedback_role_arn: feedback_role_arn
      })
      
      expect(result.feedback_protocols).to eq(["application"])
      expect(result.has_feedback_enabled?).to eq(true)
    end
    
    it "supports webhook notifications pattern" do
      result = test_instance.aws_sns_topic(:webhooks, {
        name: "webhook-notifications",
        http_success_feedback_role_arn: feedback_role_arn,
        http_success_feedback_sample_rate: 50,
        http_failure_feedback_role_arn: feedback_role_arn
      })
      
      expect(result.feedback_protocols).to eq(["http"])
    end
    
    it "supports fan-out to queues pattern" do
      result = test_instance.aws_sns_topic(:fanout, {
        name: "event-fanout",
        sqs_success_feedback_role_arn: feedback_role_arn,
        sqs_failure_feedback_role_arn: feedback_role_arn
      })
      
      expect(result.feedback_protocols).to eq(["sqs"])
    end
    
    it "supports analytics streaming pattern" do
      result = test_instance.aws_sns_topic(:analytics, {
        name: "analytics-events",
        firehose_success_feedback_role_arn: feedback_role_arn,
        firehose_success_feedback_sample_rate: 100,
        firehose_failure_feedback_role_arn: feedback_role_arn
      })
      
      expect(result.feedback_protocols).to eq(["firehose"])
    end
    
    it "supports secure messaging pattern with encryption and data protection" do
      data_protection = JSON.generate({
        "Name" => "block-sensitive-data",
        "Statement" => [{
          "Sid" => "BlockCreditCards",
          "DataIdentifier" => ["arn:aws:dataprotection::aws:data-identifier/CreditCardNumber"],
          "Operation" => { "Deny" => {} }
        }]
      })
      
      result = test_instance.aws_sns_topic(:secure_messaging, {
        name: "secure-communications",
        kms_master_key_id: kms_key_arn,
        message_data_protection_policy: data_protection
      })
      
      expect(result.is_encrypted?).to eq(true)
      expect(result.has_data_protection?).to eq(true)
    end
  end
  
  describe "validation edge cases" do
    it "rejects empty delivery policy JSON" do
      expect {
        Pangea::Resources::AWS::Types::SNSTopicAttributes.new({
          name: "test-topic",
          delivery_policy: ""
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "rejects malformed JSON policies" do
      expect {
        Pangea::Resources::AWS::Types::SNSTopicAttributes.new({
          name: "test-topic",
          policy: "{ malformed json: }"
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "accepts PassThrough tracing mode" do
      attrs = Pangea::Resources::AWS::Types::SNSTopicAttributes.new({
        name: "passthrough-topic",
        tracing_config: "PassThrough"
      })
      
      expect(attrs.tracing_config).to eq("PassThrough")
      expect(attrs.tracing_enabled?).to eq(false)
    end
    
    it "handles nil values for optional attributes" do
      attrs = Pangea::Resources::AWS::Types::SNSTopicAttributes.new({
        name: nil, # auto-generated
        display_name: nil,
        kms_master_key_id: nil
      })
      
      expect(attrs.name).to be_nil
      expect(attrs.display_name).to be_nil
      expect(attrs.kms_master_key_id).to be_nil
      expect(attrs.is_encrypted?).to eq(false)
    end
    
    it "validates sample rate boundary values" do
      # Test boundary values
      [0, 100].each do |rate|
        attrs = Pangea::Resources::AWS::Types::SNSTopicAttributes.new({
          name: "boundary-test",
          lambda_success_feedback_role_arn: feedback_role_arn,
          lambda_success_feedback_sample_rate: rate
        })
        
        expect(attrs.lambda_success_feedback_sample_rate).to eq(rate)
      end
    end
    
    it "rejects invalid sample rate boundary values" do
      [-1, 101].each do |invalid_rate|
        expect {
          Pangea::Resources::AWS::Types::SNSTopicAttributes.new({
            name: "invalid-rate",
            lambda_success_feedback_role_arn: feedback_role_arn,
            lambda_success_feedback_sample_rate: invalid_rate
          })
        }.to raise_error(Dry::Struct::Error)
      end
    end
  end
end