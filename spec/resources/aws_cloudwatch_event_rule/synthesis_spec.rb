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
require 'pangea/resources/aws_cloudwatch_event_rule/resource'

RSpec.describe "aws_cloudwatch_event_rule synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON for a scheduled rule" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_event_rule(:hourly_task, {
          name: "hourly-maintenance",
          description: "Triggers hourly maintenance tasks",
          schedule_expression: "rate(1 hour)"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_cloudwatch_event_rule")
      expect(result["resource"]["aws_cloudwatch_event_rule"]).to have_key("hourly_task")

      config = result["resource"]["aws_cloudwatch_event_rule"]["hourly_task"]
      expect(config["name"]).to eq("hourly-maintenance")
      expect(config["description"]).to eq("Triggers hourly maintenance tasks")
      expect(config["schedule_expression"]).to eq("rate(1 hour)")
      expect(config["state"]).to eq("ENABLED")
    end

    it "generates valid terraform JSON for an event pattern rule" do
      event_pattern = JSON.generate({
        "source" => ["aws.ec2"],
        "detail-type" => ["EC2 Instance State-change Notification"],
        "detail" => {
          "state" => ["running", "stopped", "terminated"]
        }
      })

      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_event_rule(:ec2_state_changes, {
          name: "ec2-instance-state-changes",
          description: "Captures EC2 instance state changes",
          event_pattern: event_pattern
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_cloudwatch_event_rule"]["ec2_state_changes"]

      expect(config["name"]).to eq("ec2-instance-state-changes")
      expect(config["event_pattern"]).to eq(event_pattern)
    end

    it "supports cron schedule expressions" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_event_rule(:daily_backup, {
          name: "daily-backup",
          schedule_expression: "cron(0 2 * * ? *)"
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_cloudwatch_event_rule"]["daily_backup"]

      expect(config["schedule_expression"]).to eq("cron(0 2 * * ? *)")
    end

    it "supports disabled state" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_event_rule(:disabled_rule, {
          name: "disabled-rule",
          schedule_expression: "rate(1 day)",
          state: "DISABLED"
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_cloudwatch_event_rule"]["disabled_rule"]

      expect(config["state"]).to eq("DISABLED")
    end

    it "supports custom event bus" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_event_rule(:custom_bus_rule, {
          name: "custom-bus-rule",
          event_bus_name: "my-custom-bus",
          event_pattern: JSON.generate({ "source" => ["myapp.orders"] })
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_cloudwatch_event_rule"]["custom_bus_rule"]

      expect(config["event_bus_name"]).to eq("my-custom-bus")
    end

    it "includes role_arn when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_event_rule(:rule_with_role, {
          name: "rule-with-role",
          schedule_expression: "rate(1 hour)",
          role_arn: "arn:aws:iam::123456789012:role/events-role"
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_cloudwatch_event_rule"]["rule_with_role"]

      expect(config["role_arn"]).to eq("arn:aws:iam::123456789012:role/events-role")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_event_rule(:tagged_rule, {
          name: "tagged-rule",
          schedule_expression: "rate(1 hour)",
          tags: { Name: "tagged-rule", Environment: "test" }
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_cloudwatch_event_rule"]["tagged_rule"]

      expect(config).to have_key("tags")
    end
  end

  describe "resource reference" do
    it "returns a reference with expected outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_cloudwatch_event_rule(:ref_test, {
          name: "reference-test-rule",
          schedule_expression: "rate(1 hour)"
        })
      end

      expect(ref).not_to be_nil
      expect(ref.type).to eq('aws_cloudwatch_event_rule')
      expect(ref.name).to eq(:ref_test)
      expect(ref.outputs[:arn]).to eq("${aws_cloudwatch_event_rule.ref_test.arn}")
      expect(ref.outputs[:id]).to eq("${aws_cloudwatch_event_rule.ref_test.id}")
      expect(ref.outputs[:name]).to eq("${aws_cloudwatch_event_rule.ref_test.name}")
    end

    it "includes computed properties" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_cloudwatch_event_rule(:computed_test, {
          name: "computed-test-rule",
          schedule_expression: "rate(1 hour)"
        })
      end

      expect(ref.computed_properties[:rule_type]).to eq(:scheduled)
      expect(ref.computed_properties[:schedule_type]).to eq(:rate)
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_event_rule(:validation_test, {
          name: "validation-test-rule",
          schedule_expression: "rate(1 hour)"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_cloudwatch_event_rule"]).to be_a(Hash)
      expect(result["resource"]["aws_cloudwatch_event_rule"]["validation_test"]).to be_a(Hash)

      # Validate required attributes are present
      config = result["resource"]["aws_cloudwatch_event_rule"]["validation_test"]
      expect(config).to have_key("name")
      expect(config).to have_key("schedule_expression")
      expect(config).to have_key("state")
    end
  end
end
