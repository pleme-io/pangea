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
require 'terraform-synthesizer'
require 'pangea/resources/aws_eventbridge_target/resource'

RSpec.describe "aws_eventbridge_target synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON for a Lambda target" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eventbridge_target(:lambda_target, {
          rule: "my-rule",
          target_id: "lambda-processor",
          arn: "arn:aws:lambda:us-east-1:123456789012:function:ProcessorFunction"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_cloudwatch_event_target")
      expect(result["resource"]["aws_cloudwatch_event_target"]).to have_key("lambda_target")

      config = result["resource"]["aws_cloudwatch_event_target"]["lambda_target"]
      expect(config["rule"]).to eq("my-rule")
      expect(config["target_id"]).to eq("lambda-processor")
      expect(config["arn"]).to eq("arn:aws:lambda:us-east-1:123456789012:function:ProcessorFunction")
    end

    it "generates valid terraform JSON for an SNS target" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eventbridge_target(:sns_target, {
          rule: "alert-rule",
          target_id: "sns-notification",
          arn: "arn:aws:sns:us-east-1:123456789012:alerts-topic"
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_cloudwatch_event_target"]["sns_target"]

      expect(config["arn"]).to eq("arn:aws:sns:us-east-1:123456789012:alerts-topic")
    end

    it "generates valid terraform JSON for an SQS target" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eventbridge_target(:sqs_target, {
          rule: "queue-rule",
          target_id: "sqs-processor",
          arn: "arn:aws:sqs:us-east-1:123456789012:my-queue"
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_cloudwatch_event_target"]["sqs_target"]

      expect(config["arn"]).to eq("arn:aws:sqs:us-east-1:123456789012:my-queue")
    end

    it "supports custom event bus" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eventbridge_target(:custom_bus_target, {
          rule: "my-rule",
          target_id: "custom-bus-target",
          arn: "arn:aws:lambda:us-east-1:123456789012:function:MyFunction",
          event_bus_name: "my-custom-bus"
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_cloudwatch_event_target"]["custom_bus_target"]

      expect(config["event_bus_name"]).to eq("my-custom-bus")
    end

    it "supports input transformation" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eventbridge_target(:transformed_target, {
          rule: "event-rule",
          target_id: "transformed-target",
          arn: "arn:aws:sns:us-east-1:123456789012:topic",
          input_transformer: {
            input_paths: {
              "instance" => "$.detail.instance",
              "status" => "$.detail.status"
            },
            input_template: '"Instance <instance> is now <status>"'
          }
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_cloudwatch_event_target"]["transformed_target"]

      expect(config).to have_key("input_transformer")
    end

    it "supports retry policy" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eventbridge_target(:retrying_target, {
          rule: "my-rule",
          target_id: "retrying-target",
          arn: "arn:aws:lambda:us-east-1:123456789012:function:MyFunction",
          retry_policy: {
            maximum_retry_attempts: 3,
            maximum_event_age_in_seconds: 3600
          }
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_cloudwatch_event_target"]["retrying_target"]

      expect(config).to have_key("retry_policy")
    end

    it "supports dead letter configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eventbridge_target(:dlq_target, {
          rule: "my-rule",
          target_id: "dlq-target",
          arn: "arn:aws:lambda:us-east-1:123456789012:function:MyFunction",
          dead_letter_config: {
            arn: "arn:aws:sqs:us-east-1:123456789012:dlq"
          }
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_cloudwatch_event_target"]["dlq_target"]

      expect(config).to have_key("dead_letter_config")
    end

    it "supports Kinesis target with role_arn" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eventbridge_target(:kinesis_target, {
          rule: "stream-rule",
          target_id: "kinesis-target",
          arn: "arn:aws:kinesis:us-east-1:123456789012:stream/my-stream",
          role_arn: "arn:aws:iam::123456789012:role/kinesis-role",
          kinesis_parameters: {
            partition_key_path: "$.detail.id"
          }
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_cloudwatch_event_target"]["kinesis_target"]

      expect(config["role_arn"]).to eq("arn:aws:iam::123456789012:role/kinesis-role")
      expect(config).to have_key("kinesis_parameters")
    end

    it "supports ECS target configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eventbridge_target(:ecs_target, {
          rule: "scheduled-task",
          target_id: "ecs-task",
          arn: "arn:aws:ecs:us-east-1:123456789012:cluster/my-cluster",
          role_arn: "arn:aws:iam::123456789012:role/ecs-events-role",
          ecs_parameters: {
            task_definition_arn: "arn:aws:ecs:us-east-1:123456789012:task-definition/my-task:1",
            task_count: 1,
            launch_type: "FARGATE",
            network_configuration: {
              awsvpc_configuration: {
                subnets: ["subnet-12345678"],
                security_groups: ["sg-12345678"],
                assign_public_ip: "DISABLED"
              }
            }
          }
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_cloudwatch_event_target"]["ecs_target"]

      expect(config).to have_key("ecs_parameters")
      expect(config["role_arn"]).to eq("arn:aws:iam::123456789012:role/ecs-events-role")
    end

    it "supports Batch target configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eventbridge_target(:batch_target, {
          rule: "batch-rule",
          target_id: "batch-job",
          arn: "arn:aws:batch:us-east-1:123456789012:job-queue/my-queue",
          role_arn: "arn:aws:iam::123456789012:role/batch-events-role",
          batch_parameters: {
            job_definition: "arn:aws:batch:us-east-1:123456789012:job-definition/my-job:1",
            job_name: "my-batch-job"
          }
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_cloudwatch_event_target"]["batch_target"]

      expect(config).to have_key("batch_parameters")
      expect(config["role_arn"]).to eq("arn:aws:iam::123456789012:role/batch-events-role")
    end

    it "supports SQS FIFO queue with message group ID" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eventbridge_target(:fifo_target, {
          rule: "fifo-rule",
          target_id: "fifo-queue",
          arn: "arn:aws:sqs:us-east-1:123456789012:my-queue.fifo",
          sqs_parameters: {
            message_group_id: "default-group"
          }
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_cloudwatch_event_target"]["fifo_target"]

      expect(config).to have_key("sqs_parameters")
    end
  end

  describe "resource reference" do
    it "returns a reference with expected outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_eventbridge_target(:ref_test, {
          rule: "test-rule",
          target_id: "test-target",
          arn: "arn:aws:lambda:us-east-1:123456789012:function:TestFunction"
        })
      end

      expect(ref).not_to be_nil
      expect(ref.type).to eq('aws_cloudwatch_event_target')
      expect(ref.name).to eq(:ref_test)
      expect(ref.outputs[:id]).to eq("${aws_cloudwatch_event_target.ref_test.id}")
      expect(ref.outputs[:arn]).to eq("${aws_cloudwatch_event_target.ref_test.arn}")
      expect(ref.outputs[:rule]).to eq("${aws_cloudwatch_event_target.ref_test.rule}")
      expect(ref.outputs[:target_id]).to eq("${aws_cloudwatch_event_target.ref_test.target_id}")
    end

    it "includes computed properties for Lambda target" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_eventbridge_target(:lambda_ref, {
          rule: "test-rule",
          target_id: "lambda-ref",
          arn: "arn:aws:lambda:us-east-1:123456789012:function:TestFunction"
        })
      end

      expect(ref.computed_properties[:target_type]).to eq("lambda")
      expect(ref.computed_properties[:is_lambda_target]).to eq(true)
      expect(ref.computed_properties[:uses_default_bus]).to eq(true)
    end

    it "includes computed properties for SQS target" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_eventbridge_target(:sqs_ref, {
          rule: "test-rule",
          target_id: "sqs-ref",
          arn: "arn:aws:sqs:us-east-1:123456789012:my-queue"
        })
      end

      expect(ref.computed_properties[:target_type]).to eq("sqs")
      expect(ref.computed_properties[:is_sqs_target]).to eq(true)
    end

    it "includes reliability features in computed properties" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_eventbridge_target(:reliable_ref, {
          rule: "test-rule",
          target_id: "reliable-ref",
          arn: "arn:aws:lambda:us-east-1:123456789012:function:TestFunction",
          retry_policy: {
            maximum_retry_attempts: 5,
            maximum_event_age_in_seconds: 7200
          },
          dead_letter_config: {
            arn: "arn:aws:sqs:us-east-1:123456789012:dlq"
          }
        })
      end

      expect(ref.computed_properties[:has_retry_policy]).to eq(true)
      expect(ref.computed_properties[:has_dead_letter_queue]).to eq(true)
      expect(ref.computed_properties[:max_retry_attempts]).to eq(5)
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eventbridge_target(:validation_test, {
          rule: "validation-rule",
          target_id: "validation-target",
          arn: "arn:aws:lambda:us-east-1:123456789012:function:ValidationFunction"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_cloudwatch_event_target"]).to be_a(Hash)
      expect(result["resource"]["aws_cloudwatch_event_target"]["validation_test"]).to be_a(Hash)

      # Validate required attributes are present
      config = result["resource"]["aws_cloudwatch_event_target"]["validation_test"]
      expect(config).to have_key("rule")
      expect(config).to have_key("target_id")
      expect(config).to have_key("arn")
    end
  end
end
