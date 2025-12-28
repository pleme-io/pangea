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
require 'pangea/resources/aws_wafv2_regex_pattern_set/resource'

RSpec.describe "aws_wafv2_regex_pattern_set synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON for regex pattern set" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_wafv2_regex_pattern_set(:sql_patterns, {
          name: "sql-injection-patterns",
          scope: "REGIONAL",
          regular_expression: [
            { regex_string: "union.*select" },
            { regex_string: "drop.*table" }
          ],
          tags: { Purpose: "SQL Injection Protection" }
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_wafv2_regex_pattern_set")
      expect(result["resource"]["aws_wafv2_regex_pattern_set"]).to have_key("sql_patterns")

      pattern_set = result["resource"]["aws_wafv2_regex_pattern_set"]["sql_patterns"]
      expect(pattern_set["name"]).to eq("sql-injection-patterns")
      expect(pattern_set["scope"]).to eq("REGIONAL")
    end

    it "includes description when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_wafv2_regex_pattern_set(:xss_patterns, {
          name: "xss-patterns",
          description: "Patterns to detect XSS attempts",
          scope: "REGIONAL",
          regular_expression: [
            { regex_string: "script[^>]*>" }
          ],
          tags: {}
        })
      end

      result = synthesizer.synthesis
      pattern_set = result["resource"]["aws_wafv2_regex_pattern_set"]["xss_patterns"]

      expect(pattern_set).to have_key("description")
      expect(pattern_set["description"]).to eq("Patterns to detect XSS attempts")
    end

    it "supports CLOUDFRONT scope" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_wafv2_regex_pattern_set(:cloudfront_patterns, {
          name: "cloudfront-patterns",
          scope: "CLOUDFRONT",
          regular_expression: [
            { regex_string: "malicious-pattern" }
          ],
          tags: {}
        })
      end

      result = synthesizer.synthesis
      pattern_set = result["resource"]["aws_wafv2_regex_pattern_set"]["cloudfront_patterns"]

      expect(pattern_set["scope"]).to eq("CLOUDFRONT")
    end

    it "includes multiple regex patterns" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_wafv2_regex_pattern_set(:multi_patterns, {
          name: "multi-patterns",
          scope: "REGIONAL",
          regular_expression: [
            { regex_string: "pattern-one" },
            { regex_string: "pattern-two" },
            { regex_string: "pattern-three" }
          ],
          tags: {}
        })
      end

      result = synthesizer.synthesis
      pattern_set = result["resource"]["aws_wafv2_regex_pattern_set"]["multi_patterns"]

      expect(pattern_set).to have_key("regular_expression")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_wafv2_regex_pattern_set(:tagged_patterns, {
          name: "tagged-patterns",
          scope: "REGIONAL",
          regular_expression: [
            { regex_string: "test-pattern" }
          ],
          tags: { Environment: "production", Team: "security" }
        })
      end

      result = synthesizer.synthesis
      pattern_set = result["resource"]["aws_wafv2_regex_pattern_set"]["tagged_patterns"]

      expect(pattern_set).to have_key("tags")
      expect(pattern_set["tags"]["Environment"]).to eq("production")
      expect(pattern_set["tags"]["Team"]).to eq("security")
    end
  end

  describe "resource references" do
    it "returns a ResourceReference with correct outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_wafv2_regex_pattern_set(:ref_test, {
          name: "ref-test-patterns",
          scope: "REGIONAL",
          regular_expression: [
            { regex_string: "test" }
          ],
          tags: {}
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq("${aws_wafv2_regex_pattern_set.ref_test.id}")
      expect(ref.outputs[:arn]).to eq("${aws_wafv2_regex_pattern_set.ref_test.arn}")
      expect(ref.outputs[:name]).to eq("${aws_wafv2_regex_pattern_set.ref_test.name}")
    end

    it "returns computed properties" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_wafv2_regex_pattern_set(:computed_test, {
          name: "computed-test",
          scope: "REGIONAL",
          regular_expression: [
            { regex_string: "select.*from" },
            { regex_string: "union.*select" }
          ],
          tags: {}
        })
      end

      expect(ref.computed_properties[:pattern_count]).to eq(2)
      expect(ref.computed_properties[:regional_scope]).to eq(true)
      expect(ref.computed_properties[:cloudfront_scope]).to eq(false)
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_wafv2_regex_pattern_set(:validation_test, {
          name: "validation-test",
          scope: "REGIONAL",
          regular_expression: [
            { regex_string: "test-pattern" }
          ],
          tags: {}
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_wafv2_regex_pattern_set"]).to be_a(Hash)
      expect(result["resource"]["aws_wafv2_regex_pattern_set"]["validation_test"]).to be_a(Hash)

      pattern_set = result["resource"]["aws_wafv2_regex_pattern_set"]["validation_test"]
      expect(pattern_set).to have_key("name")
      expect(pattern_set).to have_key("scope")
      expect(pattern_set).to have_key("regular_expression")
    end
  end
end
