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
require 'pangea/resources/aws_sfn_state_machine/resource'

RSpec.describe "aws_sfn_state_machine synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  let(:simple_definition) do
    JSON.generate({
      "Comment" => "Simple state machine",
      "StartAt" => "HelloWorld",
      "States" => {
        "HelloWorld" => {
          "Type" => "Task",
          "Resource" => "arn:aws:lambda:us-east-1:123456789012:function:HelloWorld",
          "End" => true
        }
      }
    })
  end

  describe "terraform generation" do
    it "generates valid terraform JSON for a standard state machine" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sfn_state_machine(:test_machine, {
          name: "test-state-machine",
          definition: JSON.generate({
            "Comment" => "Test state machine",
            "StartAt" => "FirstState",
            "States" => {
              "FirstState" => {
                "Type" => "Pass",
                "End" => true
              }
            }
          }),
          role_arn: "arn:aws:iam::123456789012:role/step-functions-role"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_sfn_state_machine")
      expect(result["resource"]["aws_sfn_state_machine"]).to have_key("test_machine")

      config = result["resource"]["aws_sfn_state_machine"]["test_machine"]
      expect(config["name"]).to eq("test-state-machine")
      expect(config["role_arn"]).to eq("arn:aws:iam::123456789012:role/step-functions-role")
    end

    it "supports EXPRESS type state machines" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sfn_state_machine(:express_machine, {
          name: "express-state-machine",
          definition: JSON.generate({
            "Comment" => "Express state machine",
            "StartAt" => "FastTask",
            "States" => {
              "FastTask" => {
                "Type" => "Pass",
                "End" => true
              }
            }
          }),
          role_arn: "arn:aws:iam::123456789012:role/step-functions-role",
          type: "EXPRESS"
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_sfn_state_machine"]["express_machine"]

      expect(config["type"]).to eq("EXPRESS")
    end

    it "includes logging configuration when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sfn_state_machine(:logged_machine, {
          name: "logged-state-machine",
          definition: JSON.generate({
            "Comment" => "Logged state machine",
            "StartAt" => "LoggedTask",
            "States" => {
              "LoggedTask" => {
                "Type" => "Pass",
                "End" => true
              }
            }
          }),
          role_arn: "arn:aws:iam::123456789012:role/step-functions-role",
          logging_configuration: {
            level: "ALL",
            include_execution_data: true,
            destinations: [
              {
                cloud_watch_logs_log_group: {
                  log_group_arn: "arn:aws:logs:us-east-1:123456789012:log-group:/aws/states/test:*"
                }
              }
            ]
          }
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_sfn_state_machine"]["logged_machine"]

      expect(config).to have_key("logging_configuration")
    end

    it "includes tracing configuration when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sfn_state_machine(:traced_machine, {
          name: "traced-state-machine",
          definition: JSON.generate({
            "Comment" => "Traced state machine",
            "StartAt" => "TracedTask",
            "States" => {
              "TracedTask" => {
                "Type" => "Pass",
                "End" => true
              }
            }
          }),
          role_arn: "arn:aws:iam::123456789012:role/step-functions-role",
          tracing_configuration: {
            enabled: true
          }
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_sfn_state_machine"]["traced_machine"]

      expect(config).to have_key("tracing_configuration")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sfn_state_machine(:tagged_machine, {
          name: "tagged-state-machine",
          definition: JSON.generate({
            "Comment" => "Tagged state machine",
            "StartAt" => "TaggedTask",
            "States" => {
              "TaggedTask" => {
                "Type" => "Pass",
                "End" => true
              }
            }
          }),
          role_arn: "arn:aws:iam::123456789012:role/step-functions-role",
          tags: { Name: "tagged-machine", Environment: "test" }
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_sfn_state_machine"]["tagged_machine"]

      expect(config).to have_key("tags")
      expect(config["tags"]["Name"]).to eq("tagged-machine")
      expect(config["tags"]["Environment"]).to eq("test")
    end
  end

  describe "resource reference" do
    it "returns a reference with expected outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_sfn_state_machine(:ref_test, {
          name: "reference-test-machine",
          definition: JSON.generate({
            "Comment" => "Reference test",
            "StartAt" => "RefTask",
            "States" => {
              "RefTask" => {
                "Type" => "Pass",
                "End" => true
              }
            }
          }),
          role_arn: "arn:aws:iam::123456789012:role/step-functions-role"
        })
      end

      expect(ref).not_to be_nil
      expect(ref.type).to eq('aws_sfn_state_machine')
      expect(ref.name).to eq(:ref_test)
      expect(ref.outputs[:arn]).to eq("${aws_sfn_state_machine.ref_test.arn}")
      expect(ref.outputs[:id]).to eq("${aws_sfn_state_machine.ref_test.id}")
      expect(ref.outputs[:name]).to eq("${aws_sfn_state_machine.ref_test.name}")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sfn_state_machine(:validation_test, {
          name: "validation-test-machine",
          definition: JSON.generate({
            "Comment" => "Validation test",
            "StartAt" => "ValidationTask",
            "States" => {
              "ValidationTask" => {
                "Type" => "Pass",
                "End" => true
              }
            }
          }),
          role_arn: "arn:aws:iam::123456789012:role/step-functions-role"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_sfn_state_machine"]).to be_a(Hash)
      expect(result["resource"]["aws_sfn_state_machine"]["validation_test"]).to be_a(Hash)

      # Validate required attributes are present
      config = result["resource"]["aws_sfn_state_machine"]["validation_test"]
      expect(config).to have_key("name")
      expect(config).to have_key("definition")
      expect(config).to have_key("role_arn")
    end
  end
end
