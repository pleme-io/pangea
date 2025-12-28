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
require 'pangea/resources/aws_glue_trigger/resource'

RSpec.describe "aws_glue_trigger synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON for scheduled trigger" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_trigger(:test, {
          name: "scheduled_trigger",
          type: "SCHEDULED",
          schedule: "cron(0 12 * * ? *)",
          actions: [
            { job_name: "etl_job" }
          ]
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_glue_trigger")
      expect(result["resource"]["aws_glue_trigger"]).to have_key("test")
    end

    it "includes type and schedule for scheduled triggers" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_trigger(:test, {
          name: "hourly_trigger",
          type: "SCHEDULED",
          schedule: "rate(1 hour)",
          actions: [
            { job_name: "hourly_job" }
          ]
        })
      end

      result = synthesizer.synthesis
      trigger_config = result["resource"]["aws_glue_trigger"]["test"]

      expect(trigger_config["type"]).to eq("SCHEDULED")
      expect(trigger_config["schedule"]).to eq("rate(1 hour)")
    end

    it "generates valid terraform JSON for on-demand trigger" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_trigger(:test, {
          name: "on_demand_trigger",
          type: "ON_DEMAND",
          actions: [
            { job_name: "manual_job" }
          ]
        })
      end

      result = synthesizer.synthesis
      trigger_config = result["resource"]["aws_glue_trigger"]["test"]

      expect(trigger_config["type"]).to eq("ON_DEMAND")
    end

    it "generates valid terraform JSON for conditional trigger" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_trigger(:test, {
          name: "conditional_trigger",
          type: "CONDITIONAL",
          actions: [
            { job_name: "downstream_job" }
          ],
          predicate: {
            logical: "AND",
            conditions: [
              { job_name: "upstream_job", state: "SUCCEEDED" }
            ]
          }
        })
      end

      result = synthesizer.synthesis
      trigger_config = result["resource"]["aws_glue_trigger"]["test"]

      expect(trigger_config["type"]).to eq("CONDITIONAL")
      expect(trigger_config).to have_key("predicate")
    end

    it "includes actions block" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_trigger(:test, {
          name: "multi_action_trigger",
          type: "ON_DEMAND",
          actions: [
            { job_name: "first_job", timeout: 120 },
            { job_name: "second_job" }
          ]
        })
      end

      result = synthesizer.synthesis
      trigger_config = result["resource"]["aws_glue_trigger"]["test"]

      expect(trigger_config).to have_key("actions")
    end

    it "supports crawler actions" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_trigger(:test, {
          name: "crawler_trigger",
          type: "ON_DEMAND",
          actions: [
            { crawler_name: "my_crawler" }
          ]
        })
      end

      result = synthesizer.synthesis
      trigger_config = result["resource"]["aws_glue_trigger"]["test"]

      expect(trigger_config).to have_key("actions")
    end

    it "supports enabled flag" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_trigger(:test, {
          name: "disabled_trigger",
          type: "ON_DEMAND",
          enabled: false,
          actions: [
            { job_name: "disabled_job" }
          ]
        })
      end

      result = synthesizer.synthesis
      trigger_config = result["resource"]["aws_glue_trigger"]["test"]

      expect(trigger_config["enabled"]).to eq(false)
    end

    it "supports workflow_name" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_trigger(:test, {
          name: "workflow_trigger",
          type: "ON_DEMAND",
          workflow_name: "my_workflow",
          actions: [
            { job_name: "workflow_job" }
          ]
        })
      end

      result = synthesizer.synthesis
      trigger_config = result["resource"]["aws_glue_trigger"]["test"]

      expect(trigger_config["workflow_name"]).to eq("my_workflow")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_trigger(:test, {
          name: "tagged_trigger",
          type: "ON_DEMAND",
          actions: [
            { job_name: "tagged_job" }
          ],
          tags: { Name: "etl-trigger", Environment: "production" }
        })
      end

      result = synthesizer.synthesis
      trigger_config = result["resource"]["aws_glue_trigger"]["test"]

      expect(trigger_config).to have_key("tags")
      expect(trigger_config["tags"]["Name"]).to eq("etl-trigger")
      expect(trigger_config["tags"]["Environment"]).to eq("production")
    end

    it "supports start_on_creation for scheduled triggers" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_trigger(:test, {
          name: "immediate_trigger",
          type: "SCHEDULED",
          schedule: "rate(1 day)",
          start_on_creation: true,
          actions: [
            { job_name: "daily_job" }
          ]
        })
      end

      result = synthesizer.synthesis
      trigger_config = result["resource"]["aws_glue_trigger"]["test"]

      expect(trigger_config["start_on_creation"]).to eq(true)
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_trigger(:test, {
          name: "valid_trigger",
          type: "ON_DEMAND",
          actions: [
            { job_name: "valid_job" }
          ]
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_glue_trigger"]).to be_a(Hash)
      expect(result["resource"]["aws_glue_trigger"]["test"]).to be_a(Hash)
    end
  end

  describe "resource references" do
    it "returns a resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_glue_trigger(:test, {
          name: "ref_test_trigger",
          type: "ON_DEMAND",
          actions: [
            { job_name: "ref_job" }
          ]
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq("${aws_glue_trigger.test.id}")
      expect(ref.outputs[:name]).to eq("${aws_glue_trigger.test.name}")
      expect(ref.outputs[:arn]).to eq("${aws_glue_trigger.test.arn}")
    end

    it "returns computed properties for scheduled triggers" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_glue_trigger(:test, {
          name: "hourly_trigger",
          type: "SCHEDULED",
          schedule: "rate(1 hour)",
          actions: [
            { job_name: "hourly_job" }
          ]
        })
      end

      expect(ref.computed_properties[:is_scheduled]).to eq(true)
      expect(ref.computed_properties[:is_conditional]).to eq(false)
      expect(ref.computed_properties[:is_on_demand]).to eq(false)
    end

    it "returns computed properties for conditional triggers" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_glue_trigger(:test, {
          name: "conditional_trigger",
          type: "CONDITIONAL",
          actions: [
            { job_name: "downstream_job" }
          ],
          predicate: {
            logical: "AND",
            conditions: [
              { job_name: "upstream_job", state: "SUCCEEDED" }
            ]
          }
        })
      end

      expect(ref.computed_properties[:is_conditional]).to eq(true)
      expect(ref.computed_properties[:condition_count]).to eq(1)
    end

    it "returns action counts in computed properties" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_glue_trigger(:test, {
          name: "multi_action",
          type: "ON_DEMAND",
          actions: [
            { job_name: "job1" },
            { job_name: "job2" },
            { crawler_name: "crawler1" }
          ]
        })
      end

      expect(ref.computed_properties[:total_actions]).to eq(3)
      expect(ref.computed_properties[:job_actions_count]).to eq(2)
      expect(ref.computed_properties[:crawler_actions_count]).to eq(1)
    end
  end
end
