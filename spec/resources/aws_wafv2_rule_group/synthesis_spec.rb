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
require 'pangea/resources/aws_wafv2_rule_group/resource'

RSpec.describe "aws_wafv2_rule_group synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON for rule group with geo match" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_wafv2_rule_group(:geo_blocking, {
          name: "geo-blocking-rules",
          scope: "REGIONAL",
          capacity: 50,
          visibility_config: {
            cloudwatch_metrics_enabled: true,
            metric_name: "geo-blocking-metric",
            sampled_requests_enabled: true
          },
          rules: [
            {
              name: "block-countries",
              priority: 1,
              action: { block: {} },
              statement: {
                geo_match_statement: {
                  country_codes: ["CN", "RU"]
                }
              },
              visibility_config: {
                cloudwatch_metrics_enabled: true,
                metric_name: "block-countries-metric",
                sampled_requests_enabled: true
              }
            }
          ],
          tags: { Purpose: "Geo Blocking" }
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_wafv2_rule_group")
      expect(result["resource"]["aws_wafv2_rule_group"]).to have_key("geo_blocking")

      rule_group = result["resource"]["aws_wafv2_rule_group"]["geo_blocking"]
      expect(rule_group["name"]).to eq("geo-blocking-rules")
      expect(rule_group["scope"]).to eq("regional")
      expect(rule_group["capacity"]).to eq(50)
    end

    it "generates rule group with rate based statement" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_wafv2_rule_group(:rate_limiting, {
          name: "rate-limiting-rules",
          scope: "REGIONAL",
          capacity: 100,
          visibility_config: {
            cloudwatch_metrics_enabled: true,
            metric_name: "rate-limiting-metric",
            sampled_requests_enabled: true
          },
          rules: [
            {
              name: "rate-limit-rule",
              priority: 1,
              action: { block: {} },
              statement: {
                rate_based_statement: {
                  limit: 2000,
                  aggregate_key_type: "IP"
                }
              },
              visibility_config: {
                cloudwatch_metrics_enabled: true,
                metric_name: "rate-limit-metric",
                sampled_requests_enabled: true
              }
            }
          ],
          tags: {}
        })
      end

      result = synthesizer.synthesis
      rule_group = result["resource"]["aws_wafv2_rule_group"]["rate_limiting"]

      expect(rule_group["name"]).to eq("rate-limiting-rules")
      expect(rule_group["capacity"]).to eq(100)
    end

    it "generates rule group with byte match statement" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_wafv2_rule_group(:string_matching, {
          name: "string-matching-rules",
          scope: "REGIONAL",
          capacity: 30,
          visibility_config: {
            cloudwatch_metrics_enabled: true,
            metric_name: "string-matching-metric",
            sampled_requests_enabled: true
          },
          rules: [
            {
              name: "block-bad-user-agent",
              priority: 1,
              action: { block: {} },
              statement: {
                byte_match_statement: {
                  field_to_match: {
                    single_header: { name: "user-agent" }
                  },
                  positional_constraint: "CONTAINS",
                  search_string: "BadBot",
                  text_transformations: [
                    { priority: 0, type: "LOWERCASE" }
                  ]
                }
              },
              visibility_config: {
                cloudwatch_metrics_enabled: true,
                metric_name: "block-bad-user-agent-metric",
                sampled_requests_enabled: true
              }
            }
          ],
          tags: {}
        })
      end

      result = synthesizer.synthesis
      rule_group = result["resource"]["aws_wafv2_rule_group"]["string_matching"]

      expect(rule_group["name"]).to eq("string-matching-rules")
    end

    it "includes description when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_wafv2_rule_group(:described_group, {
          name: "described-rule-group",
          description: "A rule group with a description",
          scope: "REGIONAL",
          capacity: 20,
          visibility_config: {
            cloudwatch_metrics_enabled: true,
            metric_name: "described-metric",
            sampled_requests_enabled: true
          },
          rules: [],
          tags: {}
        })
      end

      result = synthesizer.synthesis
      rule_group = result["resource"]["aws_wafv2_rule_group"]["described_group"]

      expect(rule_group).to have_key("description")
      expect(rule_group["description"]).to eq("A rule group with a description")
    end

    it "supports CLOUDFRONT scope" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_wafv2_rule_group(:cloudfront_rules, {
          name: "cloudfront-rules",
          scope: "CLOUDFRONT",
          capacity: 25,
          visibility_config: {
            cloudwatch_metrics_enabled: true,
            metric_name: "cloudfront-metric",
            sampled_requests_enabled: true
          },
          rules: [],
          tags: {}
        })
      end

      result = synthesizer.synthesis
      rule_group = result["resource"]["aws_wafv2_rule_group"]["cloudfront_rules"]

      expect(rule_group["scope"]).to eq("cloudfront")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_wafv2_rule_group(:tagged_rules, {
          name: "tagged-rules",
          scope: "REGIONAL",
          capacity: 10,
          visibility_config: {
            cloudwatch_metrics_enabled: true,
            metric_name: "tagged-metric",
            sampled_requests_enabled: true
          },
          rules: [],
          tags: { Environment: "production", Team: "security" }
        })
      end

      result = synthesizer.synthesis
      rule_group = result["resource"]["aws_wafv2_rule_group"]["tagged_rules"]

      expect(rule_group).to have_key("tags")
      expect(rule_group["tags"]["Environment"]).to eq("production")
    end
  end

  describe "resource references" do
    it "returns a ResourceReference with correct outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_wafv2_rule_group(:ref_test, {
          name: "ref-test-rules",
          scope: "REGIONAL",
          capacity: 10,
          visibility_config: {
            cloudwatch_metrics_enabled: true,
            metric_name: "ref-test-metric",
            sampled_requests_enabled: true
          },
          rules: [],
          tags: {}
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq("${aws_wafv2_rule_group.ref_test.id}")
      expect(ref.outputs[:arn]).to eq("${aws_wafv2_rule_group.ref_test.arn}")
      expect(ref.outputs[:capacity]).to eq("${aws_wafv2_rule_group.ref_test.capacity}")
      expect(ref.outputs[:lock_token]).to eq("${aws_wafv2_rule_group.ref_test.lock_token}")
    end

    it "returns computed properties" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_wafv2_rule_group(:computed_test, {
          name: "computed-test",
          scope: "REGIONAL",
          capacity: 100,
          visibility_config: {
            cloudwatch_metrics_enabled: true,
            metric_name: "computed-metric",
            sampled_requests_enabled: true
          },
          rules: [
            {
              name: "test-rule",
              priority: 1,
              action: { block: {} },
              statement: {
                geo_match_statement: {
                  country_codes: ["CN"]
                }
              },
              visibility_config: {
                cloudwatch_metrics_enabled: true,
                metric_name: "test-rule-metric",
                sampled_requests_enabled: true
              }
            }
          ],
          tags: {}
        })
      end

      expect(ref.computed[:total_rule_count]).to eq(1)
      expect(ref.computed[:has_geo_blocking]).to eq(true)
      expect(ref.computed[:scope]).to eq("REGIONAL")
      expect(ref.computed[:capacity]).to eq(100)
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_wafv2_rule_group(:validation_test, {
          name: "validation-test",
          scope: "REGIONAL",
          capacity: 10,
          visibility_config: {
            cloudwatch_metrics_enabled: true,
            metric_name: "validation-metric",
            sampled_requests_enabled: true
          },
          rules: [],
          tags: {}
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_wafv2_rule_group"]).to be_a(Hash)
      expect(result["resource"]["aws_wafv2_rule_group"]["validation_test"]).to be_a(Hash)

      rule_group = result["resource"]["aws_wafv2_rule_group"]["validation_test"]
      expect(rule_group).to have_key("name")
      expect(rule_group).to have_key("scope")
      expect(rule_group).to have_key("capacity")
      expect(rule_group).to have_key("visibility_config")
    end
  end
end
