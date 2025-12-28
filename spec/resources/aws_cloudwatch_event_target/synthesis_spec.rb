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
require 'pangea/resources/aws_cloudwatch_event_target/resource'

RSpec.describe "aws_cloudwatch_event_target synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON for a Lambda target" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_event_target(:lambda_processor, {
          rule: "hourly-task",
          arn: "arn:aws:lambda:us-east-1:123456789012:function:ProcessorFunction"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_cloudwatch_event_target")
      expect(result["resource"]["aws_cloudwatch_event_target"]).to have_key("lambda_processor")

      config = result["resource"]["aws_cloudwatch_event_target"]["lambda_processor"]
      expect(config["rule"]).to eq("hourly-task")
      expect(config["arn"]).to eq("arn:aws:lambda:us-east-1:123456789012:function:ProcessorFunction")
    end

    it "generates valid terraform JSON for an SNS target" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_event_target(:sns_notification, {
          rule: "alert-rule",
          arn: "arn:aws:sns:us-east-1:123456789012:alerts-topic"
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_cloudwatch_event_target"]["sns_notification"]

      expect(config["arn"]).to eq("arn:aws:sns:us-east-1:123456789012:alerts-topic")
    end

    it "supports target_id when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_event_target(:target_with_id, {
          rule: "my-rule",
          arn: "arn:aws:lambda:us-east-1:123456789012:function:MyFunction",
          target_id: "my-custom-target-id"
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_cloudwatch_event_target"]["target_with_id"]

      expect(config["target_id"]).to eq("my-custom-target-id")
    end

    it "supports input transformation" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_event_target(:transformed_target, {
          rule: "event-rule",
          arn: "arn:aws:sns:us-east-1:123456789012:topic",
          input_transformer: {
            input_paths_map: {
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
        aws_cloudwatch_event_target(:retrying_target, {
          rule: "my-rule",
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
        aws_cloudwatch_event_target(:dlq_target, {
          rule: "my-rule",
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

    it "supports custom event bus" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_event_target(:custom_bus_target, {
          rule: "my-rule",
          arn: "arn:aws:lambda:us-east-1:123456789012:function:MyFunction",
          event_bus_name: "my-custom-bus"
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_cloudwatch_event_target"]["custom_bus_target"]

      expect(config["event_bus_name"]).to eq("my-custom-bus")
    end

    it "supports ECS target configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_event_target(:ecs_target, {
          rule: "scheduled-task",
          arn: "arn:aws:ecs:us-east-1:123456789012:cluster/my-cluster",
          role_arn: "arn:aws:iam::123456789012:role/ecs-events-role",
          ecs_target: {
            task_definition_arn: "arn:aws:ecs:us-east-1:123456789012:task-definition/my-task:1",
            task_count: 1,
            launch_type: "FARGATE",
            network_configuration: {
              awsvpc_configuration: {
                subnets: ["subnet-12345678"],
                security_groups: ["sg-12345678"],
                assign_public_ip: "ENABLED"
              }
            }
          }
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_cloudwatch_event_target"]["ecs_target"]

      expect(config).to have_key("ecs_target")
      expect(config["role_arn"]).to eq("arn:aws:iam::123456789012:role/ecs-events-role")
    end

    it "supports role_arn for cross-account targets" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_event_target(:cross_account_target, {
          rule: "my-rule",
          arn: "arn:aws:sqs:us-east-1:999999999999:cross-account-queue",
          role_arn: "arn:aws:iam::123456789012:role/cross-account-role"
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_cloudwatch_event_target"]["cross_account_target"]

      expect(config["role_arn"]).to eq("arn:aws:iam::123456789012:role/cross-account-role")
    end
  end

  describe "resource reference" do
    it "returns a reference with expected outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_cloudwatch_event_target(:ref_test, {
          rule: "test-rule",
          arn: "arn:aws:lambda:us-east-1:123456789012:function:TestFunction"
        })
      end

      expect(ref).not_to be_nil
      expect(ref.type).to eq('aws_cloudwatch_event_target')
      expect(ref.name).to eq(:ref_test)
      expect(ref.outputs[:id]).to eq("${aws_cloudwatch_event_target.ref_test.id}")
      expect(ref.outputs[:arn]).to eq("${aws_cloudwatch_event_target.ref_test.arn}")
      expect(ref.outputs[:rule]).to eq("${aws_cloudwatch_event_target.ref_test.rule}")
    end

    it "includes computed properties" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_cloudwatch_event_target(:computed_test, {
          rule: "test-rule",
          arn: "arn:aws:lambda:us-east-1:123456789012:function:TestFunction"
        })
      end

      expect(ref.computed_properties[:target_service]).to eq(:lambda)
      expect(ref.computed_properties[:requires_role]).to eq(false)
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_event_target(:validation_test, {
          rule: "validation-rule",
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
      expect(config).to have_key("arn")
    end
  end
end
